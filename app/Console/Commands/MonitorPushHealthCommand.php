<?php

namespace App\Console\Commands;

use App\Models\Notification;
use App\Models\UserDeviceToken;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

/**
 * Phase 10 push ops monitors:
 *  - push_status='failed' rate (page-worthy)
 *  - no_devices rate (rising share = broken Flutter token registration)
 *  - failure_count climbing (usually SENDER_ID_MISMATCH)
 *  - fallback volume proxy: failed+no_devices in window (high volume =
 *    push silently failing → NotificationFallbackMail surge)
 */
class MonitorPushHealthCommand extends Command
{
    protected $signature = 'notifications:monitor {--window=60 : minutes to look back}';

    protected $description = 'Check push delivery health and alert on degradation.';

    public function handle(): int
    {
        $window = (int) $this->option('window');
        $since = now()->subMinutes($window);

        $total = Notification::where('created_at', '>=', $since)->count();
        $failed = Notification::where('created_at', '>=', $since)->where('push_status', 'failed')->count();
        $noDevices = Notification::where('created_at', '>=', $since)->where('push_status', 'no_devices')->count();
        $badTokens = UserDeviceToken::where('failure_count', '>', 0)->count();

        $failedRate = $total > 0 ? $failed / $total : 0;
        $noDevicesRate = $total > 0 ? $noDevices / $total : 0;

        $alerts = [];
        if ($total > 20 && $failedRate > 0.05) {
            $alerts[] = "push failed rate {$failed}/{$total}";
        }
        if ($total > 20 && $noDevicesRate > 0.30) {
            $alerts[] = "no_devices rate {$noDevices}/{$total} — check Flutter token registration";
        }
        if ($badTokens > 50) {
            $alerts[] = "{$badTokens} tokens with failure_count>0 — possible SENDER_ID_MISMATCH";
        }

        if ($alerts !== []) {
            Log::warning('SportX push health degraded', [
                'window_minutes' => $window,
                'total' => $total,
                'failed' => $failed,
                'no_devices' => $noDevices,
                'bad_tokens' => $badTokens,
                'alerts' => $alerts,
            ]);
            $this->error(implode('; ', $alerts));

            return self::FAILURE;
        }

        $this->info("Push health OK (total={$total}, failed={$failed}, no_devices={$noDevices}).");

        return self::SUCCESS;
    }
}
