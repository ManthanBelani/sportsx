<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class MediaItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_type', 'owner_id', 'media_type', 'disk', 'path',
        'original_name', 'mime_type', 'size_bytes', 'sort_order',
    ];

    protected $appends = ['url'];

    public function owner(): MorphTo
    {
        return $this->morphTo();
    }

    public function url(): string
    {
        $path = ltrim($this->path, '/');
        $prefix = $this->disk === 'public' ? 'storage/' : '';

        // Root-relative on purpose: the mobile client absolutizes against its
        // configured API host, so the URL stays valid across emulator /
        // physical-device / tunnel setups without depending on APP_URL.
        return "/{$prefix}{$path}";
    }

    public function getUrlAttribute(): string
    {
        return $this->url();
    }
}
