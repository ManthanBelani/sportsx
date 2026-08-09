<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $query = Notification::where('user_id', $user->id)
            ->orderBy('created_at', 'desc');

        if ($request->boolean('unread_only')) {
            $query->where('is_read', false);
        }

        $notifications = $query->paginate(20);

        return response()->json([
            'data' => $notifications->items(),
            'meta' => [
                'pagination' => [
                    'total' => $notifications->total(),
                    'per_page' => $notifications->perPage(),
                    'current_page' => $notifications->currentPage(),
                    'last_page' => $notifications->lastPage(),
                ],
                'unread_count' => Notification::where('user_id', $user->id)->where('is_read', false)->count(),
            ],
        ]);
    }

    public function markRead(Request $request, Notification $notification)
    {
        abort_unless($notification->user_id === $request->user()->id, 403);
        $notification->update(['is_read' => true]);

        return response()->json(['data' => $notification]);
    }

    public function markAllRead(Request $request)
    {
        $user = $request->user();
        Notification::where('user_id', $user->id)->where('is_read', false)->update(['is_read' => true]);

        return response()->json(['data' => ['message' => 'All notifications marked as read']]);
    }

    public function destroy(Notification $notification)
    {
        abort_unless($notification->user_id === request()->user()->id, 403);
        $notification->delete();

        return response()->json(['data' => ['message' => 'Notification deleted']]);
    }
}
