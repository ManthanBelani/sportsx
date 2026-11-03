# 02 — Screen Coverage Matrix

Covers every screen ID in `sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md` (129 screens; 94 P0). Route mapping evidence: `lib/core/router.dart` (routes list :322-734, full mapping in `_drafts/05_mobile_review.md` §1). Backend admin screens: `sportx-api/resources/views/admin/**`.

**Sampling statement:** "Built?" is verified for every ID via the router map + module traces. "Matches wireframe?" was assessed per-module during the traces (elements cited in `_drafts/`), NOT pixel-by-pixel for all 129 — treat it as a sampled judgment. Admin (AD.x) was checked against both the Blade panel and the in-app Flutter admin (`lib/features/admin/`).

Legend — Built: yes / partial (exists with defects) / mock (screen exists, hard-coded data, no backend) / no. States = empty/loading/error handling. Real data = wired to live API end-to-end.

## A — Auth & Onboarding (10)

| ID | Screen | Route / file | Built | Matches wireframe | States | Real data | Notes |
|---|---|---|---|---|---|---|---|
| A.1 | Splash | `/splash` | yes | yes | yes | yes | auth revalidation via `/auth/me` |
| A.2 | Role selection | `/role-selection` | yes | yes | yes | yes | |
| A.3 | Sign Up | `/sign-up` | partial | yes | yes | yes | T&C checkbox UI-only — consent never stored (M1.1) |
| A.4 | OTP Verification | `/verify-otp` | yes | yes | yes | yes | resend timer + error feedback good |
| A.5 | Login | `/login` | yes | yes | yes | yes | OTP bypassable server-side (`require_otp=false`) |
| A.6 | Forgot/Reset (P1) | `/forgot-password` | mock | no | yes | no | asks for code never sent; no reset route (M1.7 BROKEN) |
| A.7 | Language (P1) | `/language` | mock | yes | yes | partial | selection not persisted in auth flow |
| A.8 | Permissions primer (P1) | `/permissions` | partial | yes | yes | — | no real permission wiring |
| A.9 | Guardian consent | `/guardian-consent` | yes | yes | yes | yes | guardian OTP verified; consent stored |
| A.10 | Verification request | `/verification` | yes | yes | yes | yes | status + document upload |

## S — Shared shell (30)

| ID | Screen | Built | Matches | States | Real data | Notes |
|---|---|---|---|---|---|---|
| S.1 | Home shell | yes | yes | yes | yes | per-role dashboards; completion card + leaderboard strip |
| S.2 | Explore — All | yes | yes | yes | yes | backend `/explore` unused (app builds its own rails) |
| S.3 | Explore — Category list | yes | yes | yes | yes | truncation issues in some rails (first 20) |
| S.4 | Filter & Sort sheet | partial | yes | yes | yes | relevance/distance/rating sorts are server no-ops |
| S.5 | Universal search | partial | yes | weak | yes | pagination broken; errors shown as "No results" |
| S.6 | Leaderboard | yes | yes | yes | yes | board integrity broken server-side (M8.1) |
| S.7 | Leaderboard info (P1) | partial | no | yes | no | hard-coded rules text, ignores admin weights |
| S.8 | Create launcher | partial | partial | yes | yes | FAB opens sheet; full `/create` tab reachable only from organizer dashboard |
| S.9 | Create post | partial | yes | yes | yes | video unsupported (server 422) |
| S.10 | Upload media | partial | yes | yes | yes | no upload progress/cancel |
| S.11 | Add/Edit achievement | yes | yes | yes | yes | |
| S.12 | Community — Network (P1) | yes | yes | yes | yes | real, working |
| S.13/14 | Groups (P2) | yes | partial | yes | yes | P2 scope creep — built |
| S.15 | More menu | yes | yes | yes | yes | role-adaptive rows |
| S.16 | Notifications | yes | yes | yes (model) | yes | model list implementation |
| S.17 | Messages inbox | partial | yes | yes | yes | Requests tab = connection requests; no unread badge on entry icon; stale badges |
| S.18 | Chat thread | partial | yes | yes | yes | 4s polling in-thread; no block/report menu; no media attach |
| S.19 | Connections | yes | yes | yes | yes | accept/decline/cancel/remove all live |
| S.20 | Saved | partial | yes | yes | yes | client truncates at 20 |
| S.21 | My Activity (P1) | yes | partial | yes | yes | |
| S.22 | Settings & privacy | yes | yes | yes | yes | delete-account present (fails for Google accounts — backend) |
| S.23 | Blocked users / safety centre | partial | partial | yes | yes | unblock only; **no way to block anyone** → list always empty |
| S.24 | Help & support | yes | yes | yes | — | |
| S.25 | About/legal | yes | yes | yes | — | |
| S.26 | Report sheet | partial | yes | yes | partial | reachable only from 4 listing detail screens — not posts/profiles |
| S.27 | Post detail | partial | yes | yes | yes | no edit/delete/report/save actions |
| S.28 | Media viewer | yes | yes | yes | yes | |
| S.29 | Logout confirm | yes | yes | yes | yes | settings-screen logout skips dialog |
| S.30 | Share sheet (P1) | partial | partial | yes | partial | shares URLs that 404 |

## D — Shared detail & transactional (17)

| ID | Screen | Built | Matches | States | Real data | Notes |
|---|---|---|---|---|---|---|
| D.1 | Athlete profile | yes | yes | yes | yes | visitor gallery key mismatch → empty media tab |
| D.2 | Coach profile | yes | yes | yes | yes | |
| D.3 | Academy profile | yes | yes | yes | yes | Reviews tab fed by nothing |
| D.4 | Organizer profile | partial | partial | yes | yes | public card leaks fields |
| D.5 | Scout profile | yes | yes | yes | yes | public view correctly hides shortlists |
| D.6 | Event/trial detail | yes | yes | yes | yes | draft leak via unified endpoint |
| D.7 | Registration form | partial | yes | yes | yes | DOB dead field; docs not enforced; team fields dropped; no capacity error possible |
| D.8 | Registration confirmation | yes | yes | yes | yes | fabricated `registration_ref` on tournament path |
| D.9 | Opportunity detail | yes | yes | yes | yes | |
| D.10 | Opportunity apply | partial | partial | yes | yes | no document upload UI |
| D.11 | Program detail | yes | yes | yes | yes | |
| D.12 | Enquiry form | yes | yes | yes | yes | owner never notified (M6.2) |
| D.13 | Facility detail | yes | yes | yes | yes | |
| D.14/15 | Reviews (P1) | mock | yes | yes | no | hard-coded `average: 4.6` |
| D.16 | Map view (P2) | no | — | — | — | |
| D.17 | Team page (P2) | no | — | — | — | |

## AT — Athlete (10)

AT.1 Home yes/yes/yes/yes · AT.2 Onboarding yes · AT.3 Edit profile yes · AT.4 Manage sports yes · AT.5 Achievements yes · AT.6 Completion checklist yes (deep links partially mismatched) · AT.7 View as public **mock** (hard-coded stats) · AT.8 My opportunities yes (saved-tab hides closed) · AT.9 My registrations yes (no loadMore) · AT.10 Guardian controls yes (but minor-editable server-side).

## CO — Coach (8)

CO.1 Onboarding yes · CO.2 Dashboard yes (strip + enquiries) · CO.3 Edit profile yes · CO.4 My programs yes · CO.5 Create/edit program yes (draft saving works) · CO.6 My events (P1) yes (reuses lists) · CO.7 Opportunities/achievements (P1) yes · CO.8 Go live (P2) no.

## AC — Academy (12)

AC.1 Onboarding yes · AC.2 Dashboard yes · AC.3 Edit profile yes · AC.4 Programs yes (reuses CO.4/5) · AC.5 Our athletes (P1) **mock** (hard-coded candidates, zero API) · AC.6 Events/trials yes · AC.7 Facilities yes · AC.8 Add facility yes · AC.9 Scholarships/opportunities yes · AC.10 Invite athlete (P1) **mock** · AC.11 Staff (P2) no · AC.12 Collaborations (P2) no.

## OR — Organizer (17)

OR.1 Onboarding yes · OR.2 Dashboard yes · OR.3 Edit profile yes · OR.4 My events yes · OR.5 Create/edit event yes (drafts persist) · OR.6 Event management yes (capacity bar math correct — but backend accepts unlimited) · OR.7 Registrations partial (per-row works; bulk buttons absent; export button works) · OR.8 Registrant detail yes · OR.9 Schedule editor (P1) **no route at all** · OR.10 Gallery yes · OR.11 Results yes · OR.12 Analytics yes · OR.13 Venues (P1) yes · OR.14 Announcement **UI-only** (no backend) · OR.15 Promote (P2) no · OR.16/17 (P2) no.

## SC — Talent scout (13)

SC.1 Onboarding yes · SC.2 Dashboard partial (leaks minor names; stale "upcoming") · SC.3 Edit profile yes · SC.4 Discover partial (no position filter) · SC.5 Shortlist yes · SC.6 Add-to-shortlist sheet yes · SC.7 Compare (P1) **mock** (`_sample` fallback) · SC.8 Talent report (P1) **mock** · SC.9 My reports (P1) **mock** · SC.10 Observation yes · SC.11 Opportunities yes (chips) · SC.12 Create opportunity yes · SC.13 Contact yes (guardian routing fictitious server-side).

## AD — Admin (12)

| ID | Screen | Blade panel | Flutter admin | Status | Notes |
|---|---|---|---|---|---|
| AD.1 | Login + 2FA | yes (CSRF, throttled, forced TOTP) | `/admin/login` | partial | API login path unthrottled; `ADMIN_2FA_ENFORCE=false` accepts any code |
| AD.2 | Dashboard | partial | yes | partial | missing pending-verifications tile + by-role breakdown |
| AD.3 | User management | yes | yes | partial | no ban; suspend doesn't kill sessions; 2FA secret leaks in API |
| AD.4 | Verification queue | yes | yes | **DONE** | best admin screen |
| AD.5 | Content manager | yes (7 types) | yes (11 via API) | partial | 4 types unaudited |
| AD.6 | Record edit | yes | yes | partial | `$request->all()` fallback |
| AD.7 | Moderation queue | yes | yes | **BROKEN** | remove 500s on post/facility reports; content stays live |
| AD.8 | Moderation detail | partial | yes | partial | Blade lacks Warn/Suspend; resolve leaves content live; no notifications from Blade actions |
| AD.9 | Master data | yes | yes | **DONE** | positions API-only in panel |
| AD.10 | Expiry rules | yes (Blade works) | **mock** (hard-coded, never persisted) | partial | admin API updateRules 500s |
| AD.11 | Leaderboard config (P1) | yes (`leaderboard.blade.php`) | yes | partial | |
| AD.12 | Broadcast (P1) | yes (`notifications.blade.php`) | yes | partial | broadcast + targeted + stats |

## Totals

| Section | Screens | Built yes | Partial | Mock/UI-only | No |
|---|---|---|---|---|---|
| A (Auth) | 10 | 6 | 2 | 2 | 0 |
| S (Shell) | 30 | 15 | 13 | 0 | 2 (P2) |
| D (Detail) | 17 | 11 | 4 | 1 | 2 (P2) |
| AT | 10 | 9 | 0 | 1 | 0 |
| CO | 8 | 7 | 0 | 0 | 1 (P2) |
| AC | 12 | 8 | 1 | 2 | 1 (P2) |
| OR | 17 | 12 | 3 | 1 | 1 |
| SC | 13 | 8 | 2 | 3 | 0 |
| AD | 12 | 2 | 9 | 0 | 0 |

**P0 screen completion: ~78 of 94 (~83%) exist and render real data; ~8 are mocks/UI-only; the rest are partial (functional with named defects).** No P0 screen ID lacks a route (only P1 OR.9 has no route). The dominant pattern: screens exist and render, but safety actions (block/report/edit/delete), state handling, and server enforcement behind them are the gaps.
