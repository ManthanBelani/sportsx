<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OpportunityApplication extends Model
{
    public const STATUSES = ['submitted', 'shortlisted', 'declined'];

    protected $fillable = [
        'opportunity_id', 'athlete_id', 'pitch', 'document_media_ids',
        'snapshot', 'status', 'decision_note', 'replied_at',
    ];

    protected function casts(): array
    {
        return [
            'document_media_ids' => 'array',
            'snapshot' => 'array',
            'replied_at' => 'datetime',
        ];
    }

    public function opportunity(): BelongsTo
    {
        return $this->belongsTo(Opportunity::class);
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_id');
    }
}
