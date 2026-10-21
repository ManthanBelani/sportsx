# Test Credentials

Seeded test users for development and testing.

Every account below uses the password **`password`** and a verified email, so
`POST /api/v1/auth/login` works out of the box. All active accounts have a
complete role profile, so the app never redirects them into onboarding
(`needs_onboarding: false`).

## Users

| Role | Email | Password | Name | Notes |
|------|-------|----------|------|-------|
| Admin | `admin@sportx.test` | `password` | Admin User | Super admin, 2FA pre-verified for 12h |
| Admin | `admin2@sportx.test` | `password` | Meera Admin | Second admin for role/permission checks |
| Athlete | `athlete@sportx.test` | `password` | John Athlete | Primary athlete account, adult |
| Athlete | `rahul@sportx.test` | `password` | Rahul Sharma | Minor, guardian consent **verified** |
| Athlete | `priya@sportx.test` | `password` | Priya Patel | Minor, guardian consent **pending** |
| Athlete | `aarav@sportx.test` | `password` | Aarav Menon | Adult, basketball |
| Athlete | `diya@sportx.test` | `password` | Diya Nair | Minor, guardian consent **verified** (first-name-only leaderboard) |
| Athlete | `kabir@sportx.test` | `password` | Kabir Khan | Adult, kabaddi |
| Coach | `coach@sportx.test` | `password` | Sarah Coach | Published listing, academy head coach |
| Coach | `vikram@sportx.test` | `password` | Vikram Singh | Published listing |
| Coach | `coach2@sportx.test` | `password` | Ritu Desai | Published listing, badminton |
| Academy | `academy@sportx.test` | `password` | Elite Academy | Published + verified badge |
| Academy | `mca@sportx.test` | `password` | Mumbai Cricket Academy | Published + verified badge |
| Academy | `academy2@sportx.test` | `password` | Surat Sports Academy | Published, unverified (pending blue check) |
| Organizer | `organizer@sportx.test` | `password` | Gujarat Sports Federation | Verified, has tournaments |
| Organizer | `organizer2@sportx.test` | `password` | Mumbai District Sports Council | Verified, NGO type |
| Organizer | `organizer.cricket@sportx.test` | `password` | Gujarat Cricket Federation | Owns the U-16 State Cup |
| Organizer | `organizer.badminton@sportx.test` | `password` | Badminton Association of India | Owns the All India Badminton Open |
| Organizer | `organizer.swimming@sportx.test` | `password` | Mumbai Swimming Association | Owns the Junior Swimming Championship |
| Organizer | `organizer.athletics@sportx.test` | `password` | Delhi Athletics Federation | Owns the Delhi Athletics Meet |
| Organizer | `organizer.basketball@sportx.test` | `password` | Karnataka Basketball Association | Owns the Bangalore Basketball League |
| Organizer | `organizer.tennis@sportx.test` | `password` | All India Tennis Association | Owns the National Tennis Open |
| Organizer | `organizer.wfootball@sportx.test` | `password` | Women Football Association | Owns the Women Football Cup |
| Organizer | `organizer.kabaddi@sportx.test` | `password` | Gujarat Kabaddi Association | Owns the Gujarat Kabaddi Championship |
| Organizer | `organizer.chess@sportx.test` | `password` | Ahmedabad Chess Association | Owns the Junior Chess Tournament |
| Talent Scout | `kiran@scout.test` | `password` | Kiran Patel | Shortlists + observations |
| Talent Scout | `scout2@sportx.test` | `password` | Anita Fernandes | Second scout for two-way connect |
| Sponsor | `sponsor@sportx.test` | `password` | Decathlon India | Legacy role — API returns `410 SPONSOR_REMOVED` |

### Accounts that cannot log in (by design)

These exist so the admin approve / reject / suspend flows have something to act on.

| Email | Status | Expected response |
|-------|--------|-------------------|
| `athlete.pending@sportx.test` | `pending` | `403` — pending admin approval |
| `coach.pending@sportx.test` | `pending` | `403` — pending admin approval |
| `academy.pending@sportx.test` | `pending` | `403` — pending admin approval |
| `organizer.pending@sportx.test` | `pending` | `403` — pending admin approval |
| `scout.pending@sportx.test` | `pending` | `403` — pending admin approval |
| `athlete.suspended@sportx.test` | `suspended` | `403` — account suspended |

## Admin 2FA

The seeded admin accounts carry a **known TOTP secret** so a 6-digit code can
be generated with any authenticator app:

```
Secret: JBSWY3DPEHPK3PXP   (admin@sportx.test and admin2@sportx.test)
```

`users.admin_2fa_verified_at` is pre-set for 12 hours, so the admin API
(`/api/v1/admin/*`) is reachable immediately after a seed. The admin **panel**
(`/panel`) always demands a fresh code — generate one from the secret above.

Local shortcut: set `ADMIN_2FA_ENFORCE=false` in `.env` to accept any 6-digit
code on `/api/v1/admin/verify-2fa`. Never do this outside local development.

## Usage

```bash
# Run all seeders (safe to re-run — every seeder is idempotent)
php artisan db:seed --class=AllSeeder

# Reset and re-seed from scratch
php artisan migrate:fresh --seed --seeder=AllSeeder
```

`php artisan db:seed` (no `--class`) runs the same full set.

## What the seed covers

| Area | Seeded data |
|------|-------------|
| Master data | 10 sports, 12 cities, 6 age groups, 59 playing positions |
| Accounts | 25 users across admin / athlete / coach / academy / organizer / talent_scout / sponsor, incl. pending + suspended |
| Profiles | athlete, coach, academy, organizer, sponsor, talent scout, admin — with every mandatory field filled |
| Listings | 8 trials, 10 tournaments (+40 categories), 8 sports venues, 7 opportunities (+6 applications), 7 programs, 7 facilities |
| Registrations | trial, tournament and coaching-enrolment registrations in mixed approval states |
| Social | 11 connections (accepted / pending / blocked), 12 follows, 2 blocks, 5 conversations (+12 messages), 3 posts with likes and comments |
| Scout workspace | 5 shortlists, 5 scout connections, 4 observations, 3 seasons of leaderboard scores |
| Trust & safety | 5 blue-check verification requests (pending / approved / rejected), 4 guardian consents (verified / pending / revoked) |
| Platform | 16 notifications, 20 analytics events, 6 expiry rules + pending expiry queue, 8 + 9 device tokens, 2 linked Google identities |
| Media | 50 media items (avatars, academy galleries, venue, trial, tournament, opportunity logos) |

## Seeder Files

Located in `database/seeders/`:

| Seeder | Table(s) |
|--------|----------|
| `AllSeeder.php` | Runs all seeders in order |
| `DatabaseSeeder.php` | Default `db:seed` entry point (delegates to `AllSeeder`) |
| `Support/SeedLookup.php` | Name→id lookups shared by the seeders |
| `MasterDataSeeder.php` | sports, cities, age_groups |
| `PositionSeeder.php` | positions |
| `UserSeeder.php` | users |
| `AdminProfileSeeder.php` | admin_profiles (+ 2FA secret) |
| `AthleteProfileSeeder.php` | athlete_profiles, athlete_sports |
| `CoachProfileSeeder.php` | coach_profiles |
| `AcademySeeder.php` | academies, academy_sports, academy_coaches |
| `OrganizerProfileSeeder.php` | organizer_profiles, organizer_sports |
| `SponsorProfileSeeder.php` | sponsor_profiles |
| `TalentScoutSeeder.php` | talent_scout_profiles |
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
| `OpportunitySeeder.php` | opportunities, opportunity_applications |
| `ProgramSeeder.php` | programs |
| `FacilitySeeder.php` | facilities |
| `EnquirySeeder.php` | enquiries |
| `EnquiryMessageSeeder.php` | enquiry_messages |
| `SavedItemSeeder.php` | saved_items |
| `ListingReportSeeder.php` | listing_reports |
| `NotificationSeeder.php` | notifications |
| `SocialSeeder.php` | conversations, conversation_participants, messages |
| `ConnectionSeeder.php` | connections |
| `SocialGraphSeeder.php` | follows, blocks |
| `ConversationSeeder.php` | conversations, conversation_participants, messages |
| `LeaderboardSeeder.php` | leaderboard_seasons, leaderboard_scores |
| `ScoutActivitySeeder.php` | scout_shortlists, scout_connections, observations |
| `TrustSafetySeeder.php` | verification_requests, guardian_consents |
| `DeviceTokenSeeder.php` | device_tokens |
| `UserDeviceTokenSeeder.php` | user_device_tokens |
| `SocialAccountSeeder.php` | social_accounts |
| `AnalyticsSeeder.php` | analytics_events |
| `ExpirySeeder.php` | expiry_rules, expiry_events |
| `PostSeeder.php` | posts |
| `PostLikeSeeder.php` | post_likes |
| `PostCommentSeeder.php` | post_comments |
| `RecentSearchSeeder.php` | recent_searches |
| `AchievementSeeder.php` | achievements |
| `CoachingEnrollmentSeeder.php` | coaching_enrollments |
| `MediaItemSeeder.php` | media_items |
