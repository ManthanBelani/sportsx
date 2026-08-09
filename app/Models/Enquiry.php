<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Enquiry extends Model
{
    protected $fillable = ['athlete_id', 'subject_type', 'subject_id', 'preferred_datetime'];

    protected $casts = ['preferred_datetime' => 'datetime'];

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_id');
    }

    public function subject(): MorphTo
    {
        return $this->morphTo();
    }

    public function messages(): HasMany
    {
        return $this->hasMany(EnquiryMessage::class);
    }
}
