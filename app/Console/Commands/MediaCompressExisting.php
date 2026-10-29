<?php

namespace App\Console\Commands;

use App\Jobs\CompressPhoto;
use App\Models\MediaItem;
use Illuminate\Console\Command;

/**
 * One-off backlog compression (plan Step 2C): chunk through existing
 * uncompressed photos and (re-)compress them. Uses the same queue job as
 * live uploads so processing share the same idempotency guard
 * (media_items.compressed_at) — run via queue workers or inline with --now.
 */
class MediaCompressExisting extends Command
{
    protected $signature = 'media:compress-existing
        {--now : Process inline instead of dispatching to the queue}
        {--chunk=100 : Number of media rows per chunk}';

    protected $description = 'Compress all previously uploaded photos that have not been compressed yet';

    public function handle(): int
    {
        $query = MediaItem::query()
            ->where('media_type', 'photo')
            ->whereNotNull('context');

        $total = (clone $query)->whereNull('compressed_at')->count();
        if ($total === 0) {
            $this->info('Nothing to compress.');

            return self::SUCCESS;
        }

        $this->info("Compressing {$total} photos (chunk ".((int) $this->option('chunk')).")…");

        $query->whereNull('compressed_at')
            ->orderBy('id')
            ->chunkById((int) $this->option('chunk'), function ($items) {
                foreach ($items as $media) {
                    if ($this->option('now')) {
                        // Try/keep a failure from aborting the sweep.
                        try {
                            $before = (int) $media->size_bytes;
                            app(\App\Services\PhotoCompressor::class)->compress($media);
                            $this->line("  #{$media->id}: {$before} → ".($media->size_bytes ?? $before).' bytes');
                        } catch (\Throwable $e) {
                            report($e);
                            $this->warn("  #{$media->id}: failed ({$e->getMessage()})");
                        }
                    } else {
                        CompressPhoto::dispatch($media->id);
                    }
                }
            });

        $this->info($this->option('now')
            ? 'Compression sweep finished.'
            : "Dispatched {$total} compression jobs to the queue.");

        return self::SUCCESS;
    }
}
