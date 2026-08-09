<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class ListingReport extends Model
{
    protected $fillable = [
        'reporter_user_id', 'reportable_type', 'reportable_id', 'reason',
        'comment', 'status', 'resolved_by', 'resolved_at',
    ];

    protected $casts = ['resolved_at' => 'datetime'];

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reporter_user_id');
    }

    public function reportable(): MorphTo
    {
        return $this->morphTo();
    }
}
