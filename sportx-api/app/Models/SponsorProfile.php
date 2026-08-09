<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SponsorProfile extends Model
{
    protected $fillable = ['user_id', 'brand_name', 'logo_media_id', 'category', 'verification_status'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function sponsorships(): HasMany
    {
        return $this->hasMany(Sponsorship::class, 'sponsor_id');
    }

    public function shortlistEntries(): HasMany
    {
        return $this->hasMany(ShortlistEntry::class, 'sponsor_id');
    }
}
