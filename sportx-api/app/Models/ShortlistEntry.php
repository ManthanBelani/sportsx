<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShortlistEntry extends Model
{
    protected $fillable = ['sponsor_id', 'athlete_id', 'note'];

    public function sponsor(): BelongsTo
    {
        return $this->belongsTo(SponsorProfile::class, 'sponsor_id');
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_id');
    }
}
