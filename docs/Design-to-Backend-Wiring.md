# SportX India — Design Screen to API Endpoint Wiring

Maps each Flutter screen (by design screen ID from `sportsx/src/screens/`) to its backend API endpoints in `sportx-api`.

---

## Auth Flow

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| S1 | Splash | `splash_screen.dart` | `GET /api/v1/auth/me` (token check) |
| S2 | Role Selection | `role_selection_screen.dart` | No API (local state) |
| S3 | Sign Up | `sign_up_screen.dart` | `POST /api/v1/auth/register` |
| S4 | OTP Verification | `otp_screen.dart` | `POST /api/v1/auth/verify-otp` |
| S5 | Login | `login_screen.dart` | `POST /api/v1/auth/login` |
| — | Forgot Password | `login_screen.dart` | `POST /api/v1/auth/forgot-password` |
| — | Reset Password | — | `POST /api/v1/auth/reset-password` |
| — | Logout | `settings_screen.dart` | `POST /api/v1/auth/logout` |

**Auth API Controller:** `AuthController`
- `POST /auth/register` → register()
- `POST /auth/verify-otp` → verifyOtp()
- `POST /auth/resend-otp` → resendOtp()
- `POST /auth/login` → login()
- `POST /auth/logout` → logout()
- `POST /auth/forgot-password` → forgotPassword()
- `POST /auth/reset-password` → resetPassword()
- `GET /auth/me` → me()

---

## Onboarding Flow

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| A1 | Athlete Onboarding Step 1 | `onboarding_sport_age_screen.dart` | `POST /api/v1/onboarding/athlete` |
| A2 | Athlete Onboarding Step 2 | `onboarding_skill_location_screen.dart` | `PUT /api/v1/me/profile/sports` |
| C1 | Coach Onboarding | `coach_onboarding_screen.dart` | `POST /api/v1/onboarding/coach` |
| AC1 | Academy Onboarding | `academy_onboarding_screen.dart` | `POST /api/v1/onboarding/academy` |
| — | Organizer Onboarding | `organizer_onboarding_screen.dart` | `POST /api/v1/onboarding/organizer` |
| SP1 | Sponsor Onboarding | `sponsor_onboarding_screen.dart` | `POST /api/v1/onboarding/sponsor` |

**Onboarding API Controller:** `OnboardingController`
- `POST /onboarding/athlete` → athlete()
- `POST /onboarding/coach` → coach()
- `POST /onboarding/academy` → academy()
- `POST /onboarding/organizer` → organizer()
- `POST /onboarding/sponsor` → sponsor()

---

## Home & Discovery

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| A3 | Home Dashboard | `home_screen.dart` | `GET /api/v1/academies`, `/trials`, `/tournaments`, `/scholarships`, `/sports-venues` |
| A7 | Academy Directory | `academy_directory_screen.dart` | `GET /api/v1/academies` |
| A8 | Academy Detail | `academy_detail_screen.dart` | `GET /api/v1/academies/{id}` |
| A9 | Coach Directory | `coach_directory_screen.dart` | `GET /api/v1/coaches` |
| A10 | Coach Detail | `coach_detail_screen.dart` | `GET /api/v1/coaches/{id}` |
| A12 | Trial Directory | `trial_directory_screen.dart` | `GET /api/v1/trials` |
| A13 | Trial Detail | `trial_detail_screen.dart` | `GET /api/v1/trials/{id}` |
| A16 | Tournament Directory | `tournament_directory_screen.dart` | `GET /api/v1/tournaments` |
| A17 | Tournament Detail | `tournament_detail_screen.dart` | `GET /api/v1/tournaments/{id}` |
| A19 | Scholarship Feed | `scholarship_list_screen.dart` | `GET /api/v1/scholarships` |
| A20 | Scholarship Detail | `scholarship_list_screen.dart` | `GET /api/v1/scholarships/{id}` |
| A21 | Sponsorship List | `sponsor_pitch_screen.dart` | `GET /api/v1/sponsorships` |
| A22 | Sponsorship Detail | (detail screen) | `GET /api/v1/sponsorships/{id}` |
| AS-47 | Sports Venue Directory | `sports_venue_list_screen.dart` | `GET /api/v1/sports-venues` |
| AS-47 | Sports Venue Detail | (detail screen) | `GET /api/v1/sports-venues/{id}` |

**Directory API Controller:** `DirectoryController`, `TrialController`, `TournamentController`, `ScholarshipController`, `SponsorshipController`, `SportsVenueController`
- `GET /academies`, `GET /academies/{id}`
- `GET /coaches`, `GET /coaches/{id}`
- `GET /trials`, `GET /trials/{id}`
- `GET /tournaments`, `GET /tournaments/{id}`
- `GET /scholarships`, `GET /scholarships/{id}`
- `GET /sponsorships`, `GET /sponsorships/{id}`
- `GET /sports-venues`, `GET /sports-venues/{id}`

---

## Search

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| S6 | Universal Search | `search_screen.dart` | `GET /api/v1/search?q=` |
| S7 | Search Results | `search_screen.dart` | `GET /api/v1/search?type=&q=` |
| S8 | Filter Panel | `search_screen.dart` | `GET /api/v1/search?sport=&city=&age_group=` |

**Search API Controller:** `SearchController`
- `GET /search` → search()

---

## Profile

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| A4 | My Profile (Athlete) | `profile_screen.dart` | `GET /api/v1/me/profile` |
| A5 | Edit Profile | — | `PUT /api/v1/me/profile` |
| A6 | Media Gallery | — | `POST /media/upload`, `PUT /media/reorder`, `DELETE /media/{id}` |
| — | Add Achievement | — | `PUT /api/v1/me/profile` (achievements array) |
| — | Edit Stats | — | `PUT /api/v1/me/profile` |
| — | Social Links | — | `PUT /api/v1/me/profile` |

**Profile API Controller:** `ProfileController`, `MediaController`
- `GET /me/profile` → show()
- `PUT /me/profile` → update()
- `PUT /me/profile/sports` → updateSports()
- `POST /media/upload` → upload()
- `PUT /media/reorder` → reorder()
- `DELETE /media/{id}` → destroy()

---

## Saved Items & Reports

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| A25 | Saved/Bookmarked Items | `saved_screen.dart` | `GET /api/v1/me/saved` |
| — | Save Item | (toggle) | `POST /api/v1/me/saved` |
| — | Unsave Item | (toggle) | `DELETE /api/v1/me/saved` |
| S10 | Report a Listing | — | `POST /api/v1/reports` |

**SavedItem API Controller:** `SavedItemController`, `ReportController`
- `GET /me/saved` → index()
- `POST /me/saved` → store()
- `DELETE /me/saved` → destroy()
- `POST /reports` → store()

---

## Enquiries

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| A11 | Enquire with Coach | `enquire_screen.dart` | `POST /api/v1/enquiries` |
| C4 | Coach Enquiry Inbox | `enquiry_inbox_screen.dart` | `GET /api/v1/me/enquiries` |
| C5 | Enquiry Detail/Reply | `enquiry_detail_screen.dart` | `GET /api/v1/enquiries/{id}`, `POST /api/v1/enquiries/{id}/messages` |
| AC8 | Academy Enquiry Inbox | `enquiry_inbox_screen.dart` | `GET /api/v1/me/enquiries` |
| AC9 | Academy Enquiry Detail | `enquiry_detail_screen.dart` | `GET /api/v1/enquiries/{id}`, `POST /api/v1/enquiries/{id}/messages` |

**Enquiry API Controller:** `EnquiryController`
- `POST /enquiries` → store()
- `GET /me/enquiries` → inbox()
- `GET /enquiries/{id}` → show()
- `POST /enquiries/{id}/messages` → reply()
- `PUT /enquiries/{id}/read` → markRead()

---

## Trial Registration

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| A14 | Trial Registration Form | `trial_registration_screen.dart` | `POST /api/v1/trials/{trial}/register` |
| A15 | Registration Confirmation | `registration_confirmation_screen.dart` | `GET /api/v1/registrations/trials/{registration}` |
| AC4 | Academy Trial Posting | `trial_posting_screen.dart` | `POST /api/v1/me/trials` |
| AC5 | My Trials Management | `my_trials_management_screen.dart` | `GET /api/v1/me/trials` |
| AC6 | Registrant List | `registrant_list_screen.dart` | `GET /api/v1/trials/{trial}/registrations` |
| AC7 | Registrant Detail | `registrant_detail_screen.dart` | `POST /api/v1/registrations/trials/{registration}/verify`, `/reject` |
| A24 | Activity Hub (Trials) | `activity_hub_screen.dart` | `GET /api/v1/me/activity` |

**Registration API Controller:** `RegistrationController`
- `POST /trials/{trial}/register` → storeTrial()
- `GET /trials/{trial}/registrations` → trialIndex()
- `GET /registrations/trials/{registration}` → trialShow()
- `POST /registrations/trials/{registration}/verify` → verifyTrial()
- `POST /registrations/trials/{registration}/reject` → rejectTrial()
- `POST /registrations/trials/{registration}/reminder` → toggleTrialReminder()

**Provider Trial API Controller:** `ProviderTrialController`
- `GET /me/trials` → index()
- `POST /me/trials` → store()
- `PUT /me/trials/{trial}` → update()
- `POST /me/trials/{trial}/publish` → publish()
- `POST /me/trials/{trial}/close` → close()

---

## Tournament Registration

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| A18 | Tournament Registration | `tournament_registration_screen.dart` | `POST /api/v1/tournaments/{tournament}/register` |
| O2 | Organizer Dashboard | `organizer_dashboard_screen.dart` | `GET /api/v1/me/activity` |
| O3/O4 | Trial Management | `my_trials_management_screen.dart` | `GET/POST /api/v1/me/trials` |
| O5 | Tournament Create/Edit | `tournament_posting_screen.dart` | `POST /api/v1/me/tournaments` |
| O6 | My Tournaments | `my_tournaments_management_screen.dart` | `GET /api/v1/me/tournaments` |
| O7 | Registration Management | `registration_management_screen.dart` | `GET /api/v1/tournaments/{tournament}/registrations` |
| O8 | Capacity Management | `capacity_management_screen.dart` | `GET/PUT /api/v1/tournaments/{tournament}/capacity` |
| O9 | Results Publishing | `results_publishing_screen.dart` | `POST /api/v1/tournaments/{tournament}/results` |
| O10 | Results/Brackets View | `results_view_screen.dart` | `GET /api/v1/tournaments/{tournament}/results` |

**Tournament Registration API Controller:** `RegistrationController`
- `POST /tournaments/{tournament}/register` → storeTournament()
- `GET /tournaments/{tournament}/registrations` → tournamentIndex()
- `GET /tournaments/{tournament}/capacity` → tournamentCapacity()
- `PUT /tournaments/{tournament}/capacity` → updateTournamentCapacity()
- `PATCH /registrations/tournaments/{registration}/payment` → updateTournamentPayment()
- `GET /me/registrations` → myRegistrations()

**Provider Tournament API Controller:** `ProviderTournamentController`
- `GET /me/tournaments` → index()
- `POST /me/tournaments` → store()
- `PUT /me/tournaments/{tournament}` → update()
- `PUT /me/tournaments/{tournament}/categories` → updateCategories()
- `POST /me/tournaments/{tournament}/publish` → publish()
- `POST /me/tournaments/{tournament}/close` → close()

**Results API Controller:** `ResultsController`
- `GET /tournaments/{tournament}/results` → index()
- `POST /tournaments/{tournament}/results` → store()
- `POST /tournaments/{tournament}/results/{result}/publish` → publish()
- `POST /tournaments/{tournament}/results/{result}/unpublish` → unpublish()

---

## Sponsorship / Sponsor Features

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| A23 | Apply/Pitch to Sponsor | `sponsor_pitch_screen.dart` | `POST /api/v1/sponsorships/{sponsorship}/apply` |
| SP1 | Sponsor Onboarding | `sponsor_onboarding_screen.dart` | `POST /api/v1/onboarding/sponsor` |
| SP2 | Sponsor Dashboard | `sponsor_dashboard_screen.dart` | `GET /api/v1/me/activity` |
| SP3 | Sponsorship Create/Edit | `sponsorship_posting_screen.dart` | `POST/PUT /api/v1/me/sponsorships` |
| SP4 | My Sponsorships | `my_sponsorships_management_screen.dart` | `GET /api/v1/me/sponsorships` |
| SP5 | Athlete Discovery | `athlete_discovery_screen.dart` | `GET /api/v1/athletes` |
| SP6 | Athlete Profile View | `athlete_profile_view_screen.dart` | `GET /api/v1/athletes/{id}` |
| SP7 | Applications Inbox | `applications_inbox_screen.dart` | `GET /api/v1/sponsorships/{sponsorship}/applications` |
| SP8 | Application Detail | `application_detail_screen.dart` | `PATCH /api/v1/sponsorships/{sponsorship}/applications/{application}` |
| SP9 | Shortlist | `shortlist_screen.dart` | `GET /api/v1/me/shortlist`, `POST /me/shortlist` |
| A24 | Activity Hub (Sponsorships) | `activity_hub_screen.dart` | `GET /api/v1/me/activity` |

**Sponsor Engagement API Controller:** `SponsorEngagementController`
- `GET /me/sponsorships` → mySponsorships()
- `POST /me/sponsorships` → storeSponsorship()
- `PUT /me/sponsorships/{sponsorship}` → updateSponsorship()
- `POST /me/sponsorships/{sponsorship}/publish` → publishSponsorship()
- `POST /me/sponsorships/{sponsorship}/close` → closeSponsorship()
- `POST /sponsorships/{sponsorship}/apply` → apply()
- `GET /me/applications` → myApplications()
- `GET /sponsorships/{sponsorship}/applications` → applications()
- `PATCH /sponsorships/{sponsorship}/applications/{application}` → updateApplication()
- `GET /me/shortlist` → shortlist()
- `POST /me/shortlist` → addToShortlist()
- `DELETE /me/shortlist/{entry}` → removeFromShortlist()

**Athlete Discovery API Controller:** `AthleteDiscoveryController`
- `GET /athletes` → index()
- `GET /athletes/{id}` → show()

---

## Notifications

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| S9 | Notifications Center | `notifications_screen.dart` | `GET /api/v1/me/notifications` |
| — | Mark Read | (toggle) | `PATCH /api/v1/me/notifications/{notification}/read` |
| — | Mark All Read | (button) | `POST /api/v1/me/notifications/read-all` |
| — | Delete Notification | (swipe) | `DELETE /api/v1/me/notifications/{notification}` |

**Notification API Controller:** `NotificationController`
- `GET /me/notifications` → index()
- `PATCH /me/notifications/{notification}/read` → markRead()
- `POST /me/notifications/read-all` → markAllRead()
- `DELETE /me/notifications/{notification}` → destroy()

---

## Settings

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| S11 | Settings | `settings_screen.dart` | `GET /api/v1/me/settings`, `PUT /me/settings` |
| — | Change Password | (in settings) | `PUT /api/v1/me/settings/password` |
| — | Delete Account | (danger zone) | `DELETE /api/v1/me/account` |

**Settings API Controller:** `SettingsController`
- `GET /me/settings` → show()
- `PUT /me/settings` → update()
- `PUT /me/settings/password` → updatePassword()
- `DELETE /me/account` → destroy()

---

## Activity Hub

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| A24 | My Activity Hub | `activity_hub_screen.dart` | `GET /api/v1/me/activity` |
| — | My Registrations | `activity_hub_screen.dart` | `GET /api/v1/me/registrations` |
| — | My Enquiries | `activity_hub_screen.dart` | `GET /api/v1/me/enquiries` |
| — | My Applications | (sponsor tab) | `GET /api/v1/me/applications` |

**Activity API Controller:** `ActivityController`
- `GET /me/activity` → index()

---

## Admin Panel

| Screen ID | Screen Name | Flutter File | API Endpoints |
|-----------|-------------|--------------|---------------|
| AD1 | Admin Login | `admin_login_screen.dart` | `POST /api/v1/auth/login` (admin role) |
| AD2 | Admin Dashboard | `admin_dashboard_screen.dart` | `GET /api/v1/me/activity` (aggregated) |
| AD3 | Content Category Picker | `admin_content_picker_screen.dart` | `GET /api/v1/meta/sports`, `/meta/cities`, `/meta/age-groups` |
| AD4 | Content List per Category | `admin_content_list_screen.dart` | Directory endpoints with admin filter |
| AD5 | Content Create/Edit/Delete | — | Respective CRUD endpoints |
| AD6 | Flagged Listings Queue | — | `GET /api/v1/reports` (admin) |
| AD7 | Moderation Detail | — | Report review endpoints |
| AD8 | Expiry Rules Config | — | `ExpiryRule` model CRUD (implicit) |
| AD9 | Expiry Monitor | — | `ExpiryEvent` endpoints |
| AD10 | Category Mgmt — Sports | — | `Sport` model CRUD |
| AD11 | Category Mgmt — Cities | — | `City` model CRUD |
| AD12 | Category Mgmt — Age Groups | — | `AgeGroup` model CRUD |
| FR-ADMIN-11 | Scholarship Admin CRUD | — | `Scholarship` admin endpoints |

**Meta API Controller:** `MetaController`
- `GET /meta/sports` → sports()
- `GET /meta/cities` → cities()
- `GET /meta/age-groups` → ageGroups()
- `GET /meta/trending-searches` → trendingSearches()

---

## Master Data (Used Across All Screens)

| Purpose | API Endpoint | Flutter Provider |
|---------|--------------|------------------|
| Sports list | `GET /api/v1/meta/sports` | `metaProvider` |
| Cities list | `GET /api/v1/meta/cities` | `metaProvider` |
| Age groups | `GET /api/v1/meta/age-groups` | `metaProvider` |
| Trending searches | `GET /api/v1/meta/trending-searches` | `metaProvider` |

---

## Summary

| Category | Screens | API Endpoints Used |
|----------|---------|-------------------|
| Auth | 8 | 8 |
| Onboarding | 6 | 5 |
| Directory/Discovery | 14 | 12 |
| Search | 3 | 1 |
| Profile | 6 | 4 |
| Saved/Reports | 4 | 4 |
| Enquiries | 5 | 5 |
| Trial Registration | 7 | 11 |
| Tournament Registration | 10 | 15 |
| Sponsorship | 11 | 18 |
| Notifications | 4 | 4 |
| Settings | 4 | 4 |
| Activity Hub | 5 | 5 |
| Admin | 13 | 10+ |
| **Total** | **~90** | **~100** |
