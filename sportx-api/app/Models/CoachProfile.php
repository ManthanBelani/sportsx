<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Traits\Auditable;

class CoachProfile extends Model
{
    use HasFactory, Auditable;

    protected $fillable = [
        'user_id', 'full_name', 'sport_id', 'contact_number', 'experience',
        'qualification', 'certifications', 'academy_id', 'languages', 'email',
        'personal_coaching', 'fee_structure', 'bio', 'city_id', 'photo_media_id',
        'listing_status', 'profile_completeness', 'headline', 'location',
        'fee_per_session', 'fee_monthly', 'fee_quarterly', 'availability',
        'achievements',
    ];

    protected $appends = ['connections_count'];

    protected $casts = [
        'certifications' => 'array',
        'languages' => 'array',
        'achievements' => 'array',
        'personal_coaching' => 'boolean',
        'profile_completeness' => 'integer',
        'availability' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    public function academy(): BelongsTo
    {
        return $this->belongsTo(Academy::class);
    }

    public function photo(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'photo_media_id');
    }

    public function mediaItems(): MorphMany
    {
        return $this->morphMany(MediaItem::class, 'owner');
    }

    public function getConnectionsCountAttribute(): int
    {
        return Connection::where('status', 'accepted')
            ->where(fn ($q) => $q->where('follower_user_id', $this->user_id)
                ->orWhere('followee_user_id', $this->user_id))
            ->count();
    }
}
