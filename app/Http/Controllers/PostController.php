<?php

namespace App\Http\Controllers;

use App\Models\Post;
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

        $query = Post::with(['user', 'comments.user'])
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
        $page->getCollection()->transform(function ($post) use ($likedIds) {
            $arr = $post->toArray();
            $arr['liked'] = isset($likedIds[$post->id]);

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

        if ($post->visibility === 'followers' && $post->user_id !== $userId) {
            $allowed = Connection::where('status', 'accepted')
                    ->where(function ($q) use ($userId, $post) {
                        $q->where(fn ($w) => $w->where('follower_user_id', $userId)->where('followee_user_id', $post->user_id))
                            ->orWhere(fn ($w) => $w->where('follower_user_id', $post->user_id)->where('followee_user_id', $userId));
                    })->exists()
                || Follow::where('follower_user_id', $userId)->where('followee_user_id', $post->user_id)->exists();

            abort_unless($allowed && !Block::hasBlockBetween($userId, (int) $post->user_id), 404);
        }

        $postArray = $post->toArray();
        $postArray['liked'] = $post->likedBy($request->user());

        return response()->json(['data' => $postArray]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'body' => 'nullable|string|max:5000',
            'image_url' => 'nullable|string',
            'video_url' => 'nullable|string',
            'visibility' => 'in:public,followers',
            'audience' => 'in:public,followers',
            'hashtags' => 'nullable|array|max:10',
            'hashtags.*' => 'string|max:40',
            'sport_id' => 'nullable|integer|exists:sports,id',
        ]);

        abort_if(empty($validated['body']) && empty($validated['image_url']) && empty($validated['video_url']), 422, 'Post cannot be empty');

        $post = Post::create([
            'user_id' => $request->user()->id,
            'body' => $validated['body'] ?? null,
            'image_url' => $validated['image_url'] ?? null,
            'video_url' => $validated['video_url'] ?? null,
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

        $validated = $request->validate([
            'body' => 'nullable|string|max:5000',
            'image_url' => 'nullable|string',
            'video_url' => 'nullable|string',
            'visibility' => 'in:public,followers',
            'audience' => 'in:public,followers',
            'hashtags' => 'nullable|array|max:10',
            'hashtags.*' => 'string|max:40',
            'sport_id' => 'nullable|integer|exists:sports,id',
        ]);

        $post->update(array_filter([
            'body' => $validated['body'] ?? null,
            'image_url' => $validated['image_url'] ?? null,
            'video_url' => $validated['video_url'] ?? null,
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
        // Comment access mirrors post visibility (see show()).
        if ($post->visibility === 'followers' && $post->user_id !== $request->user()->id) {
            $allowed = Connection::where('status', 'accepted')
                    ->where(function ($q) use ($request, $post) {
                        $q->where(fn ($w) => $w->where('follower_user_id', $request->user()->id)->where('followee_user_id', $post->user_id))
                            ->orWhere(fn ($w) => $w->where('follower_user_id', $post->user_id)->where('followee_user_id', $request->user()->id));
                    })->exists()
                || Follow::where('follower_user_id', $request->user()->id)->where('followee_user_id', $post->user_id)->exists();
            if (!$allowed) {
                return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Connect or follow this user first.']], 403);
            }
        }
        $comments = PostComment::where('post_id', $post->id)
            ->with('user')
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
        // Commenting on followers-only posts requires follow/connection (like show()).
        if ($post->visibility === 'followers' && $post->user_id !== $request->user()->id) {
            $allowed = Connection::where('status', 'accepted')
                    ->where(function ($q) use ($request, $post) {
                        $q->where(fn ($w) => $w->where('follower_user_id', $request->user()->id)->where('followee_user_id', $post->user_id))
                            ->orWhere(fn ($w) => $w->where('follower_user_id', $post->user_id)->where('followee_user_id', $request->user()->id));
                    })->exists()
                || Follow::where('follower_user_id', $request->user()->id)->where('followee_user_id', $post->user_id)->exists();
            if (!$allowed) {
                return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Connect or follow this user first.']], 403);
            }
        }

        $comment = PostComment::create([
            'post_id' => $post->id,
            'user_id' => $request->user()->id,
            'body' => $validated['body'],
            'parent_id' => $validated['parent_id'] ?? null,
        ]);

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
        }

        return response()->json(['data' => $comment->load('user')], 201);
    }
}
