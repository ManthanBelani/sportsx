<?php

namespace App\Jobs;

use App\Services\ReminderService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class SendDueRemindersJob implements ShouldQueue
{
    use Queueable;

    public function handle(ReminderService $reminders): void
    {
        $count = $reminders->sendDue();
        if ($count > 0) {
            Log::info("SendDueRemindersJob: sent {$count} reminder(s)");
        }
    }
}
