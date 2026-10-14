<?php

namespace App\Jobs;

use App\Models\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class PruneNotificationRowsJob implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        $days = (int) config('sportx.notifications.retention_days', 90);
        Notification::where('created_at', '<', now()->subDays($days))->delete();
    }
}
