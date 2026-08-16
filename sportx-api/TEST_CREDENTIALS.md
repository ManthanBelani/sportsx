# Test Credentials

Seeded test users for development and testing.

## Users

| Role | Email | Password | Name |
|------|-------|----------|------|
| Admin | `admin@sportx.test` | `password` | Admin User |
| Athlete | `athlete@sportx.test` | `password` | John Athlete |
| Athlete | `rahul@sportx.test` | `password` | Rahul Sharma |
| Athlete | `priya@sportx.test` | `password` | Priya Patel |
| Coach | `coach@sportx.test` | `password` | Sarah Coach |
| Coach | `vikram@sportx.test` | `password` | Vikram Singh |
| Academy | `academy@sportx.test` | `password` | Elite Academy |
| Academy | `mca@sportx.test` | `password` | Mumbai Cricket Academy |
| Organizer | `organizer@sportx.test` | `password` | Gujarat Sports Federation |
| Sponsor | `sponsor@sportx.test` | `password` | Decathlon India |

## Usage

```bash
# Run all seeders
php artisan db:seed --class=AllSeeder

# Reset and re-seed
php artisan migrate:fresh --seed --seeder=AllSeeder
```

## Seeder Files

Located in `database/seeders/`:

| Seeder | Table(s) |
|--------|----------|
| `AllSeeder.php` | Runs all seeders in order |
| `UserSeeder.php` | users |
| `MasterDataSeeder.php` | sports, cities, age_groups |
| `AdminProfileSeeder.php` | admin_profiles |
| `AthleteProfileSeeder.php` | athlete_profiles |
| `CoachProfileSeeder.php` | coach_profiles |
| `AcademySeeder.php` | academies |
| `OrganizerProfileSeeder.php` | organizer_profiles |
| `SponsorProfileSeeder.php` | sponsor_profiles |
| `TrialSeeder.php` | trials |
| `TrialRegistrationSeeder.php` | trial_registrations |
| `TournamentSeeder.php` | tournaments |
| `TournamentCategorySeeder.php` | tournament_categories |
| `TournamentRegistrationSeeder.php` | tournament_registrations |
| `TournamentResultSeeder.php` | tournament_results |
| `ScholarshipSeeder.php` | scholarships |
| `SponsorshipSeeder.php` | sponsorships |
| `SponsorshipApplicationSeeder.php` | sponsorship_applications |
| `ShortlistEntrySeeder.php` | shortlist_entries |
| `SportsVenueSeeder.php` | sports_venues |
| `EnquirySeeder.php` | enquiries |
| `EnquiryMessageSeeder.php` | enquiry_messages |
| `SavedItemSeeder.php` | saved_items |
| `ListingReportSeeder.php` | listing_reports |
| `NotificationSeeder.php` | notifications |
| `SocialSeeder.php` | conversations, conversation_participants, messages |
| `ConnectionSeeder.php` | connections |
| `PostSeeder.php` | posts |
| `PostLikeSeeder.php` | post_likes |
| `PostCommentSeeder.php` | post_comments |
| `DeviceTokenSeeder.php` | device_tokens |
| `RecentSearchSeeder.php` | recent_searches |
| `AchievementSeeder.php` | achievements |
