<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = ['role', 'name', 'email', 'phone', 'password', 'google_id', 'status', 'email_verified_at', 'admin_2fa_verified_at'];

    protected $hidden = ['password', 'remember_token', 'google_id'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'admin_2fa_verified_at' => 'datetime',
            'password' => 'hashed',
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

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }
}
