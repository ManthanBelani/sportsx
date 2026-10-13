<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Traits\Auditable;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, Auditable;

    protected $fillable = [
        'role', 'name', 'email', 'phone', 'password',
        'status', 'email_verified_at', 'admin_2fa_verified_at',
        'notification_prefs', 'social_links', 'privacy_settings', 'language',
        'verification_token', 'reset_password_token', 'reset_password_sent_at',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'admin_2fa_verified_at' => 'datetime',
            'password' => 'hashed',
            'notification_prefs' => 'array',
            'social_links' => 'array',
            'privacy_settings' => 'array',
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

    /**
     * Third-party identities ("Continue with Google").
     *
     * @see \App\Models\SocialAccount
     */
    public function socialAccounts(): HasMany
    {
        return $this->hasMany(SocialAccount::class);
    }

    /**
     * Guardian consents recorded for this athlete (minors only).
     *
     * @see \App\Models\GuardianConsent
     */
    public function guardianConsents(): HasMany
    {
        return $this->hasMany(GuardianConsent::class, 'athlete_user_id');
    }

    public function isVerified(): bool
    {
        return \App\Models\VerificationRequest::where('requester_user_id', $this->id)
            ->where('status', \App\Models\VerificationRequest::STATUS_APPROVED)
            ->exists();
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
            'talent_scout', 'scout' => (bool) $this->talentScoutProfile,
            default => true,
        };
    }
}
