<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class Tournament extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'organizer_id', 'sport_id', 'name', 'organizer_name', 'format',
        'start_date', 'end_date', 'registration_deadline', 'venue',
        'google_maps_url', 'city_id', 'entry_fee', 'contact_number',
        'registration_link', 'prize_pool', 'rules', 'banner_media_id',
        'gender', 'status', 'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'registration_deadline' => 'date',
            'expires_at' => 'datetime',
        ];
    }

    public function organizer(): BelongsTo
    {
        return $this->belongsTo(OrganizerProfile::class, 'organizer_id');
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    public function categories(): HasMany
    {
        return $this->hasMany(TournamentCategory::class);
    }

    public function registrations(): HasMany
    {
        return $this->hasMany(TournamentRegistration::class);
    }

    public function results(): HasMany
    {
        return $this->hasMany(TournamentResult::class);
    }

    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }
}
