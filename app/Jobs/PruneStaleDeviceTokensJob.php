<?php

namespace App\Jobs;

use App\Models\UserDeviceToken;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class PruneStaleDeviceTokensJob implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        $ttlDays = (int) config('sportx.notifications.device_token_ttl_days', 180);
        UserDeviceToken::where('failure_count', '>=', 3)->delete();
        UserDeviceToken::where('last_seen_at', '<', now()->subDays($ttlDays))->delete();
        UserDeviceToken::whereNull('last_seen_at')->where('created_at', '<', now()->subDays($ttlDays))->delete();
    }
}
