<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class TrialRegistration extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'trial_id', 'athlete_id', 'registration_ref', 'document_status',
        'verification_status', 'approval_status', 'reminder_enabled',
        'playing_role', 'medical_conditions', 'parental_consent',
        'rejection_reason', 'reviewed_by', 'reviewed_at', 'status',
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
        'reminder_enabled' => 'boolean',
        'parental_consent' => 'boolean',
    ];

    public function trial(): BelongsTo
    {
        return $this->belongsTo(Trial::class);
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function documents(): HasMany
    {
        return $this->hasMany(TrialRegistrationDocument::class);
    }
}
