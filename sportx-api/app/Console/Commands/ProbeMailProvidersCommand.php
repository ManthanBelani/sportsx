<?php

namespace App\Console\Commands;

use App\Services\MailProviderService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

/**
 * Phase 10 email ops: hourly provider probe so an outage surfaces
 * BEFORE users report a missing OTP (not after).
 */
class ProbeMailProvidersCommand extends Command
{
    protected $signature = 'mail:probe';

    protected $description = 'Probe each configured mail provider and alert on failure.';

    public function handle(MailProviderService $mail): int
    {
        $status = $mail->status();
        $failed = [];
        foreach (($status['providers'] ?? []) as $name => $info) {
            if (!($info['configured'] ?? false)) {
                continue;
            }
            try {
                $result = $mail->testConnection($name);
                if (!($result['ok'] ?? false)) {
                    $failed[] = $name;
                }
            } catch (\Throwable $e) {
                $failed[] = "{$name}: {$e->getMessage()}";
            }
        }

        if ($failed !== []) {
            Log::warning('SportX mail provider probe failed', ['providers' => $failed]);
            $this->error('Probe failed: '.implode(', ', $failed));

            return self::FAILURE;
        }

        $this->info('All configured mail providers OK.');

        return self::SUCCESS;
    }
}
