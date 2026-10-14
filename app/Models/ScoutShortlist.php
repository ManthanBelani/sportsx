<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ScoutShortlist extends Model
{
    public const STATUSES = ['under_review', 'good', 'high', 'final'];

    protected $fillable = [
        'talent_scout_profile_id', 'athlete_profile_id', 'status', 'tags', 'notes',
    ];

    protected $casts = ['tags' => 'array'];

    public function scout(): BelongsTo
    {
        return $this->belongsTo(TalentScoutProfile::class, 'talent_scout_profile_id');
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_profile_id');
    }
}
