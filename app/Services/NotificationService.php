<?php

namespace App\Services;

use App\Events\NotificationCreated;
use App\Models\Notification;

class NotificationService
{
    public function create(array $data): Notification
    {
        $notification = Notification::create([
            'user_id' => $data['user_id'],
            'type' => $data['type'],
            'title' => $data['title'],
            'body' => $data['body'],
            'notifiable_type' => $data['notifiable_type'] ?? null,
            'notifiable_id' => $data['notifiable_id'] ?? null,
            'action_url' => $data['action_url'] ?? null,
        ]);

        NotificationCreated::dispatch($notification);

        return $notification;
    }

    public static function createStatic(array $data): Notification
    {
        return (new self)->create($data);
    }
}
