<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Achievement extends Model
{
    protected $fillable = [
        'athlete_id', 'coach_profile_id', 'text', 'sort_order',
        'title', 'type', 'sport_id', 'level', 'year',
        'certificate_media_id', 'description',
    ];

    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'sort_order' => 'integer',
        ];
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_id');
    }

    public function coachProfile(): BelongsTo
    {
        return $this->belongsTo(CoachProfile::class, 'coach_profile_id');
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function certificate(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'certificate_media_id');
    }
}
