<?php

namespace App\Jobs;

use App\Models\OtpCode;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class PurgeExpiredOtpsJob implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        OtpCode::where('expires_at', '<', now()->subDay())->delete();
    }
}
