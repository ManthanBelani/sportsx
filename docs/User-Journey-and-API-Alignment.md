# SportX India — User Journey & API Alignment Document

## Executive Summary

This document provides:
1. **Alignment Analysis** — Current state vs documented state (API, Flow, Router)
2. **Complete User Journeys** — Page-by-page navigation for each role
3. **Screen-to-API Binding** — Which API endpoints each screen calls
4. **Issues & Fixes** — Misalignments found and recommended corrections

---

## Part 1: Alignment Analysis

### 1.1 VERIFICATION COMPLETED - August 2026

**Finding**: The Flutter CODE and Backend LARAVEL are aligned. The API-SPEC.md documentation had ERRORS that have been corrected.

### 1.2 Corrected API Endpoints (Backend is source of truth)

| Feature | Old Doc (WRONG) | Correct Endpoint | Status |
|---------|----------------|------------------|--------|
| Email verification | `POST /auth/verify-otp` | `POST /auth/verify-email` | ✅ Fixed |
| Resend OTP | `POST /auth/resend-otp` | NOT IMPLEMENTED | ⚠️ Note |
| Trial Registration | `POST /trials/{id}/registrations` | `POST /trials/{trial}/register` | ✅ Fixed |
| Tournament Registration | `POST /tournaments/{id}/registrations` | `POST /tournaments/{tournament}/register` | ✅ Fixed |
| Sponsorship Apply | `POST /sponsorships/{id}/applications` | `POST /sponsorships/{sponsorship}/apply` | ✅ Fixed |
| Application Update | Various | `PATCH /sponsorships/{sponsorship}/applications/{application}` | ✅ Fixed |

### 1.3 Code vs Backend Verification

| Item | Location | Finding |
|------|---------|---------|
| Trial Registration | `trial_registration_screen.dart:33` | ✅ CORRECT - uses `/trials/${widget.trialId}/register` |
| Sponsor Pitch | `sponsor_pitch_screen.dart:32` | ✅ CORRECT - uses `/sponsorships/${widget.sponsorId}/apply` |
| Auth Register | `auth_provider.dart:83` | ✅ CORRECT - uses `/auth/register` |
| Auth Login | `auth_provider.dart:125` | ✅ CORRECT - uses `/auth/login` |
| Auth Verify | `auth_provider.dart:98` | ✅ CORRECT - uses `/auth/verify-email` |

### 1.4 Remaining Issues Found

#### Issue #1: `resendOtp` calls non-existent endpoint
```
Location: auth_provider.dart:114-119
Problem: Calls POST /auth/resend-verification which doesn't exist in backend
Severity: Minor - fails silently, UI shows generic toast
```

#### Issue #2: `verifyOtp` wrapper is misleading
```
Location: auth_provider.dart:110-112
Problem: verifyOtp({email, otp}) ignores email, calls verifyEmail(otp)
This works because backend accepts OTP as token, but naming is confusing
Severity: Minor - naming inconsistency
```

#### Issue #3: Registration Confirmation has hardcoded data
```
Location: registration_confirmation_screen.dart:50-73
Problem: Shows hardcoded date/time/location instead of actual registration data
"View Ticket" button does nothing
Severity: Major - user experience issue
Status: ✅ FIXED - Now accepts data via constructor and displays real registration info
```

#### Issue #4: Recent Searches not fetched from API
```
Location: search_provider.dart
Problem: GET /me/recent-searches not implemented, only local state
Severity: Major - missing functionality
Status: ⚠️ NOT FIXED - requires backend endpoint implementation
```

#### Issue #5: Scholarship tap in HomeScreen does nothing
```
Location: home_screen.dart:411
Problem: onTap: () => {} is empty
Severity: Major - dead UI element
Status: ✅ FIXED - Now navigates to /scholarship-detail/:id
```

### 1.5 Onboarding Route Mapping (CORRECT)
| Role | Route | Status |
|------|-------|--------|
| Athlete | `/onboarding-1` → `/onboarding-2` | ✅ Correct |
| Coach | `/coach-onboarding` | ✅ Correct |
| Academy | `/academy-onboarding` | ✅ Correct |
| Organizer | `/organizer-onboarding` | ✅ Correct |
| Sponsor | `/sponsor-onboarding` | ✅ Correct |

---

## Part 2: Complete User Journeys by Role

### 2.1 ATHLETE / PARENT Journey

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ATHLETE USER JOURNEY                              │
└─────────────────────────────────────────────────────────────────────────────┘

[ENTRY POINT]
      │
      ▼
┌─────────────┐
│   Splash    │ ─── Check auth state ───► /role-selection (if unauthenticated)
└─────────────┘                                  │
      │                                         ▼
      │                              ┌─────────────────────┐
      └─────────────────────────────►│  Role Selection     │
                                     │  (Choose Athlete)   │
                                     └─────────────────────┘
                                              │
                                              ▼
                                     ┌─────────────────────┐
                                     │     Sign Up         │
                                     │  (email + password) │
                                     └─────────────────────┘
                                              │
                                              ▼
                                     ┌─────────────────────┐
                                     │  markOnboardingTrue │
                                     │  → redirect to      │
                                     │  /onboarding-1      │
                                     └─────────────────────┘
                                              │
                                              ▼
                                     ┌─────────────────────┐
                                     │  Onboarding Step 1  │
                                     │  /onboarding-1      │
                                     │  - Sport(s) select  │
                                     │  - Age group select │
                                     └─────────────────────┘
                                              │
                                    [Continue] │
                                              ▼
                                     ┌─────────────────────┐
                                     │  Onboarding Step 2  │
                                     │  /onboarding-2      │
                                     │  - Skill level      │
                                     │  - City select      │
                                     └─────────────────────┘
                                              │
                                    [Complete] │──► markOnboardingComplete()
                                              │                 │
                                              ▼                 ▼
                                     ┌─────────────────────┐  ┌─────────────┐
                                     │   /home (shell)     │◄─┘             │
                                     └─────────────────────┘                │
                                              │                             │
          ┌─────────────────────────────────┼─────────────────────────────┘
          │                                 │
          ▼                                 ▼
┌─────────────────────┐          ┌─────────────────────┐
│   BOTTOM NAV BAR    │          │   PROFILE TAB       │
│  [Home][Search]     │          │                     │
│  [Saved][Activity]  │          │ Quick Links:        │
│  [Profile]          │          │  - Edit Profile     │
└─────────────────────┘          │  - Media Gallery   │
          │                       │  - Achievements     │
          │                       │  - Scholarships     │
          ▼                       │  - Venues           │
┌─────────────────────┐           │  - Connections      │
│      HOME TAB       │           │  - Settings         │
│                     │           └─────────────────────┘
│ • Discover section  │
│ • Quick filters     │                     │
│ • Featured items   │                     ▼
└─────────────────────┘          ┌─────────────────────┐
          │                      │   EDIT PROFILE      │
          ▼                      │   /edit-profile     │
┌─────────────────────┐          │   PUT /me/profile   │
│  DIRECTORY BROWSING │          └─────────────────────┘
│                     │
│ [Academies]─────────┼──► /academies ──► /academy-detail/:id
│ [Coaches]───────────┼──► /coaches ────► /coach-detail/:id
│ [Trials]────────────┼──► /trials ─────► /trial-detail/:id
│ [Tournaments]───────┼──► /tournaments ► /tournament-detail/:id
│ [Scholarships]───────┼──► /scholarships
│ [Sports Venues]─────┼──► /sports-venues
│ [Sponsorships]──────┴──► /sponsorships ──► /sponsor-pitch/:id
│
└────────────────────────────────────────────────────────────────
                     │
                     ▼
        ┌────────────────────────┐
        │   DETAIL PAGE         │
        │   (trial/academy/etc)  │
        │                        │
        │   Actions:             │
        │   • Enquire (coach/    │
        │     academy)           │
        │   • Register (trial)   │
        │   • Apply (sponsor)    │
        │   • Save ♡             │
        │   • Report ⚠️           │
        └────────────────────────┘
                     │
       ┌─────────────┴─────────────┐
       │                           │
       ▼                           ▼
┌──────────────┐        ┌──────────────────┐
│   ENQUIRE     │        │  TRIAL REGISTER  │
│  /enquire/:   │        │  /trial-         │
│   title       │        │   registration/: │
│               │        │   id             │
│ POST /enquiries│        │                  │
└──────────────┘        │ POST /trials/:id/ │
                        │  registrations    │
                        └──────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  CONFIRMATION   │
                        │  /registration- │
                        │  confirmation   │
                        │                  │
                        │  → Add to        │
                        │    Calendar      │
                        │  → Toggle        │
                        │    Reminder      │
                        └──────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  ACTIVITY TAB    │
                        │  /activity-hub   │
                        │                  │
                        │  GET /me/activity│
                        │  (trials/tourna- │
                        │   ments/sponsor- │
                        │   ships tabs)     │
                        └──────────────────┘
```

---

### 2.2 COACH Journey

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            COACH USER JOURNEY                                │
└─────────────────────────────────────────────────────────────────────────────┘

[ENTRY POINT]
      │
      ▼
┌─────────────┐
│   Splash    │ ─── Check auth ───► /role-selection
└─────────────┘
      │
      ▼
┌─────────────────────┐
│  Role Selection     │
│  (Choose Coach)     │
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│     Sign Up         │
│  (email + password) │
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│  /coach-onboarding  │
│                     │
│  - Sport coached    │
│  - Experience       │
│  - Certifications   │
│                     │
│  POST /onboarding/  │
│    coach            │
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│  markOnboarding     │
│  Complete()         │
│         │           │
│         ▼           ▼
┌─────────────────────────────┐
│   /coach-dashboard (landing)│
└─────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│       COACH DASHBOARD       │
│                              │
│  • Listing status            │
│  • Enquiry stats             │
│  • Recent enquiries          │
│                              │
│  Quick Actions:              │
│  [Edit Profile]              │
│  [Post Trial]                │
│  [View Enquiries]            │
└─────────────────────────────┘
              │
              ├──────────────────────────────────────┐
              │                                      │
              ▼                                      ▼
┌─────────────────────────┐          ┌─────────────────────────┐
│   PROFILE TAB           │          │   POST TRIAL            │
│                         │          │   /post-trial           │
│   Quick Links:          │          │                         │
│   • Dashboard           │          │   POST /me/trials       │
│   • Edit Profile        │          │   (publish=true/false)  │
│   • Post Trial          │          └─────────────────────────┘
│   • My Trials           │                    │
│   • Enquiries           │                    ▼
│   • Activity            │          ┌─────────────────────────┐
└─────────────────────────┘          │   MY TRIALS             │
              │                     │   /my-trials            │
              │                     │                          │
              │                     │   GET /me/trials         │
              │                     └─────────────────────────┘
              │                               │
              │                               ▼
              │                     ┌─────────────────────────┐
              │                     │   REGISTRANT LIST       │
              │                     │   /registrant-list       │
              │                     │                          │
              │                     │   GET /trials/:id/       │
              │                     │     registrations        │
              │                     └─────────────────────────┘
              │                               │
              │                               ▼
              │                     ┌─────────────────────────┐
              │                     │   REGISTRANT DETAIL     │
              │                     │   /registrant-detail     │
              │                     │                          │
              │                     │   POST /registrations/:id│
              │                     │     /verify or /reject   │
              │                     └─────────────────────────┘
              │
              ▼
┌─────────────────────────┐
│   ENQUIRY INBOX         │
│   /enquiry-inbox         │
│                          │
│   GET /me/enquiries      │
│   (filter: all/new/      │
│    replied)               │
└─────────────────────────┘
              │
              ▼
┌─────────────────────────┐
│   ENQUIRY DETAIL        │
│   /enquiry-detail        │
│                          │
│   GET /enquiries/:id     │
│   POST /enquiries/:id/   │
│     messages             │
└─────────────────────────┘
```

---

### 2.3 ACADEMY Journey

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ACADEMY USER JOURNEY                              │
└─────────────────────────────────────────────────────────────────────────────┘

[ENTRY POINT] → /role-selection (Choose Academy)
      │
      ▼
┌─────────────────────┐
│     Sign Up         │
└─────────────────────┘
      │
      ▼
┌─────────────────────────────┐
│   /academy-onboarding       │
│                             │
│   - Academy name            │
│   - Sport(s)                │
│   - City                    │
│   - Facilities info         │
│                             │
│   POST /onboarding/academy  │
└─────────────────────────────┘
      │
      ▼
┌─────────────────────────────┐
│   /academy-dashboard        │
│       (LANDING)             │
└─────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│      ACADEMY DASHBOARD       │
│                               │
│   • Academy listing status    │
│   • Trial statistics          │
│   • Enquiry count            │
│                               │
│   [Edit Profile]             │
│   [Post Trial]               │
│   [View Enquiries]           │
└─────────────────────────────┘
              │
              ├──────────────────────────────────────────┐
              │                                          │
              ▼                                          ▼
┌─────────────────────────┐          ┌─────────────────────────┐
│   PROFILE TAB           │          │   POST TRIAL             │
│   Quick Links:          │          │   /post-trial             │
│   • Dashboard           │          │                           │
│   • Edit Profile        │          │   POST /me/trials        │
│   • Post Trial          │          └─────────────────────────┘
│   • My Trials           │                    │
│   • Enquiries           │                    ▼
└─────────────────────────┘          ┌─────────────────────────┐
              │                     │   MY TRIALS              │
              │                     │   /my-trials              │
              │                     │   GET /me/trials          │
              │                     └─────────────────────────┘
              │                               │
              │                               ├──────────────────┐
              │                               │                  │
              ▼                               ▼                  ▼
┌─────────────────────────┐      ┌─────────────────┐  ┌─────────────────┐
│   ENQUIRY INBOX         │      │  REGISTRANT     │  │  TRIAL DETAIL   │
│   /enquiry-inbox        │      │  LIST           │  │  (public view)  │
│                         │      │  /registrant-   │  │                 │
│   GET /me/enquiries     │      │  list           │  │  GET /trials/:id│
└─────────────────────────┘      └─────────────────┘  └─────────────────┘
```

---

### 2.4 ORGANIZER Journey

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ORGANIZER USER JOURNEY                              │
└─────────────────────────────────────────────────────────────────────────────┘

[ENTRY POINT] → /role-selection (Choose Organizer)
      │
      ▼
┌─────────────────────────────┐
│   /organizer-onboarding     │
│                             │
│   - Organization name       │
│   - Organization type       │
│   - Verification docs       │
│                             │
│   POST /onboarding/         │
│     organizer               │
└─────────────────────────────┘
      │
      ▼
┌─────────────────────────────┐
│   /organizer-dashboard      │
│       (LANDING)             │
└─────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│     ORGANIZER DASHBOARD      │
│                               │
│   • Tournament stats         │
│   • Registration counts      │
│                               │
│   [Post Tournament]           │
│   [My Tournaments]            │
│   [Registration Mgmt]         │
└─────────────────────────────┘
              │
              ├────────────────────────────────────────────────────────┐
              │                                                        │
              ▼                                                        ▼
┌─────────────────────────┐                        ┌─────────────────────────┐
│   POST TOURNAMENT       │                        │   MY TOURNAMENTS       │
│   /post-tournament     │                        │   /my-tournaments      │
│                         │                        │                         │
│   POST /me/tournaments │                        │   GET /me/tournaments  │
│   (with categories,    │                        └─────────────────────────┘
│    capacity, waitlist) │                                   │
│                         │                                   ▼
└─────────────────────────┘           ┌─────────────────────────────────────┐
              │                      │   REGISTRATION MANAGEMENT           │
              │                      │   /registration-management           │
              │                      │                                      │
              │                      │   GET /tournaments/:id/registrations │
              │                      │   PATCH /registrations/:id/          │
              │                      │     payment-status                    │
              │                      └─────────────────────────────────────┘
              │                                   │
              │                                   ├───────────────────────┐
              │                                   │                       │
              ▼                                   ▼                       ▼
┌─────────────────────────┐      ┌─────────────────┐  ┌─────────────────┐
│   CAPACITY MANAGEMENT   │      │  CAPACITY       │  │  RESULTS        │
│   /capacity-management  │      │  (from list)    │  │  PUBLISHING     │
│                         │      └─────────────────┘  │  /results-      │
│   PUT /tournaments/:id/ │                            │  publishing     │
│     capacity            │                            │                 │
└─────────────────────────┘                            │  POST /tourna- │
                                                          │  ments/:id/    │
                                                          │  results       │
                                                          └─────────────────┘

[PUBLIC VIEW]
      │
      ▼
┌─────────────────────────┐
│   RESULTS VIEW          │
│   /results-view         │
│                         │
│   GET /tournaments/:id/ │
│     results             │
└─────────────────────────┘
```

---

### 2.5 SPONSOR Journey

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SPONSOR USER JOURNEY                               │
└─────────────────────────────────────────────────────────────────────────────┘

[ENTRY POINT] → /role-selection (Choose Sponsor)
      │
      ▼
┌─────────────────────────────┐
│   /sponsor-onboarding       │
│                             │
│   - Brand name              │
│   - Brand category          │
│   - Verification docs       │
│                             │
│   POST /onboarding/sponsor │
└─────────────────────────────┘
      │
      ▼
┌─────────────────────────────┐
│   /sponsor-dashboard        │
│       (LANDING)             │
└─────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│      SPONSOR DASHBOARD       │
│                               │
│   • Active sponsorships       │
│   • Application stats         │
│   • Shortlisted athletes      │
│                               │
│   [Post Sponsorship]          │
│   [Discover Athletes]          │
│   [Applications Inbox]         │
└─────────────────────────────┘
              │
              ├──────────────────────────────────────────────────────────┐
              │                                                          │
              ▼                                                          ▼
┌─────────────────────────┐                        ┌─────────────────────────┐
│   POST SPONSORSHIP      │                        │   ATHLETE DISCOVERY     │
│   /sponsor-posting      │                        │   /athlete-discovery     │
│                         │                        │                          │
│   POST /me/sponsorships │                        │   GET /athletes          │
│   (publish=true/false)  │                        │   (with filters)         │
└─────────────────────────┘                        └─────────────────────────┘
              │                                            │
              │                                            ├───────────────┐
              │                                            │               │
              ▼                                            ▼               ▼
┌─────────────────────────┐          ┌─────────────────┐  ┌─────────────────┐
│   MY SPONSORSHIPS       │          │  ATHLETE        │  │  SHORTLIST      │
│   /my-sponsorships     │          │  PROFILE VIEW   │  │  /shortlist     │
│                         │          │  /athlete-      │  │                 │
│   GET /me/sponsorships │          │  profile-view   │  │  GET /me/       │
│   PATCH /me/sponsorships│          │                 │  │    shortlist   │
│     /:id/status         │          │  GET /athletes/ │  │  PUT /me/       │
│                         │          │    :id          │  │    shortlist/   │
│                         │          │                 │  │    :id          │
│                         │          │  POST /me/      │  │                 │
│                         │          │    shortlist    │  │                 │
│                         │          └─────────────────┘  └─────────────────┘
              │
              ▼
┌─────────────────────────┐
│   APPLICATIONS INBOX   │
│   /applications-inbox   │
│                         │
│   GET /me/applications │
└─────────────────────────┘
              │
              ▼
┌─────────────────────────┐
│   APPLICATION DETAIL   │
│   /application-detail   │
│                         │
│   GET /me/applications/ │
│     :id                 │
│                         │
│   Actions:              │
│   • Shortlist           │
│   • Reject              │
│   • Reply (enquiry)     │
│                         │
│   POST /me/applications/│
│     :id/shortlist       │
│   POST /me/applications/│
│     :id/reject          │
│   POST /me/applications/│
│     :id/reply           │
└─────────────────────────┘
```

---

### 2.6 ADMIN Journey

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            ADMIN USER JOURNEY                                 │
└─────────────────────────────────────────────────────────────────────────────┘

[ENTRY POINT]
      │
      ▼
┌─────────────────────────────┐
│   /admin/login              │
│                             │
│   - Email                   │
│   - Password                │
│   - 2FA Code                │
│                             │
│   POST /admin/login         │
│   POST /admin/verify-2fa    │
└─────────────────────────────┘
      │
      ▼
┌─────────────────────────────┐
│   /admin/dashboard          │
│       (LANDING)             │
│   (Separate portal,         │
│    NOT in bottom nav)        │
└─────────────────────────────┘
              │
              ├──────────────────────────────────────────────────────────┐
              │                                                          │
              ▼                                                          ▼
┌─────────────────────────┐                        ┌─────────────────────────┐
│   MANAGE USERS          │                        │   PENDING APPROVALS    │
│   /admin/users          │                        │   /admin/approvals      │
│                         │                        │                         │
│   GET /admin/users      │                        │   (list of items        │
│   POST /admin/users/    │                        │    awaiting approval)   │
│     :id/verify          │                        │                         │
└─────────────────────────┘                        └─────────────────────────┘
              │                                            │
              ▼                                            ▼
┌─────────────────────────┐          ┌─────────────────────────────────────┐
│   USER VERIFY           │          │   OPPORTUNITY APPROVAL              │
│   /admin/users/:id/     │          │   /admin/opportunities               │
│     verify              │          │                                      │
│                         │          │   GET /admin/opportunities           │
│   (view details,        │          │   POST /admin/opportunities/:id      │
│    verify/suspend)      │          │     /approve or /reject             │
└─────────────────────────┘          └─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────┐
│   MODERATION QUEUE      │
│   /admin/moderation     │
│                         │
│   GET /admin/moderation/│
│     queue               │
│                         │
│   POST /admin/moderation│
│     /reports/:id/       │
│     (approve/remove/    │
│      warn/edit)         │
└─────────────────────────┘
              │
              ▼
┌─────────────────────────┐
│   PLATFORM REPORTS      │
│   /admin/reports        │
│                         │
│   GET /admin/reports    │
│   GET /admin/reports/:id│
└─────────────────────────┘
              │
              ▼
┌─────────────────────────┐
│   COMPOSE NOTIFICATION  │
│   /admin/notifications/ │
│     compose             │
│                         │
│   POST /admin/notifs    │
│   (broadcast to users)  │
└─────────────────────────┘
```

---

## Part 3: Screen-to-API Binding

### 3.1 Authentication Screens

| Screen | Route | API Calls |
|--------|-------|-----------|
| Splash | `/splash` | None (checks stored token) |
| Role Selection | `/role-selection` | None |
| Sign Up | `/sign-up` | `POST /auth/register` |
| Login | `/login` | `POST /auth/login` |
| OTP (if needed) | `/otp` | `POST /auth/verify-otp` |

### 3.2 Onboarding Screens

| Screen | Route | API Calls |
|--------|-------|-----------|
| Athlete Onboarding 1 | `/onboarding-1` | `GET /meta/sports`, `GET /meta/age-groups` |
| Athlete Onboarding 2 | `/onboarding-2` | `GET /meta/cities` |
| Coach Onboarding | `/coach-onboarding` | `GET /meta/sports` |
| Academy Onboarding | `/academy-onboarding` | `GET /meta/sports`, `GET /meta/cities` |
| Organizer Onboarding | `/organizer-onboarding` | `POST /media/upload` (docs) |
| Sponsor Onboarding | `/sponsor-onboarding` | `POST /media/upload` (docs) |

**OnComplete**: All onboarding screens call `authProvider.notifier.markOnboardingComplete()` then navigate to landing.

### 3.3 Directory & Discovery Screens

| Screen | Route | API Calls |
|--------|-------|-----------|
| Home | `/home` | `GET /meta/trending-searches` |
| Discover | `/discover` | None (local UI) |
| Universal Search | `/universal-search` | `GET /search?q=`, `GET /me/recent-searches` |
| Search Filter | `/search-filter` | `GET /meta/sports`, `GET /meta/cities` |
| Academy Directory | `/academies` | `GET /academies` |
| Academy Detail | `/academy-detail/:id` | `GET /academies/:id` |
| Coach Directory | `/coaches` | `GET /coaches` |
| Coach Detail | `/coach-detail/:id` | `GET /coaches/:id` |
| Trial Directory | `/trials` | `GET /trials` |
| Trial Detail | `/trial-detail/:id` | `GET /trials/:id` |
| Tournament Directory | `/tournaments` | `GET /tournaments` |
| Tournament Detail | `/tournament-detail/:id` | `GET /tournaments/:id` |
| Scholarship List | `/scholarships` | `GET /scholarships` |
| Scholarship Detail | `/scholarship-detail/:id` | `GET /scholarships/:id` |
| Sports Venue List | `/sports-venues` | `GET /sports-venues` |
| Sponsorship List | `/sponsorships` | `GET /sponsorships` |

### 3.4 Registration & Action Screens

| Screen | Route | API Calls |
|--------|-------|-----------|
| Enquire | `/enquire/:title` | `POST /enquiries` |
| Trial Registration | `/trial-registration/:id` | `POST /media/upload`, `POST /trials/:id/registrations` |
| Tournament Registration | `/tournament-registration/:id` | `POST /tournaments/:id/registrations` |
| Registration Confirmation | `/registration-confirmation` | None |
| Sponsor Pitch | `/sponsor-pitch/:id` | `POST /sponsorships/:id/applications` |

### 3.5 Profile & Management Screens

| Screen | Route | API Calls |
|--------|-------|-----------|
| Profile | `/profile` | `GET /me/profile` |
| Edit Profile | `/edit-profile` | `PUT /me/profile`, `POST /media/upload` |
| Add Achievement | `/add-achievement` | `PUT /me/profile` |
| Media Gallery | `/media-gallery` | `GET /me/profile`, `DELETE /media/:id` |
| View Profile | `/view-profile` | `GET /athletes/:id` |

### 3.6 Role-Specific Dashboards

| Screen | Route | API Calls |
|--------|-------|-----------|
| Coach Dashboard | `/coach-dashboard` | `GET /me/coach-profile`, `GET /me/enquiries` |
| Academy Dashboard | `/academy-dashboard` | `GET /me/academy`, `GET /me/enquiries` |
| Organizer Dashboard | `/organizer-dashboard` | `GET /me/tournaments` |
| Sponsor Dashboard | `/sponsor-dashboard` | `GET /me/sponsorships`, `GET /me/applications` |

### 3.7 Management Screens

| Screen | Route | API Calls |
|--------|-------|-----------|
| Post Trial | `/post-trial` | `POST /me/trials` |
| My Trials | `/my-trials` | `GET /me/trials` |
| Registrant List | `/registrant-list` | `GET /trials/:id/registrations` |
| Registrant Detail | `/registrant-detail` | `GET /registrations/:id`, `POST /registrations/:id/verify`, `POST /registrations/:id/reject` |
| Post Tournament | `/post-tournament` | `POST /me/tournaments` |
| My Tournaments | `/my-tournaments` | `GET /me/tournaments` |
| Registration Management | `/registration-management` | `GET /tournaments/:id/registrations`, `PATCH /registrations/:id/payment-status` |
| Capacity Management | `/capacity-management` | `GET /tournaments/:id/capacity`, `PUT /tournaments/:id/capacity` |
| Results Publishing | `/results-publishing` | `POST /tournaments/:id/results` |
| Results View | `/results-view` | `GET /tournaments/:id/results` |
| Enquiry Inbox | `/enquiry-inbox` | `GET /me/enquiries` |
| Enquiry Detail | `/enquiry-detail` | `GET /enquiries/:id`, `POST /enquiries/:id/messages` |
| Sponsor Posting | `/sponsor-posting` | `POST /me/sponsorships` |
| My Sponsorships | `/my-sponsorships` | `GET /me/sponsorships` |
| Athlete Discovery | `/athlete-discovery` | `GET /athletes` |
| Athlete Profile View | `/athlete-profile-view` | `GET /athletes/:id`, `POST /me/shortlist` |
| Applications Inbox | `/applications-inbox` | `GET /me/applications` |
| Application Detail | `/application-detail` | `GET /me/applications/:id`, `POST /me/applications/:id/shortlist`, `POST /me/applications/:id/reject` |
| Shortlist | `/shortlist` | `GET /me/shortlist`, `PUT /me/shortlist/:id` |
| My Connections | `/my-connections` | `GET /me/connections` |
| Connection Requests | `/connection-requests` | `GET /me/connections/requests` |

### 3.8 Utility Screens

| Screen | Route | API Calls |
|--------|-------|-----------|
| Saved | `/saved` | `GET /me/saved`, `POST /me/saved`, `DELETE /me/saved` |
| Activity Hub | `/activity-hub` | `GET /me/activity` |
| Notifications | `/notifications` | `GET /me/notifications`, `PATCH /me/notifications/:id/read` |
| Settings | `/settings` | `GET /me/settings`, `PUT /me/settings` |
| Help & Support | `/help-support` | None (external link likely) |
| Create Post | `/create-post` | `POST /posts` |
| Post Detail | `/post-detail/:id` | `GET /posts/:id`, `POST /posts/:id/like` |
| Chat List | `/chat-list` | `GET /me/conversations` |
| Chat Screen | `/chat-screen` | `GET /conversations/:id`, `POST /conversations/:id/messages` |

### 3.9 Admin Screens

| Screen | Route | API Calls |
|--------|-------|-----------|
| Admin Login | `/admin/login` | `POST /admin/login`, `POST /admin/verify-2fa` |
| Admin Dashboard | `/admin/dashboard` | `GET /admin/dashboard` |
| Manage Users | `/admin/users` | `GET /admin/users` |
| User Verify | `/admin/users/:id/verify` | `POST /admin/users/:id/verify` |
| Pending Approvals | `/admin/approvals` | `GET /admin/approvals` |
| Moderation Queue | `/admin/moderation` | `GET /admin/moderation/queue` |
| Report Detail | `/admin/reports/:id` | `GET /admin/moderation/reports/:id`, `POST /admin/moderation/reports/:id/approve` |
| Platform Reports | `/admin/reports` | `GET /admin/reports` |
| Opportunity Approval | `/admin/opportunities` | `GET /admin/opportunities`, `POST /admin/opportunities/:id/approve` |
| Opp Review Detail | `/admin/opportunities/:id` | `GET /admin/opportunities/:id` |
| Compose Notification | `/admin/notifications/compose` | `POST /admin/notifications` |
| Notification Targeting | `/admin/notifications/targeting` | (targeting UI) |

---

## Part 4: API Alignment Fixes Required

### 4.1 Critical Fixes

#### Fix #1: Auth Provider vs API Spec Mismatch
**Problem**: `auth_provider.dart` uses `verifyEmail` with token but API spec says `verify-otp`.

**Current Code** (lines 95-108):
```dart
Future<void> verifyEmail(String token) async {
  // Uses /auth/verify-email
}
Future<void> verifyOtp({required String email, required String otp}) async {
  await verifyEmail(otp);  // Calls verifyEmail with OTP as token!
}
```

**Recommended**: Align with actual backend implementation. Either:
- Update API spec to say `POST /auth/verify-email` with token
- Or update code to call `POST /auth/verify-otp` with email+code

#### Fix #2: Missing Onboarding-2 Screen Import
**Problem**: Router defines `/onboarding-2` route but `OnboardingSkillLocationScreen` is not imported.

**Current** (router.dart line 172):
```dart
GoRoute(path: '/onboarding-2', builder: (context, state) => const OnboardingSkillLocationScreen()),
```

**Fix**: Add import:
```dart
import '.../onboarding_skill_location_screen.dart';
```

#### Fix #3: Discover Route Missing
**Problem**: `_calculateSelectedIndex` checks for `/discover` but no route exists.

**Current** (router.dart line 283):
```dart
GoRoute(path: '/discover', builder: (context, state) => const DiscoverScreen()),
```

**Fix**: Already exists, just not imported. Add import.

#### Fix #4: Inconsistent Enquiry Subject Types
**Problem**: API spec says `subject_type: sponsorship_application` for sponsor replies, but code may not handle this.

**Spec** (API-Specification.md line 240):
```
subject_type: coach_profile, academy, sponsorship_application
```

**Fix**: Ensure frontend passes correct `subject_type` based on context.

#### Fix #5: Shortlist Endpoint Path Inconsistency
**Problem**: API spec says `POST /me/shortlist` with body `{item_type, item_id}` but code may expect different format.

**Spec** (line 378):
```json
POST /me/shortlist { "item_type": "athlete", "item_id": 5 }
```

**Code should match**: Verify `athlete_discovery_screen.dart` and `shortlist_screen.dart` use correct payload.

### 4.2 Recommended Router Updates

Add these missing imports and verify routes:
```dart
// MISSING IMPORTS
import 'package:sportx_app/features/onboarding/presentation/screens/onboarding_skill_location_screen.dart';
import 'package:sportx_app/features/home/presentation/screens/discover_screen.dart';
import 'package:sportx_app/features/search/presentation/screens/search_filter_screen.dart';
```

---

## Part 5: Bottom Navigation Shell Behavior

```
┌─────────────────────────────────────────────────────────────────────┐
│                    BOTTOM NAV SHELL                                  │
│                                                                      │
│   All authenticated users (any role) share this shell:              │
│                                                                      │
│   ┌────────┬────────┬────────┬────────┬────────┐                    │
│   │  Home  │ Search │ Saved  │Activity│Profile │                    │
│   │  /home │/search │ /saved │/activ- │/profile│                    │
│   │        │        │        │  ity   │        │                    │
│   └────────┴────────┴────────┴────────┴────────┘                    │
│                                                                      │
│   • Role-specific tools accessed via Profile tab "Quick Links"        │
│   • Admin has SEPARATE navigation (not in this shell)                 │
│   • Shell persists during all role-specific flows                     │
│                                                                      │
│   Navigator Behavior:                                                │
│   - Tab tap = context.go() (replaces, not stacks)                     │
│   - Deep links = normal push onto navigator stack                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Part 6: Quick Reference - Role Landing Pages

| Role | Landing Page | Route | After Onboarding |
|------|-------------|-------|------------------|
| Athlete | Home | `/home` | Bottom nav shell |
| Coach | Coach Dashboard | `/coach-dashboard` | From Profile tab |
| Academy | Academy Dashboard | `/academy-dashboard` | From Profile tab |
| Organizer | Organizer Dashboard | `/organizer-dashboard` | From Profile tab |
| Sponsor | Sponsor Dashboard | `/sponsor-dashboard` | From Profile tab |
| Admin | Admin Dashboard | `/admin/dashboard` | Separate portal, no bottom nav |

---

## Appendix: File Locations

| Concern | File Path |
|---------|-----------|
| Router & Navigation | `sportx_app/lib/core/router.dart` |
| Auth State | `sportx_app/lib/features/auth/presentation/providers/auth_provider.dart` |
| API Client | `sportx_app/lib/core/utils/api_client.dart` |
| System Flows | `docs/System-Flow.md` |
| Mobile App Flows | `docs/Mobile-App-Flow.md` |
| API Specification | `docs/API-Specification.md` |
