> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

# Development Checklist — SportX India

Trackable checklist organized by phase and module. Maps to Jira ticket IDs in `Jira-Tickets.md` and feature IDs in `Functional-Requirements.md`.

> **Last Updated:** 2026-09-04 (v3 sync)
>
> **Design Source:** old `sportsx-design-v1/` (78 HTML screens); **v3 source:** `sportsx-design-v3/new_design_docs/`
>
> **v3 backend status:** old spec ~136/141 implemented — **now superseded by the v3 delta** (≈70 new P0 + ≈25 changed + ≈10 verify-first; `Backend-Feature-Delta.md` §11). **Role model:** `athlete, coach, academy, organizer, scout, admin` — `sponsor` REMOVED, `scout` added. **Auth:** OTP (phone/email) is P0 again.
>
> **⚠️ SUPERSEDED phases:** Phase 0-E2 (Phone/OTP legacy) and Phase 5 (Phone/OTP → Email/Password) are **[SUPERSEDED — see Backend-Feature-Delta.md]**. The v3 P0 work is tracked in **Phase 8** below.
>
> **Design Tokens (from `sportsx-design-v1/`):**
> - Primary Blue: `#1677ff`, Surface: `#f7f8fa`, Text: `#111111`, Muted: `#6b7280`
> - Font: **Inter** (Google Fonts)
> - Spacing: 8px base grid | Border Radius: 8px (standard)
>
> **Documents:**
> - `docs/Design-Implementation-Plan.md` — Design-to-Flutter mapping
> - `docs/UI-Completion-And-Backend-Wiring-Plan.md` — UI fixes + backend wiring
> - `docs/Production-Backend-Plan.md` — Production readiness + auth redesign

---

## Phase 0 — Foundation

### P0-E1: Project Setup

- [x] Laravel project created and running
- [x] MySQL database connected, `.env` configured
- [x] `config/sportx.php` created
- [x] CORS configured for Flutter origin(s)
- [x] Sanctum installed and configured
- [x] API route prefix `/api/v1` working
- [x] All database migrations written (17+ tables + sessions)
- [x] All migrations run cleanly
- [x] Master data seeders written
- [x] Dev data seeder written
- [x] Flutter project with feature-first folder structure
- [x] Flutter core infrastructure (Dio, StorageService, Riverpod, go_router)
- [x] Shared models complete
- [x] Flutter theme with design tokens

### P0-E2: Auth API (Phone/OTP - Legacy) — [SUPERSEDED — see Backend-Feature-Delta.md]

> **⚠️ SUPERSEDED (v3, D1):** OTP is **P0 again**. The old "replace OTP with email/password" plan is reversed — the OTP stack is re-created (phone **or** email) **alongside** password login. See Phase 8.

- [x] `POST /auth/register` — phone-based (to be replaced)
- [x] `POST /auth/verify-otp` — OTP verification (to be replaced)
- [x] `POST /auth/login` — phone/OTP (to be replaced)
- [x] `POST /auth/forgot-password` — OTP-based (to be replaced)
- [x] `POST /onboarding/*` — all onboarding endpoints
- [x] `auth:sanctum` middleware
- [x] `role:xxx` middleware
- [x] `GET /meta/*` — master data endpoints

---

## Phase 1 — Discovery

### Auth UI (Flutter)

- [x] S1 Splash screen (3-dot pulse animation implemented)
- [x] S2 Role Selection (60px top padding; 5 public roles — **scout added, sponsor removed**)
- [x] S3 Sign Up (Full Name field first, Email, Phone, Password order; triggers OTP — v3)
- [x] S4 OTP Verification (phone **or** email 6-digit OTP — v3 D1)
- [x] S5 Login (email/password + phone/email OTP branch — v3)
- [x] Auth state management (password + OTP flow)

### Onboarding & Profile

- [x] A1/A2 Athlete onboarding
- [x] A3 Home Dashboard (5-tab bottom navigation: Home, Search, Saved, Activity, Profile)
- [x] A4 My Profile view
- [x] A5 Edit Profile
- [x] A6 Media Gallery Manager
- [x] C1/C2 Coach onboarding
- [x] AC1/AC2 Academy onboarding
- [ ] TS1/TS2 Talent Scout onboarding + profile creation

### Search & Directories

- [x] T1 Directory List template
- [x] T2 Detail Page template
- [x] S6 Universal Search
- [x] S7 Search Results
- [x] S8 Filter Panel
- [x] A7/A8 Academy Directory + Detail
- [x] A9/A10 Coach Directory + Detail
- [x] A12/A13 Trial Listings + Detail
- [x] A16/A17 Tournament Calendar + Detail
- [x] A19/A20 Scholarship Feed + Detail — **[SUPERSEDED — see Backend-Feature-Delta.md]** now `opportunities`
- [x] A21/A22 Sponsorship List + Detail — **[SUPERSEDED — see Backend-Feature-Delta.md]** now `opportunities`
- [x] Sports Venue Directory + Detail

### Save & Report

- [x] A25 Saved/Bookmarked Items
- [x] Save toggle on T2
- [x] S10 Report a Listing
- [x] Bottom navigation bar (5 tabs: Home, Search, Saved, Activity, Profile)
- [x] S11 Settings shell

---

## Phase 2 — Actions & Supply Side

### Enquiries

- [x] A11 Enquire with Coach
- [x] C4/C5 Coach Enquiry Inbox + Detail
- [x] AC8/AC9 Academy Enquiry Inbox + Detail
- [x] Enquiry reply notification

### Trial Registration

- [x] A14/A15 Trial Registration + Confirmation
- [x] AC4-AC7 Academy Trial Management
- [x] A24 Activity Hub — Trials tab

### Tournament Registration

- [x] A18 Tournament Registration
- [x] O2-O10 Organizer Tournament Management
- [x] A24 Activity Hub — Tournaments tab

### Sponsorship Applications — [SUPERSEDED — see Backend-Feature-Delta.md]

> Sponsor role REMOVED (v3 D2). Applicants now apply to unified `opportunities` (scholarship/sponsorship/tryout/camp) via `/opportunities/{id}/apply`. See Phase 8.

- [x] A23 Apply/Pitch to Sponsor — **[SUPERSEDED]** now `POST /opportunities/{id}/apply`
- [x] SP1-SP9 Sponsor Screens — **[SUPERSEDED]** sponsor role/routes removed
- [x] A24 Activity Hub — Sponsorships tab — now `opportunities`

### Coach Browse Mode

- [x] C6 Coach Browse Mode

### Talent Scout — first-class role (v3)

> **v3:** the scout role is now first-class (was a side-guide). 30 fields in `talent_scout_profiles`; shortlist status/tags/notes; observations; guardian contact for U-18 (`Talent-Scout-Implementation-Guide.md`).

- [ ] SC.1 Scout onboarding + `talent_scout_profiles` (30 fields)
- [ ] SC.2 Scout dashboard (fold into `/me/home`)
- [ ] SC.4/SC.5/SC.6 Athlete search + shortlist (status/tags/notes, pipeline tabs)
- [ ] SC.10 Observations
- [ ] SC.13 Contact athlete/parent via guardian connection
- [ ] SC.8/SC.9 Scout reports (P1)

---

## Phase 3 — Admin & Reminders

### Admin Console (Web Panel)

- [x] AD1 Admin Login
- [x] AD2 Admin Dashboard
- [x] AD3-AD5 Content Management
- [x] AD6-AD7 Moderation Queue + Detail
- [x] AD8-AD9 Expiry Rules + Monitor
- [x] AD10-AD12 Category Management
- [x] FR-ADMIN-11 Scholarship CRUD — **[SUPERSEDED — see Backend-Feature-Delta.md]** now unified `opportunities` + admin verification/user mgmt (Phase 8)
- [x] Admin Web Panel views (`admin/*.blade.php`)

### Auto-Expiry Engine

- [x] Expiry rule model + CRUD
- [x] `expires_at` computed on publish
- [x] SweepExpiredContentJob
- [x] Expiry events + listing status
- [x] Admin Override/Restore

### Reminders & Notifications

- [x] Reminder subscription on confirm
- [x] Reminder subscription on save
- [x] Reminder offset config
- [x] SendDueRemindersJob
- [x] Notification model + API
- [x] S9 Notifications Center
- [x] Notification toggle in Settings
- [ ] S12 Help/Support Center (FAQ search, contact form)

---

## Phase 3E — Platform Integrations (2026-10)

> Three vendor decisions closed. Detailed specs: `Email-Provider-Architecture.md`, `Google-Authentication.md`, `FCM-Notification-System.md`.
> **Closes:** AS-03a (email), AS-03c (push), D9 (Google sign-in). **Still open:** AS-60 (SMS vendor) — blocks `channel=phone` OTP only.

### Email — dual SMTP + Gmail (`Email-Provider-Architecture.md`)

**Backend**

- [x] `MailProviderService` — provider resolution, `configuredChain()`, `status()`, `diagnostics()`, `testConnection()`
- [x] `GmailApiTransport` — Gmail REST v1 `messages:send`; `user` + `service_account` auth modes; token cache with 60s margin
- [x] Register `gmail-api` transport via `Mail::extend()`; resolve `mail.default` per request from `MailProviderService`
- [x] `sportx_failover` mailer — chain filtered to configured providers
- [x] `SportXMail` base mailable — `ShouldQueue`, `$tries = 3`, `$backoff = [10,30,90]`, deep-link helper, `failed()` logging
- [x] Mailables: `EmailOtpMail`, `VerifyEmail` (**was never sent — now wired**), `PasswordResetMail`, `AccountApprovedMail`, `AccountRejectedMail`, `WelcomeMail`, `NotificationFallbackMail`
- [x] Email views — `emails/layout.blade.php` (table-based, inline-styled) + 7 templates
- [x] `admin/email-settings` controller — status / diagnostics / runtime switch / test / clear-token-cache
- [x] Config `config/sportx.php → 'mail'`; `config/mail.php` gains the `gmail` mailer
- [x] `.env.example` — `MAIL_PROVIDER`, `GMAIL_*`, `FRONTEND_URL`

**Migration**

- [ ] `php artisan migrate` — `2026_10_01_000002` (restore `otp_codes`)
- [x] `OtpCode::$fillable` corrected — it listed legacy columns, so every write was silently discarded
- [ ] Wire an **SMS driver** for `channel=phone` (AS-60) — **blocks phone signup**

**Verification**

- [ ] SPF / DKIM / DMARC published for the sending domain (SEC-26)
- [ ] Both providers configured so failover has somewhere to fail over **to**
- [ ] `POST /admin/email-settings/test` returns `ok: true` for **each** provider
- [ ] OTP round-trip: `send-otp` → email received → `verify-otp` succeeds
- [ ] Admin approve/reject each produce an email (previously silent)
- [ ] Runtime switch: `POST /admin/email-settings/provider` takes effect without a redeploy

### Google sign-in (`Google-Authentication.md`)

**Backend**

- [x] `social_accounts` migration — unique `(provider, provider_user_id)`; encrypted tokens; drops `users.google_id`
- [x] `SocialAccount` model — `encrypted` casts, `$hidden` tokens, morph-map registration
- [x] `GoogleAuthService::verifyIdToken()` — six checks: structure, `alg` pinned to RS256, JWKS signature (24h cache, refetch on unknown `kid`), `aud`, `exp` + 60s skew, `email_verified`
- [x] Account resolution — known identity → sign in; verified email match → link; else create
- [x] `pending` accounts linked but refused login (403 `PENDING_APPROVAL`) — the approval gate cannot be bypassed
- [x] `role` on signup validated against `GOOGLE_ALLOWED_ROLES`
- [x] `User` model — `google_id` removed from `$fillable` / `$hidden`
- [x] Domain error codes documented in `API-Specification.md` §21

**Migration**

- [ ] `php artisan migrate` — `2026_10_01_000001`
- [ ] Back-fill existing `users.google_id` values into `social_accounts` in production **before** dropping the column

**Flutter**

- [ ] Add `google_sign_in` to `pubspec.yaml` (**pin explicitly** — `^6.2.1`; v7 changes the API surface)
- [ ] **Populate `oauth_client` in `google-services.json`** — it is currently empty, so Android gets no `serverClientId` and sign-in fails with `DEVELOPER_ERROR`
- [ ] `serverClientId` in `android/app/build.gradle.kts`; `REVERSED_CLIENT_ID` + URL scheme in `Info.plist`
- [ ] `AuthNotifier.signInWithGoogle()` — on success run the **same** post-login sequence as password login (persist token → `checkAuth()` → `_registerFcmToken()`)
- [ ] "Continue with Google" button on Login + Sign Up, below the primary action with an "or" rule
- [ ] Sign-up captures the **role** before the Google button (role drives approval routing)

### FCM notifications (`FCM-Notification-System.md`)

**Backend — correctness fixes (all previously broken)**

- [x] `FCMService` — **`messages:send` per token**. The old code called `messages:sendMulticast`, which **does not exist in HTTP v1**; it 404'd and `responses[0]` was null, so every push silently reported success while delivering nothing
- [x] Android `channel_id` per notification type — **without it Android 8+ silently drops every notification**
- [x] APNs headers — `apns-priority`, `apns-push-type`, `apns-sound` (iOS alerts were silent in the background)
- [x] `notification_prefs` honoured before dispatch (the column existed but **nothing ever read it**)
- [x] `NotificationController::sendPushNotification()` read `$notification->message` — a column that does not exist — producing **empty push bodies**; now uses `toPushPayload()`
- [x] Invalid-token handling — `UNREGISTERED` retires immediately; transient errors increment `failure_count` and retire only after 3 strikes (**never retire on the first transient failure**)
- [x] `user_device_tokens` — unique `token` (de-dupe first), `last_seen_at`, `failure_count`
- [x] `notifications` — `channel`, `category`, `image_url`, `priority`, `metadata`, `pushed_at`, `push_status`; `type` widened to `VARCHAR(40)`
- [x] `NotificationService` — row first (source of truth), preference gate, hard overrides, email fallback on `no_devices`/`failed`
- [x] `SendPushNotification` job — chunked (`FCM_BATCH_SIZE` 500), retries, backoff
- [x] `PruneStaleDeviceTokensJob` + `PruneNotificationRowsJob` — scheduled daily
- [x] New notification types wired to admin approve/reject (previously produced **no notification of any kind**)

**API**

- [x] `GET/PUT /me/notification-preferences`; `POST /me/device-tokens/subscribe`; `POST /me/device-tokens/test`
- [x] `GET /admin/notifications/stats`

**Flutter**

- [ ] Add `flutter_local_notifications` (AS-72) — **without it, background delivery produces nothing visible**
- [ ] Fix `main.dart` — `Firebase.initializeApp()` is called with **no `options:`**, so `DefaultFirebaseOptions` is unused and web/tests will fail
- [ ] Android `POST_NOTIFICATIONS` declared in `AndroidManifest.xml` — `requestPermission()` is a silent no-op on Android 13+ without it
- [ ] Android channel IDs must match the backend exactly (`sportx_default`, `sportx_enquiries`, `sportx_reminders`, `sportx_updates`, `sportx_announcements`)
- [ ] Darwin settings — `presentAlert: true` for foreground
- [ ] `getInitialMessage()` / `onMessageOpenedApp` → deep link via `action_url` + `category`

**Launch blockers**

- [ ] **Raise FCM quota** (AS-67) — default ≈ 10,000 sends/day
- [ ] **Upload APNs auth key** (AS-68) — iOS release builds otherwise get no push

**Verification**

- [ ] Push reaches a real device on both platforms, foreground **and** background
- [ ] Tapping a push deep-links to the right screen and re-authorizes server-side
- [ ] `push_status` records `sent` in the admin stats after a test push
- [ ] A user with no device token receives the **email fallback**
- [ ] Disabling a category in Settings actually suppresses that push
- [ ] Logout deactivates all of the user's device tokens

---

## Phase 4 — Polish (Completed Items)

- [x] Password change in Settings
- [x] Rate limiting on auth endpoints
- [x] CORS configured
- [x] File upload validation
- [x] Query optimization
- [x] Index review
- [x] Pagination enforced

---

## Phase 5 — UI Completion & Auth Redesign — [SUPERSEDED — see Backend-Feature-Delta.md]

> **⚠️ SUPERSEDED (v3, D1):** the "Phone/OTP → Email/Password" auth change described below is reversed — OTP is P0 again. The email/password endpoints/mailables remain (password auth is kept), but OTP + `otp_codes` are re-added. UI fixes from this phase remain valid. See Phase 8 for the v3 P0 auth work.

### ⚠️ Auth System (Phone/OTP → Email/Password)

| Task | Status |
|------|--------|
| AuthController email/password endpoints | ✅ Complete |
| Email verification endpoint | ✅ Complete |
| VerifyEmail mailable | ✅ Complete |
| PasswordResetMail mailable | ✅ Complete |
| Email view templates (verify-email.blade.php, password-reset.blade.php) | ✅ Complete |
| Migration (verification_token, reset_password_token, drop otp_codes) | ✅ Complete |
| Flutter auth provider (register, login, verifyEmail, forgotPassword, resetPassword) | ✅ Complete |
| Flutter login/signup screens | ✅ Complete |

### UI Fixes (from Design Audit)

| Screen | Issue | Status |
|--------|-------|--------|
| Home Dashboard | Bottom nav bar (5 tabs) | ✅ Complete |
| Sign Up | Full Name field first, correct order | ✅ Complete |
| Academy Detail | Phone contact button + callback | ✅ Complete |
| Splash Screen | 3-dot pulse animation | ✅ Complete |
| Role Selection | 60px top padding | ✅ Complete |

**Reference:** `docs/UI-Completion-And-Backend-Wiring-Plan.md`

---

## Phase 6 — Backend Production Hardening

### Security

| Task | Status | Priority |
|------|--------|----------|
| Admin 2FA enforcement middleware + registration | ✅ Complete | CRITICAL |
| Signed URLs for media downloads | ✅ Complete | HIGH |
| Rate limiting review | ✅ Complete | MEDIUM |

### Monitoring

| Task | Status | Priority |
|------|--------|----------|
| Health check endpoint | ✅ Basic implemented | HIGH |
| Sentry exception tracking | Pending | HIGH |
| Laravel Telescope (dev) | Pending | LOW |

### Performance

| Task | Status | Priority |
|------|--------|----------|
| Load testing (1000+ users) | Pending | MEDIUM |
| Redis/Cache optimization | Pending | MEDIUM |

### Calendar Export

| Task | Status | Priority |
|------|--------|----------|
| ICS service for trials | ✅ Complete | MEDIUM |
| ICS service for tournaments | ✅ Complete | MEDIUM |
| Download endpoints (trials/tournaments ICS) | ✅ Complete | MEDIUM |

**Reference:** `docs/Production-Backend-Plan.md`

---

## Phase 7 — OAuth & Deferred Features

### Google OAuth

| Task | Status | Priority |
|------|--------|----------|
| Laravel Socialite setup | Pending | MEDIUM |
| Google OAuth Controller | Pending | MEDIUM |
| Flutter Google sign-in | Pending | MEDIUM |
| Google OAuth routes | Pending | MEDIUM |

### Auto Waitlist Promotion

| Task | Status | Priority |
|------|--------|----------|
| PromoteWaitlistedRegistrations job | Pending | LOW |
| Notification on promotion | Pending | LOW |

---

## Phase 8 — v3 P0 Delta (new design) 🔴 IN PROGRESS

> Source of truth: `Backend-Feature-Delta.md` §1 (P0), §11 (endpoint catalog), `SportX_Mandatory_Fields.md` (30 fields/role). Build order: delta §9.

### 8.1 Roles, Auth & Trust (BE-M1.x)

- [ ] `UserRole` enum: remove `sponsor`, add `scout` (middleware/policies/seeders/admin filters)
- [ ] OTP stack: re-create `otp_codes`; `POST /auth/send-otp`, `/auth/verify-otp`, `/auth/resend-otp` (phone + email); `RateLimitOtp`
- [ ] Keep email/password login + reset (do NOT drop)
- [ ] Guardian consent: `guardian_consents`, `POST /guardian/consent`, `/guardian/verify-otp`, `GET/PUT /me/guardian-controls`; enforce < 18
- [ ] Verification: `verification_requests`, `POST/GET /me/verification`, `GET/POST /admin/verification` + approve/reject + badge surfacing
- [ ] Profile completion checklist API `GET /me/completion-checklist` per role

### 8.2 Profiles (30 fields/role) (BE-M1.3, BE-M2.x)

- [ ] `talent_scout_profiles` (30 fields) + `POST /onboarding/scout` + `/me/scout-profile`
- [ ] `athlete_sports` pivot: `playing_role`, `level`, `experience_years`, `is_primary`
- [ ] Typed `achievements` CRUD; `GET /me/media`; social links; privacy (`PUT /me/privacy`)
- [ ] Other profiles collect all 30 fields from `SportX_Mandatory_Fields.md`

### 8.3 Opportunities (BE-M5.x)

- [ ] `opportunities` table + `opportunity_applications`
- [ ] `GET /opportunities`, `/opportunities/{id}`, `POST /me/opportunities`, edit/publish/close, `POST /opportunities/{id}/apply`, `GET /me/opportunities?type=`
- [ ] Migrate `sponsorships`/`scholarships` → `opportunities`; `sponsorship_applications` → `opportunity_applications`; old endpoints 410
- [ ] Applicant review (P1): `GET /opportunities/{id}/applications`, `PATCH …/applications/{app}`

### 8.4 Programs & Facilities (BE-M6.x)

- [ ] `programs` table + CRUD + public detail + Explore surfacing
- [ ] `facilities` table + CRUD + public detail (replace `academies.facilities` JSON)
- [ ] Program enquiry → chat thread (`POST /programs/{id}/enquire`)

### 8.5 Discovery, Leaderboard & Search (BE-M3.x, BE-M8.x)

- [ ] `GET /me/home` (role-aware) + `GET /explore`
- [ ] Athletes group in `/search`; recent-searches POST; enriched cards; distance sort; position/level/facility/price/rating filters
- [ ] `leaderboard_scores` + `leaderboard_seasons` + points engine + `RecalculateLeaderboardJob`
- [ ] `GET /leaderboard` + `GET /leaderboard/strip` (+ P1 admin config)

### 8.6 Social, Network & Messaging (BE-M7.x) — verify partial first

- [ ] Posts + feed (`/feed`, `/posts*`, likes, comments)
- [ ] Follows + connection requests (`/follow*`, `/connections*`)
- [ ] 1:1 chat (`/conversations*`); rules: accepted connection / enquiry thread; minors guardian-only
- [ ] Blocks + report user/post; privacy enforcement

### 8.7 Scouting (BE-M10.x)

- [ ] Shortlist status/tags/notes (`/me/shortlist`); observations; reports (P1)
- [ ] `POST /athletes/{id}/contact` (guardian routing for U-18)

### 8.8 Admin P0 (BE-M1.5, BE-M11.x)

- [ ] `GET /admin/users` (+ filters), detail, suspend/ban
- [ ] Verification queue approve/reject
- [ ] Content `{type}` extensions: opportunities/programs/facilities/posts; moderation suspend; positions master
- [ ] Registrant export CSV (`GET /events/{id}/registrations/export`)
- [ ] `analytics_events` log (`POST /analytics/events`)

### 8.9 Notifications, Jobs & Policies

- [ ] Notification `type` enum extensions + events/listeners (`RegistrationDecided`, `VerificationDecided`, `ConnectionAccepted`)
- [ ] `RecalculateLeaderboardJob`, `ResetLeaderboardSeasonJob`; expiry + opportunities
- [ ] Policies: minors, scout-data privacy, provider posting matrix, review gating, no cold DMs

---

## Summary — Remaining Items

### Auth System (Phase 5) ✅ COMPLETED
| Item | Status |
|------|--------|
| Email/password auth backend | ✅ Complete |
| Email verification flow | ✅ Complete |
| Password reset email | ✅ Complete |
| Flutter auth update | ✅ Complete |

### UI Completion (Phase 5) ✅ COMPLETED
| Item | Status |
|------|--------|
| Bottom navigation bar | ✅ Complete |
| Sign up name field | ✅ Complete |
| Academy phone button | ✅ Complete |
| Splash loader | ✅ Complete |
| Role selection padding | ✅ Complete |

### Backend Production (Phase 6)
| Item | Status |
|------|--------|
| Admin 2FA middleware | ✅ Complete |
| Signed URLs | ✅ Complete |
| Health check | ✅ Basic |
| ICS export | ✅ Complete |
| Sentry | Pending |

### Deferred to Phase 7
| Item | Status |
|------|--------|
| ~~Google OAuth~~ | **✅ DONE (P0)** — `Google-Authentication.md`; AS-64 / D9 CLOSED. Remaining: Flutter `google_sign_in` wiring + `oauth_client` |
| Auto waitlist promotion | Pending |
| Load testing | Pending |

### v3 P0 Delta (Phase 8)
| Item | Status |
|------|--------|
| Roles (scout add / sponsor remove) | Pending |
| OTP stack (phone + email) | Pending |
| Guardian consent | Pending |
| Verification queue + admin user mgmt | Pending |
| Opportunities (unified) + migration | Pending |
| Programs + facilities | Pending |
| Social feed + chat + follows + blocks | Pending (verify first) |
| Leaderboard points engine | Pending |
| Discovery (`/me/home`, `/explore`) + athlete search | Pending |
| Profiles 30 fields + scout onboarding | Pending |
| Notifications matrix + jobs + policies | Pending |
| **Email — dual SMTP + Gmail** | **✅ DONE (backend)** — `Email-Provider-Architecture.md`; AS-59/AS-03a CLOSED |
| **Google sign-in** | **✅ DONE (backend)** — `Google-Authentication.md`; AS-64/D9 CLOSED. Flutter wiring pending |
| **FCM push + in-app + email fallback** | **✅ DONE (backend)** — `FCM-Notification-System.md`; AS-03c CLOSED. Local-notification display + quota/APNs pending |

---

## Reference Documents

| Document | Purpose |
|----------|---------|
| `docs/Backend-Feature-Delta.md` | **v3 source of truth** — new/changed/removed backend features + full endpoint catalog |
| `sportsx-design-v3/new_design_docs/SportX_Mandatory_Fields.md` | 30 profile fields per role (mandatory/optional) |
| `docs/Database-Design.md` | Canonical v3 schema |
| `docs/Design-Implementation-Plan.md` | Design source analysis, screen mapping |
| `docs/UI-Completion-And-Backend-Wiring-Plan.md` | UI fixes, backend wiring, auth change |
| `docs/Production-Backend-Plan.md` | Production hardening, OAuth, monitoring |
| `sportsx-design-v1/` | Legacy 78 HTML design files (mobile + admin) |
| `docs/Admin-Panel-Implementation-Prompt.md` | Admin web panel specs |
| `docs/Email-Provider-Architecture.md` | **Dual transactional email (SMTP + Gmail API), runtime switchable** |
| `docs/Google-Authentication.md` | **"Continue with Google" — ID-token sign-in, verification and account linking** |
| `docs/FCM-Notification-System.md` | **Notification system — in-app + FCM push + email fallback, device tokens, preferences** |
| `docs/Mobile-Architecture.md` | Flutter architecture |
