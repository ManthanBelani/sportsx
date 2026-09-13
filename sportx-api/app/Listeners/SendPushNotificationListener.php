<?php

namespace App\Listeners;

use App\Events\NotificationCreated;
use App\Jobs\SendPushNotification;
use App\Models\UserDeviceToken;

class SendPushNotificationListener
{
    public function handle(NotificationCreated $event): void
    {
        $notification = $event->notification;
        $notification->load('user');

        $user = $notification->user;
        $prefs = $user->notification_prefs ?? [];

        if (isset($prefs['push']) && $prefs['push'] === false) {
            return;
        }

        $deviceTokens = UserDeviceToken::where('user_id', $notification->user_id)
            ->active()
            ->pluck('token')
            ->toArray();

        if (empty($deviceTokens)) {
            return;
        }

        SendPushNotification::dispatch(
            $deviceTokens,
            $notification->title ?? 'SportX',
            $notification->body ?? '',
            [
                'notification_id' => (string) $notification->id,
                'type' => $notification->type ?? 'general',
                'action_url' => $notification->action_url ?? '',
            ],
            $notification->user_id
        );
    }
}
