<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class TournamentRegistration extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'tournament_id', 'category_id', 'athlete_id', 'participation_type',
        'team_name', 'payment_status', 'approval_status', 'status',
        'rejection_reason', 'reviewed_by', 'reviewed_at', 'reminder_enabled',
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
        'reminder_enabled' => 'boolean',
    ];

    public function tournament(): BelongsTo
    {
        return $this->belongsTo(Tournament::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(TournamentCategory::class, 'category_id');
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
