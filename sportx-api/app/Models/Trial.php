<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Trial extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'posted_by_user_id', 'academy_id', 'name', 'organization_name',
        'sport_id', 'event_datetime', 'venue', 'google_maps_url', 'city_id',
        'contact_number', 'registration_deadline', 'eligibility',
        'required_documents', 'vacancies', 'benefits', 'entry_fee', 'status', 'expires_at',
    ];

    protected $casts = [
        'event_datetime' => 'datetime',
        'registration_deadline' => 'datetime',
        'required_documents' => 'array',
        'vacancies' => 'integer',
        'expires_at' => 'datetime',
    ];

    public function postedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'posted_by_user_id');
    }

    public function academy(): BelongsTo
    {
        return $this->belongsTo(Academy::class);
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    public function registrations(): HasMany
    {
        return $this->hasMany(TrialRegistration::class);
    }

    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }

    public function scopeOpen($query)
    {
        return $query->published()->where('registration_deadline', '>=', now());
    }

    public function isRegisterable(): bool
    {
        return $this->status === 'published'
            && ($this->registration_deadline === null || $this->registration_deadline->isFuture());
    }
}
