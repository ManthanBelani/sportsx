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
| Google OAuth | Pending (P1 / confirm D9) |
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
| `docs/Mobile-Architecture.md` | Flutter architecture |
