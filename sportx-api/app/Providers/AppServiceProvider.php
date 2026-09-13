<?php

namespace App\Providers;

use App\Events\ListingRemoved;
use App\Events\ListingWarned;
use App\Events\NotificationCreated;
use App\Listeners\NotifyOwnerOnListingRemoved;
use App\Listeners\NotifyOwnerOnListingWarned;
use App\Listeners\SendPushNotificationListener;
use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\OrganizerProfile;
use App\Models\SponsorProfile;
use App\Models\TalentScoutProfile;
use App\Models\Scholarship;
use App\Models\Sponsorship;
use App\Models\SponsorshipApplication;
use App\Models\SportsVenue;
use App\Models\Trial;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Support\Facades\Event;
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
            'organizer_profile' => OrganizerProfile::class,
            'sponsor_profile' => SponsorProfile::class,
            'talent_scout_profile' => TalentScoutProfile::class,
            'user' => User::class,
            'sponsorship_application' => SponsorshipApplication::class,
            'trial' => Trial::class,
            'tournament' => Tournament::class,
            'scholarship' => Scholarship::class,
            'sponsorship' => Sponsorship::class,
            'sports_venue' => SportsVenue::class,
        ]);

        Event::listen(NotificationCreated::class, SendPushNotificationListener::class);
        Event::listen(ListingRemoved::class, NotifyOwnerOnListingRemoved::class);
        Event::listen(ListingWarned::class, NotifyOwnerOnListingWarned::class);
    }
}
