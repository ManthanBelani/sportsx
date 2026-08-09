# Development Checklist — SportX India

Trackable checklist organized by phase and module. Maps to Jira ticket IDs in `Jira-Tickets.md` and feature IDs in `Functional-Requirements.md`.

> **Last Updated:** 2026-08-09
>
> **Design Source:** `sportsx-design-v1/` (78 HTML screens - mobile + admin)
>
> **Backend Status:** ~136/141 endpoints implemented
> **Flutter Status:** All 63 screens implemented (UI complete)
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

### P0-E2: Auth API (Phone/OTP - Legacy)

> **⚠️ DEPRECATED:** Auth system is being changed to Email/Password.
> See Phase 5 for new auth implementation.

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
- [x] S2 Role Selection (60px top padding, 5 role cards)
- [x] S3 Sign Up (Full Name field first, Email, Phone, Password order)
- [x] S4 OTP Verification (email-based verification)
- [x] S5 Login (email/password only)
- [x] Auth state management (email/password flow)

### Onboarding & Profile

- [x] A1/A2 Athlete onboarding
- [x] A3 Home Dashboard (5-tab bottom navigation: Home, Search, Saved, Activity, Profile)
- [x] A4 My Profile view
- [x] A5 Edit Profile
- [x] A6 Media Gallery Manager
- [x] C1/C2 Coach onboarding
- [x] AC1/AC2 Academy onboarding

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
- [x] A19/A20 Scholarship Feed + Detail
- [x] A21/A22 Sponsorship List + Detail
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

### Sponsorship Applications

- [x] A23 Apply/Pitch to Sponsor
- [x] SP1-SP9 Sponsor Screens
- [x] A24 Activity Hub — Sponsorships tab

### Coach Browse Mode

- [x] C6 Coach Browse Mode

---

## Phase 3 — Admin & Reminders

### Admin Console (Web Panel)

- [x] AD1 Admin Login
- [x] AD2 Admin Dashboard
- [x] AD3-AD5 Content Management
- [x] AD6-AD7 Moderation Queue + Detail
- [x] AD8-AD9 Expiry Rules + Monitor
- [x] AD10-AD12 Category Management
- [x] FR-ADMIN-11 Scholarship CRUD
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

## Phase 5 — UI Completion & Auth Redesign ✅ COMPLETED

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
| Google OAuth | Pending |
| Auto waitlist promotion | Pending |
| Load testing | Pending |

---

## Reference Documents

| Document | Purpose |
|----------|---------|
| `docs/Design-Implementation-Plan.md` | Design source analysis, screen mapping |
| `docs/UI-Completion-And-Backend-Wiring-Plan.md` | UI fixes, backend wiring, auth change |
| `docs/Production-Backend-Plan.md` | Production hardening, OAuth, monitoring |
| `sportsx-design-v1/` | 78 HTML design files (mobile + admin) |
| `docs/Admin-Panel-Implementation-Prompt.md` | Admin web panel specs |
| `docs/Mobile-Architecture.md` | Flutter architecture |
