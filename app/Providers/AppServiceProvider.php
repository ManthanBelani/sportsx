<?php

namespace App\Providers;

use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\SponsorshipApplication;
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
        ]);
    }
}
