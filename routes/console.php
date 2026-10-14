<?php

use App\Jobs\PruneNotificationRowsJob;
use App\Jobs\PruneOldMessagesJob;
use App\Jobs\PruneStaleDeviceTokensJob;
use App\Jobs\PurgeExpiredOtpsJob;
use App\Jobs\RecalculateLeaderboardJob;
use App\Jobs\SendDueRemindersJob;
use App\Jobs\SweepExpiredContentJob;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Auto-expiry sweep — expires listings whose event/deadline has passed (AD8/AD9)
Schedule::job(new SweepExpiredContentJob)->hourly();

// Deadline/date reminders — T-2d and T-1d offsets (AS-05)
Schedule::job(new SendDueRemindersJob)->everyFifteenMinutes();

// Purge stale OTP rows daily
Schedule::job(new PurgeExpiredOtpsJob)->dailyAt('02:00');

// 90-day chat purge (Phase 6: minors + storage)
Schedule::job(new PruneOldMessagesJob)->dailyAt('03:00');

// Stale device-token + notification-row prunes (Phase 3E/10 ops)
Schedule::job(new PruneStaleDeviceTokensJob)->dailyAt('03:30');
Schedule::job(new PruneNotificationRowsJob)->dailyAt('03:45');

// Nightly leaderboard rebuild (Phase 7: verified achievements + activity)
Schedule::job(new RecalculateLeaderboardJob)->dailyAt('04:00');

// Phase 10 ops: hourly mail-provider probe (OTP blind-spot) + push health
Schedule::command('mail:probe')->hourly();
Schedule::command('notifications:monitor')->hourly();
