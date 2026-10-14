<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LeaderboardScore extends Model
{
    protected $fillable = ['athlete_profile_id', 'sport_id', 'season_id', 'points'];

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_profile_id');
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function season(): BelongsTo
    {
        return $this->belongsTo(LeaderboardSeason::class, 'season_id');
    }
}
