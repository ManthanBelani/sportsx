<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Opportunity extends Model
{
    use SoftDeletes;

    public const TYPES = ['scholarship', 'sponsorship', 'tryout', 'camp'];

    public const STATUSES = ['draft', 'published', 'closed', 'expired'];

    protected $fillable = [
        'provider_type', 'provider_id', 'created_by_user_id', 'type', 'title',
        'sport_id', 'age_group_id', 'eligibility', 'benefits', 'amount',
        'deadline', 'documents_required', 'description', 'logo_media_id',
        'status', 'legacy_type', 'legacy_id', 'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'deadline' => 'date',
            'amount' => 'decimal:2',
            'documents_required' => 'array',
            'expires_at' => 'datetime',
        ];
    }

    public function provider(): MorphTo
    {
        return $this->morphTo();
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function ageGroup(): BelongsTo
    {
        return $this->belongsTo(AgeGroup::class);
    }

    public function logo(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'logo_media_id');
    }

    public function applications(): HasMany
    {
        return $this->hasMany(OpportunityApplication::class);
    }

    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }

    public function scopeOpen($query)
    {
        // Expired-by-deadline listings auto-hide even before the sweep flips
        // their status.
        return $query->published()->where(fn ($q) => $q
            ->whereNull('deadline')
            ->orWhereDate('deadline', '>=', now()->toDateString()));
    }

    public function isRegisterable(): bool
    {
        return $this->status === 'published'
            && ($this->deadline === null || ! $this->deadline->isPast());
    }
}
