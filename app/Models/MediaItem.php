<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Support\Facades\Storage;

class MediaItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_type', 'owner_id', 'media_type', 'disk', 'path',
        'original_name', 'mime_type', 'size_bytes', 'sort_order',
    ];

    public function owner(): MorphTo
    {
        return $this->morphTo();
    }

    public function url(): string
    {
        return Storage::disk($this->disk ?? 'public')->url($this->path);
    }
}
