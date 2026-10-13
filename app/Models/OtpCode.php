<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * One-time codes delivered over email (or SMS later).
 *
 * Only the bcrypt hash is persisted; the plaintext code exists solely inside
 * the outbound email. The fillable list previously targeted a legacy schema
 * (`phone` / `code` / `expires_at`) that no longer matched the table, which
 * silently discarded the fields OtpService tried to write.
 *
 * @see \App\Services\OtpService
 */
class OtpCode extends Model
{
    use HasFactory;

    public const PURPOSE_LOGIN = 'login';

    public const PURPOSE_SIGNUP = 'signup';

    public const PURPOSE_VERIFY_EMAIL = 'verify_email';

    public const PURPOSE_RESET_PASSWORD = 'reset_password';

    public const PURPOSE_GUARDIAN_CONSENT = 'guardian_consent';

    public const PURPOSE_VERIFY_CONTACT = 'verify_contact';

    /**
     * Every purpose the API accepts. Mirrors the documented vocabulary in
     * `API-Specification.md` §1 — a request for anything else is a 422.
     */
    public const PURPOSES = [
        self::PURPOSE_SIGNUP,
        self::PURPOSE_LOGIN,
        self::PURPOSE_RESET_PASSWORD,
        self::PURPOSE_GUARDIAN_CONSENT,
        self::PURPOSE_VERIFY_CONTACT,
    ];

    protected $fillable = [
        'user_id',
        'channel',
        'destination',
        'code_hash',
        'purpose',
        'expires_at',
        'attempts',
        'consumed_at',
    ];

    protected $hidden = ['code_hash'];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'consumed_at' => 'datetime',
            'attempts' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /* ---------------------------------------------------------------------
     | State helpers
     | ------------------------------------------------------------------ */

    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    public function isConsumed(): bool
    {
        return $this->consumed_at !== null;
    }

    public function isUsable(): bool
    {
        return ! $this->isConsumed() && ! $this->isExpired();
    }

    public function maxAttemptsReached(): bool
    {
        return $this->attempts >= (int) config('sportx.otp.max_attempts', 5);
    }

    /* ---------------------------------------------------------------------
     | Scopes
     | ------------------------------------------------------------------ */

    /**
     * The row a verification lookup should read: newest first, per tuple.
     */
    public function scopePending(Builder $query): Builder
    {
        return $query->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->latest();
    }

    public function scopeForDestination(Builder $query, string $channel, string $destination): Builder
    {
        return $query->where('channel', $channel)
            ->where('destination', $destination);
    }
}