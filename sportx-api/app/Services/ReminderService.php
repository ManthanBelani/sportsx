<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\ReminderSubscription;
use Carbon\Carbon;

class ReminderService
{
    /**
     * Arm reminder subscriptions for a user at the configured offsets (T-2d, T-1d)
     * before the given target date.
     */
    public function arm(int $userId, string $type, int $id, $targetDate): void
    {
        if (! $targetDate) {
            return;
        }

        $target = Carbon::parse($targetDate);
        $offsets = config('sportx.reminder.offsets', ['2_days' => 2, '1_day' => 1]);

        foreach ($offsets as $days) {
            $remindAt = $target->copy()->subDays((int) $days)->setTime(9, 0);
            if ($remindAt->isPast()) {
                continue;
            }

            ReminderSubscription::firstOrCreate([
                'user_id' => $userId,
                'reminderable_type' => $type,
                'reminderable_id' => $id,
                'remind_at' => $remindAt,
            ]);
        }
    }

    /**
     * Remove pending reminders for a user+item (reminder toggle off / item unsaved).
     */
    public function disarm(int $userId, string $type, int $id): void
    {
        ReminderSubscription::where('user_id', $userId)
            ->where('reminderable_type', $type)
            ->where('reminderable_id', $id)
            ->whereNull('sent_at')
            ->delete();
    }

    /**
     * Send all due reminders as in-app notifications. Returns count sent.
     */
    public function sendDue(): int
    {
        $due = ReminderSubscription::whereNull('sent_at')
            ->where('remind_at', '<=', now())
            ->get();

        foreach ($due as $reminder) {
            Notification::create([
                'user_id' => $reminder->user_id,
                'type' => 'reminder',
                'title' => 'Reminder',
                'body' => 'An item you saved or registered for is coming up.',
                'notifiable_type' => $reminder->reminderable_type,
                'notifiable_id' => $reminder->reminderable_id,
            ]);

            $reminder->update(['sent_at' => now()]);
        }

        return $due->count();
    }
}
