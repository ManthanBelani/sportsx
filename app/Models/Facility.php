<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Facility extends Model
{
    public const TYPES = ['ground', 'indoor', 'gym', 'other'];

    protected $fillable = [
        'academy_id', 'organizer_id', 'name', 'type', 'size', 'amenities', 'image_media_ids',
    ];

    protected function casts(): array
    {
        return [
            'amenities' => 'array',
            'image_media_ids' => 'array',
        ];
    }

    public function academy(): BelongsTo
    {
        return $this->belongsTo(Academy::class);
    }

    public function organizer(): BelongsTo
    {
        return $this->belongsTo(OrganizerProfile::class);
    }
}
