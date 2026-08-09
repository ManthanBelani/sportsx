<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SponsorshipApplication extends Model
{
    protected $fillable = ['sponsorship_id', 'athlete_id', 'pitch_note', 'status', 'replied_at'];

    protected $casts = ['replied_at' => 'datetime'];

    public function sponsorship(): BelongsTo
    {
        return $this->belongsTo(Sponsorship::class);
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_id');
    }
}
