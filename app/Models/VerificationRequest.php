<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

/**
 * A request to display the verified blue check.
 *
 * @see \App\Http\Controllers\VerificationController
 */
class VerificationRequest extends Model
{
    use HasFactory;

    public const STATUS_PENDING = 'pending';

    public const STATUS_APPROVED = 'approved';

    public const STATUS_REJECTED = 'rejected';

    /**
     * Which column carries the verified flag on each verifiable entity.
     *
     * The profile tables predate the verification feature and do not agree on a
     * name — `academies` uses `verification_badge`, organizers and sponsors use
     * `verification_status`. Rather than rename columns the admin panel already
     * reads, each type declares its own so the badge logic stays in one place.
     *
     * @var array<string, string>
     */
    public const BADGE_COLUMNS = [
        'academy' => 'verification_badge',
        'organizer_profile' => 'verification_status',
        'sponsor_profile' => 'verification_status',
    ];

    protected $fillable = [
        'requester_user_id',
        'verifiable_type',
        'verifiable_id',
        'status',
        'proof_media_ids',
        'notes',
        'reviewed_by',
        'decision_reason',
        'reviewed_at',
    ];

    protected function casts(): array
    {
        return [
            'proof_media_ids' => 'array',
            'reviewed_at' => 'datetime',
        ];
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requester_user_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function verifiable(): MorphTo
    {
        return $this->morphTo();
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    public function scopeForRequester(Builder $query, int $userId): Builder
    {
        return $query->where('requester_user_id', $userId);
    }

        /**
     * The column holding the verified flag for this request's entity, if the
     * entity has one.
     */
    public function badgeColumn(): ?string
    {
        return self::BADGE_COLUMNS[$this->verifiable_type] ?? null;
    }

    public function approve(User $admin, ?string $reason = null): void
    {
        $this->forceFill([
            'status' => self::STATUS_APPROVED,
            'reviewed_by' => $admin->id,
            'decision_reason' => $reason,
            'reviewed_at' => now(),
        ])->save();

        $this->setBadge(true);
    }

    public function reject(User $admin, string $reason): void
    {
        $this->forceFill([
            'status' => self::STATUS_REJECTED,
            'reviewed_by' => $admin->id,
            'decision_reason' => $reason,
            'reviewed_at' => now(),
        ])->save();

        $this->setBadge(false);
    }

    /**
     * Apply the verified flag to the underlying entity, if it has such a column.
     */
    protected function setBadge(bool $verified): void
    {
        $column = $this->badgeColumn();

        if ($column === null) {
            return;
        }

        $entity = $this->verifiable;

        if ($entity === null) {
            return;
        }

        $entity->forceFill([$column => $verified])->save();
    }
}