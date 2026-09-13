<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class TalentScoutProfile extends Model
{
    use Auditable;
    use SoftDeletes;

    protected $fillable = [
        'user_id', 'organization', 'affiliation',
        'sports_specialization', 'experience_years',
        'city_id', 'bio', 'photo_media_id', 'listing_status',
    ];

    protected $casts = [
        'sports_specialization' => 'array',
        'listing_status' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    public function photo(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'photo_media_id');
    }

    public function shortlists(): HasMany
    {
        return $this->hasMany(ScoutShortlist::class);
    }

    public function connections(): HasMany
    {
        return $this->hasMany(ScoutConnection::class);
    }
}
