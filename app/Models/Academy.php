<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Academy extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_user_id', 'name', 'description', 'address', 'city_id',
        'contact_number', 'google_maps_url', 'facilities', 'fee_range',
        'timings', 'age_groups', 'year_established', 'achievements', 'email', 'website',
        'head_coach_id', 'logo_media_id', 'cover_media_id', 'verification_badge', 'listing_status',
    ];

    protected $casts = [
        'facilities' => 'array',
        'age_groups' => 'array',
        'achievements' => 'array',
        'year_established' => 'integer',
        'verification_badge' => 'boolean',
    ];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_user_id');
    }

    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    public function sports(): HasMany
    {
        return $this->hasMany(AcademySport::class);
    }

    public function coaches(): HasMany
    {
        return $this->hasMany(AcademyCoach::class);
    }

    public function trials(): HasMany
    {
        return $this->hasMany(Trial::class);
    }

    public function logo(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'logo_media_id');
    }

    public function cover(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'cover_media_id');
    }

    public function headCoach(): BelongsTo
    {
        return $this->belongsTo(User::class, 'head_coach_id');
    }

    public function enquiries(): MorphMany
    {
        return $this->morphMany(Enquiry::class, 'subject');
    }

    public function photos(): MorphMany
    {
        return $this->morphMany(MediaItem::class, 'owner');
    }

    public function scopePublished($query)
    {
        return $query->where('listing_status', 'published');
    }
}
