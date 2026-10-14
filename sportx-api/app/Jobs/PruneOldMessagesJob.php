<?php

namespace App\Jobs;

use App\Models\Message;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class PruneOldMessagesJob implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        $days = (int) config('sportx.chat.retention_days', 90);
        Message::where('created_at', '<', now()->subDays($days))->delete();
    }
}
