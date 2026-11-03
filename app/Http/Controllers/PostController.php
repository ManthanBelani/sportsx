<?php

namespace App\Http\Controllers;

use App\Models\Post;
use App\Models\MediaItem;
use App\Support\PlatformSettings;
use App\Models\PostComment;
use App\Models\PostLike;
use App\Models\Block;
use App\Models\Connection;
use App\Models\Follow;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class PostController extends Controller
{
    /** Feed: posts by the user + followers-scoped posts + public posts. */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        $blockedIds = Block::where('blocker_user_id', $userId)->pluck('blocked_user_id')
            ->merge(Block::where('blocked_user_id', $userId)->pluck('blocker_user_id'))
            ->unique()->all();

        $connectedIds = Connection::where('status', 'accepted')
            ->where(fn ($q) => $q->where('follower_user_id', $userId)->orWhere('followee_user_id', $userId))
            ->pluck('follower_user_id')
            ->merge(
                Connection::where('status', 'accepted')
                    ->where(fn ($q) => $q->where('follower_user_id', $userId)->orWhere('followee_user_id', $userId))
                    ->pluck('followee_user_id')
            )
            ->push($userId)
            ->unique();

        // Users I follow (one-way) — they can share `followers` posts with me.
        $followedIds = Follow::where('follower_user_id', $userId)
            ->whereNotIn('followee_user_id', $blockedIds)
            ->pluck('followee_user_id')
            ->merge($connectedIds)
            ->unique()
            ->all();

        // ?following=1 → only posts authored by people I follow (I still see my own posts).
        $onlyFollowing = $request->boolean('following');
        if ($onlyFollowing) {
            $followedIds = array_values(array_unique(array_merge($followedIds, [$userId])));
        }

        // Feed rows carry counts + first-image URL only. Comments are NOT
        // hydrated here (they're paginated per post via /posts/{id}/comments)
        // — loading every comment of every post made the feed payload grow
        // linearly with engagement.
        $query = Post::with(['user'])
            ->withCount(['likes', 'comments'])
            ->when($onlyFollowing, fn ($q) => $q->whereIn('user_id', $followedIds))
            ->when(!$onlyFollowing, fn ($q) => $q->whereNotIn('user_id', $blockedIds))
            // ?author_role=organizer → role-scoped feed, so each role sees the
            // content that is relevant to it (coaching posts for a coach,
            // tournament posts for an organizer, …).
            ->when($request->filled('author_role'), function ($q) use ($request) {
                $roles = array_filter(array_map(
                    fn ($r) => strtolower(trim((string) $r)),
                    explode(',', (string) $request->query('author_role'))
                ));
                $q->whereHas('user', fn ($uq) => $uq->whereIn('role', $roles));
            })
            ->where(function ($q) use ($userId, $followedIds) {
                $q->where('visibility', 'public')
                    ->orWhere('user_id', $userId)
                    ->orWhere(function ($q2) use ($followedIds) {
                        $q2->where('visibility', 'followers')->whereIn('user_id', $followedIds);
                    });
            })
            ->latest();

        $page = $query->paginate(15);
        // Single-query liked map so feed rows carry correct heart state (G-2).
        $likedIds = PostLike::where('user_id', $userId)->whereIn('post_id', $page->getCollection()->pluck('id'))->pluck('post_id')->flip();
        // One query for every multi-photo post on the page.
        $pageImageIds = $page->getCollection()
            ->flatMap(fn ($post) => (array) ($post->image_media_ids ?? []))
            ->unique()->values()->all();
        $imageUrls = $pageImageIds
            ? MediaItem::whereIn('id', $pageImageIds)->get()->mapWithKeys(fn ($m) => [$m->id => $m->url()])
            : collect();
        $page->getCollection()->transform(function ($post) use ($likedIds, $imageUrls) {
            $arr = $post->toArray();
            $arr['liked'] = isset($likedIds[$post->id]);
            $arr['images'] = collect((array) ($post->image_media_ids ?? []))
                ->map(fn ($id) => $imageUrls[$id] ?? null)
                ->filter()->values()->all();

            return $arr;
        });

        return response()->json($page);
    }

    /** GET /posts/{id} — visibility enforced: public, own, or follower/connected for `followers` posts. 404 hides existence. */
    public function show(Request $request, string $id)
    {
        $userId = $request->user()->id;
        $post = Post::with(['user', 'comments.user', 'comments.replies.user'])
            ->withCount(['likes', 'comments'])
            ->findOrFail($id);

        // Blocks hide the post entirely (404), for any visibility.
        abort_if(Block::hasBlockBetween($userId, (int) $post->user_id) && $post->user_id !== $userId, 404);

        if ($post->visibility === 'followers' && $post->user_id !== $userId) {
            $allowed = self::viewerLinkedTo($userId, (int) $post->user_id);

            abort_unless($allowed, 404);
        }

        $postArray = self::withImageUrls($post->toArray());
        $postArray['liked'] = $post->likedBy($request->user());

        return response()->json(['data' => $postArray]);
    }

    /** Whether the viewer follows or is connected with the author (shared by show/comments/comment). */
    private static function viewerLinkedTo(int $viewerId, int $authorId): bool
    {
        return Connection::where('status', 'accepted')
                ->where(function ($q) use ($viewerId, $authorId) {
                    $q->where(fn ($w) => $w->where('follower_user_id', $viewerId)->where('followee_user_id', $authorId))
                        ->orWhere(fn ($w) => $w->where('follower_user_id', $authorId)->where('followee_user_id', $viewerId));
                })->exists()
            || Follow::where('follower_user_id', $viewerId)->where('followee_user_id', $authorId)->exists();
    }

    /** Resolve image_media_ids to absolute URL list for multi-photo rendering. */
    private static function withImageUrls(array $postArray): array
    {
        $ids = $postArray['image_media_ids'] ?? [];
        $postArray['images'] = [];
        if (! empty($ids) && is_array($ids)) {
            $postArray['images'] = MediaItem::whereIn('id', $ids)
                ->orderByRaw('FIELD(id, '.implode(',', array_map('intval', $ids)).')')
                ->get()
                ->map(fn ($m) => $m->url())
                ->all();
        }

        return $postArray;
    }

    public function store(Request $request)
    {
        // Video posts are no longer supported (photos only). Existing posts
        // with video_url remain renderable; new posts cannot set it.
        if ($request->filled('video_url')) {
            abort(422, 'Video posts are no longer supported. Please upload a photo.');
        }

        $validated = $request->validate([
            'body' => 'nullable|string|max:5000',
            // Only platform-uploaded media paths — a free-form URL would let a
            // post embed arbitrary third-party content.
            'image_url' => 'nullable|string|max:500|starts_with:/storage/',
            'image_media_ids' => 'nullable|array|max:'.(int) (PlatformSettings::get('post_max_photos', 5)),
            'image_media_ids.*' => 'integer|exists:media_items,id',
            'visibility' => 'in:public,followers',
            'audience' => 'in:public,followers',
            'hashtags' => 'nullable|array|max:10',
            'hashtags.*' => 'string|max:40',
            'sport_id' => 'nullable|integer|exists:sports,id',
        ]);

        // Multi-photo posts (Step 3G): every media id must belong to the
        // caller (user row or the caller's own profile rows) and be a photo.
        $imageMediaIds = null;
        $imageUrl = $validated['image_url'] ?? null;
        if (! empty($validated['image_media_ids'])) {
            $u = $request->user();
            $ownableIds = collect([$u->id])
                ->merge([$u->athleteProfile?->id, $u->coachProfile?->id, $u->academies?->id,
                    $u->organizerProfile?->id, $u->sponsorProfile?->id, $u->talentScoutProfile?->id])
                ->filter()->map(fn ($i) => (int) $i)->all();
            $medias = MediaItem::whereIn('id', $validated['image_media_ids'])
                ->where('media_type', 'photo')
                ->whereIn('owner_id', $ownableIds)
                ->get()
                ->keyBy('id');
            foreach ($validated['image_media_ids'] as $id) {
                abort_if(! isset($medias[$id]), 422, 'One of the attached photos does not belong to you.');
            }
            $imageMediaIds = $validated['image_media_ids'];
            // Keep image_url in sync with the first photo so every existing
            // reader (feed, cards, notifications) keeps rendering.
            $imageUrl ??= $medias[$imageMediaIds[0]]->url();
        }

        abort_if(empty($validated['body']) && empty($imageUrl), 422, 'Post cannot be empty');

        $post = Post::create([
            'user_id' => $request->user()->id,
            'body' => $validated['body'] ?? null,
            'image_url' => $imageUrl,
            'image_media_ids' => $imageMediaIds,
            'visibility' => $validated['visibility'] ?? $validated['audience'] ?? 'public',
            'audience' => $validated['audience'] ?? $validated['visibility'] ?? 'public',
            'hashtags' => $validated['hashtags'] ?? null,
            'sport_id' => $validated['sport_id'] ?? null,
        ]);

        return response()->json(['data' => $post->load('user')], 201);
    }

    /** PATCH /posts/{id} — owner or admin. */
    public function update(Request $request, string $id)
    {
        $post = Post::findOrFail($id);
        abort_unless($post->user_id === $request->user()->id || $request->user()->isAdmin(), 403);

        if ($request->filled('video_url') && $request->input('video_url') !== $post->video_url) {
            abort(422, 'Video posts are no longer supported. Please upload a photo.');
        }

        $validated = $request->validate([
            'body' => 'nullable|string|max:5000',
            // Only platform-uploaded media paths (see store()).
            'image_url' => 'nullable|string|max:500|starts_with:/storage/',
            'image_media_ids' => 'nullable|array|max:'.(int) (PlatformSettings::get('post_max_photos', 5)),
            'image_media_ids.*' => 'integer|exists:media_items,id',
            'visibility' => 'in:public,followers',
            'audience' => 'in:public,followers',
            'hashtags' => 'nullable|array|max:10',
            'hashtags.*' => 'string|max:40',
            'sport_id' => 'nullable|integer|exists:sports,id',
        ]);

        $imageMediaIds = $post->image_media_ids;
        $imageUrl = $validated['image_url'] ?? $post->image_url;
        if (array_key_exists('image_media_ids', $validated)) {
            if (! empty($validated['image_media_ids'])) {
                $u = $request->user();
                $ownableIds = collect([$u->id])
                    ->merge([$u->athleteProfile?->id, $u->coachProfile?->id, $u->academies?->id,
                        $u->organizerProfile?->id, $u->sponsorProfile?->id, $u->talentScoutProfile?->id])
                    ->filter()->map(fn ($i) => (int) $i)->all();
                $medias = MediaItem::whereIn('id', $validated['image_media_ids'])
                    ->where('media_type', 'photo')
                    ->whereIn('owner_id', $ownableIds)
                    ->get()->keyBy('id');
                foreach ($validated['image_media_ids'] as $id) {
                    abort_if(! isset($medias[$id]), 422, 'One of the attached photos does not belong to you.');
                }
                $imageMediaIds = $validated['image_media_ids'];
                $imageUrl = $medias[$imageMediaIds[0]]->url();
            } else {
                $imageMediaIds = null;
                $imageUrl = null;
            }
        }

        $post->update(array_filter([
            'body' => $validated['body'] ?? null,
            'image_url' => $imageUrl,
            'image_media_ids' => $imageMediaIds,
            'visibility' => $validated['visibility'] ?? $validated['audience'] ?? null,
            'audience' => $validated['audience'] ?? $validated['visibility'] ?? null,
            'sport_id' => $validated['sport_id'] ?? null,
        ], fn ($v) => $v !== null) + (array_key_exists('hashtags', $validated) ? ['hashtags' => $validated['hashtags']] : []));

        return response()->json(['data' => $post->fresh()->load('user')]);
    }

    /** DELETE /posts/{id} — owner or admin. */
    public function destroy(Request $request, string $id)
    {
        $post = Post::findOrFail($id);
        abort_unless($post->user_id === $request->user()->id || $request->user()->isAdmin(), 403);
        $post->delete();

        return response()->json(['data' => ['message' => 'Deleted']]);
    }

    /** GET /posts/{id}/comments */
    public function comments(Request $request, string $id)
    {
        $post = Post::findOrFail($id);
        $userId = $request->user()->id;

        // Blocks: a blocked pair cannot read each other's comment threads.
        abort_if($post->user_id !== $userId && Block::hasBlockBetween($userId, (int) $post->user_id), 404);

        // Comment access mirrors post visibility (see show()).
        if ($post->visibility === 'followers' && $post->user_id !== $userId) {
            if (! self::viewerLinkedTo($userId, (int) $post->user_id)) {
                return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Connect or follow this user first.']], 403);
            }
        }
        // Top-level comments with their replies threaded (same shape as show()).
        $comments = PostComment::where('post_id', $post->id)
            ->whereNull('parent_id')
            ->with(['user', 'replies.user'])
            ->latest()
            ->paginate(20);

        return response()->json($comments);
    }

    /** DELETE /comments/{id} — comment owner, post owner, or admin. */
    public function deleteComment(Request $request, string $id)
    {
        $comment = PostComment::findOrFail($id);
        $post = Post::find($comment->post_id);
        $isOwner = $comment->user_id === $request->user()->id
            || ($post && $post->user_id === $request->user()->id)
            || $request->user()->isAdmin();
        abort_unless($isOwner, 403);
        $comment->delete();

        return response()->json(['data' => ['message' => 'Deleted']]);
    }

    /** DELETE /posts/{id}/like — explicit unlike (toggle POST kept for compat). */
    public function unlike(Request $request, string $id)
    {
        PostLike::where('post_id', $id)->where('user_id', $request->user()->id)->delete();
        $count = PostLike::where('post_id', $id)->count();

        return response()->json(['data' => ['liked' => false, 'likes_count' => $count]]);
    }

    public function toggleLike(Request $request, string $id)
    {
        $post = Post::findOrFail($id);
        $userId = $request->user()->id;

        // Likes respect the same walls as viewing: blocked pairs and
        // followers-only posts the viewer isn't linked to are off-limits.
        abort_if($post->user_id !== $userId && Block::hasBlockBetween($userId, (int) $post->user_id), 404);
        if ($post->visibility === 'followers' && $post->user_id !== $userId) {
            abort_unless(self::viewerLinkedTo($userId, (int) $post->user_id), 404);
        }

        $like = PostLike::where('post_id', $id)->where('user_id', $userId)->first();

        if ($like) {
            $like->delete();
            $liked = false;
        } else {
            PostLike::create(['post_id' => $id, 'user_id' => $userId]);
            $liked = true;
            // Notify author (skip self-likes; prefs + block gates inside service).
            if ((int) $post->user_id !== (int) $userId && !Block::hasBlockBetween((int) $userId, (int) $post->user_id)) {
                NotificationService::createStatic([
                    'user_id' => $post->user_id,
                    'type' => 'like',
                    'title' => 'New like',
                    'body' => ($request->user()->name ?? 'Someone').' liked your post.',
                    'notifiable_type' => 'post',
                    'notifiable_id' => $post->id,
                    'action_url' => '/post-detail/'.$post->id,
                ]);
            }
        }

        return response()->json(['data' => ['liked' => $liked, 'likes_count' => $post->likes()->count()]]);
    }

    public function comment(Request $request, string $id)
    {
        $validated = $request->validate([
            'body' => 'required|string|max:2000',
            'parent_id' => 'nullable|integer|exists:post_comments,id',
        ]);

        $post = Post::findOrFail($id);
        $userId = $request->user()->id;

        // Blocks: a blocked pair cannot comment on each other's posts.
        abort_if($post->user_id !== $userId && Block::hasBlockBetween($userId, (int) $post->user_id), 404);

        // Commenting on followers-only posts requires follow/connection (like show()).
        if ($post->visibility === 'followers' && $post->user_id !== $userId) {
            if (! self::viewerLinkedTo($userId, (int) $post->user_id)) {
                return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Connect or follow this user first.']], 403);
            }
        }

        $comment = PostComment::create([
            'post_id' => $post->id,
            'user_id' => $request->user()->id,
            'body' => $validated['body'],
            'parent_id' => $validated['parent_id'] ?? null,
        ]);

        $notified = [];
        if ((int) $post->user_id !== (int) $request->user()->id && !Block::hasBlockBetween((int) $request->user()->id, (int) $post->user_id)) {
            NotificationService::createStatic([
                'user_id' => $post->user_id,
                'type' => 'comment',
                'title' => 'New comment',
                'body' => ($request->user()->name ?? 'Someone').' commented on your post.',
                'notifiable_type' => 'post',
                'notifiable_id' => $post->id,
                'action_url' => '/post-detail/'.$post->id,
            ]);
            $notified[] = (int) $post->user_id;
        }

        // Replies also notify the parent-comment owner (unless already
        // notified as the post author, self, or blocked).
        if (! empty($validated['parent_id'])) {
            $parent = PostComment::find($validated['parent_id']);
            $parentId = (int) ($parent->user_id ?? 0);
            if ($parent
                && $parentId !== (int) $request->user()->id
                && ! in_array($parentId, $notified, true)
                && ! Block::hasBlockBetween((int) $request->user()->id, $parentId)) {
                NotificationService::createStatic([
                    'user_id' => $parentId,
                    'type' => 'comment',
                    'title' => 'New reply',
                    'body' => ($request->user()->name ?? 'Someone').' replied to your comment.',
                    'notifiable_type' => 'post',
                    'notifiable_id' => $post->id,
                    'action_url' => '/post-detail/'.$post->id,
                ]);
            }
        }

        return response()->json(['data' => $comment->load('user')], 201);
    }
}
