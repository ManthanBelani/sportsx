<?php

namespace App\Listeners;

use App\Events\NotificationCreated;

/**
 * Deprecated shim (Phase 9).
 *
 * Push fan-out is owned by NotificationService::create (prefs gate,
 * push_status, chunked SendPushNotification on the `push` queue, email
 * fallback). This listener intentionally no-ops so a notification is
 * never fanned out twice. Kept (not deleted) so the
 * NotificationCreated event stays observable for logging/analytics.
 */
class SendPushNotificationListener
{
    public function handle(NotificationCreated $event): void
    {
        return;
    }
}
