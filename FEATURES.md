# SportX — Role-wise Feature Documentation (Screens + Backend)

> Last updated: Sep 2026. Built from a full audit of `sportx_app/lib/core/router.dart` (all Flutter routes), `sportx-api/routes/api.php` (all API endpoints), `sportx-api/database/migrations` (all tables), and the feature modules under `sportx_app/lib/features/`.
> Purpose: a single reference so any developer (Flutter, backend, QA, PM, or new team member) can understand **every feature, who uses it, which screen implements it, and which backend endpoint powers it**.
> Companion doc: `USERFLOW.md` (journey-level flows and diagrams). This doc goes feature-by-feature instead.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Roles & Access Model](#2-roles--access-model)
3. [Global Features (all roles)](#3-global-features-all-roles)
   - 3.1 Authentication · 3.2 Role Onboarding · 3.3 Notifications & Push · 3.4 Chat · 3.5 Peer Connections · 3.6 Saved Items · 3.7 Reporting · 3.8 Search · 3.9 Settings & Account · 3.10 Social Links · 3.11 Activity Feed · 3.12 Media Service · 3.13 Social Posts · 3.14 Master Data
4. [Role 1 — Athlete / Parent](#4-role-1--athlete--parent)
5. [Role 2 — Coach](#5-role-2--coach)
6. [Role 3 — Academy](#6-role-3--academy)
7. [Role 4 — Organizer (incl. Federations)](#7-role-4--organizer-incl-federations)
8. [Role 5 — Sponsor / Brand](#8-role-5--sponsor--brand)
9. [Role 6 — Talent Scout](#9-role-6--talent-scout)
10. [Role 7 — Admin](#10-role-7--admin)
11. [The Universal Approval Pattern](#11-the-universal-approval-pattern)
12. [Status Cheat-Sheet](#12-status-cheat-sheet)
13. [Database Table Reference (by domain)](#13-database-table-reference-by-domain)
14. [Known Gaps & Quirks](#14-known-gaps--quirks)

---

## 1. System Overview

SportX is a **sports ecosystem marketplace** connecting athletes with coaches, academies, tournament organizers, sponsors, and talent scouts in India.

**Architecture:**

| Layer | Tech | Location |
|---|---|---|
| Mobile app | Flutter (Riverpod state, GoRouter navigation, feature-first structure) | `sportx_app/` |
| Backend API | Laravel (Sanctum token auth, role middleware, throttle) | `sportx-api/` |
| Database | MySQL/SQL — 59 tables (see §13) | `sportx-api/database/migrations` |
| Admin panel | Mobile screens in web-style layout + Laravel controllers behind 2FA | `sportx_app/lib/features/admin/` |

**Core product principle:** There is **no payment gateway**. Every fee is display-only. Every participation action (trial registration, tournament entry, coaching enrollment, sponsorship application, scout connection) follows **Request → Provider reviews → Approve / Reject (+ reason) → Notification**.

**Two backend "gates" exist for providers:** (1) account verification for Organizer/Sponsor at onboarding, and (2) per-listing admin approval for sponsorship postings before they become public.

---

## 2. Roles & Access Model

Roles are stored in `users.role`. The router (`router.dart`) enforces role-based redirects:

- Every role has a mandatory **onboarding** step after signup (`needs_onboarding` flag); the router blocks all other routes until it's done.
- **Only athletes** get the consumer bottom-nav shell (`MainShell`: Home · Discover · ➕ FAB · Network · Me).
- **Only talent scouts** get the scout shell (`ScoutShell`: Home · Discover · Shortlist · Connections · Profile).
- Coach / Academy / Organizer / Sponsor are **dashboard apps**: a landing dashboard plus push screens. If they tap an athlete shell route, the router bounces them to their dashboard.
- **Admin** is completely separate: `/admin/login` + 2FA, web-style layout, `role:admin` + `admin.2fa` middleware on every API.

| Role | Route value | Landing screen after login | Key persona goal |
|---|---|---|---|
| Athlete / Parent | `athlete` | `/home` (MainShell) | Find & enter trials, tournaments, coaching, sponsorships; network |
| Coach | `coach` | `/coach-dashboard` | Get enquiries, approve enrollments, post trials |
| Academy | `academy` | `/academy-dashboard` | Public listing, post trials, manage registrants |
| Organizer | `organizer` | `/organizer-dashboard` | Run tournaments: registrations, capacity, results |
| Sponsor / Brand | `sponsor` | `/sponsor-dashboard` | Post sponsorships, discover & shortlist athletes |
| Talent Scout | `talent_scout` | `/scout-dashboard` (ScoutShell) | Discover athletes, shortlist, connect |
| Admin | `admin` | `/admin/dashboard` | Verify, approve, moderate, broadcast (no self-signup) |

**Naming rules:** Parent is **not** a role (parents use an Athlete account; parental consent is a form checkbox for minors). Federation is **not** a role (it's an `org_type` under Organizer). "Providers" = Coach + Academy + Organizer + Sponsor collectively.

---

## 3. Global Features (all roles)

### 3.1 Authentication & Account Creation

**What it does:** Email/password signup per role, email OTP verification, login, password reset. Google OAuth signup skips OTP. Admin has a separate login with 2FA (see §10).

**Screens (Flutter):**

| Route | Screen | Purpose |
|---|---|---|
| `/splash` | `SplashScreen` | Restores session via `GET /auth/me`; decides splash → dashboard / onboarding / role-selection |
| `/role-selection` | `RoleSelectionScreen` | 6 role cards (athlete, coach, academy, organizer, sponsor, talent scout) |
| `/sign-up` | `SignUpScreen` | Email + password + pre-selected role (passed via route extra) |
| `/login` | `LoginScreen` | Email/password login + OTP login + Google OAuth |

**Backend (Laravel):**

| Endpoint | Controller | Auth | Notes |
|---|---|---|---|
| `POST /api/v1/auth/register` | `AuthController@register` | public, `throttle:10,1` | Creates user (`status=active` for athlete/coach/academy; `pending` for organizer/sponsor), sends OTP |
| `POST /api/v1/auth/verify-email` | `AuthController@verifyEmail` | public, throttled | Verifies 6-digit OTP from `otp_codes` |
| `POST /api/v1/auth/login` | `AuthController@login` | public, throttled | Returns Sanctum bearer token |
| `POST /api/v1/auth/forgot-password` | `AuthController@forgotPassword` | public, throttled | Sends reset OTP/link |
| `POST /api/v1/auth/reset-password` | `AuthController@resetPassword` | public, throttled | |
| `POST /api/v1/auth/logout` | `AuthController@logout` | `auth:sanctum` | Revokes token |
| `GET /api/v1/auth/me` | `AuthController@me` | `auth:sanctum` | Used by splash; returns role + `needs_onboarding` |

**Data:** `users`, `otp_codes`, `personal_access_tokens`.

**Account statuses:** `pending` (provider awaiting admin verification) → `active` → `suspended` / soft-`deleted`. Phone is stored **unverified** (deferred feature).

---

### 3.2 Role Onboarding

**What it does:** One-time profile setup per role; the router **forces** each user through it before anything else is reachable.

**Screens:**

| Route | Screen | Collected |
|---|---|---|
| `/onboarding-1`, `/onboarding-2` | `OnboardingSportAgeScreen`, `OnboardingSkillLocationScreen` | Athlete: sports + age group → skill level + city |
| `/coach-onboarding` | `CoachOnboardingScreen` | Sport, experience, certifications, fees, location |
| `/academy-onboarding` | `AcademyOnboardingScreen` | Academy name, sports, city, facilities, fees, photos |
| `/organizer-onboarding` | `OrganizerOnboardingScreen` | Org name, type (federation/club), **verification docs** |
| `/sponsor-onboarding` | `SponsorOnboardingScreen` | Brand, category, **verification docs** |
| `/scout-onboarding` | `TalentScoutOnboardingScreen` | Org/affiliation, sports multi-select, experience, city, bio |

**Backend:**

| Endpoint | Controller | Auth |
|---|---|---|
| `POST /api/v1/onboarding/athlete` | `OnboardingController@athlete` | `auth:sanctum` |
| `POST /api/v1/onboarding/coach` | `OnboardingController@coach` | `auth:sanctum` |
| `POST /api/v1/onboarding/academy` | `OnboardingController@academy` | `auth:sanctum` |
| `POST /api/v1/onboarding/organizer` | `OnboardingController@organizer` | `auth:sanctum` |
| `POST /api/v1/onboarding/sponsor` | `OnboardingController@sponsor` | `auth:sanctum` |
| `POST /api/v1/onboarding/talent-scout` | `OnboardingController@talentScout` | `auth:sanctum` |
| `GET /api/v1/onboarding/{role}` | `OnboardingController@schema` | `auth:sanctum` — returns the field schema per role |

**Data:** role profile tables — `athlete_profiles`, `coach_profiles`, `academies`, `organizer_profiles`, `sponsor_profiles`, `talent_scout_profiles`; pivots `athlete_sports`, `academy_sports`.

**Rule:** Organizer & Sponsor accounts are created `status=pending` + `listing_status=draft`; they stay locked out of listing until Admin approves in `/admin/approvals` (§10.2).

---

### 3.3 Notifications & Push

**What it does:** In-app notification center + device push tokens. All approval/rejection/expiry/enquiry/connection events create notifications.

**Screens:** `/notifications` → `NotificationsScreen` (list, unread badge, mark read, mark all read, delete; rows deep-link via `action_url`).

**Backend:**

| Endpoint | Controller | Notes |
|---|---|---|
| `GET /me/notifications` | `NotificationController@index` | Paginated, unread count |
| `PATCH /me/notifications/{id}/read` | `markRead` | |
| `POST /me/notifications/read-all` | `markAllRead` | |
| `DELETE /me/notifications/{id}` | `destroy` | |
| `POST /me/device-tokens` / `DELETE /me/device-tokens` | `registerDeviceToken` / `unregisterDeviceToken` | FCM token registration on app start |
| `POST /me/notifications/{id}/send-push` | `sendPushNotification` | Pushes a stored notification to the device |

**Data:** `notifications` (with `action_url` for deep links), `user_device_tokens`, legacy `device_tokens`.

---

### 3.4 Chat (Conversations)

**What it does:** 1-to-1 messaging. Conversations are created by enquiry replies and accepted connections.

**Screens:** `/chat-list` → `ChatListScreen` (threads with last message + unread count); `/chat-screen` → `ChatScreen` (thread view; receives `id`, `name`, `avatar` via route extra).

**Backend:**

| Endpoint | Controller |
|---|---|
| `GET /me/conversations` | `ConversationController@index` |
| `POST /me/conversations` | `store` (create/find 1-to-1 thread) |
| `GET /conversations/{id}` | `show` (messages + participants) |
| `POST /conversations/{id}/messages` | `sendMessage` |
| `PUT /conversations/{id}/read` | `markRead` |

All guarded by `auth:sanctum`. **Data:** `conversations`, `conversation_participants`, `messages`.

---

### 3.5 Peer Connections (athlete ↔ athlete)

**What it does:** Athletes connect with each other; accepted connections surface suggested users and let peers message. (Scout connections are a separate system — see §9.)

**Screens:** `/network` → `NetworkScreen` (suggested athletes with Connect / Requested / Message states); `/my-connections` → `MyConnectionsScreen` (search, message, view profile, long-press remove); `/connection-requests` → `ConnectionRequestsScreen` (incoming accept/reject).

**Backend (`ConnectionController`, `auth:sanctum`):** `GET /me/connections`, `POST /me/connections/request`, `POST /me/connections/{id}/accept`, `DELETE /me/connections/{id}`, `GET /me/connections/requests`, `GET /me/connections/status/{userId}`, `GET /me/connections/count`.

**Data:** `connections` (requester, addressee, status: pending/accepted).

---

### 3.6 Saved Items (Bookmarks)

**What it does:** Bookmark any directory entity (academy, coach, trial, tournament, scholarship, sponsorship, venue) from its detail page.

**Screens:** `/saved` → `SavedScreen` (grouped list of saved entities, tap → detail, unsave).

**Backend:** `GET /me/saved`, `POST /me/saved` (subject type + id), `DELETE /me/saved` — `SavedItemController`, `auth:sanctum`. **Data:** `saved_items` (polymorphic `saveable`).

---

### 3.7 Report Content

**What it does:** Any user can report any listing or post; reports land in the Admin moderation queue (§10.3).

**Screens:** `/report` → `ReportScreen` (reason picker + note; receives `type`, `id`, `title` via extra).

**Backend:** `POST /reports` — `ReportController@store`, `auth:sanctum`. **Data:** `listing_reports`.

---

### 3.8 Universal Search

**What it does:** One search box across all entity types + filter sheet; recent + trending searches.

**Screens:** `/universal-search` → `UniversalSearchScreen` (typeahead, grouped results, recent searches); `/search-filter` → `SearchFilterScreen` (sport, city, age group, price, date filters).

**Backend:** `GET /search` (q + filters) and `GET /me/recent-searches` — `SearchController`, recent-searches requires `auth:sanctum`. **Data:** `recent_searches`. Master data for filters: `GET /meta/sports|cities|age-groups` and `GET /meta/trending-searches` (public).

---

### 3.9 Settings & Account Management

**Screens:** `/settings` → `SettingsScreen` (notification prefs, change password, logout, delete account); `/help-support` → `HelpSupportScreen`.

**Backend (`SettingsController`, `auth:sanctum`):** `GET /me/settings`, `PUT /me/settings`, `PUT /me/settings/password`, `DELETE /me/account` (soft delete). **Data:** `users.settings` JSON column.

---

### 3.10 Social Links

**Screens:** `/social-links` → `SocialLinksScreen` (Instagram, YouTube, X, etc.).

**Backend:** `GET /me/social-links`, `PUT /me/social-links` — `SocialLinksController`, `auth:sanctum`, all roles. **Data:** `users.social_links` JSON.

---

### 3.11 Activity Feed

**Screens:** `/activity-hub` → `ActivityHubScreen` (chronological "your registration was approved/rejected…" feed; in an athlete's bottom nav under Network). **Note:** rows are currently read-only — no drill-down.

**Backend:** `GET /me/activity` — `ActivityController@index`, `auth:sanctum`. Derived from registration/enrollment/application events.

---

### 3.12 Media Service (shared backend)

**What it does:** Central upload/attach pipeline for profile photos, academy galleries, achievement media, tournament brackets, registration documents.

**Backend (`MediaController`):**

| Endpoint | Auth | Notes |
|---|---|---|
| `POST /media/upload` | `auth:sanctum` | Returns `media_item` id + URL |
| `DELETE /media/{id}` | `auth:sanctum` | Owner-only |
| `PUT /media/reorder` | `auth:sanctum` | Sort order for galleries |
| `GET /media/download/{id}` | public (named route) | |
| `GET /media/{id}/signed-url` | `auth:sanctum` | Temporary signed URL — used for registration docs (privacy) |

**Data:** `media_items` (attachable to any entity).

---

### 3.13 Social Posts (community feed)

**What it does:** Athlete-style community posts with likes and comments. Reached via the **➕ FAB create sheet** (`create_sheet.dart`): Create Post · Create Opportunity · Add Achievement · Add Event · Upload Photo/Video.

**Screens:** `/create-post` → `CreatePostScreen`; `/post-detail/:id` → `PostDetailScreen` (like, comment). Feed is surfaced from `GET /posts`.

**Backend (`PostController`, `auth:sanctum`):** `GET /posts`, `POST /posts`, `GET /posts/{id}`, `POST /posts/{id}/like` (toggle), `POST /posts/{id}/comments`.

**Data:** `posts`, `post_likes`, `post_comments`.

⚠️ **Gap:** the create sheet is not role-gated — every role sees the same athlete-flavored options.

---

### 3.14 Master Data (Meta)

**Backend (public):** `GET /meta/sports`, `/meta/cities`, `/meta/age-groups`, `/meta/trending-searches` — `MetaController`. Used by every filter, form, and search screen. Admin can manage the underlying masters (§10.6). **Data:** `sports`, `cities`, `age_groups`.

---

## 4. Role 1 — Athlete / Parent

**Shell:** MainShell bottom nav — `Home` · `Discover` · ➕ FAB · `Network` · `Me`.
**After onboarding lands on:** `/home`.

### 4.1 Home & Discovery

| Screen (route) | What the athlete does |
|---|---|
| `/home` `HomeScreen` | Quick tiles → Trials / Tournaments / Scholarships / Sponsorships; recommended academies & coaches; latest opportunities |
| `/discover` `DiscoverScreen` | Tabs **Athletes / Coaches / Sponsors** + sport & state filter chips |
| `/opportunities` `OpportunitiesScreen` | Opportunity feed with tabs All / Trials / Tournaments / Scholarships / Sponsorships |
| `/universal-search`, `/search-filter` | See §3.8 |

**Backend:** directory reads are **public** — `GET /academies`, `/coaches`, `/trials`, `/tournaments`, `/scholarships`, `/sponsorships`, `/sports-venues` (all with `/{id}` detail variants) from `DirectoryController` / `TrialController` / `TournamentController` / `ScholarshipController` / `SponsorshipController` / `SportsVenueController`. Athlete discovery needs login: `GET /athletes` (allowed roles: sponsor, talent_scout, athlete) and `GET /athletes/{id}`.

**Known quirks:** Home cards currently show mock dates/prizes; the Home "Follow" button only navigates; Discover's age-group filter is cosmetic.

### 4.2 Directory Detail Pages

| Route | Screen | Actions available |
|---|---|---|
| `/academy-detail/:id` | `AcademyDetailScreen` | Save, Report, Enquire |
| `/coach-detail/:id` (also `/coach-profile-detail/:id`, `/view-profile`) | `CoachDetailScreen` / `CoachProfileDetailScreen` | Save, Report, Enquire, **Enroll** |
| `/trial-detail/:id` | `TrialDetailScreen` | Save, Report, Enquire, **Register** |
| `/tournament-detail/:id` | `TournamentDetailScreen` | Save, Report, Enquire, **Register** |
| `/scholarship-detail/:id` | `ScholarshipDetailScreen` | Save, Report |
| `/sponsorship-detail/:id` | `SponsorshipDetailScreen` | Save, Report, **Apply** |
| `/sports-venue-detail/:id` | `SportsVenueDetailScreen` | Save, Report |
| `/tournaments` + `/tournament-calendar` | Directory + calendar views | Browse by date |
| `/sponsors`, `/scholarships`, `/sports-venues`, `/coaches`, `/academies`, `/trials` | Directory list screens | Filter + tap → detail |

Public listings are readable without auth; **acting requires login**.

### 4.3 Trial Registration (approval-based)

**Flow:** Trial detail → **Register** → `/trial-registration/:id` `TrialRegistrationScreen` (sport, age group, experience, **document upload**, parental-consent checkbox for minors) → submit → status **Pending Approval** → `/registration-confirmation` `RegistrationConfirmationScreen` (ref number, **Add to Calendar** = ICS download, **Remind me** toggle) → provider approves/rejects (+reason) → push notification → visible in My Activity and `/my-registrations`.

**Backend:**

| Endpoint | Guard |
|---|---|
| `POST /trials/{trial}/register` | `auth:sanctum, role:athlete` |
| `GET /me/registrations/trials` (my list), `GET /registrations/trials/{registration}` | `auth:sanctum` |
| `POST /registrations/trials/{registration}/reminder` | toggle reminder |
| `GET /registrations/trials/{registration}/ics` | calendar file download |

**Data:** `trial_registrations` (+ athlete-detail columns), `trial_registration_documents`, `reminder_subscriptions`, `registration_activity_logs`. Provider actions (verify/approve/reject) in §5/§6; admin overrides in §10.

### 4.4 Tournament Registration (capacity + waitlist)

**Flow:** Tournament detail → **Register** → `/tournament-registration/:id` `TournamentRegistrationScreen` (pick category: Individual/Team) → submit → **capacity logic**: spots free → `confirmed` after approval; full + waitlist on → `waitlisted`; full + no waitlist → error. Track in `/my-registrations`.

**Backend:** `POST /tournaments/{tournament}/register` (`role:athlete`), `GET /me/registrations/tournaments`, `GET /registrations/tournaments/{registration}/ics`. Capacity endpoints (§7.4). Organizer can manually flip `payment_status` (`PATCH /registrations/tournaments/{registration}/payment`) — no gateway.

**Data:** `tournament_registrations`, `tournament_categories`, `registration_activity_logs`.

### 4.5 Coaching Enrollment

**Flow:** Coach detail → **Enroll** → `/coach-enrollments` entry (`CoachEnrollmentScreen`) → pick plan (session / monthly / quarterly) + notes → `pending` → coach approves with start/end dates → **Active** → appears in `/my-coaching-enrollments` `MyCoachingEnrollmentsScreen`.

**Backend:** `POST /coaches/{coach}/enroll` (`role:athlete`), `GET /me/coaching-enrollments`. Coach-side queue §5.3. **Data:** `coaching_enrollments` (plan, status, start/end dates, response).

### 4.6 Sponsorship Application

**Flow:** Sponsorship detail → **Apply** → `/apply-sponsor/:id` `ApplySponsorScreen` (pitch note; profile auto-attached; document dropzone is **UI-only** today) or `/sponsor-pitch/:id` `SponsorPitchScreen` → `POST /sponsorships/{id}/apply` → success pops back past the detail screen. Track via `/my-applications` `MyApplicationsScreen` and `/application-status` `ApplicationStatusScreen` — a 5-step tracker: **Applied → Under Review → Shortlisted → Final Selection → Result**.

**Backend:** `POST /sponsorships/{sponsorship}/apply` (`role:athlete`), `GET /me/applications`. Sponsor-side §8.4. **Data:** `sponsorship_applications`.

**Gap:** the status timeline screen is driven by route params, not a live fetch; the Registrations/Enquiries tabs in My Applications are static link menus.

### 4.7 Enquiries (ask a question)

**Flow:** Any coach/academy detail → **Enquire** → `/enquire/:subjectType/:subjectId/:title` `EnquireScreen` (message + preferred datetime) → provider's inbox → reply → athlete notified → continue in Chat.

**Backend:** `POST /enquiries` (`role:athlete`), `GET /me/enquiries` (inbox — provider side uses the same endpoint), `GET /enquiries/{id}`, `POST /enquiries/{id}/messages` (reply thread), `PUT /enquiries/{id}/read`. **Data:** `enquiries`, `enquiry_messages`.

### 4.8 Networking (athletes + scouts)

**Screens & flows:**

| Route | Purpose |
|---|---|
| `/network` | Suggested athletes; connect requests; entry to scout discovery |
| `/athlete-directory` | Browse athletes |
| `/scout-directory` | "Find Talent Scouts & Chat" — scout list |
| `/scout-requests` | Incoming scout connection requests → accept/reject |
| `/my-connections`, `/connection-requests` | Peer connection management (§3.5) |

**Backend:** scout directory `GET /scouts` (`role:athlete`); athlete-initiated scout connect `POST /scouts/{scout}/connect`; incoming requests `GET /me/scout-connection-requests`, accept/reject `POST /me/scout-connection-requests/{connection}/accept|reject`. The full scout system is described in §9. **Data:** `scout_connections` (with `requested_by`), `connections`.

### 4.9 Athlete Profile ("Me" tab)

| Route | Purpose |
|---|---|
| `/profile` | Profile hub: photo, sports, stats, achievements preview, gallery, settings links |
| `/edit-profile` | Edit personal + sport details |
| `/add-achievement` | Add achievement (title, level, date, media) |
| `/media-gallery` | Upload/reorder/delete gallery media |
| `/view-profile` | Generic profile viewer (type + id via extra) |

**Backend:** `GET/PUT /me/profile`, `PUT /me/profile/sports` — `ProfileController`; achievements stored via `achievements` table; media via §3.12.

---

## 5. Role 2 — Coach

**Shell:** none — dashboard + push screens. **Lands on:** `/coach-dashboard` after `/coach-onboarding`.

### 5.1 Coach Dashboard & Listing Management

| Route | Purpose |
|---|---|
| `/coach-dashboard` `CoachDashboardScreen` | Listing status, enquiry stats, recent enquiries, quick links |
| `/coach-profile-edit` `CoachProfileEditScreen` | View/manage the public listing |
| `/edit-coach-profile` `CoachProfilePostingScreen` | Edit core listing fields (create-if-missing) |
| `/add-credential` | Certifications/credentials |
| `/edit-facilities` | Facilities offered |
| `/showcase-athletes` | Athletes trained (showcase) |
| `/coach-profile-detail/:id` | Preview of the public profile |

**Backend:** `GET/PUT /me/coach-profile` — `CoachProfileController`, guard `auth:sanctum, role:coach`. **Data:** `coach_profiles` (+ achievements columns), `media_items`.

### 5.2 Enquiry Inbox

`/coach-enquiry-inbox` (tabs All / New / Replied) → `/coach-enquiry-detail` → reply (athlete notified; thread marks read). Backend: `GET /me/enquiries`, `POST /enquiries/{id}/messages`, `PUT /enquiries/{id}/read` (§4.7 — same API, coach is the receiver).

### 5.3 Enrollment Queue (approve/reject)

**Screen:** `/coach-enrollments` `CoachEnrollmentScreen` — incoming requests with plan + notes; **Approve** sets start/end dates + response; **Reject** records a reason shown to the athlete.

**Backend:** `GET /coach/enrollments` (`role:coach`), `PATCH /coaching-enrollments/{enrollment}/approve`, `PATCH /coaching-enrollments/{enrollment}/reject`. Admin can override (§10.7). **Data:** `coaching_enrollments`.

### 5.4 Post & Manage Trials

**Flow:** `/post-trial` `TrialPostingScreen` (name, sport, dates, venue, eligibility, fee, required docs → publish or save draft) → `/my-trials` `MyTrialsManagementScreen` (publish / close / edit) → `/registrant-list` per trial (document-status badges) → `/registrant-detail` (athlete snapshot + documents via signed URLs) → **Mark Verified / Reject** → athlete's My Activity updates + push.

**Backend (`ProviderTrialController`, `auth:sanctum`):** `GET /me/trials`, `POST /me/trials`, `PUT /me/trials/{trial}`, `POST /me/trials/{trial}/publish`, `POST /me/trials/{trial}/close`. Registration review: `GET /trials/{trial}/registrations`, `GET /trials/{trial}/pending-requests`, `POST /registrations/trials/{registration}/verify`, `PATCH …/approve`, `PATCH …/reject`. **Data:** `trials`, `trial_registrations`, `trial_registration_documents`.

### 5.5 Browse Sponsorships

**Screen:** `/sponsor-directory-coach` `SponsorDirectoryCoachScreen` — coaches can browse the sponsor directory (same public `/sponsorships` data).

---

## 6. Role 3 — Academy

**Lands on:** `/academy-dashboard` after `/academy-onboarding`. Shares the trial pipeline with Coach (same `/my-trials` + registrant screens + endpoints).

### 6.1 Academy Dashboard & Public Listing

| Route | Purpose |
|---|---|
| `/academy-dashboard` `AcademyDashboardScreen` | Listing status, trial stats, enquiry count |
| `/academy-profile` `AcademyProfileScreen` | Own public listing preview |
| `/edit-academy-profile` `AcademyProfilePostingScreen` | Edit name, sports, city, facilities, fees, photos |

**Backend:** `GET/PUT /me/academy` — `AcademyController`, guard `role:academy`. **Data:** `academies`, `academy_sports`, `academy_coaches`, `media_items`.

### 6.2 Post & Manage Trials

Same as Coach §5.4 — screens `/post-trial`, `/my-trials`, `/registrant-list`, `/registrant-detail`; endpoints under `/me/trials` and `/registrations/trials/*`. The `ProviderTrialController` accepts both coach and academy owners.

### 6.3 Enquiry Inbox

`/enquiry-inbox` (tabs All / New / Replied) → `/enquiry-detail` → reply. Same enquiry API as §5.2.

---

## 7. Role 4 — Organizer (incl. Federations)

**Lands on:** `/organizer-dashboard` after `/organizer-onboarding`. **Gate:** account starts `pending` — Admin must verify uploaded docs (§10.2) before the dashboard is useful.

### 7.1 Dashboard, Profile & Analytics

| Route | Purpose |
|---|---|
| `/organizer-dashboard` `OrganizerDashboardScreen` | Tournament list snapshot, registration stats |
| `/organizer-analytics` `OrganizerAnalyticsScreen` | Registration analytics per tournament |
| `/organizer-profile` `OrganizerProfileScreen` | Public org profile |

**Backend:** `GET/PUT /me/organizer` — `OrganizerProfileController` (`role:organizer`); `GET /me/organizer/analytics` — `OrganizerAnalyticsController` (`role:organizer,admin`). **Data:** `organizer_profiles`, `tournaments`, `tournament_registrations`.

### 7.2 Post & Manage Tournaments

**Flow:** `/post-tournament` `TournamentPostingScreen` (format, dates, venue, fees, prize, **categories with per-category capacity + waitlist toggle**) → publish or draft → `/my-tournaments` `MyTournamentsManagementScreen` → `/edit-tournament/:id` `TournamentEditScreen`.

**Backend (`ProviderTournamentController`, `auth:sanctum`):** `GET/POST /me/tournaments`, `PUT /me/tournaments/{tournament}`, `PUT /me/tournaments/{tournament}/categories`, `POST /me/tournaments/{tournament}/publish`, `POST /me/tournaments/{tournament}/close`. **Data:** `tournaments`, `tournament_categories`.

### 7.3 Registration Management (approve/reject)

**Screen:** `/registration-management` per tournament — pending list with athlete details; **Approve** (→ `confirmed`, or `waitlisted` if capacity full) / **Reject** with reason (→ `cancelled` + reason visible to athlete).

**Backend:** `GET /tournaments/{tournament}/registrations`, `GET /tournaments/{tournament}/pending-requests`, `PATCH /registrations/tournaments/{registration}/approve`, `PATCH /registrations/tournaments/{registration}/reject`. **Data:** `tournament_registrations`, `registration_activity_logs`.

### 7.4 Capacity & Payment Management

**Screen:** `/capacity-management` — view + adjust per-category capacity; waitlist auto-promotes on capacity increase. Organizer manually flips `payment_status` per registration (fees are display-only; no gateway).

**Backend:** `GET /tournaments/{tournament}/capacity`, `PUT /tournaments/{tournament}/capacity`, `PATCH /registrations/tournaments/{registration}/payment`. **Data:** `tournament_categories`, `tournament_registrations`.

### 7.5 Results Publishing

**Flow:** `/results-publishing` (winners / runner-up / 3rd place + bracket image upload) → publish → public at `/results-view`; unpublish hides again. Publishing notifies participants.

**Backend (`ResultsController`):** `GET /tournaments/{tournament}/results` (**public**), `POST …/results`, `POST …/results/{result}/publish`, `POST …/results/{result}/unpublish`. **Data:** `tournament_results`, `media_items`.

Athlete-visible calendar of tournaments lives at `/tournament-calendar` (public directory read).

---

## 8. Role 5 — Sponsor / Brand

**Lands on:** `/sponsor-dashboard` after `/sponsor-onboarding`. **Two gates:** (1) account `pending` until Admin verifies docs; (2) each sponsorship listing passes the Admin opportunity queue (§10.5) before it is publicly visible.

### 8.1 Sponsor Dashboard & Listing Management

| Route | Purpose |
|---|---|
| `/sponsor-dashboard` `SponsorDashboardScreen` | Active sponsorships, application stats, shortlist count |
| `/sponsor-posting` `SponsorshipPostingScreen` | Create sponsorship (title, category, value, eligibility, description) |
| `/my-sponsorships` `MySponsorshipsManagementScreen` | Publish / close / edit own listings |

**Backend (`SponsorEngagementController`, `role:sponsor`):** `GET /me/sponsorships`, `POST /me/sponsorships`, `PUT /me/sponsorships/{sponsorship}`, `POST /me/sponsorships/{sponsorship}/publish` (blocked until admin approval), `POST /me/sponsorships/{sponsorship}/close`. **Data:** `sponsorships`, `sponsor_profiles`.

### 8.2 Athlete Discovery & Shortlist

**Screens:** `/athlete-discovery` `AthleteDiscoveryScreen` (filters: sport, age, city, achievements) → `/athlete-profile-view` `AthleteProfileViewScreen` (full profile: sports history timeline, achievements, media gallery) → **Shortlist ♥ + private note**.

**Backend:** `GET /athletes`, `GET /athletes/{id}` — `AthleteDiscoveryController` (`role:sponsor,talent_scout,athlete`). Shortlist: `GET /me/shortlist`, `POST /me/shortlist`, `DELETE /me/shortlist/{entry}` (`role:sponsor`). **Data:** `athlete_profiles`, `athlete_sports`, `achievements`, `media_items`, `shortlist_entries` (note the separate scout shortlist table in §9).

### 8.3 Applications Inbox (review & respond)

**Screens:** `/applications-inbox` per sponsorship → `/application-detail` (athlete profile + pitch) → **Shortlist** / **Reject** / **Reply** (opens an enquiry thread with the athlete).

**Backend:** `GET /sponsorships/{sponsorship}/applications`, `PATCH /sponsorships/{sponsorship}/applications/{application}` (status transitions incl. shortlist/reject), reply via enquiry API §4.7. **Data:** `sponsorship_applications`, `enquiries`, `enquiry_messages`.

### 8.4 Grouped Shortlist

**Screen:** `/shortlist` `ShortlistScreen` — grouped list with per-athlete notes (backed by `/me/shortlist` endpoints above).

---

## 9. Role 6 — Talent Scout

**Shell:** ScoutShell bottom nav — `Home · Discover · Shortlist · Connections · Profile`. **Lands on:** `/scout-dashboard` after `/scout-onboarding`.

### 9.1 Scout Dashboard & Profile

| Route | Purpose |
|---|---|
| `/scout-dashboard` `TalentScoutDashboardScreen` | Search shortcut, saved count, connections sent, profile completeness |
| `/scout-profile` `TalentScoutProfileScreen` | Edit org/affiliation, sports, experience, city, bio |

**Backend:** `GET/PUT /me/scout-profile` — `TalentScoutController`, guard `auth:sanctum, role:talent_scout`. **Data:** `talent_scout_profiles`.

### 9.2 Athlete Discovery

**Screen:** `/scout-discovery` `TalentScoutAthleteDiscoveryScreen` — athlete grid + chips (sport / age / city / skill) + advanced filters → `/scout-athlete/:id` `TalentScoutAthleteProfileViewScreen` (info, sports-history timeline, achievements, media gallery).

**Backend:** `GET /athletes` (`role:sponsor,talent_scout,athlete`), `GET /athletes/{id}`. **Data:** `athlete_profiles`, `athlete_sports`, `achievements`, `media_items`.

### 9.3 Shortlist (private)

**Screen:** `/scout-shortlist` `TalentScoutShortlistScreen` — saved athletes + private notes (add / edit / remove).

**Backend (namespaced to avoid clash with sponsor shortlist):** `GET /me/scout-shortlist`, `POST /me/scout-shortlist/{athlete}`, `DELETE /me/scout-shortlist/{athlete}`, `PATCH /me/scout-shortlist/{athlete}`. **Data:** `scout_shortlists`.

### 9.4 Connections (two-way)

**Scout side:** `/scout-connect/:athleteId` `TalentScoutConnectionScreen` (message form → `POST /athletes/{athlete}/connect` — request sits `pending` until the athlete accepts/rejects). `/scout-connections` `TalentScoutConnectionsScreen` — outgoing + incoming (`GET /me/scout-connections`, `GET …/incoming`, accept/reject for requests initiated by athletes, withdraw `DELETE /me/scout-connections/{connection}`). Status check for a profile: `GET /scout-connection-status/{type}/{id}`.

**Athlete side:** `/scout-requests` (§4.8) — `GET /me/scout-connection-requests`, accept/reject. Accepted scouts appear in the athlete's connections; both sides get push notifications.

**Data:** `scout_connections` (status pending/accepted/rejected, `requested_by` distinguishes scout-initiated vs athlete-initiated).

---

## 10. Role 7 — Admin

**Separate flow:** `/admin/login` → **2FA verify** → `/admin/dashboard`. Web-style layout, no bottom nav. **Every** admin API is behind `auth:sanctum + role:admin + admin.2fa`. Admin has **no self-signup** — accounts are seeded/managed directly. Admin auth endpoints: `POST /admin/login`, `POST /admin/verify-2fa`, `POST /admin/logout`, `GET /admin/me` (`AdminAuthController`; 2FA state in `users` + `admin_profiles`).

### 10.1 Dashboard & Analytics

| Screen | Purpose | Backend |
|---|---|---|
| `/admin/dashboard` `AdminDashboardScreen` | Platform KPIs, pending counts, quick links | `GET /admin/dashboard` — `AdminDashboardController@index` |
| `/admin/analytics` `AdminAnalyticsScreen` | Approval analytics + registration funnel + audit trail | `GET /admin/registrations/analytics/dashboard`, `GET /admin/registrations/activity-log` — `RegistrationAnalyticsController` |

**Data:** aggregates over `users`, `trials`, `tournaments`, `sponsorships`, `registrations`; `audit_logs` for the trail.

### 10.2 User Management & Provider Approvals

| Screen | Purpose | Backend |
|---|---|---|
| `/admin/users` `ManageUsersScreen` | Browse/filter all users by role/status | `GET /admin/users`, `GET /admin/users/{id}` |
| `/admin/users/:id/verify` `UserDetailVerifyScreen` | Full profile + documents → verify/approve/reject | `POST /admin/users/{id}/approve`, `POST /admin/users/{id}/reject`, `POST /admin/users/{id}/suspend`, `DELETE /admin/users/{id}` |
| `/admin/approvals` `PendingApprovalsScreen` | Queue of pending Organizer/Sponsor accounts (they cannot list until approved) | Same endpoints; filtered to `status=pending` providers |

**Data:** `users`, role profile tables, `media_items` (verification docs), `audit_logs`.

### 10.3 Moderation & Platform Reports

| Screen | Purpose | Backend |
|---|---|---|
| `/admin/moderation` `ModerationQueueScreen` | Reports grouped by content type | `GET /admin/moderation/queue` |
| `/admin/reports` `PlatformReportsScreen` | All user-submitted reports | (same queue API) |
| `/admin/reports/:id` `ReportDetailScreen` | Evidence + content snapshot → **Dismiss** / **Remove content** (owner notified) / **Warn owner** | `GET /admin/moderation/reports/{id}`, `POST …/approve`, `POST …/remove`, `POST …/warn` |

**Data:** `listing_reports`, `posts`/listings, `notifications` (owner notices), `audit_logs`.

### 10.4 Broadcast Notifications

| Screen | Purpose | Backend |
|---|---|---|
| `/admin/notifications/compose` `ComposeNotificationScreen` | Title + body push | `POST /admin/notifications/broadcast` — `AdminUserController@broadcast` |
| `/admin/notifications/targeting` `NotificationTargetingScreen` | Audience targeting (role / city / sport) | same endpoint with target params |

**Data:** `notifications`, `user_device_tokens` (push fan-out).

### 10.5 Opportunity (Sponsorship) Approval Queue

**Screens:** `/admin/opportunities` `OppApprovalQueueScreen` (pending sponsorship listings) → `/admin/opportunities/:id` `OppReviewDetailScreen` → approve (goes public) / reject (sponsor notified).

**Backend:** `GET /admin/opportunities`, `POST /admin/opportunities/{id}/approve`, `POST /admin/opportunities/{id}/reject` — `AdminUserController`. **Data:** `sponsorships` (`listing_status` draft → pending → published / rejected).

### 10.6 Content & Master Data Management

| Screen | Purpose | Backend (`AdminContentController`, `AdminCategoryController`) |
|---|---|---|
| `/admin/settings` `AdminSettingsScreen` | Content picker + category masters (sports / cities / age groups) + expiry rules | `GET /admin/content`, `GET/POST/PUT/DELETE /admin/content/{type}[/{id}]`; `GET/POST/PUT/DELETE /admin/categories/sports|cities|age-groups`; `GET/PUT /admin/expiry-rules` |

### 10.7 Expiry Engine & Registration Overrides

- **Expiry monitor** (in admin settings/dashboard tabs): hourly scheduler expires old listings → admin can **Override** (keep live) or **Restore** (re-publish). Backend: `GET /admin/expiry/monitor`, `POST /admin/expiry/events/{id}/override`, `POST /admin/expiry/events/{id}/restore`. **Data:** `expiry_events`, `expiry_rules`.
- **Registration overrides:** Admin can force approve/reject any trial registration, tournament registration, or coaching enrollment — logged as `admin_override`. Backend: `PATCH /admin/registrations/tournaments/{registration}/admin-approve|admin-reject`, `PATCH /admin/registrations/trials/{registration}/admin-approve|admin-reject`, `PATCH /coaching-enrollments/{enrollment}/admin-approve|admin-reject`. **Data:** `registration_activity_logs`, `audit_logs`.

---

## 11. The Universal Approval Pattern

Every athlete→provider action follows: **Request (pending) → Provider reviews → Approve / Reject (+reason) → Push notification → status visible in My Activity**.

| Action | Athlete sends | Provider queue (screens) | Athlete tracks in |
|---|---|---|---|
| Trial registration | `POST /trials/{trial}/register` | `/my-trials` → `/registrant-list` → `/registrant-detail` | `/my-registrations`, `/activity-hub` |
| Tournament entry | `POST /tournaments/{tournament}/register` | `/registration-management` | `/my-registrations` + ICS |
| Coach enrollment | `POST /coaches/{coach}/enroll` | `/coach-enrollments` | `/my-coaching-enrollments` |
| Sponsorship application | `POST /sponsorships/{sponsorship}/apply` | `/applications-inbox` → `/application-detail` | `/my-applications` → `/application-status` |
| Scout connect (scout-initiated) | `POST /athletes/{athlete}/connect` | `/scout-connections` (athlete answers in `/scout-requests`) | `/scout-requests` / connection status |
| Enquiry | `POST /enquiries` | `/coach-enquiry-inbox` or `/enquiry-inbox` | Notifications → `/chat-screen` |

Admin can override any of the first four (§10.7); everything is written to activity/audit logs.

---

## 12. Status Cheat-Sheet

| Entity | Pending state | Success state(s) | Failure state(s) | Notes |
|---|---|---|---|---|
| Trial/tournament registration | `pending` / Pending Approval | `confirmed` / `waitlisted` | `rejected` + reason | ICS + reminder toggles after confirm |
| Coaching enrollment | `pending` | `active` (start/end dates) | `rejected` + reason | |
| Sponsorship application | `applied` | `shortlisted` → `final_selection` | `rejected` / `closed` | 5-step tracker timeline |
| Scout connection | `pending` | `accepted` | `rejected` | Both sides notified; `requested_by` marks initiator |
| Enquiry | new | replied | — | Thread read-marking |
| Listing (trial/tournament/sponsorship) | `draft` | `published` | `closed` / `expired` | Sponsorship additionally needs admin approval to publish |
| User account | `pending` (providers) | `active` | `suspended` / `deleted` | Admin-managed |

---

## 13. Database Table Reference (by domain)

| Domain | Tables |
|---|---|
| Identity & auth | `users`, `otp_codes`, `personal_access_tokens`, `sessions`, `admin_profiles`, `cache`/`jobs` (Laravel infra) |
| Role profiles | `athlete_profiles`, `coach_profiles`, `academies`, `academy_sports`, `academy_coaches`, `organizer_profiles`, `sponsor_profiles`, `talent_scout_profiles` |
| Sports & masters | `sports`, `cities`, `age_groups`, `athlete_sports` |
| Directory listings | `trials`, `tournaments`, `tournament_categories`, `tournament_results`, `scholarships`, `sponsorships`, `sports_venues` |
| Registration & approvals | `trial_registrations`, `trial_registration_documents`, `tournament_registrations`, `coaching_enrollments`, `registration_activity_logs`, `reminder_subscriptions` |
| Sponsorship pipeline | `sponsorship_applications`, `shortlist_entries` (sponsor), `scout_shortlists` (scout) |
| Scouting | `scout_connections` |
| Social | `posts`, `post_likes`, `post_comments`, `connections`, `achievements` |
| Messaging | `conversations`, `conversation_participants`, `messages`, `enquiries`, `enquiry_messages` |
| Notifications | `notifications`, `user_device_tokens`, `device_tokens` (legacy) |
| Platform ops | `saved_items`, `listing_reports`, `media_items`, `recent_searches`, `expiry_events`, `expiry_rules`, `audit_logs` |

---

## 14. Known Gaps & Quirks

(From the code audit — useful for any developer picking up work. Full context in `USERFLOW.md` §12.)

1. FAB create sheet is **not role-gated** (all roles see athlete options).
2. Application status timeline is **static** (route params, no live fetch).
3. Home screen has **mock data** (hardcoded dates/prizes; "Recommended Athletes" shows academies+coaches; Follow button only navigates).
4. Activity Hub rows are **read-only** (no drill-down).
5. My Applications Registrations/Enquiries tabs are static link menus, not live lists.
6. Discover's age-group filter is **cosmetic**.
7. Sponsorship apply document dropzone is **UI-only** (no file picker wired).
8. **No payment gateway** — fees display-only; organizer flips `payment_status` manually.
9. Phone numbers stored **unverified**; OTP-resend endpoint is a known backend gap.
10. Three different coach-detail routes exist (`/coach-detail/:id`, `/coach-profile-detail/:id`, `/view-profile`) — consolidation opportunity.
11. Admin has no mobile signup — seeded accounts + `/admin/login` + 2FA only.
