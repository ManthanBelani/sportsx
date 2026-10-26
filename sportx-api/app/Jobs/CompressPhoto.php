<?php

namespace App\Jobs;

use App\Models\MediaItem;
use App\Services\PhotoCompressor;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Queued photo compression so upload latency is unchanged (plan Step 2C).
 * Idempotent — guarded by media_items.compressed_at.
 */
class CompressPhoto implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;

    public function __construct(public int $mediaId)
    {
    }

    public function handle(PhotoCompressor $compressor): void
    {
        $media = MediaItem::find($this->mediaId);

        // Deleted in the meantime, already compressed, or not a photo.
        if (! $media || $media->compressed_at || $media->media_type !== 'photo') {
            return;
        }

        $result = $compressor->compress($media);

        if ($result !== null) {
            $saved = $result['original'] - $result['compressed'];
            Log::info('photo.compressed', [
                'media_id' => $media->id,
                'original_bytes' => $result['original'],
                'compressed_bytes' => $result['compressed'],
                'saved_bytes' => $saved,
                'saved_ratio' => $result['saved_ratio'],
            ]);
        }
    }
}
