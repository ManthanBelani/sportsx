<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class CoachProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'full_name', 'sport_id', 'contact_number', 'experience',
        'qualification', 'certifications', 'academy_id', 'languages', 'email',
        'personal_coaching', 'fee_structure', 'bio', 'city_id', 'photo_media_id',
        'listing_status', 'profile_completeness',
    ];

    protected $appends = ['connections_count'];

    protected $casts = [
        'certifications' => 'array',
        'languages' => 'array',
        'personal_coaching' => 'boolean',
        'profile_completeness' => 'integer',
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

    public function getConnectionsCountAttribute(): int
    {
        return Connection::where('status', 'accepted')
            ->where(fn ($q) => $q->where('follower_user_id', $this->user_id)
                ->orWhere('followee_user_id', $this->user_id))
            ->count();
    }
}
