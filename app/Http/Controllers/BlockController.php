<?php

namespace App\Http\Controllers;

use App\Models\Block;
use App\Models\Connection;
use App\Models\Conversation;
use App\Models\Follow;
use App\Models\User;
use Illuminate\Http\Request;

class BlockController extends Controller
{
    /** GET /blocks — users I blocked. */
    public function index(Request $request)
    {
        $rows = Block::where('blocker_user_id', $request->user()->id)
            ->with('blocked')
            ->latest()
            ->paginate(30);

        return response()->json($rows);
    }

    /** POST /blocks {user_id} — block; hides both ways, disables chat/follow. */
    public function store(Request $request)
    {
        $validated = $request->validate(['user_id' => 'required|integer|exists:users,id']);
        $me = $request->user()->id;
        $other = (int) $validated['user_id'];
        abort_if($other === $me, 422, 'You cannot block yourself.');

        $block = Block::firstOrCreate(['blocker_user_id' => $me, 'blocked_user_id' => $other]);

        // Disable follow both ways.
        Follow::where(fn ($q) => $q
            ->where(fn ($w) => $w->where('follower_user_id', $me)->where('followee_user_id', $other))
            ->orWhere(fn ($w) => $w->where('follower_user_id', $other)->where('followee_user_id', $me))
        )->delete();

        // Remove connections both ways (kills chat unlock path).
        Connection::where(fn ($q) => $q
            ->where(fn ($w) => $w->where('follower_user_id', $me)->where('followee_user_id', $other))
            ->orWhere(fn ($w) => $w->where('follower_user_id', $other)->where('followee_user_id', $me))
        )->delete();

        return response()->json(['data' => $block], $block->wasRecentlyCreated ? 201 : 200);
    }

    /** DELETE /blocks/{user} — unblock. */
    public function destroy(Request $request, int $user)
    {
        Block::where('blocker_user_id', $request->user()->id)
            ->where('blocked_user_id', $user)
            ->delete();

        return response()->json(['data' => ['message' => 'Unblocked']]);
    }
}
