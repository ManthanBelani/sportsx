<?php

namespace App\Providers;

use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\Scholarship;
use App\Models\Sponsorship;
use App\Models\SponsorshipApplication;
use App\Models\SportsVenue;
use App\Models\Trial;
use App\Models\Tournament;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Relation::morphMap([
            'athlete_profile' => AthleteProfile::class,
            'coach_profile' => CoachProfile::class,
            'academy' => Academy::class,
            'sponsorship_application' => SponsorshipApplication::class,
            'trial' => Trial::class,
            'tournament' => Tournament::class,
            'scholarship' => Scholarship::class,
            'sponsorship' => Sponsorship::class,
            'sports_venue' => SportsVenue::class,
        ]);
    }
}
