<?php

namespace App\Providers;

use App\Events\ListingRemoved;
use App\Events\ListingWarned;
use App\Events\NotificationCreated;
use App\Listeners\NotifyOwnerOnListingRemoved;
use App\Listeners\NotifyOwnerOnListingWarned;
use App\Listeners\SendPushNotificationListener;
use App\Mail\Transport\GmailApiTransport;
use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\OrganizerProfile;
use App\Models\Connection;
use App\Models\Conversation;
use App\Models\Facility;
use App\Models\Opportunity;
use App\Models\OpportunityApplication;
use App\Models\Post;
use App\Models\Program;
use App\Models\SocialAccount;
use App\Models\SponsorProfile;
use App\Models\TalentScoutProfile;
use App\Models\Scholarship;
use App\Models\Sponsorship;
use App\Models\SponsorshipApplication;
use App\Models\SportsVenue;
use App\Models\Trial;
use App\Models\Tournament;
use App\Models\User;
use App\Services\MailProviderService;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(MailProviderService::class);
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
            'social_account' => SocialAccount::class,
            'sponsorship_application' => SponsorshipApplication::class,
            'trial' => Trial::class,
            'tournament' => Tournament::class,
            'scholarship' => Scholarship::class,
            'sponsorship' => Sponsorship::class,
            'opportunity' => Opportunity::class,
            'opportunity_application' => OpportunityApplication::class,
            'program' => Program::class,
            'sports_venue' => SportsVenue::class,
            'facility' => Facility::class,
            'post' => Post::class,
            'connection' => Connection::class,
            'conversation' => Conversation::class,
            'scout_shortlist' => \App\Models\ScoutShortlist::class,
            'observation' => \App\Models\Observation::class,
            'leaderboard_score' => \App\Models\LeaderboardScore::class,
        ]);

        Event::listen(NotificationCreated::class, SendPushNotificationListener::class);
        Event::listen(ListingRemoved::class, NotifyOwnerOnListingRemoved::class);
        Event::listen(ListingWarned::class, NotifyOwnerOnListingWarned::class);

        $this->registerMailTransports();
    }

    /**
     * Wire up the two transactional email providers SportX supports.
     *
     * "smtp"  — handled natively by Symfony Mailer via config/mail.php.
     * "gmail" — delivered through the Gmail REST API, which is the only option
     *           for Google Workspace accounts that enforce 2FA and therefore
     *           reject app-password logins from unfamiliar hosts.
     */
    private function registerMailTransports(): void
    {
        Mail::extend('gmail-api', fn (array $config = []) => new GmailApiTransport($config));

        // Resolve the active mailer on every request so an admin switching
        // SMTP <-> Gmail in the panel takes effect without a redeploy.
        $mailer = app(MailProviderService::class)->activeMailer();

        config([
            'mail.default' => $mailer,
            // Failover chains are resolved from the same config, but the chain
            // must be filtered to providers that actually have credentials.
            'mail.mailers.sportx_failover' => [
                'transport' => 'failover',
                'mailers' => app(MailProviderService::class)->configuredChain() ?: ['log'],
                'retry_after' => (int) config('sportx.mail.retry_after', 60),
            ],
        ]);
    }
}
