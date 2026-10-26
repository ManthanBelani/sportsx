<?php

namespace App\Services;

use App\Models\MediaItem;
use App\Support\PlatformSettings;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\Drivers\Gd\Driver as GdDriver;
use Intervention\Image\Encoders\JpegEncoder;
use Intervention\Image\Encoders\WebpEncoder;
use Intervention\Image\ImageManager;

/**
 * Server-side photo compression (plan Step 2B).
 *
 * Resizes every newly uploaded photo to fit within `photo_max_dimension`
 * (default 1600px), strips EXIF metadata (privacy — drops GPS coordinates)
 * and re-encodes to JPEG at `photo_jpeg_quality` (default 78). PNGs with
 * transparency keep their alpha by being re-encoded to WebP instead. The
 * stored file is overwritten in place and the media row's size/mime are
 * kept in sync. Uses Intervention Image v4 with the bundled GD driver.
 */
class PhotoCompressor
{
    private int $maxDimension;

    private int $jpegQuality;

    public function __construct(?int $maxDimension = null, ?int $jpegQuality = null)
    {
        $this->maxDimension = $maxDimension > 0
            ? $maxDimension
            : (int) (PlatformSettings::get('photo_max_dimension') ?? config('sportx.media.photo_max_dimension', 1600));
        $this->jpegQuality = ($jpegQuality !== null && $jpegQuality > 0 && $jpegQuality <= 100)
            ? $jpegQuality
            : (int) (PlatformSettings::get('photo_jpeg_quality') ?? config('sportx.media.photo_jpeg_quality', 78));
    }

    /**
     * Compress the stored photo in place. Returns [
     *   'original' => bytes before, 'compressed' => bytes after,
     *   'saved_ratio' => 0..1 fraction saved,
     * ] or null when the file was missing / not compressible.
     */
    public function compress(MediaItem $media): ?array
    {
        if ($media->media_type !== 'photo') {
            return null;
        }

        $disk = $media->disk ?: 'public';
        if (! Storage::disk($disk)->exists($media->path)) {
            return null;
        }

        $originalBytes = (int) Storage::disk($disk)->size($media->path);
        $raw = Storage::disk($disk)->get($media->path);
        if ($raw === null || $raw === '') {
            return null;
        }

        try {
            $manager = new ImageManager(new GdDriver());
            $image = $manager->decodeBinary($raw);

            // Resize (no upscale): fit within the max dimension.
            if (max($image->width(), $image->height()) > $this->maxDimension) {
                $image->scaleDown(width: $this->maxDimension, height: $this->maxDimension);
            }

            // Transparency-safe encoding: alpha-bearing pixels (PNG/WebP)
            // must not go to JPEG — re-encode those to WebP; everything
            // else (including opaque PNGs) to JPEG. decodeBinary() drops
            // EXIF, so location metadata is removed as a side effect.
            $hasAlpha = $this->detectAlpha($image, $media->mime_type);

            $encoded = $hasAlpha
                ? $image->encode(new WebpEncoder(max(65, $this->jpegQuality)))
                : $image->encode(new JpegEncoder($this->jpegQuality));

            $newMime = $encoded->mediaType();
            $compressedBytes = $encoded->size();
            if ($compressedBytes <= 0) {
                return null;
            }

            // Only overwrite when the result is actually smaller; never
            // grow storage with a "compression".
            if ($compressedBytes <= $originalBytes) {
                $path = $media->path;
                $newExt = $hasAlpha ? 'webp' : 'jpg';
                if (strtolower(pathinfo($path, PATHINFO_EXTENSION)) !== $newExt) {
                    $newPath = preg_replace('/\.[A-Za-z0-9]+$/', '.'.$newExt, $path);
                    if (is_string($newPath)) {
                        $path = $newPath;
                    }
                }
                Storage::disk($disk)->put($path, $encoded->toString());
                if ($path !== $media->path) {
                    Storage::disk($disk)->delete($media->path);
                }

                $media->forceFill([
                    'path' => $path,
                    'mime_type' => $newMime,
                    'size_bytes' => $compressedBytes,
                    'compressed_at' => now(),
                ])->save();

                return [
                    'original' => $originalBytes,
                    'compressed' => $compressedBytes,
                    'saved_ratio' => $originalBytes > 0
                        ? round(1 - ($compressedBytes / $originalBytes), 4)
                        : 0.0,
                ];
            }

            // No gain — still stamp compressed_at so the job never retries.
            $media->forceFill(['compressed_at' => now()])->save();

            return null;
        } catch (\Throwable $e) {
            report($e);

            return null;
        }
    }

    /**
     * Detects usable alpha channel. PNGs/WebPs are scanned on a stride so a
     * fully-opaque PNG still re-encodes to JPEG (usually a big win over WebP).
     */
    private function detectAlpha(\Intervention\Image\Interfaces\ImageInterface $image, string $mime): bool
    {
        if (! in_array($mime, ['image/png', 'image/webp'], true)) {
            return false;
        }

        try {
            $native = $image->core()->native();
            if (! is_gd_image($native)) {
                return false;
            }
            $w = imagesx($native);
            $h = imagesy($native);
            imagesavealpha($native, true);

            $strideX = max(1, intdiv($w, 16));
            $strideY = max(1, intdiv($h, 16));
            for ($y = $h - 1; $y >= 0; $y -= $strideY) {
                for ($x = $w - 1; $x >= 0; $x -= $strideX) {
                    $rgba = @imagecolorat($native, $x, $y);
                    if ($rgba === false) {
                        continue;
                    }
                    if ((($rgba >> 24) & 0x7F) > 0) {
                        return true;
                    }
                }
            }

            return false;
        } catch (\Throwable) {
            return false;
        }
    }
}
