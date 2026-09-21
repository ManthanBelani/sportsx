<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Traits\Auditable;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, Auditable;

    protected $fillable = [
        'role', 'name', 'email', 'phone', 'password', 'google_id',
        'status', 'email_verified_at', 'admin_2fa_verified_at',
        'notification_prefs', 'social_links', 'language',
        'verification_token', 'reset_password_token', 'reset_password_sent_at',
    ];

    protected $hidden = ['password', 'remember_token', 'google_id'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'admin_2fa_verified_at' => 'datetime',
            'password' => 'hashed',
            'notification_prefs' => 'array',
            'social_links' => 'array',
        ];
    }

    public function athleteProfile(): HasOne
    {
        return $this->hasOne(AthleteProfile::class);
    }

    public function coachProfile(): HasOne
    {
        return $this->hasOne(CoachProfile::class);
    }

    public function academies(): HasOne
    {
        return $this->hasOne(Academy::class, 'owner_user_id');
    }

    public function adminProfile(): HasOne
    {
        return $this->hasOne(AdminProfile::class);
    }

    public function organizerProfile(): HasOne
    {
        return $this->hasOne(OrganizerProfile::class);
    }

    public function sponsorProfile(): HasOne
    {
        return $this->hasOne(SponsorProfile::class);
    }

    public function talentScoutProfile(): HasOne
    {
        return $this->hasOne(TalentScoutProfile::class);
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /**
     * Whether the user has completed their role-specific profile.
     * Used to derive `needs_onboarding`. Roles without a profile
     * (e.g. admin) are treated as onboarded.
     */
    public function hasRoleProfile(): bool
    {
        return match ($this->role) {
            'athlete' => (bool) $this->athleteProfile,
            'coach' => (bool) $this->coachProfile,
            'academy' => (bool) $this->academies,
            'organizer' => (bool) $this->organizerProfile,
            'sponsor' => (bool) $this->sponsorProfile,
            'talent_scout' => (bool) $this->talentScoutProfile,
            default => true,
        };
    }
}
