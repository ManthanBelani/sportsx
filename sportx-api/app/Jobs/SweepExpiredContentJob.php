<?php

namespace App\Jobs;

use App\Services\ExpiryService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class SweepExpiredContentJob implements ShouldQueue
{
    use Queueable;

    public function handle(ExpiryService $expiry): void
    {
        $count = $expiry->sweep();
        if ($count > 0) {
            Log::info("SweepExpiredContentJob: expired {$count} listing(s)");
        }
    }
}
