<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A community group — coaching circles, athlete groups, trial groups …
 */
class Group extends Model
{
    public const TYPES = ['coaching', 'athletes', 'trials', 'general'];

    protected $fillable = [
        'created_by_user_id', 'name', 'description', 'image_url', 'type', 'status',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function members(): HasMany
    {
        return $this->hasMany(GroupMember::class);
    }

    /** Total members in the group. */
    public function membersCount(): int
    {
        return $this->members()->count();
    }

    /**
     * Payload consumed by the Flutter `Group` model — member_count and
     * is_member reflect the requesting user.
     */
    public function toApiArray(?int $viewerId = null): array
    {
        $isMember = $viewerId !== null
            && $this->members()->where('user_id', $viewerId)->exists();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'image_url' => $this->image_url,
            'member_count' => $this->membersCount(),
            'is_member' => $isMember,
            'type' => $this->type,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
