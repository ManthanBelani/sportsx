<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A co-organizer / volunteer invited to help an organizer run their events.
 */
class OrganizerTeamMember extends Model
{
    public const ROLES = ['co_organizer', 'volunteer', 'staff', 'finance'];

    protected $fillable = [
        'organizer_id', 'user_id', 'name', 'email', 'role', 'status',
        'invited_at', 'joined_at',
    ];

    protected function casts(): array
    {
        return [
            'invited_at' => 'datetime',
            'joined_at' => 'datetime',
        ];
    }

    public function organizer(): BelongsTo
    {
        return $this->belongsTo(OrganizerProfile::class, 'organizer_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
