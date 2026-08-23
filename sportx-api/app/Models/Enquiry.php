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

    protected $appends = ['athlete_photo_url', 'status', 'is_read'];

    public function getAthletePhotoUrlAttribute(): ?string
    {
        return $this->athlete?->photo?->url;
    }

    public function getStatusAttribute(): string
    {
        $messages = $this->messages->sortByDesc('id');
        if ($messages->isEmpty()) {
            return 'new';
        }

        $coach = $this->subject;
        if (!$coach) {
            return 'new';
        }

        $latestMessage = $messages->first();
        $coachUserId = $coach->user_id ?? $coach->owner_user_id;

        if ($latestMessage->sender_user_id === $coachUserId) {
            return 'replied';
        }

        return 'new';
    }

    public function getIsReadAttribute(): bool
    {
        $messages = $this->messages->sortByDesc('id');
        if ($messages->isEmpty()) {
            return false;
        }

        $latestFromAthlete = $messages->firstWhere('sender_user_id', $this->athlete?->user_id);
        if ($latestFromAthlete) {
            return $latestFromAthlete->read_at !== null;
        }

        return true;
    }

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
