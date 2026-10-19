<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OrganizerProfile extends Model
{
    use Auditable;
    protected $fillable = [
        'user_id',
        'organization_name',
        'org_type',
        'logo_media_id',
        'cover_media_id',
        'city_id',
        'description',
        'event_types',
        'registration_number',
        'website',
        'verification_status',
        'verification_doc_media_id',
    ];

    protected $casts = [
        'event_types' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function tournaments(): HasMany
    {
        return $this->hasMany(Tournament::class, 'organizer_id');
    }

    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    public function sports(): BelongsToMany
    {
        return $this->belongsToMany(Sport::class, 'organizer_sports', 'organizer_id', 'sport_id')
            ->withTimestamps();
    }

    public function logo(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'logo_media_id');
    }

    public function cover(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'cover_media_id');
    }
}
