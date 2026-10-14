<?php

namespace App\Services;

use App\Events\NotificationCreated;
use App\Jobs\SendPushNotification;
use App\Mail\NotificationFallbackMail;
use App\Models\Notification;
use App\Models\User;
use App\Models\UserDeviceToken;
use Illuminate\Support\Facades\Mail;

class NotificationService
{
    /**
     * Notification categories users can toggle. Rows in HARD_OVERRIDE_TYPES
     * bypass every toggle: account decisions and registration outcomes must
     * always reach the user (in-app + email), never silently dropped.
     */
    public const CATEGORIES = ['people', 'opportunities', 'events', 'mentions', 'reminders', 'broadcasts'];

    public const HARD_OVERRIDE_TYPES = ['account_action', 'registration_approved', 'registration_rejected'];

    public static function isHardOverride(string $type): bool
    {
        return in_array(strtolower($type), self::HARD_OVERRIDE_TYPES, true);
    }

    /** Map a notification type to its user-facing category. */
    public static function categoryFor(string $type, ?string $notifiableType = null): string
    {
        $t = strtolower($type);
        $nt = strtolower($notifiableType ?? '');
        if (str_contains($nt, 'opportunity')) {
            return 'opportunities';
        }
        if (str_contains($t, 'remind')) {
            return 'reminders';
        }
        if (str_contains($t, 'broadcast')) {
            return 'broadcasts';
        }
        if (str_contains($t, 'mention') || str_contains($t, 'comment') || str_contains($t, 'like') || str_contains($t, 'message')) {
            return 'mentions';
        }
        if (str_contains($t, 'trial') || str_contains($t, 'tournament') || str_contains($t, 'regist')
            || str_contains($t, 'enquir') || str_contains($t, 'event')) {
            return 'events';
        }

        return 'people';
    }

    /** Read merged prefs: global push + per-category toggles. */
    public static function prefsFor(User $user): array
    {
        $default = ['push' => true, 'in_app' => true, 'categories' => array_fill_keys(self::CATEGORIES, true)];
        $raw = $user->notification_prefs;
        $prefs = is_array($raw) ? $raw : (is_string($raw) && $raw !== '' ? (json_decode($raw, true) ?: []) : []);
        $merged = array_merge($default, is_array($prefs) ? $prefs : []);
        $merged['categories'] = array_merge($default['categories'], (array) ($merged['categories'] ?? []));

        return $merged;
    }

    public function create(array $data): Notification
    {
        // Row first: the in-app row is the source of truth.
        $notification = Notification::create([
            'user_id' => $data['user_id'],
            'type' => $data['type'],
            'category' => $data['category'] ?? self::categoryFor($data['type'], $data['notifiable_type'] ?? null),
            'title' => $data['title'],
            'body' => $data['body'],
            'notifiable_type' => $data['notifiable_type'] ?? null,
            'notifiable_id' => $data['notifiable_id'] ?? null,
            'action_url' => $data['action_url'] ?? null,
            'image_url' => $data['image_url'] ?? null,
            'priority' => $data['priority'] ?? 'normal',
            'metadata' => $data['metadata'] ?? null,
            'push_status' => 'queued',
        ]);

        $user = User::find($data['user_id']);
        if (!$user) {
            $notification->update(['push_status' => 'failed']);

            return $notification;
        }

        $hardOverride = self::isHardOverride($notification->type);
        $prefs = self::prefsFor($user);

        // Preference gate (skipped for hard overrides): a disabled category
        // suppresses the push, never the in-app row (exit criterion).
        if (!$hardOverride) {
            $categoryOn = (bool) ($prefs['categories'][$notification->category] ?? true);
            $pushOn = (bool) ($prefs['push'] ?? true);
            if (!$categoryOn || !$pushOn) {
                $notification->update(['push_status' => 'suppressed']);

                return $notification;
            }
        }

        NotificationCreated::dispatch($notification);

        $wantsPush = $hardOverride || ($prefs['push'] ?? true);
        $tokens = $wantsPush
            ? UserDeviceToken::forUser($user->id)->active()->pluck('token')->all()
            : [];

        if (empty($tokens)) {
            // No push possible: email fallback (skip silently when no email).
            $notification->update(['push_status' => 'no_devices']);
            $this->emailFallback($user, $notification);

            return $notification;
        }

        $batchSize = (int) config('sportx.notifications.fcm.batch_size', 500);
        foreach (array_chunk($tokens, $batchSize) as $chunk) {
            SendPushNotification::dispatch(
                $chunk,
                $notification->title,
                $notification->body,
                $notification->toPushPayload(),
                $user->id,
                $notification->id
            )->onQueue('push');
        }

        return $notification;
    }

    /** Email fallback for users unreachable by push (incl. hard overrides). */
    public function emailFallback(User $user, Notification $notification): void
    {
        if (empty($user->email)) {
            return;
        }
        try {
            Mail::queue(new NotificationFallbackMail(
                $user->email,
                $notification->title,
                $notification->body,
                $notification->action_url
            ));
        } catch (\Throwable) {
        }
    }

    public static function createStatic(array $data): Notification
    {
        return (new self)->create($data);
    }
}
