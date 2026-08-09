<?php

use App\Jobs\PurgeExpiredOtpsJob;
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
