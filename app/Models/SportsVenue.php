<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class SportsVenue extends Model
{
    use HasFactory;

    protected $fillable = [
        'name', 'sport_id', 'address', 'google_maps_url', 'contact_number',
        'city_id', 'photos', 'booking_available', 'pricing', 'facilities',
        'working_hours', 'listing_status',
    ];

    protected $casts = [
        'photos' => 'array',
        'facilities' => 'array',
        'booking_available' => 'boolean',
    ];

    protected $table = 'sports_venues';

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    public function scopePublished($query)
    {
        return $query->where('listing_status', 'published');
    }
}
