<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Seeds the whole database: master data, every user role, every role
 * profile, and every feature area of the product.
 *
 * Safe to re-run — every seeder is idempotent (updateOrCreate / firstOrCreate),
 * so `php artisan db:seed --class=AllSeeder` can be used to refresh fixtures
 * without wiping data.
 *
 * Use `php artisan migrate:fresh --seed --seeder=AllSeeder` for a clean slate.
 */
class AllSeeder extends Seeder
{
    public function run(): void
    {
        // The fixture set creates accounts with a known password and a shared
        // TOTP secret. Never let it run against a real environment.
        if (app()->environment('production')) {
            $this->command->error('Refusing to seed in production.');

            return;
        }

        $this->call([
            // ── Master data ───────────────────────────────────────────
            MasterDataSeeder::class,
            PositionSeeder::class,

            // ── Accounts, one block per role ─────────────────────────
            UserSeeder::class,
            AdminProfileSeeder::class,
            CoachProfileSeeder::class,
            AcademySeeder::class,
            OrganizerProfileSeeder::class,
            SponsorProfileSeeder::class,
            TalentScoutSeeder::class,
            AthleteProfileSeeder::class,

            // ── Core listings ────────────────────────────────────────
            TrialSeeder::class,
            TrialRegistrationSeeder::class,
            TournamentSeeder::class,
            TournamentCategorySeeder::class,
            TournamentRegistrationSeeder::class,
            TournamentResultSeeder::class,
            ScholarshipSeeder::class,
            SponsorshipSeeder::class,
            SponsorshipApplicationSeeder::class,
            ShortlistEntrySeeder::class,
            SportsVenueSeeder::class,

            // ── Phase 4/5: opportunities, programs, facilities ───────
            OpportunitySeeder::class,
            ProgramSeeder::class,
            FacilitySeeder::class,

            // ── Phase 6: enquiries, chat, social graph, feed ─────────
            EnquirySeeder::class,
            EnquiryMessageSeeder::class,
            SocialSeeder::class,
            ConnectionSeeder::class,
            SocialGraphSeeder::class,
            ConversationSeeder::class,
            PostSeeder::class,
            PostLikeSeeder::class,
            PostCommentSeeder::class,

            // ── Phase 7: leaderboard + scout workspace ───────────────
            LeaderboardSeeder::class,
            ScoutActivitySeeder::class,

            // ── Trust, safety, analytics, expiry ─────────────────────
            TrustSafetySeeder::class,
            NotificationSeeder::class,
            DeviceTokenSeeder::class,
            UserDeviceTokenSeeder::class,
            SocialAccountSeeder::class,
            AnalyticsSeeder::class,
            ExpirySeeder::class,

            // ── Misc user data ───────────────────────────────────────
            SavedItemSeeder::class,
            ListingReportSeeder::class,
            RecentSearchSeeder::class,
            AchievementSeeder::class,
            CoachingEnrollmentSeeder::class,

            // ── Media (last: needs the listings it attaches to) ──────
            MediaItemSeeder::class,
        ]);
    }
}
