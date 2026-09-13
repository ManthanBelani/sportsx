<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class AuditLog extends Model
{
    protected $fillable = [
        'user_id', 'user_name', 'user_role', 'action',
        'auditable_type', 'auditable_id', 'auditable_label',
        'old_values', 'new_values', 'changed_fields',
        'ip_address', 'user_agent', 'route',
    ];

    protected $casts = [
        'old_values' => 'array',
        'new_values' => 'array',
        'changed_fields' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function auditable(): MorphTo
    {
        return $this->morphTo();
    }

    public function scopeFilter($query, array $filters)
    {
        if (!empty($filters['q'])) {
            $q = $filters['q'];
            $query->where(function ($b) use ($q) {
                $b->where('auditable_label', 'like', "%{$q}%")
                  ->orWhere('auditable_type', 'like', "%{$q}%")
                  ->orWhere('user_name', 'like', "%{$q}%")
                  ->orWhere('action', 'like', "%{$q}%");
            });
        }
        if (!empty($filters['action'])) {
            $query->where('action', $filters['action']);
        }
        if (!empty($filters['auditable_type'])) {
            $query->where('auditable_type', $filters['auditable_type']);
        }
        if (!empty($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }
        return $query;
    }
}
