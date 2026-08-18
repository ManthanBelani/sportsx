<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notification extends Model
{
    protected $fillable = ['user_id', 'type', 'title', 'body', 'notifiable_type', 'notifiable_id', 'read_at'];

    protected $casts = ['read_at' => 'datetime'];

    protected $appends = ['is_read'];

    public function getIsReadAttribute(): bool
    {
        return $this->read_at !== null;
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
