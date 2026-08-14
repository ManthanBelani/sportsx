<?php

namespace App\Http\Controllers;

use App\Jobs\SendPushNotification;
use App\Models\Notification;
use App\Models\UserDeviceToken;
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

    public function registerDeviceToken(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string',
            'device_type' => 'required|in:ios,android,web',
            'device_id' => 'nullable|string',
        ]);

        $user = $request->user();

        $existingToken = UserDeviceToken::where('token', $validated['token'])->first();

        if ($existingToken) {
            $existingToken->update([
                'user_id' => $user->id,
                'device_type' => $validated['device_type'],
                'device_id' => $validated['device_id'] ?? null,
                'is_active' => true,
            ]);
        } else {
            UserDeviceToken::create([
                'user_id' => $user->id,
                'token' => $validated['token'],
                'device_type' => $validated['device_type'],
                'device_id' => $validated['device_id'] ?? null,
                'is_active' => true,
            ]);
        }

        return response()->json(['data' => ['message' => 'Device token registered']]);
    }

    public function unregisterDeviceToken(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string',
        ]);

        $user = $request->user();

        UserDeviceToken::where('user_id', $user->id)
            ->where('token', $validated['token'])
            ->update(['is_active' => false]);

        return response()->json(['data' => ['message' => 'Device token unregistered']]);
    }

    public function sendPushNotification(Request $request)
    {
        $validated = $request->validate([
            'notification_id' => 'required|exists:notifications,id',
        ]);

        $notification = Notification::findOrFail($validated['notification_id']);
        $user = $notification->user;

        $deviceTokens = UserDeviceToken::where('user_id', $user->id)
            ->active()
            ->pluck('token')
            ->toArray();

        if (empty($deviceTokens)) {
            return response()->json(['data' => ['message' => 'No active device tokens found']]);
        }

        SendPushNotification::dispatch(
            $deviceTokens,
            $notification->title ?? 'SportX',
            $notification->message ?? '',
            [
                'notification_id' => (string) $notification->id,
                'type' => $notification->type ?? 'general',
                'action_url' => $notification->action_url ?? '',
            ],
            $user->id
        );

        return response()->json(['data' => ['message' => 'Push notification queued']]);
    }
}
