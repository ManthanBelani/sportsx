<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class AllSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            MasterDataSeeder::class,
            UserSeeder::class,
            AdminProfileSeeder::class,
            AthleteProfileSeeder::class,
            CoachProfileSeeder::class,
            AcademySeeder::class,
            OrganizerProfileSeeder::class,
            SponsorProfileSeeder::class,
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
            EnquirySeeder::class,
            EnquiryMessageSeeder::class,
            SavedItemSeeder::class,
            ListingReportSeeder::class,
            NotificationSeeder::class,
            SocialSeeder::class,
            ConnectionSeeder::class,
            PostSeeder::class,
            PostLikeSeeder::class,
            PostCommentSeeder::class,
            DeviceTokenSeeder::class,
            RecentSearchSeeder::class,
            AchievementSeeder::class,
            MediaItemSeeder::class,
        ]);
    }
}
