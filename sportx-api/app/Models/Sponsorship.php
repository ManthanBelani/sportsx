<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class Sponsorship extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'sponsor_id', 'organization_name', 'sport_id', 'title', 'eligibility_criteria',
        'deadline', 'application_link', 'contact_email', 'contact_phone', 'benefits_offered',
        'amount', 'documents_required', 'description', 'logo_media_id', 'status', 'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'deadline' => 'date',
            'amount' => 'decimal:2',
            'documents_required' => 'array',
            'expires_at' => 'datetime',
        ];
    }

    public function sponsor(): BelongsTo
    {
        return $this->belongsTo(SponsorProfile::class, 'sponsor_id');
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function applications(): HasMany
    {
        return $this->hasMany(SponsorshipApplication::class);
    }

    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }
}
