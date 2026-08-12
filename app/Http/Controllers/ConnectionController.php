<?php

namespace App\Http\Controllers;

use App\Models\Connection;
use Illuminate\Http\Request;

class ConnectionController extends Controller
{
    /** Request to follow/connect with another user. */
    public function request(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|integer|exists:users,id|not_in:' . $request->user()->id,
        ]);

        $userId = $request->user()->id;
        $targetId = $validated['user_id'];

        $connection = Connection::firstOrCreate(
            ['follower_user_id' => $userId, 'followee_user_id' => $targetId],
            ['status' => 'pending']
        );

        // Auto-accept if the counterpart already follows (mutual consent).
        $reverse = Connection::where('follower_user_id', $targetId)
            ->where('followee_user_id', $userId)
            ->first();

        if ($reverse && $reverse->status === 'accepted') {
            $connection->update(['status' => 'accepted']);
        }

        return response()->json(['data' => $connection], 201);
    }

    /** Accept an incoming request. */
    public function accept(Request $request, string $id)
    {
        $connection = Connection::where('id', $id)
            ->where('followee_user_id', $request->user()->id)
            ->where('status', 'pending')
            ->firstOrFail();

        $connection->update(['status' => 'accepted']);

        return response()->json(['data' => $connection]);
    }

    /** Reject / remove a connection. */
    public function destroy(Request $request, string $id)
    {
        $connection = Connection::where('id', $id)
            ->where(fn ($q) => $q->where('follower_user_id', $request->user()->id)
                ->orWhere('followee_user_id', $request->user()->id))
            ->firstOrFail();

        $connection->delete();

        return response()->json(['data' => ['message' => 'Removed']]);
    }

    /** The user's accepted connections. */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        $connections = Connection::where('status', 'accepted')
            ->where(fn ($q) => $q->where('follower_user_id', $userId)->orWhere('followee_user_id', $userId))
            ->with(['follower', 'followee'])
            ->latest()
            ->paginate(30);

        return response()->json($connections);
    }

    /** Incoming pending requests. */
    public function requests(Request $request)
    {
        $requests = Connection::where('followee_user_id', $request->user()->id)
            ->where('status', 'pending')
            ->with('follower')
            ->latest()
            ->paginate(30);

        return response()->json($requests);
    }
}
