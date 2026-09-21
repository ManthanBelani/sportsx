<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ScoutConnection extends Model
{
    protected $fillable = [
        'talent_scout_profile_id', 'athlete_profile_id', 'requested_by_user_id', 'status', 'message',
    ];

    protected $casts = [
        'status' => 'string',
    ];

    public function scout(): BelongsTo
    {
        return $this->belongsTo(TalentScoutProfile::class, 'talent_scout_profile_id');
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_profile_id');
    }
}
