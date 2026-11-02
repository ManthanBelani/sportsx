# SportX India — MVP Audit: Progress & Continuation Guide

**Audit started:** 2026-11-02 · **Last updated:** 2026-11-03 · **Branch:** `system-design-change`
**Status: ~55% complete.** 4 of 8 deep-trace runs finished; their full reports are in `_drafts/`. The final 9 report files (00–08) are **not yet written** — remaining work is listed in §4.

**How to resume:** give the auditor this file + the prompt in `sportsx-design-v3/new_design_docs` audit instructions. Remaining traces are one-shot agent prompts, pre-written in §4-C — paste them verbatim, one at a time (platform allows only ONE background agent at a time; parallel launches fail with "user concurrency limit exceeded").

---

## 1. Progress at a glance

| Work item | Status | Output file |
|---|---|---|
| Read source docs (MVP_FEATURE_LIST.md, SCREEN_INVENTORY.md, wireframes) | DONE | — |
| Step 0 project discovery / stack summary | DONE | §3 below |
| Route inventory (routes/api.php fully read) | DONE | §5 below |
| Trace M1 + M12 (auth, onboarding, guardian, account) | DONE | `_drafts/03a_m1_m12_auth_account.md` |
| Trace M2 + M3 (profiles, discovery, search, saved) | DONE | `_drafts/03b_m2_m3_profiles_discovery.md` |
| Trace M4 + M5 (events, registrations, opportunities) | DONE | `_drafts/03c_m4_m5_events_opportunities.md` |
| Backend security / IDOR / secrets sweep | DONE | `_drafts/04b_backend_security.md` |
| Trace M6 + M7 (programs, facilities, feed, chat) | **CANCELLED — rerun** | prompt ready §4-C.1 |
| Trace M8 + M9 + M10 (leaderboard, notifications, scouting) | NOT RUN | prompt ready §4-C.2 |
| Trace M11 (admin panel, moderation, 2FA) | NOT RUN | prompt ready §4-C.3 |
| Flutter cross-cutting mobile review | NOT RUN | prompt ready §4-C.4 |
| Run flutter analyze | DONE — 50 issues (1 error, 2 warnings, 47 info) | §3.6 |
| Run flutter test / build | NOT RUN (flutter available; test/ dir is small) | §4-B |
| Backend tests (php artisan test) | **BLOCKED — PHP not installed on this Windows machine** (no `php` on PATH) | — |
| Step 1 matrices (feature traceability CSV/MD, screen coverage) | NOT STARTED | §4-A |
| Step 2A end-user flow results (12 flows) | NOT STARTED (assemble from module drafts) | §4-A |
| Final reports 00–08 in /audit_report/ | NOT STARTED | §4-A |

Confirmed-so-far severity snapshot: **4+ BLOCKER** items (see §2). Expect more from M6/M7 (chat rules) and M8–M11.

---

## 2. Findings so far (consolidated, with evidence)

> Full detail per module is in the `_drafts/` files — those are the authoritative evidence records. This section is the condensed cross-module view for the eventual executive summary.

### BLOCKERs (must fix before launch)

| # | Finding | Evidence |
|---|---|---|
| B-1 | **Registration capacity is never enforced.** `RegistrationController::storeTrial()` (L21–94) and `storeTournament()` (L298–370) check only status/deadline. No vacancy comparison, no per-category capacity check, no `lockForUpdate`. A 10-slot event accepts unlimited registrations. MVP rule 6 unmet. | `sportx-api/app/Http/Controllers/RegistrationController.php`; capacity appears only in read/update endpoints (L465–501) |
| B-2 | **Release signing keystore committed to git.** Anyone with repo access can sign malicious app updates. | `my-release-key.jks` in `git ls-files` (commit 251082b), repo root |
| B-3 | **Live credentials committed.** `CREDENTIALS.md` contains real `APP_KEY` (`base64:GS4p4UN9…`), DB `root`/`password`, tunnel URL. `sportx-api/TEST_CREDENTIALS.md` (tracked) publishes all seed passwords + seeded admin TOTP secret `JBSWY3DPEHPK3PXP`. Rotate APP_KEY + DB password, purge history. | repo root `CREDENTIALS.md`, `sportx-api/TEST_CREDENTIALS.md` |
| B-4 | **Suspended/pending users keep full API access.** `AdminUserController::suspend()` (L72–76) sets status but never deletes tokens; no status-check middleware exists anywhere (`bootstrap/app.php` registers none); `config/sanctum.php:53` `'expiration' => null` — tokens never expire. Comment in `AuthController.php:66` claims a write-blocking middleware exists — it does not. | backend security draft §B3 |
| B-5 | **Login OTP is client-controlled.** `AuthController.php:194-196`: `$enforceOtp = $request->has('require_otp') ? $request->boolean('require_otp') : !runningUnitTests()`. Client sends `require_otp=false` → token with password alone. | `_drafts/04b_backend_security.md` H1 |
| B-6 | **Verification/ID documents stored on PUBLIC disk.** `MediaController.php:266/272` stores all uploads (incl. blue-check proof docs) to the `public` disk; `MediaItem::url()` returns `/storage/...` — unauthenticated-fetchable. Signed-URL access control is theater for public files. | `_drafts/04b_backend_security.md` H3, `_drafts/03b` finding 1 |

### HIGH findings

| # | Finding | Evidence |
|---|---|---|
| H-1 | **Guardian controls editable by the minor.** `PUT /me/guardian-controls` (routes/api.php:149, GuardianController.php:184–207) requires only the athlete's own session → a minor can unlock their own DMs (`allow_messages`) and public profile. Chat gate + privacy floor + leaderboard masking themselves are enforced. | `_drafts/03a` finding 4 |
| H-2 | **T&C/privacy consent never captured.** Checkbox gates submit only; nothing sent to API; no consent column in any migration. Also: password registration auto-verifies email (`AuthController.php:62`), making verify/resend dead code; phone/SMS OTP unavailable (OtpService throws for non-email) — "phone or email" is email-only. | `_drafts/03a` finding 3 |
| H-3 | **Forgot-password flow broken end-to-end.** Backend emails a 64-char token as a link to `/reset-password?token=…`; Flutter router has no `/reset-password` route; the reset screen asks for a short "code" that is never sent. | `AuthController.php:339`, `PasswordResetMail.php:20-30`, `forgot_password_screen.dart:29,57-60` |
| H-4 | **Delete account fails for Google-only users** (password Hash::check on a null password → permanent 401). Media files on disk not purged; Sanctum tokens orphaned. In-app UI exists. | `SettingsController::destroy`, `GoogleAuthController` (password null) |
| H-5 | **Analytics (M12.6) is vaporware.** `logAnalyticsEvent()` defined but zero call sites in the app; Sentry removed from pubspec ("broke Android debug build"). No funnel events, no crash reporting. | `notification_prefs_provider.dart:46-57`, `pubspec.yaml:36`, `main.dart:12-15` |
| H-6 | **`who_can_connect` privacy setting never enforced.** Stored by PrivacyController (minors default `nobody`), zero references in ConnectionController/ScoutConnectionController → anyone can connect with a minor. `who_can_message` IS enforced. Coach/academy/organizer/scout detail endpoints have NO visibility enforcement; `/coaches`, `/academies` are public unauthenticated. | `PrivacyController.php:24-65`, `routes/api.php:181-184` |
| H-7 | **Athlete discovery leaks email/phone (incl. minors)** via nested `user` relation — `maskMinor()` strips athlete's own phone/DOB but not `user->email/phone`. `DirectoryController` correctly does `unsetRelation('user')` — discovery doesn't. | `AthleteDiscoveryController.php:60,132`, `User.php:24` |
| H-8 | **"View as Public"/share is fully mocked; share links 404.** Hard-coded stats in `view_as_public_screen.dart:78-83`; share URLs `https://sportx.in/profile/{id}` but routes/web.php serves only `/` and `/panel/*`. No public athlete profile endpoint. | `_drafts/03b` finding 3 |
| H-9 | **Bulk approve/reject is API-only.** Flutter has checkboxes feeding nothing (`registration_management_screen.dart:715-743`); no bulk button. API `bulk()` builds a sub-request whose `QUERY_STRING` type-pinning silently fails (Symfony overwrites QUERY_STRING). Bulk reject without reason fails every row. | `EventRegistrationController.php:190-234`, `_drafts/03c` |
| H-10 | **Opportunity apply: document upload not wired** (API accepts `document_media_ids`, Flutter UI has none); no dedupe unique index on `opportunity_applications`. | `OpportunityController.php:204-208`, `_drafts/03c` |
| H-11 | **Tournaments have no `required_documents`; trial form collects DOB but never sends it** (age screening impossible); tournament registration fabricates `registration_ref` client-side and sends team fields the API validation silently drops. Athletes can self-declare `payment_status=paid`. | `trial_registration_screen.dart:70-75`, `tournament_registration_screen.dart:81`, `RegistrationController.php:305-311` |
| H-12 | **Draft events leak** via unified `EventController::show()` (L93–106) — `Trial::find($id)` with no status filter; any authed user can read draft trials. | `_drafts/03c` M4.2 |
| H-13 | **Registration outcome notifications use type `status_update`**, which misses the `HARD_OVERRIDE_TYPES` list (`registration_approved/rejected`) → user prefs can suppress registration outcomes. | `NotificationService.php:14-19`, `_drafts/03c` M4.6 |

### MEDIUMs (headline items)

- Export CSV works but thin (`id, athlete, status, payment_status, created_at` only; UI hint about selection misleading) — M4.5 PARTIAL.
- Auto-expiry DONE (SweepExpiredContentJob hourly, ExpiryRule-driven, idempotent) but owners never notified and editing an event date doesn't reschedule the pending expiry event.
- Universal search pagination broken end-to-end (fixed `limit()->get()`, client reads `meta.current_page` that never exists → loadMore dead); search errors render as "No results found"; legacy scholarship/sponsorship groups still query 410'd tables.
- Saved list truncates at 20 (no pagination client-side; `isSaved()` wrong beyond 20).
- Near-me / distance (M3.8) NOT STARTED — no lat/lng columns, no geo logic, `sort=distance` accepted and silently ignored. Ratings/reviews (M2.12) NOT STARTED at every layer.
- Fee filters compare numerically against string columns (`fee_structure`/`fee_range`).
- Language selection never saved in auth flow; backend validates only `en,hi` (Gujarati would 422); no l10n framework.
- Sanctum tokens never expire; password change doesn't invalidate other sessions; settings-screen logout skips confirmation dialog.
- Deep links: share URLs dead (no app-links intent filter, AndroidManifest.xml:26-29 launcher only).
- No offline detection anywhere (no connectivity_plus).
- Admin API login + 2FA verify unthrottled (`routes/api.php:640-645`); TOTP ±1 window brute-forceable online; TOTP secret stored plaintext; `ADMIN_2FA_ENFORCE=false` accepts any 6 digits.
- No global API rate limit; no TrustProxies (throttle keys collapse onto proxy IP behind tunnel); reset/verification tokens unhashed in DB; CORS defaults `*` when unset; no HTTPS forcing/HSTS; no DB backups; Sentry wired but disabled.
- Reset-password: backend logic fine (60-min expiry, token revocation) but UI path broken (H-3).
- Organizer public card returns raw `toArray()` incl. `registration_number`, `verification_doc_media_id`.
- Flutter analyze: 50 issues — 1 error (`chat_provider.dart:111` — `FutureProviderRef` passed where `WidgetRef` expected), 2 warnings, 47 info.

### Verified GOOD (positive findings, evidence-backed)

- OTP pipeline strong: bcrypt-hashed codes, 10-min expiry + replay burn, 5 attempts, 5/hour send cap per destination, 60s resend cooldown, uniform anti-enumeration errors, never logged. (`OtpService.php`, `OtpController.php:289-315`)
- IDOR sweep of ~22 endpoint families: **no missing ownership checks found** (registrations approve/reject, conversations, scout shortlists/observations, notifications, saved items, media signed-urls, opportunity review, enrollment, results, posts).
- One-account-one-role enforced server-side (role set only at creation; no endpoint mutates `users.role`; onboarding aborts on role mismatch).
- Verification/blue-check: admin-only approve under `auth:sanctum + role:admin + admin.2fa`, ownership checks, notification on decision.
- Tokens in `flutter_secure_storage`; logout revokes Sanctum token, deactivates device tokens, unregisters FCM, clears storage.
- Media upload validation: content-sniffed MIME allowlist, 10MB cap, quota enforced in-transaction, no SVG.
- No SQL injection found (only guarded `orderByRaw`); Blade panel has session auth + role + 2FA + CSRF + throttled login; Horizon installed but NOT mounted.
- Follow/connection state machines DB-unique-protected; trial/tournament duplicate registration unique-index protected (app 409 check sits outside transaction → race yields 500, not 409).
- Fees display-only confirmed (no payment gateway anywhere).
- Auto-expiry job exists, scheduled hourly, idempotent, admin CRUD + override/restore present.
- Profiles/discovery substantially real (strongest area); empty/loading/retry states present on directory screens.

---

## 3. Step 0 — Project summary (for 00_EXECUTIVE_SUMMARY)

### 3.1 Repo layout
- `sportx_app/` — Flutter mobile app (280 Dart files, 23 feature folders)
- `sportx-api/` — Laravel 13 API + Blade admin panel (`resources/views/admin/`)
- `informative-site/` — static info site (no deep-link handling found)
- `sportsx-design-v1/v2/v3/` — design HTML prototypes; **source of truth docs in `sportsx-design-v3/new_design_docs/`** (MVP_FEATURE_LIST.md, SCREEN_INVENTORY.md, 01–06 role wireframes)
- `docs/` — older spec set (PRD, ER diagrams, API spec)
- Root also has: `my-release-key.jks` (committed!), `CREDENTIALS.md` (committed!), prior audits (`PRODUCTION_READINESS_AUDIT_2026-11-02.md` etc.)

### 3.2 Tech stack
- **Mobile:** Flutter 3.44.9 (Dart SDK ^3.10), Riverpod 2.5 + riverpod_annotation, go_router 14.3, dio 5.7 (+pretty_dio_logger), flutter_secure_storage, image_picker, FCM (firebase_messaging 15.1), flutter_local_notifications, google_sign_in, flutter_dotenv, cached_network_image, pull_to_refresh, shimmer. **No Sentry** (removed), **no connectivity_plus** (no offline detection), **no geolocator** (no near-me).
- **Backend:** Laravel 13.8 / PHP 8.3, Sanctum 4.3 (tokens, `expiration => null`), Horizon installed-but-unmounted, Sentry SDK wired (disabled in env), intervention/image, Blade admin panel. DB: MySQL in real `.env` (sqlite in example). Queue: `database` driver. Filesystem: `local`/`public` disk — **no S3**.
- **Jobs (routes/console.php):** SweepExpiredContentJob hourly · SendDueRemindersJob 15-min · PurgeExpiredOtpsJob daily · PruneOldMessagesJob daily (90-day chat purge) · PruneStaleDeviceTokensJob + PruneNotificationRowsJob daily · RecalculateLeaderboardJob nightly 04:00 · mail:probe + notifications:monitor hourly.
- **Hosting/config reality:** `.env` APP_URL is an **ngrok tunnel** (`movable-washstand-ungraded.ngrok-free.dev`); Flutter `.env` API_BASE_URL points at the same tunnel (+ commented raw-IP http URL). APP_ENV=local, APP_DEBUG=true. This is a dev setup being treated as production.

### 3.3 Build/run
- Backend: `php artisan serve` + `queue:listen` (composer dev script); no PHP on this machine → **backend tests could not run**.
- Mobile: `flutter run` / `flutter build apk`; `flutter analyze` = 50 issues; tests exist but tiny (`test/` — core/models/ui only).
- Test accounts seeded: `sportx-api/TEST_CREDENTIALS.md` (all `password`, incl. admin with pre-verified 2FA).

### 3.4 Scale
94 P0 features (M1–M12), 94 P0 screens (129 total), 6 roles. routes/api.php: 365 Route:: calls across ~65 controllers, 70+ models, 60+ migrations.

### 3.5 Flutter analyze result (2026-11-02)
`50 issues found` — **error**: `lib\features\chat\presentation\providers\chat_provider.dart:111:24` argument_type_not_assignable (`FutureProviderRef<List<ChatMessage>>` passed as `WidgetRef`); **warnings**: unnecessary_cast `tournament_posting_screen.dart:169`; **info**: 47 (use_build_context_synchronously ×3, style lints). Build NOT run yet.

### 3.6 Sampling statement (for the final report)
Fully traced: M1, M12, M2, M3, M4, M5 (agent traces, full path UI→API→DB) + routes/api.php + backend security sweep (~22 endpoint families + uploads + secrets). NOT yet traced: M6, M7 (chat rules!), M8, M9, M10, M11, Flutter cross-cutting review, backend data-model gap list, endpoint inventory compilation, screen-by-screen wireframe comparison, live endpoint testing (blocked: no PHP).

---

## 4. Remaining work — exact plan

### 4-A. Assembly work (no new tracing needed for parts)
1. **01_FEATURE_TRACEABILITY.md + .csv** — one row per feature ID M1.1–M12.7 (59 rows): `ID | Name | Priority | Screens | Mobile files | Backend endpoints/files | DB tables | Status | Evidence | Gaps | Severity`. Statuses already determined for M1–M5, M12 (drafts §2). M6–M11 rows come from the remaining traces. P2 rows: M1.10, M2.13, M3.12, M4.13/14, M6.5/6, M7.11/12/13, M4.13 — mark OUT OF SCOPE (note M7-adjacent groups/polls endpoints EXIST — scope creep: `/groups` routes + GroupController + groups tables are built).
2. **02_SCREEN_COVERAGE.md** — for every screen ID in SCREEN_INVENTORY.md: file/route, built?, matches wireframe?, states?, real data? Known inputs: routes live in `sportx_app/lib/core/router.dart`; wireframe comparison is per-screen — sample it (prioritize P0 screens), state the sample.
3. **03_USER_FLOW_RESULTS.md** — the 12 flows from MVP_FEATURE_LIST §5 / SCREEN_INVENTORY §12. Assemble from module drafts: Onboarding (03a), Athlete trial flow (03c), Scholarship (03c), Portfolio (03a/03b), Academy enquiry (M6 trace), Networking/chat (M7 trace), Coach program (M6), Academy trial (03c), Organizer event (03c), Scout (M10 trace), Safety loop (M11 trace), Admin (M11 trace). Verdicts PASS/PARTIAL/FAIL per flow with failing step + evidence.
4. **04_TECHNICAL_REVIEW.md** — merge `_drafts/04b_backend_security.md` + cross-module rule enforcement status. §2 table above is the backbone. Child-safety/DPDP section: draw from H-1, H-6, H-7, B-6 + guardian-consent positives in 03a; app-store compliance from H-4 (deletion), H-5 (reporting), M11 trace.
5. **05_MOBILE_REVIEW.md** — from Flutter agent prompt (§4-C.4) + flutter analyze results (§3.5).
6. **06_BACKEND_REVIEW.md** — endpoint inventory (build from routes/api.php — 365 routes; group by area; flag features with no endpoint and endpoints with no feature) + data-model gap list (known so far: no unique index on opportunity_applications; no lat/lng columns; no reviews table; fee string columns; Sanctum morph tokens no FK) + jobs review (§3.2) + ops (backups none, Sentry disabled, no CI found — verify: no `.github/workflows` seen, confirm).
7. **07_FIX_PLAN.md** — backlog table from all drafts: ID | Problem | Where | Exact change | Perspective | Severity | Effort S/M/L | Blocks launch Y/N | Depends on. Seed with §2 findings (B-1…B-6, H-1…H-13 + mediums). Add M6–M11 findings when traced.
8. **08_NEEDS_HUMAN_CONFIRMATION.md** — known items so far: FCM console config (FCM_SERVER_KEY empty in committed CREDENTIALS.md — is push actually configured?), Google Sign-In client ID production status, email provider credentials (MAIL_PASSWORD null), hosting/deployment target (ngrok is dev-only), DB backup existence, app-store accounts, whether `sportx.in` domain + web app exist (share links point there), production signing key custody after keystore rotation, CI/CD existence.
9. **00_EXECUTIVE_SUMMARY.md** — compute: P0 DONE count / 59 features, P1 %, screen %; verdict GO / NO-GO / GO WITH CONDITIONS + 5 driving reasons; top-10 risk list. Based on evidence so far the verdict is trending **NO-GO** (4–6 BLOCKERs incl. capacity, secrets, suspended-user access, OTP bypass, public verification docs).

### 4-B. Runnable checks still to do
- `flutter test` in sportx_app (report pass/fail counts; test/ is small).
- `flutter build apk --debug` (or at least `flutter pub get`) to confirm the app compiles given the chat_provider analyze error.
- Confirm no CI: check for `.github/`, `.gitlab-ci.yml` at repo root.
- Grep sweep for TODO/FIXME/mock in both codebases (partially done in module traces — consolidate).
- If PHP becomes available: `php artisan test`, `php artisan migrate:fresh --seed` against sqlite, and live IDOR probes.

### 4-C. Remaining agent traces — run ONE AT A TIME (concurrency limit = 1)

**C.1 — M6+M7 (programs, facilities, feed, follow/connect, chat)** — *was cancelled, rerun first, chat rules are the biggest open question:*
> You are auditing the SportX India codebase at "D:\SportX Project" (Flutter app in sportx_app/, Laravel API in sportx-api/). READ-ONLY audit. Read sportsx-design-v3/new_design_docs/MVP_FEATURE_LIST.md sections M6, M7 and section 6 rules first. Trace END TO END with file:line evidence: M6.1 Training programs, M6.2 Program enquiry (creates chat thread), M6.3 Facilities, M6.4 Our Athletes (P1); M7.1 Create post, M7.2 Feed, M7.3 Post interactions, M7.4 Follow/unfollow, M7.5 Connect, M7.6 1-to-1 messaging (Chats/Requests tabs, unread badges). CRITICAL server-side rules to verify by quoting code: (1) chat allowed ONLY between accepted connections or inside enquiry/registration threads — can user A start a conversation with arbitrary user B via POST /me/conversations or POST /conversations (ConversationController::store/sendMessage)? (2) blocked users cannot message or see each other (Block checks in chat, feed, profile, discovery); (3) minor chat restrictions (guardian allow_messages) enforced in messaging; (4) follow/connect state machines + unique constraints in migrations; (5) deleted/reported posts hidden from feed. Key files: routes/api.php; PostController, FollowController, ConnectionController, ConversationController, EnquiryController, ProgramController, FacilityController, CoachingEnrollmentController, BlockController + models/migrations. Flutter: lib/features/social, chat, connections, coach, program, academy. Also: chat unread/polling, enquiry thread creation + notifications, feed pagination/N+1/blocked filtering, Flutter chat error handling, hard-coded data. WRITE full findings (per feature ID: Status {DONE,PARTIAL,UI-ONLY,API-ONLY,NOT STARTED,BROKEN,UNVERIFIED}, Evidence, Gaps, Severity) to "D:\SportX Project\audit_report\_drafts\03d_m6_m7_social_chat.md". Return condensed summary (max ~150 lines).

**C.2 — M8+M9+M10 (leaderboard, notifications, scouting):**
> Audit "D:\SportX Project" (READ-ONLY). Read MVP_FEATURE_LIST.md sections M8, M9, M10 + rules 8 & 10 (sportsx-design-v3/new_design_docs/MVP_FEATURE_LIST.md). Trace with file:line evidence: M8.1 athlete leaderboard (verified achievements + activity only; minors = first name + initial unless guardian opts in — quote LeaderboardService), M8.2 home strip, M8.3/M8.4 (P1); M9.1 in-app feed (tabs, unread, mark-all), M9.2 push (FCM triggers for follows/connections/messages/enquiries/registration/verification; action_url deep links; token register/remove; preferences respected — note known bug: registration outcomes typed status_update bypass HARD_OVERRIDE_TYPES), M9.3 reminders (P1); M10.1 scout dashboard, M10.2 discover talents, M10.3 shortlist (status/private notes/tabs), M10.4 observation, M10.5 contact athlete/parent (minors → guardian — AthleteContactController, ScoutConnectionController), M10.6/M10.7/M10.8 (P1). CRITICAL: scout data privacy — IDOR test by reading ScoutShortlistController/ObservationController for ownership scoping. Abuse protections on points. Key files: app/Services/LeaderboardService.php, LeaderboardController, AthleteLeaderboardController, ScoutDashboardController, ScoutShortlistController, ObservationController, TalentScoutController, AthleteContactController, ScoutConnectionController, NotificationController, NotificationPreferenceController, Jobs (RecalculateLeaderboardJob, SendDueRemindersJob); Flutter lib/features/talent_scout, notifications, home + FCM in main.dart. WRITE to "D:\SportX Project\audit_report\_drafts\03e_m8_m9_m10.md" (same status/severity scheme); return condensed summary (max ~150 lines).

**C.3 — M11 (admin, moderation, master data, expiry, 2FA):**
> Audit "D:\SportX Project" (READ-ONLY). Read MVP_FEATURE_LIST.md M11 + rules 4 & 9, SCREEN_INVENTORY.md §10 (AD.1–AD.12), new_design_docs/06_admin_wireframes.md. Trace with file:line evidence: M11.1 report flow (mobile ReportController → ListingReport → admin queue), M11.2 block (content hiding both ways), M11.3 moderation queue/actions (approve/reject/remove/warn/suspend — do they actually hide content in public queries? notify reporter AND reported?), M11.4 verification queue, M11.5 user management (suspend/ban — note known: suspend does NOT delete tokens), M11.6 content manager CRUD (which types; AuditLog written?), M11.7 master data + seeders (sports/cities/age-groups/positions), M11.8 expiry rules UI ↔ SweepExpiredContentJob, M11.9 admin dashboard KPIs + 2FA login (Blade: AdminAuthController, AuthenticateAdminPanel, twofa.blade.php — TOTP? email? enforce flag? rate limiting? CSRF?). Key files: routes/web.php, routes/api.php admin section, app/Http/Controllers/Admin/*, app/Http/Middleware/AuthenticateAdminPanel.php, resources/views/admin/**, ReportController, BlockController, ListingReport, AuditLog, ExpiryRule. Known security findings to build on (from _drafts/04b_backend_security.md — read it first): admin API login unthrottled, TOTP plaintext, ADMIN_2FA_ENFORCE=false accepts any code, suspend keeps tokens. WRITE to "D:\SportX Project\audit_report\_drafts\03f_m11_admin.md"; return condensed summary (max ~150 lines).

**C.4 — Flutter cross-cutting review:**
> Audit "D:\SportX Project\sportx_app" (Flutter 3.44, Riverpod, go_router, dio). READ-ONLY. Read SCREEN_INVENTORY.md §§1-3 first. Do NOT redo feature tracing (M1–M5 drafts exist in ../audit_report/_drafts/ — read them first to avoid duplication). Your job is cross-cutting mobile engineering, cite file:line: (1) router.dart routes vs screen IDs A/S/D/AT/CO/AC/OR/SC — which screen IDs have no route; auth guard + role-based redirect; deep links (known: no app-links intent filter); (2) bottom nav Home/Explore/Create/Community/More per role (role_config.dart) — Community real or placeholder?; (3) Riverpod consistency, logic-in-widgets, disposal; name worst offenders; (4) dio layer: interceptors/token refresh/timeouts/error mapping, base URL from .env, pretty_dio_logger in release logging PII?; (5) list patterns: pagination/pull-to-refresh/empty/skeleton/error-retry on Home feed, Explore, Notifications, Chats, Registrations (known broken: universal search pagination, saved truncation at 20); (6) forms: validation, double-submit, drafts; (7) media: compression, upload progress/cancel/retry, permission denial; (8) push: main.dart FCM foreground/background/terminated, token registration/removal on logout, tap→deep link; AndroidManifest/Info.plist permissions; (9) secure storage usage + logout clearing (known good — verify settings-screen logout skips dialog); (10) shared empty/loading/error widgets; offline (none — no connectivity_plus); (11) .env handling, hard-coded URLs/keys (grep http://, localhost, 192.168, apiKey); (12) run `flutter analyze` (expect 50 issues; chat_provider.dart:111 is an ERROR) and `flutter test`; (13) android/app/build.gradle signing (my-release-key.jks committed — confirm referenced), minSdk/targetSdk, privacy strings, account deletion reachable (More screen), report/block visible. WRITE to "D:\SportX Project\audit_report\_drafts\05_mobile_review.md"; return condensed summary (max ~150 lines).

### 4-D. Final assembly order
1. Run C.1 → C.2 → C.3 → C.4 (sequential; write drafts as they complete — progress is preserved per file).
2. Do 4-B runnable checks.
3. Build matrices (4-A items 1–2), flow results (3), then reviews (4–6), fix plan (7), human-confirmation list (8), executive summary (9) — writing each to /audit_report/ as completed so progress is never lost.

---

## 5. API route inventory (raw, for 06_BACKEND_REVIEW)

Full file read: `sportx-api/routes/api.php` (646 lines, 365 routes). Key structure — public: health, auth (register/login/otp/forgot/google, throttled 10/min; OTP endpoints 20/min with per-destination caps in OtpController), meta, directories (academies/coaches/trials/tournaments/sports-venues — unauthenticated), search, explore. Authed: onboarding per role, media (upload/delete/reorder/signed-url), saved, reports, profile, coach/academy/organizer profiles (role middleware), programs + enquire (role:athlete), facilities (academy,organizer), enquiries, athlete discovery (role: sponsor,talent_scout,athlete), scout shortlist/connections (role:talent_scout), registrations trials+tournaments (register role:athlete; approve/reject authed w/ ownership in controller), coaching enrollments, results, unified events + registrations (index/bulk/export/approve/reject/cancel), organizer analytics, opportunities (CRUD + apply role:athlete + applications + review), notifications + prefs + device tokens + analytics events, social links, privacy, achievements, settings + password + delete account, activity, recent searches, conversations (store ×2 paths, messages throttle 120/min), connections, follows, blocks, leaderboard (index/strip/me), observations, athletes/{id}/contact, scout dashboard, feed/posts/likes/comments, groups. Admin (auth+role:admin+admin.2fa): dashboard, verification, content CRUD, moderation queue/actions, expiry rules+monitor+override/restore, categories (sports/cities/age-groups/positions), settings, email settings, users (+approve/reject/suspend/destroy), opportunities approve/reject, broadcast + targeted broadcast, leaderboard-config, audit-logs, registration analytics + admin approve/reject overrides. Admin auth (no 2FA on the login/verify endpoints themselves — unthrottled): login, verify-2fa, logout, me. Legacy 410 Gone: scholarships/sponsorships/sponsor shortlist routes. **Anomalies noted:** POST /me/conversations AND POST /conversations both map to ConversationController::store (cold-DM surface — check in C.1); /media/download/{id} has NO auth middleware; /events/{id} show authed but no role filter (draft leak); roles used in middleware include `sponsor` which the MVP removed (legacy).

## 6. Conventions used
- Status vocabulary: DONE / PARTIAL / UI-ONLY / API-ONLY / NOT STARTED / BROKEN / UNVERIFIED / OUT OF SCOPE.
- Severity: BLOCKER / HIGH / MEDIUM / LOW.
- Evidence format: `file:line` everywhere; nothing marked DONE without full-path tracing.
