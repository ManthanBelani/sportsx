<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Block extends Model
{
    protected $fillable = ['blocker_user_id', 'blocked_user_id'];

    public function blocker(): BelongsTo
    {
        return $this->belongsTo(User::class, 'blocker_user_id');
    }

    public function blocked(): BelongsTo
    {
        return $this->belongsTo(User::class, 'blocked_user_id');
    }

    /** True when either user has blocked the other (hide both ways). */
    public static function hasBlockBetween(int $a, int $b): bool
    {
        return static::where(fn ($q) => $q
            ->where(fn ($w) => $w->where('blocker_user_id', $a)->where('blocked_user_id', $b))
            ->orWhere(fn ($w) => $w->where('blocker_user_id', $b)->where('blocked_user_id', $a))
        )->exists();
    }
}
