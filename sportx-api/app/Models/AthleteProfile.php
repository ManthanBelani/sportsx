<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class AthleteProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'full_name',
        'date_of_birth',
        'gender',
        'phone',
        'academy_id',
        'coach_id',
        'position',
        'experience',
        'age_group_id',
        'skill_level',
        'city_id',
        'photo_media_id',
    ];

    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function sports(): BelongsToMany
    {
        return $this->belongsToMany(Sport::class, 'athlete_sports', 'athlete_id', 'sport_id');
    }

    public function ageGroup(): BelongsTo
    {
        return $this->belongsTo(AgeGroup::class);
    }

    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    public function academy(): BelongsTo
    {
        return $this->belongsTo(Academy::class);
    }

    public function coach(): BelongsTo
    {
        return $this->belongsTo(CoachProfile::class);
    }

    public function photo(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'photo_media_id');
    }

    public function mediaItems(): MorphMany
    {
        return $this->morphMany(MediaItem::class, 'owner');
    }

    public function achievements(): HasMany
    {
        return $this->hasMany(Achievement::class, 'athlete_id')->orderBy('sort_order');
    }

    public function savedItems(): MorphMany
    {
        return $this->morphMany(SavedItem::class, 'item');
    }
}
