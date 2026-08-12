<?php

namespace App\Http\Controllers;

use App\Models\Post;
use App\Models\PostComment;
use App\Models\PostLike;
use App\Models\Connection;
use Illuminate\Http\Request;

class PostController extends Controller
{
    /** Feed: posts by the user + posts by their accepted connections + public posts. */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

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

        $query = Post::with(['user', 'comments.user'])
            ->withCount(['likes', 'comments'])
            ->where(function ($q) use ($userId, $connectedIds) {
                $q->where('visibility', 'public')
                    ->orWhere('user_id', $userId)
                    ->orWhere(function ($q2) use ($connectedIds) {
                        $q2->where('visibility', 'followers')->whereIn('user_id', $connectedIds);
                    });
            })
            ->latest();

        return response()->json($query->paginate(15));
    }

    public function show(Request $request, string $id)
    {
        $post = Post::with(['user', 'comments.user', 'comments.replies.user'])
            ->withCount(['likes', 'comments'])
            ->findOrFail($id);

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
        ]);

        abort_if(empty($validated['body']) && empty($validated['image_url']) && empty($validated['video_url']), 422, 'Post cannot be empty');

        $post = Post::create([
            'user_id' => $request->user()->id,
            'body' => $validated['body'] ?? null,
            'image_url' => $validated['image_url'] ?? null,
            'video_url' => $validated['video_url'] ?? null,
            'visibility' => $validated['visibility'] ?? 'public',
        ]);

        return response()->json(['data' => $post->load('user')], 201);
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

        $comment = PostComment::create([
            'post_id' => $post->id,
            'user_id' => $request->user()->id,
            'body' => $validated['body'],
            'parent_id' => $validated['parent_id'] ?? null,
        ]);

        return response()->json(['data' => $comment->load('user')], 201);
    }
}
