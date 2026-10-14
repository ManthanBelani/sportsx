<?php

namespace App\Http\Controllers;

use App\Jobs\SendPushNotification;
use App\Models\Notification;
use App\Models\UserDeviceToken;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * GET /me/notifications?tab=All|People|Opportunities|Events|Mentions
     * + unread_only. Returns meta.unread_count.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $query = Notification::where('user_id', $user->id)
            ->orderBy('created_at', 'desc');

        $tab = strtolower($request->query('tab', 'all'));
        $query = match ($tab) {
            'people' => $query->where(fn ($q) => $q
                ->whereIn('type', ['connection', 'follow', 'status_update', 'account_action'])
                ->orWhere('category', 'people')),
            'opportunities', 'opps' => $query->where(fn ($q) => $q
                ->where('category', 'opportunities')
                ->orWhere('notifiable_type', 'like', 'opportunity%')),
            'events' => $query->where(fn ($q) => $q
                ->where('category', 'events')
                ->orWhereIn('type', ['reminder', 'enquiry_reply', 'registration_approved', 'registration_rejected'])),
            'mentions' => $query->where(fn ($q) => $q
                ->where('category', 'mentions')
                ->orWhereIn('type', ['mention', 'comment', 'like', 'message'])),
            default => $query,
        };

        if ($request->boolean('unread_only')) {
            $query->whereNull('read_at');
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
                'unread_count' => Notification::where('user_id', $user->id)->whereNull('read_at')->count(),
            ],
        ]);
    }

    public function markRead(Request $request, Notification $notification)
    {
        abort_unless($notification->user_id === $request->user()->id, 403);
        $notification->update(['read_at' => now()]);

        return response()->json(['data' => $notification]);
    }

    public function markAllRead(Request $request)
    {
        $user = $request->user();
        Notification::where('user_id', $user->id)->whereNull('read_at')->update(['read_at' => now()]);

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
            $notification->body ?? '',
            $notification->toPushPayload(),
            $user->id,
            $notification->id
        )->onQueue('push');

        return response()->json(['data' => ['message' => 'Push notification queued']]);
    }
}
