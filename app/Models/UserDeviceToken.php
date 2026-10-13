<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * An FCM registration token belonging to one installed app instance.
 *
 * FCM invariants this model relies on:
 *  - A token identifies exactly one app instance on one device. A reinstall
 *    mints a new token; the old one must be retired or it will keep receiving
 *    messages for whoever registers next.
 *  - `token` is UNIQUE (migration 2026_10_01_000004), so re-registering from a
 *    new user silently transfers the device to that user rather than
 *    duplicating the row.
 *
 * @see \App\Services\FCMService::deactivateTokens()
 * @see \App\Jobs\PruneStaleDeviceTokensJob
 */
class UserDeviceToken extends Model
{
    protected $fillable = [
        'user_id',
        'token',
        'device_type',
        'device_id',
        'is_active',
        'last_seen_at',
        'failure_count',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'last_seen_at' => 'datetime',
            'failure_count' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true);
    }

    public function scopeForUser(Builder $query, int $userId): Builder
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Record a successful send so the pruner does not retire a healthy device.
     */
    public function markSeen(): void
    {
        $this->forceFill([
            'last_seen_at' => now(),
            'failure_count' => 0,
        ])->save();
    }

    /**
     * Record a rejected token. Returns true when the token is now dead enough
     * to retire.
     *
     * FCM reports a token as permanently invalid at a fairly low threshold —
     * three strikes keeps genuine transient errors (device offline) from
     * killing a working registration.
     */
    public function recordFailure(): bool
    {
        $this->increment('failure_count');
        $this->refresh();

        $threshold = (int) config('sportx.notifications.fcm.max_retries', 3);

        if ($this->failure_count >= $threshold) {
            $this->update(['is_active' => false]);

            return true;
        }

        return false;
    }
}