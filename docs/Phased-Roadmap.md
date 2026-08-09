# Phased Roadmap — SportX India

Break the build into demo-able phases. Each phase has a feature list and a clear "client can see/test" milestone. Payments are **excluded** (stakeholder decision). Admin is fully documented but scheduled in a later phase.

> **Assumptions**
> - Each phase is ~4–6 weeks with a small team (assumption — AS-46; actual timeline depends on team size and velocity).
> - Phases build on each other sequentially; overlap between phases is possible but not assumed.
> - "Client can see/test" means a demoable APK/web build with the listed features working end-to-end on dev/staging.

---

## Phase 0 — Project Foundation (Week 1)

> Not a demo-able phase, but a prerequisite for all phases.

| # | Task | Deliverable |
|---|---|---|
| P0-1 | Laravel project scaffolding + config | `composer create-project`, `.env` setup, `config/sportx.php`, CORS, Sanctum |
| P0-2 | Database migrations (all tables) | Full schema per `Database-Design.md` migration order |
| P0-3 | Master data seeders | Sports, cities, age groups, expiry rules |
| P0-4 | Flutter project scaffolding | `flutter create`, folder structure per `Mobile-Architecture.md`, Dio setup, go_router shell |
| P0-5 | API auth endpoints (register, OTP, login, logout) | Working auth flow: email OTP → token → logout |
| P0-6 | Onboarding endpoints (all 5 roles) | Post-verify profile creation per role |
| P0-7 | CI/CD skeleton (GitHub Actions / equivalent) | Lint + test on push; staging deploy on merge |
| P0-8 | Dev data seeding script | Seed sample academies, coaches, trials for testing |

**Milestone:** Flutter app can sign up → verify OTP → complete onboarding for any role → get token → hit a test API endpoint. Laravel has all migrations running and seeds loaded.

---

## Phase 1 — Foundation & Discovery

> **Duration target:** ~5 weeks
> **Milestone:** Client can browse the full app as an athlete: search, filter, view listings, save/bookmark, report a listing, and manage their own profile with media. No transactions yet.

### Feature List

| # | Feature | FR References | Screens |
|---|---|---|---|
| P1-1 | **Auth UI:** Splash (S1), Role Selection (S2), Sign Up (S3), OTP Verify (S4), Login (S5) | FR-AUTH-1–5 | S1–S5 |
| P1-2 | **Athlete onboarding:** Sport + age group (A1), skill level + city (A2) → Home dashboard (A3) | FR-AUTH-6 | A1–A3 |
| P1-3 | **Athlete profile:** View (A4), edit (A5), media gallery upload/delete/reorder (A6) | FR-ATH-1,2 | A4–A6 |
| P1-4 | **Coach onboarding** (C1) + **Coach profile creation/edit** (C2) | FR-AUTH-7, FR-COACH-1 | C1–C2 |
| P1-5 | **Academy onboarding** (AC1) + **Academy listing creation/edit** (AC2) | FR-AUTH-8, FR-ACAD-1 | AC1–AC2 |
| P1-6 | **Universal search:** Search screen (S6), unified results with category tabs (S7) | FR-DISC-1,2 | S6–S7 |
| P1-7 | **Global filters:** Filter panel (S8) — sport, city, age group, price range, date range | FR-DISC-3,4 | S8 |
| P1-8 | **Academy directory:** List (A7/T1) + detail page (A8/T2) | FR-ATH-4 | A7–A8 |
| P1-9 | **Coach directory:** List (A9/T1) + detail page (A10/T2) | FR-ATH-5 | A9–A10 |
| P1-10 | **Trial listings:** List (A12/T1) + detail page (A13/T2) | FR-ATH-7 | A12–A13 |
| P1-11 | **Tournament calendar:** Calendar/list toggle (A16) + detail page (A17/T2) | FR-ATH-9 | A16–A17 |
| P1-12 | **Scholarship feed:** List (A19/T1) + detail page (A20/T2 with external link) | FR-ATH-11 | A19–A20 |
| P1-13 | **Sponsorship opportunities:** List (A21/T1) + detail page (A22/T2) | FR-ATH-12 | A21–A22 |
| P1-13b | **Sports venue directory:** List + detail page (new from Mandatory Fields PDF — AS-47). Uses T1/T2 templates. | AS-47 | New screens |
| P1-14 | **Saved/bookmarked items:** Save from detail (T2 ♡), saved items list (A25) | FR-ATH-15 | A25 |
| P1-15 | **Report a listing:** Report modal (S10) | FR-TRUST-1 | S10 |
| P1-16 | **Bottom navigation bar** — Home / Search / Saved / Profile shell | FR-PLAT-3 | T1 etc. |
| P1-17 | **Settings shell:** Edit profile link, logout, delete account | FR-PLAT-1 | S11 |

### "Client Can See / Test"

1. Sign up as Athlete, complete onboarding, land on Home dashboard with recommended cards.
2. Search "cricket ahmedabad" → see results across categories → switch tabs.
3. Open Academy detail → see facilities, coaches, fees, location → save it → see it in Saved.
4. Open Trial detail → see eligibility, entry fee, documents required → report it → confirm report submitted.
5. Edit profile → add achievement → upload photo → reorder → view updated profile.
6. Sign up as Coach → create listing → see it in Coach Directory.
7. Sign up as Academy → create listing → see it in Academy Directory.
8. Browse Sports Venues → filter by sport/city → see venue details with Google Maps link.

---

## Phase 2 — Actions & Supply Side

> **Duration target:** ~6 weeks
> **Milestone:** Athletes can take actions (register, enquire, apply), providers can manage their listings and interact with athletes, and everyone can track their activity.

### Feature List

| # | Feature | FR References | Screens |
|---|---|---|---|
| P2-1 | **Enquire with coach/academy** — modal form (A11/T3) | FR-ATH-6 | A11 |
| P2-2 | **Coach enquiry inbox** (C4) + reply (C5) | FR-COACH-3,4 | C4, C5 |
| P2-3 | **Trial registration** — form (A14/T3) + confirmation (A15) | FR-ATH-8 | A14, A15 |
| P2-4 | **Tournament registration** — form (A18/T3) | FR-ATH-10 | A18 |
| P2-5 | **Apply/pitch to sponsor** — form (A23/T3) | FR-ATH-13 | A23 |
| P2-6 | **My Activity Hub** — tabs: trials, tournaments, sponsorships with status (A24) | FR-ATH-14 | A24 |
| P2-7 | **Academy trial posting** — create/edit/publish/close (AC4) + My Trials list (AC5) | FR-ACAD-3,4 | AC4, AC5 |
| P2-8 | **Academy registrant management** — list (AC6) + detail (AC7) + verify/reject | FR-ACAD-5,6 | AC6, AC7 |
| P2-9 | **Academy enquiry inbox** (AC8) + reply (AC9) | FR-ACAD-7 | AC8, AC9 |
| P2-10 | **Organizer onboarding** (O1) + **dashboard** (O2) | FR-AUTH-9 | O1, O2 |
| P2-11 | **Organizer trial management** — create/edit/publish/close (O3/O4) | FR-ORG-2 | O3, O4 |
| P2-12 | **Organizer tournament management** — create/edit/publish (O5/O6) | FR-ORG-3,4 | O5, O6 |
| P2-13 | **Organizer registration management** — list per event (O7) + manual payment status flag | FR-ORG-5 | O7 |
| P2-14 | **Organizer capacity/spot management** — per category + waitlist toggle (O8) | FR-ORG-6 | O8 |
| P2-15 | **Organizer results publishing** — form (O9) + public view (O10) | FR-ORG-7,8 | O9, O10 |
| P2-16 | **Sponsor onboarding** (SP1) + **dashboard** (SP2) | FR-AUTH-10 | SP1, SP2 |
| P2-17 | **Sponsorship listing CRUD** — create/edit/publish (SP3) + management list (SP4) | FR-SPON-2,3 | SP3, SP4 |
| P2-18 | **Sponsor athlete discovery** — search/filter athletes (SP5) + profile view (SP6) | FR-SPON-4,5 | SP5, SP6 |
| P2-19 | **Sponsor applications inbox** (SP7) + detail/reply/shortlist/reject (SP8) | FR-SPON-6,7 | SP7, SP8 |
| P2-20 | **Sponsor shortlist** with notes (SP9) | FR-SPON-8 | SP9 |
| P2-21 | **Coach browse mode** — reuse all athlete-facing directory screens | FR-COACH-5 | C6 |

### "Client Can See / Test"

1. Athlete enquires with coach → coach sees it in inbox → replies → athlete gets notification.
2. Athlete registers for a trial → gets confirmation with registration ID → sees "Pending Review" in My Activity.
3. Organizer creates tournament with 3 categories + capacity → athlete registers → organizer sees registration → flips payment status.
4. Organizer publishes results → public results view shows bracket.
5. Sponsor creates sponsorship listing → athlete pitches → sponsor shortlists → shortlist shows with notes.
6. Academy posts trial → athlete registers → academy sees registrant list → verifies documents → athlete sees "Confirmed" in My Activity.

---

## Phase 3 — Admin, Expiry, Reminders

> **Duration target:** ~4 weeks
> **Milestone:** Admins can manage all content, moderate reports, configure and monitor auto-expiry, and manage master data. Athletes receive deadline reminders for saved items.

### Feature List

| # | Feature | FR References | Screens |
|---|---|---|---|
| P3-1 | **Admin login** with 2FA (AD1) + **admin dashboard** (AD2) | FR-ADMIN-1,2 | AD1, AD2 |
| P3-2 | **Content management** — category picker with counts (AD3), content list per category (AD4), create/edit/delete via dynamic form (AD5) | FR-ADMIN-3–5 | AD3–AD5 |
| P3-3 | **Listing moderation** — reported listings queue (AD6) + detail/actions (AD7) | FR-ADMIN-6,7 | AD6, AD7 |
| P3-4 | **Expiry rules configuration** (AD8) — per content type | FR-ADMIN-8 | AD8 |
| P3-5 | **Expiry monitor** (AD9) — pending/expired/overridden tabs + override/restore | FR-ADMIN-9 | AD9 |
| P3-6 | **Category management** — sports, cities, age groups CRUD (AD10–AD12) | FR-ADMIN-10 | AD10–AD12 |
| P3-7 | **Scholarship admin CRUD** — admin creates/maintains scholarships (only source) | FR-ADMIN-11 | AD5 (scholarships tab) |
| P3-8 | **Auto-expiry engine** — scheduled job, expiry events, listing status change | FR-ADMIN-8,9 | Backend |
| P3-9 | **Reminder system** — subscription creation on save/confirm, scheduled delivery | FR-NOTIF-2, FR-ATH-16 | Backend |
| P3-10 | **Notifications center** (S9) — list all alerts, mark read | FR-NOTIF-1 | S9 |
| P3-11 | **Notification toggle** in Settings | FR-NOTIF-4 | S11 |
| P3-12 | **Help center** (S12) — FAQ search, popular topics, contact form | FR-PLAT-2 | S12 |

### "Client Can See / Test"

1. Admin logs in with 2FA → sees dashboard counters → drills into academies list → edits a record → deletes a stale record.
2. User reports an academy listing → admin sees it in moderation queue → reviews → removes listing → owner gets notified.
3. Admin configures expiry rules (trials = 1 day after date) → published trial passes its date → auto-expired in monitor → admin sees it → restores it.
4. Athlete saves a trial with reminder ON → trial date approaches → notification appears in Notifications Center with "2 days before" message.
5. Admin adds a new sport and city → both appear in filters across the app.

---

## Phase 4 — Polish & Scale

> **Duration target:** ~3 weeks
> **Milestone:** Production-ready polish: Google sign-in, refined capacity/waitlist flows, settings completeness, security hardening, and performance optimization.

### Feature List

| # | Feature | FR References | Priority |
|---|---|---|---|
| P4-1 | **Google sign-in** ("Continue with Google" on S3) | FR-AUTH-12 | Should |
| P4-2 | **Forgot password** flow (reset link to email) | S5 | Must |
| P4-3 | **Capacity/waitlist refinement** — auto-promote waitlisted → confirmed when spots free | FR-ORG-6 | Could |
| P4-4 | **Registration confirmation enhancements** — calendar export (.ics) | A15 | Could |
| P4-5 | **Settings completion** — change password, notification prefs toggle, language selector shell | FR-PLAT-1 | Should |
| P4-6 | **Bracket visualization** enhancement — richer bracket rendering beyond basic image | O10 | Could |
| P4-7 | **Search relevance tuning** — trending, recents, relevance weighting | FR-DISC-1 | Could |
| P4-8 | **Security hardening** — rate limiting verification, CORS review, audit log | §Security doc | Must |
| P4-9 | **Performance optimization** — query optimization, index review, pagination tuning | §Performance doc | Should |
| P4-10 | **Monitoring & error tracking setup** — Sentry (or equivalent) + APM | NFR-8 | Should |
| P4-11 | **Load testing** — simulate 1000+ concurrent users, tune DB queries | NFR-3 | Should |
| P4-12 | **Accessibility pass** — screen reader basics, contrast checks, touch targets | NFR-6 | Could |

### "Client Can See / Test"

1. "Continue with Google" works on sign-up → account created, verified, onboarding skipped.
2. User forgets password → reset flow works end-to-end.
3. Tournament with waitlist: athlete waitlisted → organizer adds capacity → athlete auto-promoted → notified.
4. Settings screen: user changes password, toggles notifications, sees language selector (English only).
5. Admin panel loads under simulated load with < 500ms P95 responses.

---

## Phase Summary

| Phase | Duration (target) | Key Deliverable | New Endpoints (approx) |
|---|---|---|---|
| P0 Foundation | 1 week | Working auth + DB + seeds | ~15 (auth + meta) |
| P1 Discovery | 5 weeks | Full browse + search + profile + save/report | ~35 (directories, profile, search, saved, reports) |
| P2 Actions | 6 weeks | All transactions + provider management | ~50 (enquiries, registrations, provider CRUD, activity) |
| P3 Admin + Reminders | 4 weeks | Admin console + expiry + notifications | ~30 (admin, notifications, settings/help) |
| P4 Polish | 3 weeks | Production-ready, Google sign-in, hardening | ~5 (Google OAuth, password reset) |
| **Total** | **~19 weeks** | **Complete MVP** | **~137** |
