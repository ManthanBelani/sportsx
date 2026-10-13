<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A third-party identity linked to a SportX user.
 *
 * @property string $provider
 * @property string $provider_user_id
 * @see \App\Services\SocialAuthService
 */
class SocialAccount extends Model
{
    use HasFactory;

    public const PROVIDER_GOOGLE = 'google';

    protected $fillable = [
        'user_id',
        'provider',
        'provider_user_id',
        'email',
        'name',
        'avatar_url',
        'access_token',
        'refresh_token',
        'token_expires_at',
        'scopes',
    ];

    /**
     * OAuth tokens are secrets — never expose them through an API response.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'access_token',
        'refresh_token',
    ];

    protected function casts(): array
    {
        return [
            'token_expires_at' => 'datetime',
            // Encrypted at rest so a database dump does not leak live OAuth
            // credentials for every signed-in user.
            'access_token' => 'encrypted',
            'refresh_token' => 'encrypted',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isGoogle(): bool
    {
        return $this->provider === self::PROVIDER_GOOGLE;
    }

    public function scopeForProvider(Builder $query, string $provider): Builder
    {
        return $query->where('provider', $provider);
    }

    public function scopeGoogle(Builder $query): Builder
    {
        return $query->forProvider(self::PROVIDER_GOOGLE);
    }
}