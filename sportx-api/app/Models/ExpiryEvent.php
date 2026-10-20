<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class ExpiryEvent extends Model
{
    protected $fillable = [
        'content_type', 'content_id', 'scheduled_at', 'executed_at', 'status', 'overridden_by',
    ];

    protected $casts = [
        'scheduled_at' => 'datetime',
        'executed_at' => 'datetime',
    ];

    /**
     * The listing this expiry event targets (trial / tournament / opportunity…).
     * Resolved via the Relation::morphMap aliases ("trial", "tournament", …).
     */
    public function content(): MorphTo
    {
        return $this->morphTo(__FUNCTION__, 'content_type', 'content_id');
    }

    public function overriddenBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'overridden_by');
    }
}
