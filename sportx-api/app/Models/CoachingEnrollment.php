<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoachingEnrollment extends Model
{
    protected $fillable = [
        'coach_id', 'athlete_id', 'plan_type', 'fees_amount', 'status',
        'approval_status', 'rejection_reason', 'start_date', 'end_date',
        'sessions_remaining', 'reviewed_by', 'reviewed_at', 'notes', 'coach_response',
    ];

    protected $casts = [
        'fees_amount' => 'decimal:2',
        'start_date' => 'date',
        'end_date' => 'date',
        'reviewed_at' => 'datetime',
    ];

    public function coach(): BelongsTo
    {
        return $this->belongsTo(CoachProfile::class, 'coach_id');
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
