<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class Scholarship extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'organization_name', 'name', 'sport_id', 'eligibility', 'deadline',
        'application_link', 'contact_email', 'contact_phone', 'amount',
        'currency', 'benefits', 'documents_required', 'description',
        'logo_media_id', 'status', 'created_by',
    ];

    protected function casts(): array
    {
        return [
            'deadline' => 'date',
            'amount' => 'decimal:2',
            'documents_required' => 'array',
        ];
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function logo(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'logo_media_id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }
}
