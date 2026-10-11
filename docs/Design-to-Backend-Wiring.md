# SportX India — Design Screen to API Endpoint Wiring

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

Maps each Flutter screen to its backend API endpoints in `sportx-api`.

> **⚠️ [SUPERSEDED — see Backend-Feature-Delta.md].** The old screen IDs below (`S1`–`S12`, `A#`, `SP#`, `O#`, `C#`, `AC#`, `AD#`) referenced `sportsx/src/screens/` and the sponsor role. The v3 source of truth is `sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md` (129 screens, 6 roles; sponsor removed). **§v3 (below) is authoritative** — it maps new screen IDs to the new endpoints in `Backend-Feature-Delta.md` §11. The old tables are retained for history.

---

## v3 wiring (authoritative) — new screens → new endpoints

> Endpoints per `Backend-Feature-Delta.md` §11; every role profile now carries its **30 fields** (`SportX_Mandatory_Fields.md`). Base `/api/v1`, Bearer Sanctum. Status: ✅ exists · 🆕 new · 🔁 changed · ❓ verify · 🅿️ P1.

### Auth, OTP & guardian (A.1–A.10)

| Screen | Flutter (target) | Endpoints |
|---|---|---|
| A.1 Splash | `splash_screen.dart` | `GET /auth/me` |
| A.2 Role Selection | `role_selection_screen.dart` | (local) — 5 roles |
| A.3 Sign Up | `sign_up_screen.dart` | `POST /auth/register` 🔁 · `POST /auth/send-otp` 🆕 · (`POST /auth/google` ❓) |
| A.4 OTP Verification | `otp_screen.dart` | `POST /auth/verify-otp` 🆕 · `POST /auth/resend-otp` 🆕 |
| A.5 Login | `login_screen.dart` | `POST /auth/login` 🔁 (password + OTP branch) |
| A.6 Forgot / Reset | `forgot_password_screen.dart` | `POST /auth/forgot-password` 🔁 · `POST /auth/reset-password` 🔁 |
| A.9 Guardian Consent | `guardian_consent_screen.dart` | `POST /guardian/consent` 🆕 · `POST /guardian/verify-otp` 🆕 |
| A.10 Verification Request | `verification_screen.dart` | `POST/GET /me/verification` 🆕 |
| S.29 Logout | `settings_screen.dart` | `POST /auth/logout` ✅ |
| S.22 Change password | `settings_screen.dart` | `POST /me/change-password` 🆕 |

### Onboarding (AT.2, CO.1, AC.1, OR.1, SC.1)

| Screen | Endpoints |
|---|---|
| AT.2 Athlete | `POST /onboarding/athlete` ✅ (+ guardian gate) |
| CO.1 Coach | `POST /onboarding/coach` ✅ |
| AC.1 Academy | `POST /onboarding/academy` ✅ |
| OR.1 Organizer | `POST /onboarding/organizer` ✅ |
| SC.1 Scout | `POST /onboarding/scout` 🆕 |
| ~~Sponsor~~ | ~~`POST /onboarding/sponsor`~~ ❌ **REMOVED** |
| AT.6 Completion checklist | `GET /me/completion-checklist` 🆕 |

### Home, Explore, search, leaderboard, saved (S.1–S.7, S.20)

| Screen | Endpoints |
|---|---|
| S.1 / role Homes (AT.1/CO.2/AC.2/OR.2/SC.2) | `GET /me/home` 🆕 (unified role-aware dashboard) · `GET /leaderboard/strip` 🆕 |
| S.2 Explore — All | `GET /explore` 🆕 (grouped athletes/coaches/academies/events/opportunities) |
| S.3 Category list | `GET /academies` · `/coaches` · `/trials` · `/tournaments` · `/opportunities` · `/programs` · `/scout` |
| S.4 Filter & Sort | `GET /meta/positions` 🆕 · `/meta/facilities` 🆕 (+ sports/cities/age-groups) |
| S.5 Universal Search | `GET /search` 🔁 (adds `athletes` group); `POST /me/recent-searches` 🆕 |
| S.6 Leaderboard | `GET /leaderboard` 🆕 (tabs, sport/location/age, podium+ranks) |
| S.7 Leaderboard Info | (client static) |
| S.20 Saved | `GET /me/saved` 🔁 (morphs + post/opportunity/event) |

### Profiles (D.1–D.5, A.10) — 30 fields per role

| Screen | Endpoints |
|---|---|
| D.1 Athlete Profile | `GET /me/profile` ✅ · `PUT /me/profile` 🔁 · `PUT /me/profile/sports` 🔁 (+role/level/exp/primary) · `GET /athletes/{id}` 🔁 |
| D.2 Coach Profile | `GET/PUT /me/coach-profile` ✅ · `GET /coaches/{id}` ✅ |
| D.3 Academy Profile | `GET/PUT /me/academy` ✅ · `GET /academies/{id}` ✅ |
| D.4 Organizer Profile | `GET/PUT /me/organizer-profile` 🆕 · `GET /organizers/{id}` 🆕 |
| D.5 Scout Profile | `GET/PUT /me/scout-profile` 🆕 · `GET /scouts/{id}` 🆕 |
| Achievements (S.11/AT.5) | `GET/POST /me/achievements` 🆕 · `PUT/DELETE /me/achievements/{id}` 🆕 |
| Media (S.10/S.28) | `POST /media/upload` ✅ · `PUT /media/reorder` ✅ · `GET /me/media` 🆕 |
| Privacy (S.22/AT.10) | `PUT /me/privacy` 🆕 · `GET/PUT /me/guardian-controls` 🆕 |
| A.10 Verification | `POST/GET /me/verification` 🆕 |

### Events, trials & registrations (D.6–D.8, AT.9, OR.4–OR.8)

| Screen | Endpoints |
|---|---|
| D.6 Event/Trial Detail | `GET /events/{id}` 🆕 (or `/trials/{id}`+`/tournaments/{id}`) |
| D.7 Registration Form | `POST /trials/{id}/register` · `POST /tournaments/{id}/register` ✅ |
| D.8 Confirmation | `GET /registrations/{id}` ✅ |
| OR.5 Create/Edit Event | `POST /me/events?type=` 🆕/🔁 |
| OR.4/AC.6/CO.6 My Events | `GET /me/events` 🆕 |
| OR.7 Registrations | `GET /events/{id}/registrations` ✅ · `POST /registrations/{id}/approve|reject` ✅ (+notify) |
| OR.7 Export | `GET /events/{id}/registrations/export` 🆕 |
| AT.9 My Registrations | `GET /me/registrations` 🆕 · `DELETE /me/registrations/{id}` 🆕 |
| OR.9/OR.10/OR.11/OR.12/OR.14 | `GET/POST /events/{id}/schedule|gallery|results|analytics|announce` 🅿️ |

### Opportunities, programs, facilities, enquiries (D.9–D.13, AT.8, CO.4/CO.5, AC.7/AC.8, SC.11/SC.12)

| Screen | Endpoints |
|---|---|
| D.9 Opportunity Detail | `GET /opportunities` 🆕 · `GET /opportunities/{id}` 🆕 |
| D.10 Apply / Pitch | `POST /opportunities/{id}/apply` 🆕 |
| AT.8 My Opportunities | `GET /me/opportunities?type=applied\|saved\|created` 🆕 |
| AC.9/SC.12 Create Opportunity | `POST /me/opportunities` 🆕 · `PUT/PATCH /me/opportunities/{id}` 🆕 |
| Applicant review (P1) | `GET /opportunities/{id}/applications` 🅿️ · `PATCH …/applications/{app}` 🅿️ |
| CO.4/CO.5/AC.4 Programs | `GET /me/programs` 🆕 · `POST/PUT /me/programs` 🆕 |
| D.11 Program Detail | `GET /programs/{id}` 🆕 |
| D.12 Enquiry | `POST /programs/{id}/enquire` 🆕 · `POST /enquiries` 🔁 (subject: program/opportunity) |
| AC.7/AC.8 Facilities | `GET /me/facilities` 🆕 · `POST/PUT/DELETE /me/facilities` 🆕 |
| D.13 Facility Detail | `GET /facilities/{id}` 🆕 |
| OR.13 Venues | `GET/POST/PUT /me/venues` 🅿️ |

### Social, network, messaging (S.8/S.9/S.27/S.28, S.12/S.19, S.17/S.18)

| Screen | Endpoints |
|---|---|
| S.9 Create Post | `POST /posts` ❓/🆕 |
| S.27 Post Detail | `GET/PATCH/DELETE /posts/{id}` ❓/🆕 · `POST/DELETE /posts/{id}/like` ❓/🆕 · `GET/POST /posts/{id}/comments` ❓/🆕 |
| Feed (S.1 tabs) | `GET /feed` ❓/🆕 |
| S.19 Connections | `POST/DELETE /follow/{type}/{id}` 🆕 · `GET /me/followers|following` 🆕 · `POST /connections` 🆕 · `GET /me/connections` 🆕 · `PATCH/DELETE /connections/{id}` 🆕 |
| S.12 Network (P1) | `GET /me/suggestions` 🅿️ |
| S.17/S.18 Chat | `GET /conversations` ❓/🆕 · `GET /conversations/{id}` ❓/🆕 · `POST /conversations/{id}/messages` ❓/🆕 · `PATCH /conversations/{id}/read` 🆕 |
| S.23 Blocks/Report | `POST/GET/DELETE /blocks` 🆕 · `POST /reports` 🔁 (morphs + user/post) · `GET /me/reports` 🆕 |

### Scouting (SC.2–SC.13)

| Screen | Endpoints |
|---|---|
| SC.2 Dashboard | `GET /me/home` 🆕 (fold-in) |
| SC.4 Discover Talents | `GET /athletes` 🔁 · `GET /search` 🔁 |
| SC.5/SC.6 Shortlist | `GET/POST/DELETE /me/shortlist` 🔁 (status/tags/notes) |
| SC.10 Observation | `POST/GET /observations` 🆕 |
| SC.13 Contact | `POST /athletes/{id}/contact` 🆕 (guardian routing U-18) |
| SC.7/SC.8/SC.9 Reports | `POST/GET /scout-reports` 🅿️ · `GET /scout/compare?ids=` 🅿️ |

### Notifications, settings, admin, meta

| Screen | Endpoints |
|---|---|
| S.16 Notifications | `GET /me/notifications?tab=` 🔁 · `PATCH …/read` · `POST …/read-all` ✅ · `POST /me/device-tokens` ✅ |
| S.22–S.25 Settings/Help | `GET/PUT /me/settings` 🔁 · `GET /meta/faqs` 🆕 · `POST /support/contact` 🆕 |
| AD.1/AD.2 Admin | `POST /admin/login` · `/admin/verify-2fa` ✅ · `GET /admin/dashboard` ✅ |
| AD.3 Users | `GET /admin/users` 🆕 · `GET/POST /admin/users/{id}` · `…/suspend|ban` 🆕 |
| AD.4 Verification | `GET/POST /admin/verification` · `…/{id}/approve|reject` 🆕 |
| AD.5/AD.6 Content | `GET/POST /admin/content/{type}` 🔁 (+opportunities/programs/facilities/posts) |
| AD.7/AD.8 Moderation | `/admin/moderation/**` 🔁 (+user/post targets, suspend) |
| AD.9 Master data | `GET/POST /admin/categories/**` ✅/🆕 (+positions) |
| AD.10 Expiry | `/admin/expiry*` 🔁 (+opportunity type) |
| AD.11 Leaderboard config (P1) | `GET/PUT /admin/leaderboard-config` · `POST /admin/leaderboard/reset-season` 🅿️ |
| AD.12 Broadcast (P1) | `POST/GET /admin/broadcasts` 🅿️ |
| Master data | `GET /meta/sports|cities|age-groups|positions|facilities|trending-searches` |
| Analytics | `POST /analytics/events` 🆕 |

---

## [SUPERSEDED] old wiring (pre-v3, incl. Sponsor)

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
| SC1 | **[SUPERSEDED]** Scout Onboarding (new) | `scout_onboarding_screen.dart` | `POST /api/v1/onboarding/scout` |
| ~~SP1~~ | ~~Sponsor Onboarding~~ | — | **[REMOVED — see Backend-Feature-Delta.md §4]** |

**Onboarding API Controller:** `OnboardingController`
- `POST /onboarding/athlete` → athlete()
- `POST /onboarding/coach` → coach()
- `POST /onboarding/academy` → academy()
- `POST /onboarding/organizer` → organizer()
- `POST /onboarding/scout` → scout() 🆕
- ~~`POST /onboarding/sponsor`~~ → **[REMOVED]**

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

> **[SUPERSEDED — see Backend-Feature-Delta.md §4].** The sponsor role and all `sponsor_*` endpoints are **REMOVED**; sponsorship is now an Opportunity type (`/opportunities/**`, see §v3). Table retained for history.

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

> **[SUPERSEDED]** old summary (~90 screens, incl. Sponsor). New roll-up below.

| Category | Screens | API Endpoints Used |
|----------|---------|-------------------|
| Auth / OTP / Guardian | 10 | 8 |
| Onboarding | 6 | 5 |
| Directory/Discovery | 14 | 12 |
| Search | 3 | 1 |
| Profile | 6 | 4 |
| Saved/Reports | 4 | 4 |
| Enquiries | 5 | 5 |
| Trial Registration | 7 | 11 |
| Tournament Registration | 10 | 15 |
| Sponsorship | 11 | 18 — **[REMOVED → opportunities]** |
| Notifications | 4 | 4 |
| Settings | 4 | 4 |
| Activity Hub | 5 | 5 |
| Admin | 13 | 10+ |
| **Total (old)** | **~90** | **~100** |

**New design (v3) roll-up** (`Backend-Feature-Delta.md` §11 end): P0 **~70 new endpoints / ~25 changed / ~10 verify-first**; P1 **~30 new**; sponsor routes (~12) removed. Screens: **129** (`SCREEN_INVENTORY.md`), across 6 roles.
