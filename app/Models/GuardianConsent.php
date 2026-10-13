<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A guardian's verified consent for an athlete under 18.
 *
 * @see \App\Http\Controllers\GuardianController
 * @see \App\Services\GuardianConsentService
 */
class GuardianConsent extends Model
{
    use HasFactory;

    public const STATUS_PENDING = 'pending';

    public const STATUS_VERIFIED = 'verified';

    public const STATUS_REVOKED = 'revoked';

    public const RELATIONSHIPS = ['parent', 'guardian', 'sibling', 'other'];

    protected $fillable = [
        'athlete_user_id',
        'guardian_name',
        'guardian_phone',
        'relationship',
        'consent_status',
        'allow_messages',
        'allow_public_profile',
        'leaderboard_name_mode',
        'verified_at',
        'revoked_at',
    ];

    protected function casts(): array
    {
        return [
            'allow_messages' => 'boolean',
            'allow_public_profile' => 'boolean',
            'verified_at' => 'datetime',
            'revoked_at' => 'datetime',
        ];
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(User::class, 'athlete_user_id');
    }

    public function isVerified(): bool
    {
        return $this->consent_status === self::STATUS_VERIFIED;
    }

    public function scopeVerified(Builder $query): Builder
    {
        return $query->where('consent_status', self::STATUS_VERIFIED);
    }

    public function scopeForAthlete(Builder $query, int $userId): Builder
    {
        return $query->where('athlete_user_id', $userId);
    }

    public function markVerified(): void
    {
        $this->forceFill([
            'consent_status' => self::STATUS_VERIFIED,
            'verified_at' => now(),
            'revoked_at' => null,
        ])->save();
    }

    public function revoke(): void
    {
        $this->forceFill([
            'consent_status' => self::STATUS_REVOKED,
            'revoked_at' => now(),
        ])->save();
    }
}