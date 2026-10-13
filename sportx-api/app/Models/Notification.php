<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * In-app notification row, and the source of truth for the FCM payload.
 *
 * One row is written per event; the push listener reads the same row to build
 * the FCM message, which keeps the notification centre and the push tray from
 * ever disagreeing about what happened.
 *
 * @see \App\Services\NotificationService
 * @see \App\Services\FCMService
 */
class Notification extends Model
{
    use HasFactory;

    /** Channels a notification can be delivered over. */
    public const CHANNEL_IN_APP = 'in_app';

    public const CHANNEL_PUSH = 'push';

    public const CHANNEL_EMAIL = 'email';

    /** Types the notification centre groups by. */
    public const TYPE_REMINDER = 'reminder';

    public const TYPE_ENQUIRY_REPLY = 'enquiry_reply';

    public const TYPE_STATUS_UPDATE = 'status_update';

    public const TYPE_REGISTRATION_APPROVED = 'registration_approved';

    public const TYPE_REGISTRATION_REJECTED = 'registration_rejected';

    public const TYPE_TRIAL_APPROVED = 'trial_approved';

    public const TYPE_TRIAL_REJECTED = 'trial_rejected';

    public const TYPE_TOURNAMENT_APPROVED = 'tournament_approved';

    public const TYPE_TOURNAMENT_REJECTED = 'tournament_rejected';

    public const TYPE_ACCOUNT_ACTION = 'account_action';

    public const TYPE_BROADCAST = 'broadcast';

    protected $fillable = [
        'user_id',
        'type',
        'channel',
        'title',
        'body',
        'category',
        'image_url',
        'priority',
        'notifiable_type',
        'notifiable_id',
        'action_url',
        'metadata',
        'read_at',
        'pushed_at',
        'push_status',
    ];

    protected function casts(): array
    {
        return [
            'read_at' => 'datetime',
            'pushed_at' => 'datetime',
            'metadata' => 'array',
        ];
    }

    protected $appends = ['is_read'];

    public function getIsReadAttribute(): bool
    {
        return $this->read_at !== null;
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Polymorphic pointer at whatever triggered the notification (a Trial, a
     * Post, a User, ...). Null for system broadcasts.
     *
     * @return \Illuminate\Database\Eloquent\Relations\MorphTo
     */
    public function notifiable()
    {
        return $this->morphTo();
    }

    /* ---------------------------------------------------------------------
     | Scopes
     | ------------------------------------------------------------------ */

    public function scopeUnread(Builder $query): Builder
    {
        return $query->whereNull('read_at');
    }

    public function scopeForUser(Builder $query, int $userId): Builder
    {
        return $query->where('user_id', $userId);
    }

    public function scopeOfType(Builder $query, string|array $types): Builder
    {
        return is_array($types) ? $query->whereIn('type', $types) : $query->where('type', $types);
    }

    /* ---------------------------------------------------------------------
     | Helpers
     | ------------------------------------------------------------------ */

    public function markAsRead(): bool
    {
        if ($this->read_at !== null) {
            return false;
        }

        return $this->update(['read_at' => now()]);
    }

    public function markAsUnread(): bool
    {
        return $this->update(['read_at' => null]);
    }

    /**
     * FCM requires data-payload values to be strings, and rejects empty
     * strings as well — coerce everything to a safe, non-empty representation.
     *
     * @return array<string, string>
     */
    public function toPushPayload(): array
    {
        return array_filter(
            [
                'notification_id' => (string) $this->id,
                'type' => (string) $this->type,
                'category' => (string) ($this->category ?: $this->type),
                'title' => (string) $this->title,
                'body' => (string) $this->body,
                'action_url' => (string) ($this->action_url ?: ''),
                'image_url' => (string) ($this->image_url ?: ''),
                'priority' => (string) $this->priority,
                'created_at' => optional($this->created_at)->toIso8601String(),
            ],
            static fn ($value) => $value !== null && $value !== ''
        );
    }
}