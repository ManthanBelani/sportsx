<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Program extends Model
{
    use SoftDeletes;

    public const STATUSES = ['draft', 'active', 'past'];

    public const MODES = ['online', 'offline', 'hybrid'];

    protected $fillable = [
        'owner_type', 'owner_id', 'created_by_user_id', 'title', 'sport_id',
        'age_group_id', 'duration', 'mode', 'price', 'schedule', 'about', 'status',
    ];

    protected function casts(): array
    {
        return ['price' => 'decimal:2'];
    }

    public function owner(): MorphTo
    {
        return $this->morphTo();
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function ageGroup(): BelongsTo
    {
        return $this->belongsTo(AgeGroup::class);
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }
}
