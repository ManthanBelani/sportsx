<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\SoftDeletes;

class Tournament extends Model
{
    use HasFactory, Auditable, SoftDeletes;

    protected $fillable = [
        'organizer_id', 'sport_id', 'name', 'organizer_name', 'format',
        'start_date', 'end_date', 'registration_deadline', 'venue',
        'google_maps_url', 'city_id', 'entry_fee', 'contact_number',
        'registration_link', 'external_registration_url',
        'external_registration_clicks', 'prize_pool', 'rules',
        'banner_media_id', 'gender', 'status', 'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'registration_deadline' => 'date',
            'expires_at' => 'datetime',
            'external_registration_clicks' => 'integer',
        ];
    }

    public function organizer(): BelongsTo
    {
        return $this->belongsTo(OrganizerProfile::class, 'organizer_id');
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }

    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    public function bannerMedia(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class, 'banner_media_id');
    }

    /**
     * Resolved banner URL for list/detail payloads (nullable).
     *
     * Always read through the eagerly-loaded relation so list endpoints never
     * trigger N+1 queries — see the `bannerMedia` with() calls below.
     */
    public function bannerUrl(): ?string
    {
        $path = $this->bannerMedia?->url;

        return $path === null || $path === '' ? null : $path;
    }

    public function categories(): HasMany
    {
        return $this->hasMany(TournamentCategory::class);
    }

    public function registrations(): HasMany
    {
        return $this->hasMany(TournamentRegistration::class);
    }

    public function results(): HasMany
    {
        return $this->hasMany(TournamentResult::class);
    }

    public function registrationClicks(): HasMany
    {
        return $this->hasMany(TournamentRegistrationClick::class);
    }

    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }

    /**
     * Eager-load the counters used by the registration stats block so list
     * endpoints don't fan out one query per tournament.
     */
    public function scopeWithRegistrationCounts($query)
    {
        return $query
            ->withCount([
                'registrations',
                'registrations as confirmed_registrations_count' => fn ($q) => $q->where('approval_status', 'approved'),
                'registrations as pending_registrations_count' => fn ($q) => $q->where('approval_status', 'pending'),
                'registrations as rejected_registrations_count' => fn ($q) => $q->where('approval_status', 'rejected'),
            ])
            ->withSum('categories as total_spots', 'capacity');
    }

    /**
     * True when the "Register" button should hand the user over to an
     * external registration page instead of the in-app flow.
     */
    public function hasExternalRegistration(): bool
    {
        return ! empty($this->external_registration_url);
    }

    /**
     * Registration statistics for a tournament.
     *
     * `confirmed_registrations_count` counts real registrations made on
     * SportX; `external_registration_clicks` counts clicks on the external
     * register button. The two are intentionally kept apart — an external
     * click is not a confirmed registration.
     *
     * @param  array<string, mixed>|null  $counts  Pre-loaded counters from
     *                                              scopeWithRegistrationCounts().
     */
    public function registrationStats(?array $counts = null): array
    {
        $counts = $counts ?? [];

        $total = (int) ($counts['registrations_count'] ?? $this->registrations_count ?? $this->registrations()->count());
        $confirmed = (int) ($counts['confirmed_registrations_count']
            ?? $this->confirmed_registrations_count
            ?? $this->registrations()->where('approval_status', 'approved')->count());
        $pending = (int) ($counts['pending_registrations_count']
            ?? $this->pending_registrations_count
            ?? $this->registrations()->where('approval_status', 'pending')->count());
        $rejected = (int) ($counts['rejected_registrations_count']
            ?? $this->rejected_registrations_count
            ?? $this->registrations()->where('approval_status', 'rejected')->count());
        $spots = (int) ($counts['total_spots'] ?? $this->total_spots ?? $this->categories()->sum('capacity'));
        $clicks = (int) $this->external_registration_clicks;

        return [
            'registration_mode' => $this->hasExternalRegistration() ? 'external' : 'internal',
            'has_external_registration' => $this->hasExternalRegistration(),
            'registrations_count' => $total,
            'confirmed_registrations_count' => $confirmed,
            'pending_registrations_count' => $pending,
            'rejected_registrations_count' => $rejected,
            'external_registration_clicks' => $clicks,
            'total_spots' => $spots,
            'filled_spots' => $confirmed,
            'spots_left' => max(0, $spots - $confirmed),
            'utilization_percent' => $spots > 0 ? round(($confirmed / $spots) * 100, 1) : 0.0,
        ];
    }
}
