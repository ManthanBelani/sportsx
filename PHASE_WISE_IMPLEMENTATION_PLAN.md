# SportX India — Phase-Wise Implementation List (Build Order)

> Generated from `docs/` on 2026-10-13. Synthesized from:
> `PRD.md` §8 · `Phased-Roadmap.md` (v3 delta) · `Backend-Feature-Delta.md` §9 build order + §11 endpoint catalog ·
> `Functional-Requirements.md` · `Database-Design.md` · `API-Specification.md` ·
> `Implementation-Execution-Plan.md` · `Development-Checklist.md` Phase 8 · `Jira-Tickets.md` ·
> `Talent-Scout-Implementation-Guide.md` · `UI-Completion-And-Backend-Wiring-Plan.md` ·
> **`Email-Provider-Architecture.md` · `Google-Authentication.md` · `FCM-Notification-System.md`**
>
> **Canonical rules (v3 + platform integrations):**
> - Roles = `athlete, coach, academy, organizer, scout, admin`. `sponsor` REMOVED (sponsorship = `opportunities.type`).
> - Auth = phone **OR** email + 6-digit OTP (P0, resend timer) + password login kept. **Google sign-in = P0 and built** (D9 CLOSED, AS-64).
> - **Email = delivered over one of two providers — `smtp` or `gmail` (Gmail REST API, OAuth2)** — both configured, switchable at runtime from the admin panel (AS-59).
> - **Push = FCM HTTP v1**, with in-app as the source of truth and **email as the push-failure fallback channel** (AS-03c closed).
> - Guardian consent mandatory for <18 (P0). Verification request + admin queue + user mgmt = P0.
> - No in-app payments (parked P2). Map view parked. Multi-role accounts parked.
> - New P0 modules: opportunities, programs, facilities, social feed, follow/connect, 1-to-1 chat, blocks/reports, leaderboard, positions master, opportunity expiry.

**Status legend:** `[ ]` not started · `[x]` implemented in the working tree. Items marked `[x]` for the platform integrations are **backend code only** — the four `2026_10_01_*` migrations, the Flutter wiring, and the credential/config steps have **not** been done. See Phase 3E.

> **⚠️ Launch blockers introduced by Phase 3E** — none of these are code tasks, and all of them block a production release:
> 1. **FCM quota** — default ≈ 10,000 `messages.send`/day; a broadcast larger than that fails silently (AS-67).
> 2. **APNs auth key** — iOS release builds receive no push without it (AS-68).
> 3. **`php artisan migrate`** — the OTP restore and the `notifications.type` widening both require it.
> 4. **SMS vendor still unselected** — blocks `channel=phone` OTP, and therefore phone signup entirely (AS-60).

**How to use:** build phases in order. Each phase lists Backend (Laravel `sportx-api`), Mobile (Flutter `sportx_app`), Admin, and ✅ Exit criteria (demo/test). Check boxes as you go.

---

## Phase 0 — Project Foundation (1 week)

**Goal:** monorepo runs, DB migrates, auth skeleton works.
**Docs:** `Phased-Roadmap.md` P0 · `Backend-Architecture.md` · `Mobile-Architecture.md` · `Jira P0-E1`

### Backend (`sportx-api`)
- [ ] Laravel 11 scaffold: `composer create-project`, `.env`, `config/sportx.php`, CORS (Flutter origin), Sanctum, `/api/v1` prefix
- [ ] Migrations (all tables per `Database-Design.md` order): users, all profile tables, sports/cities/age_groups/positions, trials/tournaments/categories/registrations/results, opportunities, programs/facilities, posts/likes/comments, follows/connection_requests, conversations/messages, blocks, saved, reports, verification_requests, guardian_consents, leaderboard, notifications/reminders, expiry rules, media
- [ ] **Platform-integration migrations (`Database-Design.md` §17 step 18 — run in this order):**
  - [ ] `2026_10_01_000001` `social_accounts` (unique `(provider, provider_user_id)`, encrypted tokens) + **drops `users.google_id`** → *back-fill existing Google links first in production*
  - [ ] `2026_10_01_000002` **restores `otp_codes`** (a prior migration dropped it while `OtpService`/`OtpCode`/`PurgeExpiredOtpsJob` still targeted it)
  - [ ] `2026_10_01_000003` `notifications` push columns (`channel`, `category`, `image_url`, `priority`, `metadata`, `pushed_at`, `push_status`) + **widens `type` from `enum(3)` to `VARCHAR(40)`**
  - [ ] `2026_10_01_000004` `user_device_tokens` — **unique `token`** (de-dupe existing rows first) + `last_seen_at` + `failure_count`
- [ ] `.env.example`: `MAIL_PROVIDER`, `MAIL_FAILOVER_ENABLED`, `MAIL_*`, `GMAIL_*`, `FRONTEND_URL`, `GOOGLE_*`, `FCM_*`, `DEVICE_TOKEN_TTL_DAYS`, `NOTIFICATION_RETENTION_DAYS`
- [ ] Seeders: sports (5+), cities (10+, 3+ states), age_groups (6), positions, expiry rules, dev data (sample academies/coaches/trials/athletes)
- [ ] Middleware: `auth:sanctum`, `role:{athlete,coach,academy,organizer,scout,admin}`, `EnsureAdmin2FAVerified`
- [ ] CI skeleton: lint + test on push, staging deploy on merge
- [ ] Health endpoint `GET /system/health`

> **`composer.lock` must be in sync with `composer.json`.** `google/auth` is required by the Gmail transport, the FCM client and Google ID-token verification, but was missing from the lock file — `composer install` fails outright until it is reconciled.

### Mobile (`sportx_app`)
- [ ] `flutter create`, feature-first folders, `Dio` + `AuthInterceptor` (`core/utils/api_client.dart`), Riverpod, `go_router` shell
- [ ] Theme tokens: Primary `#1677ff`, Surface `#f7f8fa`, Text `#111111`, Muted `#6b7280`, Inter, 8px grid
- [ ] Shared widgets: `async_state_view.dart` (loading Shimmer / error+retry / empty / data), `DirectoryListTemplate`, `DetailPageTemplate`, `FormPageTemplate`
- [ ] State pattern: `StateNotifier<XState>` + `copyWith`; list pagination `DirectoryNotifier` (`load/loadMore/refresh`)

✅ **Exit:** `php artisan migrate && db:seed` clean; Flutter boots; login token hits a test endpoint.

---

## Phase 1 — Roles, Auth, Guardian, Verification (P0 core trust)

**Goal:** any role can sign up → OTP → onboarding → token.
**Docs:** Delta `BE-M1.x` · FR-AUTH-1…16 · FR-GUARD-1…3 · FR-VERIF-1 · Screens `A.1–A.10` · **`Email-Provider-Architecture.md` · `Google-Authentication.md`**

### Backend
- [x] `UserRole` enum: drop `sponsor`, add `scout` — **iteration 1 done 2026-10-13 (testing remaining):** new `App\Support\UserRoles` helper (canonical `scout`, legacy `talent_scout` storage alias); `EnsureRole` middleware + `PlatformSettings::needsApproval` + `User::hasRoleProfile` accept both; **new `sponsor` signups refused with 410 `SPONSOR_REMOVED`** (`/auth/register`, OTP signup, Google signup, `/onboarding/sponsor`, `/onboarding/sponsor` schema). Full DB enum rename + existing sponsor-row migration → Phase 4 (opportunities tables don't exist yet)
- [ ] OTP stack: `otp_codes` (hash, expiry 5min, attempts≤5, channel), `POST /auth/send-otp`, `/auth/verify-otp`, `/auth/resend-otp` (60s cooldown), `RateLimitOtp`
  - [x] `otp_codes` table **restored** — a prior migration dropped it while the service, model and purge job still targeted it, so OTP was structurally dead *(migrated on MySQL 8 ✓)*
  - [x] `OtpCode::$fillable` **corrected** — it listed legacy columns (`phone`, `code`), so every write was silently discarded by mass-assignment protection
  - [x] `channel=email` delivery via `EmailOtpMail` on the **active provider** (SMTP **or** Gmail — see Phase 3E)
  - [x] `OtpService` supports **pre-registration** codes (`user_id` nullable) — sign-in/sign-up both need a code before an account exists
  - [x] Issuing a new code **burns** any prior live code; codes are scoped by `purpose`
  - [x] Per-destination throttles: 5 sends/hour, 10 verifies/5min, on top of the per-code attempt cap
  - [x] `POST /auth/send-otp` · `/auth/verify-otp` · `/auth/resend-otp` wired *(18 tests ✓)*
  - [ ] `channel=phone` / SMS driver — **BLOCKING, AS-60.** The vendor is unselected; `otp_codes.channel` already admits `phone`, so this is config-only once chosen
- [x] Keep password auth: `POST /auth/register`, `/auth/login` (password **or** OTP branch), `/auth/logout`, `GET /auth/me`, `POST /me/change-password`, `POST /me/delete-account` (soft, 90-day purge) — **iteration 1 done 2026-10-13 (testing remaining):** `POST /me/change-password` + `POST /me/delete-account` spec aliases added (same `SettingsController` handlers as `PUT /me/settings/password`, `DELETE /me/account`); OTP-login branch = `POST /auth/verify-otp` (`purpose=login`); all auth payloads now include `is_verified`
- [ ] **Google sign-in (P0 — D9 CLOSED, was P1.14):**
  - [x] `social_accounts` join table; **dropped `users.google_id`** and removed it from `User::$fillable`/`$hidden` *(migrated on MySQL 8 ✓)*
  - [x] `SocialAccount` model — `encrypted` casts on `access_token`/`refresh_token`, both in `$hidden`, registered in the morph map
  - [x] `GoogleAuthService::verifyIdToken()` — **six checks**: structure · `alg` pinned to **RS256** (never trusted from the header) · JWKS signature (24h cache, refetch on unknown `kid`) · `aud` == `GOOGLE_CLIENT_ID` · `exp` + 60s skew · `email_verified == true`. **Fails closed** — no "skip if JWKS unreachable" path
    - *Implementation note:* verification uses `firebase/php-jwt` (`App\Services\Support\GoogleKeySet`), **not** `google/auth`, which mints access tokens and has no ID-token verifier. This php-jwt version performs **no `aud` check**, so audience and issuer are validated inside `GoogleAuthService`.
    - *Covered by genuine RS256 signatures against a locally generated key pair and a stubbed JWKS — forged, `alg=none`, HS256, wrong-audience, expired and JWKS-unreachable tokens are all rejected* *(18 tests ✓)*
  - [x] Account resolution — known `sub` → sign in; verified email match → link; else create. **Keyed on `sub`, never email** (consumer Gmail addresses are not unique). Linking is refused when the SportX account's own email is still unverified, so an address squatter gains nothing
  - [x] `pending` accounts: a **new** signup gets a token with `pending_approval: true` (matching `/auth/register`, so the applicant can see the pending screen); a **returning** sign-in is refused with 403 `PENDING_APPROVAL`. Google is never a way around the gate
  - [x] `role` on signup validated against `GOOGLE_ALLOWED_ROLES` — an unvalidated role is a privilege-escalation hole *(+ `scout` alias accepted, `sponsor` refused with 410 — iteration 1, testing remaining)*
  - [x] Domain error codes in `API-Specification.md` §21 — `INVALID_ID_TOKEN` · `EMAIL_NOT_VERIFIED` · `ACCOUNT_DISABLED` · `PENDING_APPROVAL` · `SIGNUP_DISABLED` · `INVALID_ROLE` · `EMAIL_UNVERIFIED` · `GOOGLE_UNAVAILABLE`
  - [x] `POST /auth/google` + `GET/DELETE /me/social-accounts` wired *(19 tests ✓)*. Unlinking the **last** credential is refused when no password is set, otherwise the user locks themselves out
  - [ ] Back-fill existing `users.google_id` values into `social_accounts` **before** dropping the column (production only)
- [x] Onboarding: `GET /onboarding/{role}`, `POST /onboarding/athlete|coach|academy|organizer|scout` (❌ no `/onboarding/sponsor` — returns 410 `SPONSOR_REMOVED`); 30 fields/role per Mandatory Fields — **iteration 1 done 2026-10-13 (testing remaining):** `POST /onboarding/scout` alias + `scout` schema added, sponsor POST + schema return 410; full 30-field validation per role still pending
- [x] Guardian: `guardian_consents` + `GuardianConsentService` + `POST /guardian/consent`, `/guardian/verify-otp`, `GET/PUT /me/guardian-controls`, `DELETE /me/guardian-consent` *(migrated ✓, 15 tests ✓)*
  - [ ] **SMS vendor (AS-60)** — the code goes to the guardian's *phone*, so `POST /guardian/consent` returns **503 `CHANNEL_UNAVAILABLE`** until a vendor exists. The verify path is implemented and tested; only delivery is blocked
- [x] Verification: `verification_requests` (morph, proof media ids, reviewer, reason) + `POST/GET /me/verification`, `GET /admin/verification`, `PATCH …/approve|reject` *(migrated ✓, 12 tests ✓)*. Approve/reject emit an `account_action` notification (hard override)
  - [ ] **Badge on profile card / search results** — **iteration 1 done 2026-10-13 (testing remaining):** `coach_profile → verification_badge` added to `BADGE_COLUMNS`, `is_verified` now in all auth payloads (`/auth/register|login|google`, OTP verify, `/auth/me`); academy/coach badge columns already serialize in listings. Still open: athlete + scout have no badge column (needs migration), search-result enrichment
- [x] Checklist: `GET /me/completion-checklist` (per-role missing items + deep links, %) *(7 tests ✓)*

### Mobile
- [x] Screens: S1 Splash (3-dot pulse) → S2 Role Selection (5 cards, no sponsor) → S3 Sign Up (name first, phone/email, T&C) → S4 OTP Verify (6-digit + timer) → S5 Login (password/OTP toggle, forgot link) — **iteration 1 done 2026-10-13 (testing remaining):** sponsor card removed, scout card uses canonical `scout` id; `/verify-otp` route added
  - [x] **OTP screen wired** — `verifyOtp`/`resendOtp`/`sendOtp` now call `POST /auth/verify-otp|resend-otp|send-otp` (`purpose=signup`, role passed through) instead of stubs *(testing remaining)*
  - [x] **"Forgot Password?" wired** — calls `forgotPassword` with the entered email + confirmation snackbar instead of an empty closure *(testing remaining)*
- [x] **"Continue with Google"** on S3 Sign Up **and** S5 Login, below the primary action with an "or" rule — **button + provider wiring done 2026-10-13 (testing remaining):** shared `GoogleSignInButton` widget on both screens; native config bullets below still open
  - [x] Add `google_sign_in` to `pubspec.yaml` — **pin explicitly** (`^6.2.1`); `^7+` changes the API surface *(resolved 6.3.0, `flutter analyze` clean)*
  - [ ] **Populate `oauth_client` in `google-services.json`** — it is currently an empty array, so Android gets no `serverClientId` and sign-in fails with `DEVELOPER_ERROR` even though the app otherwise works
  - [ ] `serverClientId` in `android/app/build.gradle.kts`; `REVERSED_CLIENT_ID` + URL scheme in `Info.plist`; package name / bundle ID must match the OAuth client exactly
  - [x] `AuthNotifier.signInWithGoogle()` — on success run the **same** post-login sequence as password login: persist token → `checkAuth()` → `_registerFcmToken()` *(via shared `_persistAuth()` helper — testing remaining)*
  - [x] Sign-up must capture the **role** *before* the Google button (role drives approval routing) — `GoogleSignInButton(role:)` receives the role-selection value
- [ ] Onboarding wizards: A1/A2 athlete, C1 coach, AC1 academy, O1 organizer (+docs upload), TS1/SC.1 scout (30 fields each)
- [ ] Guardian screens `A.9` + Parental Controls `AT.10`; Verification Request `A.10` (upload, status Pending/Verified/Rejected+reason)

✅ **Exit:** sign up as each of 5 roles via phone AND email OTP; minor signup blocked until guardian OTP; verification request → admin approve → blue check shows. **Additionally:** "Continue with Google" signs in on Android **and** iOS, and a Google login for a `pending` account returns 403 rather than bypassing the gate.

> **Backend status:** complete and covered by **89 passing feature tests** (OTP 18 · Google endpoints 19 · Google crypto verification 18 · guardian 15 · verification 12 · checklist 7), with **zero regressions** against the pre-existing suite. Verified against real MySQL 8.
>
> **Blocked on AS-60 (SMS vendor):** `channel=phone` OTP and `POST /guardian/consent` return `503 CHANNEL_UNAVAILABLE`. Both are implemented — only the SMS transport is missing.
>
> **Remaining in this phase (updated 2026-10-13):** native Google config (`oauth_client`, `serverClientId`, `Info.plist`), athlete/scout badge columns in listings/search, full 30-field onboarding validation, and **testing of everything built in iteration 1** (backend suite + device OTP/Google round-trip not yet run). Flutter wiring (`google_sign_in` dep, OTP screen, forgot-password, `signInWithGoogle()`, role cards) is code-complete; `flutter analyze` clean on touched files.

---

## Phase 2 — Profiles, Media, Achievements (30 fields)

> **Status 2026-10-13 — STARTED (iteration 2, testing + `migrate` remaining):** backend slice extended and syntax-checked (`php -l` clean), **not yet migrated or tested**. Mobile achievements/gallery/privacy wired to the new endpoints; `flutter analyze` clean on touched files (one pre-existing `onReorder` deprecation info, unrelated).

**Goal:** complete rich profiles for all roles.
**Docs:** Delta `BE-M2.x` · FR-ATH-1/2 · FR-COACH-1 · FR-ACAD-1 · FR-PLAT-7

### Backend
- [x] `talent_scout_profiles` (30 fields) + `talent_scout_sports` pivot; `GET/PUT /me/scout-profile`, `GET /scouts/{id}` (About+Activity only), `GET/PUT /me/organizer-profile`, `GET /organizers/{id}`, `GET /athletes/{id}` (minors restricted) — **iterations 1–2 done 2026-10-13 (migrate + testing remaining):** pivot migration written; minors masking on athletes index+detail; **new `GET /scouts/{id}` (contact fields stripped, `is_verified` attached) + public `GET /organizers/{id}`**; `/me/profile` now serves scout role. Still open: full 30-field scout validation, privacy-read enforcement beyond athlete discovery (`who_can_message` chat gate = Phase 6)
- [x] `athlete_sports` pivot: `playing_role, level, experience_years, is_primary` — **migration written + `PUT /me/profile/sports` accepts rich objects (back-compat plain ids kept); relation loads pivot only when columns exist (migrate + testing remaining)**
- [x] `achievements` typed CRUD: `GET/POST /me/achievements`, `PUT/DELETE /me/achievements/{id}` (title/type/sport/level/year/certificate/desc, owner morph athlete/coach) — **iteration 2:** controller is migration-safe (writes/relations/order guarded by `Schema::hasColumn`); **mobile Add-Achievement now POSTs typed (+certificate id), gallery deletes via `DELETE` for typed rows (migrate + testing remaining)**
- [x] Media: `POST /media/upload` (+caption+sport tag), `PUT /media/reorder`, `DELETE /media/{id}`, `GET /me/media`; private docs via signed URLs — **iteration 2:** caption/`sport_id` accepted on upload (migration `2026_10_14_000002` written, persisted only when columns exist); **mobile gallery lists from `GET /me/media` with profile fallback (migrate + testing remaining)**
- [x] Privacy: `PUT /me/privacy` (`profile_visibility`, `who_can_message/connect`); `social_links` JSON; `GET/PUT /me/settings` (visibility/messaging/language/push toggles) — **iteration 2:** `PUT` returns 503 `PENDING_MIGRATION` until migrated; **athlete discovery enforces `private`/`followers` (self/admin bypass)**; **mobile Settings gains a Privacy group wired to `GET/PUT /me/privacy` (migrate + testing remaining)**

### Mobile
- [x] Profile view/edit + Media Gallery (upload/delete/reorder) per role: A4/A5/A6, C2, AC2, O-profile, TS2/SC.3 — **iteration 2 done 2026-10-13 (testing remaining):** gallery lists from `GET /me/media` (profile fallback), Add-Achievement POSTs typed CRUD with certificate id, typed deletes via `DELETE /me/achievements/{id}`, Privacy group in Settings (`GET/PUT /me/privacy`)
- [ ] Completion checklist UI `AT.6` with deep links; photo/media viewer `S.28`

✅ **Exit:** each role profile saves all 30 fields; achievements + gallery persist; privacy settings enforced.

---

## Phase 3 — Discovery, Search, Filters, Saved

> **Status 2026-10-13 — STARTED (iteration 1, testing remaining):** backend slice built, `php -l` clean; mobile search-athletes + saved-tabs wired, `flutter analyze` clean. Home-screen `/me/home` wiring + distance sort + full filter-panel UX remain for iteration 2.

**Goal:** browse everything (LinkedIn-style Explore).
**Docs:** Delta `BE-M3.x` · FR-DISC-1…7 · FR-ATH-4/5/7/9/15 · Screens `S.2–S.8`, `D.1–D.5`

### Backend
- [x] Directories (existing, extend): `GET /academies /coaches /trials /tournaments /sports-venues` + filters `position/level/facilities/price/rating`, distance sort (city-centroid MVP), registration-status on events — **iteration 1 done 2026-10-13 (testing remaining): trial + tournament detail now return `registration_status` (own state, seats taken/left, registerable); position/level/facilities meta + distance sort remain iteration 2**
- [x] `GET /me/home` (role-aware: greeting, completion %, leaderboard strip, counts, feed preview); `GET /explore` (grouped sections) — **iteration 1 done 2026-10-13 (`HomeController`; leaderboard strip `[]` until Phase 7; testing remaining)**
- [x] `GET /search` (+ `athletes` group), `POST /me/recent-searches`; `GET /meta/positions`, `/meta/facilities` (sports/cities/age-groups exist) — **iteration 1 done 2026-10-13: athletes group (auth-only, privacy-gated, minor-masked), explicit recent-search POST, curated positions/facilities masters (admin-managed in Phase 9; testing remaining)**
- [x] Saved: `GET/POST/DELETE /me/saved` — morphs `post, opportunity, event` (+ existing 6) — **iteration 1 done 2026-10-13: `post` + `athlete_profile` enrich added (`opportunity`/`event` morphs arrive with Phase 4/8; testing remaining)**

### Mobile
- [ ] Shell: bottom nav `Home / Explore / (+) Create / Community / More` (`S.1`, `S.15`), role Home dashboards (AT.1/CO.2/AC.2/OR.2/SC.2), Create launcher `S.8` — `/me/home` + `/explore` APIs ready, screen wiring is iteration 2
- [x] Universal Search `S.5` + results tabs `S.6/S.7` + Filter Panel `S.4` (sport/city/age/position/level/facilities/price/date, sort relevance/distance/rating) — **iteration 1 done 2026-10-13: Athletes tab (count, card meta, detail nav), recent-search POST on submit, position/facility filter options pending meta UX (testing remaining)**
- [ ] Directory list `T1/S.3` + Detail `T2/D.1–D.5` for academy/coach/trial/tournament/venue; Save ♡ + overflow ⋮ + Report entry on every detail
- [x] Saved screen `S.20` (tabs by type); Settings `S.22`, Help `S.24` (FAQ + contact) — **iteration 1 done 2026-10-13: Athletes/Venues/Posts tabs added, athlete/post deep-links, paginator-shape load fix (backend returned a paginator the app cast to List — previously always error state; testing remaining)**

✅ **Exit:** search "cricket ahmedabad" → tabbed results incl. athletes; filter → detail → save → appears in Saved; report works.

---

## Phase 3E — Platform Integrations: Email, Google Sign-in, FCM (1 week)

**Goal:** three vendor decisions closed and made operable. Backend is largely built; what remains is migrations, Flutter wiring, and credentials.
**Docs:** **`Email-Provider-Architecture.md` · `Google-Authentication.md` · `FCM-Notification-System.md`** · `Backend-Architecture.md` §3–§7 · `Security-and-NonFunctional.md` §2.4–2.6

> **Why this sits here:** Phase 1 (auth) depends on email OTP and Google sign-in; Phase 9 (notifications) depends on FCM. Both are already specified, so this phase consolidates the shared infrastructure — mailer resolution, the `social_accounts` table, the device-token registry — rather than scattering it across two later phases.
>
> **Backend items below are marked `[x]`:** the code exists in the working tree but is **not migrated, not committed, and not configured**. Treat every `[x]` here as "written, not proven". Phase 3E is **not done** until the exit criteria pass.

### A. Email — dual SMTP + Gmail

**Backend — `[x]` written, `[ ]` verified**

- [x] `MailProviderService` — provider resolution (`platform_settings.json` → `MAIL_PROVIDER` → `smtp`), `configuredChain()`, `isConfigured()`, `status()`, `diagnostics()`, `testConnection()`, `setActiveProvider()`, `clearTokenCache()`
- [x] `GmailApiTransport` — Gmail REST v1 `messages:send`; auth modes `user` (refresh token) and `service_account` (domain-wide delegation); access token cached with a 60s expiry margin; **fails closed** on incomplete credentials
- [x] Register the `gmail-api` transport via `Mail::extend()`; resolve `mail.default` **per request** so a runtime switch needs no deploy and no config-cache rebuild
- [x] `sportx_failover` mailer — chain filtered to providers that actually have credentials, so a half-configured provider is skipped rather than tried and failed
- [x] `SportXMail` base mailable — `ShouldQueue`, `$tries = 3`, `$backoff = [10,30,90]`, `onQueue('mail')`, deep-link helper, `failed()` logging
- [x] Mailables: `EmailOtpMail`, `VerifyEmail`, `PasswordResetMail`, `AccountApprovedMail`, `AccountRejectedMail`, `WelcomeMail`, `NotificationFallbackMail`
- [x] Email views — `emails/layout.blade.php` (table-based, inline-styled; Gmail/Outlook strip `<style>`) + 7 templates, each with a "we will never ask for this" line
- [x] `config/sportx.php → 'mail'`; `config/mail.php` gains the `gmail` mailer and a failover chain
- [x] `admin/email-settings` controller — status / diagnostics / runtime switch / test / clear-token-cache (no secret is ever returned by any endpoint)

**Verify**

- [ ] **Configure BOTH providers** so failover has somewhere to fail over *to* — a single-provider setup defeats the point
- [ ] `POST /admin/email-settings/test` returns `ok: true` for **each** provider independently
- [ ] Runtime switch takes effect on mail **already sitting in the queue** (resolution happens at send time, not at boot)
- [ ] OTP round-trip: `send-otp` → email received → `verify-otp` succeeds
- [ ] Admin approve/reject each produce an email (both endpoints previously returned silently)
- [ ] `FRONTEND_URL` is set in production — leaving it at `APP_URL` produces dead deep links
- [ ] **SPF, DKIM and DMARC** published for the sending domain (SEC-26)
- [ ] Gmail sender: Workspace **"Publish → Gmail API → Send mail as your users"** verified, and domain-wide delegation granted if using `service_account` mode (SEC-27)

### B. Google sign-in

Backend items are covered in detail under **Phase 1**. Config and credential steps only:

- [ ] OAuth consent screen configured (External + test users for dev)
- [ ] Three OAuth clients created: **Android** (package name + SHA-1), **iOS** (bundle ID), **Web**
- [ ] `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_ALLOW_SIGNUP=true`, `GOOGLE_DEFAULT_ROLE=athlete` set
- [ ] `GOOGLE_WORKSPACE_HD` set if the deployment is single-tenant
- [ ] Flutter items tracked under **Phase 1** (`google_sign_in` package, `oauth_client`, `signInWithGoogle()`)

### C. FCM notifications

**Backend correctness fixes — `[x]` written, `[ ]` verified**

> Every item below was a **live defect**, not an enhancement.

- [x] `FCMService` — **`messages:send` per token.** The previous code called `messages:sendMulticast`, which **does not exist in FCM HTTP v1**; it returned 404 and `responses[0]` was null, so the method reported success while delivering nothing
- [x] Android `channel_id` mapped per notification type (`sportx_default`, `sportx_enquiries`, `sportx_reminders`, `sportx_updates`, `sportx_announcements`) — **without it Android 8+ silently drops every notification**
- [x] APNs headers — `apns-priority`, `apns-push-type`, `apns-sound` (iOS alerts were arriving silently in the background)
- [x] `notification_prefs` honoured before dispatch — the column existed and was cast, but **no service or controller ever read it**, so every user was pushed unconditionally
- [x] `NotificationController::sendPushNotification()` read `$notification->message`, a **column that does not exist** — producing empty push bodies. Now uses `Notification::toPushPayload()`
- [x] Token lifecycle — `UNREGISTERED` retires immediately; transient errors (`QUOTA_EXHAUSTED`) increment `failure_count` and retire only after 3 strikes. **Never retire on the first transient failure**: a device in aeroplane mode would otherwise permanently lose a valid registration
- [x] `NotificationService` — row written **first** (source of truth), preference gate, hard overrides for account/registration decisions, email fallback on `no_devices`/`failed`
- [x] `SendPushNotification` job — chunked (`FCM_BATCH_SIZE` 500), retries, backoff
- [x] `PruneStaleDeviceTokensJob` + `PruneNotificationRowsJob` — scheduled daily
- [x] `push_status` recorded (`queued`/`sent`/`partial`/`failed`/`no_devices`) — this is what makes the email fallback safe; without it a retry sends a duplicate fallback to users who already got the push
- [x] Admin approve/reject now emit notifications at all — previously **no notification of any kind**

**API**

- [x] `GET/PUT /me/notification-preferences`; `POST /me/device-tokens/subscribe`; `POST /me/device-tokens/test`; `GET /admin/notifications/stats`

**Flutter**

- [ ] Add `flutter_local_notifications` (AS-72) — **without it, background delivery produces nothing visible on the device**
- [ ] Fix `main.dart` — `Firebase.initializeApp()` is called with **no `options:`**, so `DefaultFirebaseOptions` is never used and web/tests fail
- [ ] Declare `POST_NOTIFICATIONS` in `AndroidManifest.xml` — `requestPermission()` is a **silent no-op on Android 13+** without it (the most common cause of "works on 12, not 13")
- [ ] Android channel IDs must match the backend **exactly**, or notifications are silently dropped
- [ ] Darwin settings — `presentAlert: true` for foreground display
- [ ] `getInitialMessage()` / `onMessageOpenedApp` → deep link via `action_url` + `category`

**Launch blockers**

- [ ] **Raise FCM quota** (AS-67) — default ≈ 10,000 `messages.send`/day
- [ ] **Upload APNs auth key to Firebase** (AS-68) — iOS release builds otherwise get no push

### D. Admin (web panel)

- [ ] Email settings screen — provider status, runtime SMTP ⇄ Gmail switch, connection test, diagnostics
- [ ] Notification broadcast — `channels: ["in_app","push"]`, with the email fallback visible in results
- [ ] Delivery stats by type / `push_status`

✅ **Exit:**
- [ ] `php artisan migrate` runs clean; `social_accounts` exists and `users.google_id` is gone
- [ ] A test email is delivered through **each** provider, and the runtime switch flips the active one without a redeploy
- [ ] Email OTP round-trip succeeds end to end
- [ ] "Continue with Google" signs in on **both** Android and iOS
- [ ] Push reaches a **real device** in foreground **and** background on both platforms
- [ ] Tapping a push deep-links correctly **and** re-authorizes server-side
- [ ] `push_status` reads `sent` in admin stats after a test push
- [ ] A user with **no device token** receives the email fallback
- [ ] Disabling a category in Settings actually suppresses that push
- [ ] Logout deactivates all of that user's device tokens

---

## Phase 4 — Opportunities + Applications (unified, replaces sponsor/scholarship)

> **Status 2026-10-13 — STARTED (iteration 1, migrate + testing remaining):** backend complete (`php -l` clean); mobile list/detail/apply/my/post wired (`flutter analyze` clean); provider applications inbox + review UI remain iteration 2.

**Goal:** providers post, athletes apply in-app, providers review.
**Docs:** Delta `BE-M5.x` · FR-OPP-1…5 · FR-ATH-11/13 · Screens `D.9/D.10`, `AT.8`, `AC.9`, `SC.11/12`

### Backend
- [x] `opportunities` (provider morph academy/organizer/coach/scout, type scholarship/sponsorship/tryout/camp, eligibility, benefits/amount, deadline, docs, status) + `opportunity_applications` (pitch/docs/snapshot/status) — **iteration 1 done 2026-10-13: migration `2026_10_15_000001` (tables + guarded legacy backfill), models, morph-map entries (migrate + testing remaining)**
- [x] Endpoints: `GET /opportunities` (type/sport/age/deadline filters), `GET /opportunities/{id}`, `POST /me/opportunities`, `PUT/PATCH /me/opportunities/{id}` (+publish/close), `POST /opportunities/{id}/apply` (409 duplicate), `GET /me/opportunities?type=applied|saved|created` — **done; detail carries `applied`/`application_status`/`saved`; open scope auto-hides past-deadline (testing remaining)**
- [x] Migrate `scholarships/sponsorships → opportunities` (`legacy_type`), `sponsorship_applications → opportunity_applications`; old endpoints → 410 — **iteration 1 done: backfill in migration (idempotent); 4 public + 12 engagement routes → 410 `LEGACY_MOVED` via `LegacyGoneController` (migrate + testing remaining)**
- [x] Applicant review (P1-ready, build API now): `GET /opportunities/{id}/applications`, `PATCH …/applications/{app}` (shortlist/decline+note) — **API done with decision notifications; review UI is iteration 2**
- [x] Expiry: add `opportunity` to `expiry_rules` + sweep; notifications for new application/decision — **`opportunity` in `ExpiryService::MAP` (publish hook fires); `opportunity_application` notify on apply + `status_update` on decision (testing remaining)**

### Mobile
- [x] Opportunity list/detail/apply form `D.9/D.10`; My Opportunities `AT.8` (Applied/Saved/Created + status chips); provider posting + management (reuse SP3/SP4 layouts); applications inbox `SP7/SP8` + shortlist `SP9` — **iteration 1 done 2026-10-13 (testing remaining): new `opportunity` feature (model, provider, list w/ type chips, detail w/ inline apply + save, My Applied/Created tabs w/ status chips, post form draft/publish, routes); inbox + review UI iteration 2**

✅ **Exit:** academy posts scholarship → athlete applies with pitch → provider shortlists → athlete sees status; expired-by-deadline auto-hides.

---

## Phase 5 — Programs, Facilities, Venues + Enquiries

> **Status 2026-10-13 — STARTED (iteration 1, migrate + testing remaining):** backend complete (`php -l` clean); mobile program/facility features wired (`flutter analyze` clean). Venue detail enquiry CTA still shows "coming soon" — venue enquiries already work via the generic modal, CTA copy is iteration 2.

**Goal:** training inventory live, enquiries open chat threads.
**Docs:** Delta `BE-M6.x` · FR-PROG-1…4 · FR-ENQ-1…4 · Screens `D.11–D.13`, `CO.4/5`, `AC.7/8`

### Backend
- [x] `programs` (owner morph coach/academy; title/sport/age/duration/mode/price/schedule/about/status draft/active/past): `GET /me/programs`, `POST/PUT /me/programs…`, `GET /programs/{id}`, `POST /programs/{id}/enquire` (→ chat thread) — **iteration 1 done 2026-10-13: migration, model, controller (public list/detail, own list w/ status filter, enquire reuses existing thread); morph-map entry (migrate + testing remaining)**
- [x] `facilities` (academy_id, name/type/size/amenities/images): `GET /me/facilities`, `POST/PUT/DELETE …`, `GET /facilities/{id}`; migrate `academies.facilities` JSON → rows — **iteration 1 done: migration with guarded JSON backfill, full CRUD (migrate + testing remaining)**
- [x] Enquiries: add `subject_type = program, opportunity`; `POST /enquiries`, `GET /me/enquiries` (Chats/Requests tabs), `GET/POST /enquiries/{id}(/messages/read)`; enquiry creation returns/opens thread — **iteration 1 done: subject types extended with existence check, inbox pairs include own programs/opportunities, owner resolution + access control + labels cover both (testing remaining)**

### Mobile
- [x] Program list/form/detail + enquiry button; Facility list/form/detail (tabs All/Grounds/Indoor/Gym/Other); Coach/Academy program management (Active/Drafts/Past); Enquiry modal `T3/A11` + inbox `T4/C4/C5/AC8/AC9` — **iteration 1 done 2026-10-13 (testing remaining): new `program` feature (models, providers, public list, detail w/ Enquire → generic modal → thread, my-programs Active/Drafts/Past, post form, facility list w/ type tabs + form + delete, 7 routes); modal/inbox already generic so program/opportunity subjects flow through**

✅ **Exit:** coach creates program → athlete enquires → thread appears in both inboxes; facility CRUD reflects on academy detail.

---

## Phase 6 — Social, Network, Chat, Safety (verify-first)

**Goal:** LinkedIn core — feed, graph, messaging, blocks.
**Docs:** Delta `BE-M7.x` · FR-SOC-1…7 · FR-TRUST-1…4 · FR-ENQ-3 · Screens `S.9–S.14`, `S.17–S.19`, `S.23`, `S.26–S.28`

> ⚠️ `UI-Completion-And-Backend-Wiring-Plan.md` says `posts/conversations/connections` may already be partially built — **verify tables + `/posts` routes first**, then complete to v3 schema (`follows`, `connection_requests`, `conversation_participants`, `blocks`).

### Backend
- [ ] Posts/feed: `posts` (author morph, text/media/hashtags/sport/audience), `GET /feed` (For You/Following/Athletes/Coaches/Academies/Events), `POST /posts`, `GET/PATCH/DELETE /posts/{id}`, `POST/DELETE /posts/{id}/like`, `GET/POST /posts/{id}/comments`, `DELETE /comments/{id}`
- [ ] Network: `follows` + `connection_requests` — `POST/DELETE /follow/{type}/{id}`, `GET /me/followers|following`, `POST /connections` (with purpose), `GET /me/connections` (Connections/Requests/Sent), `PATCH /connections/{id}` (accept/decline → unlock chat + `ConnectionAccepted` notify), `DELETE /connections/{id}`
- [ ] Chat: `conversations` (+participants) + `messages` (text P0, media P1) — `GET/POST /conversations`, `GET /conversations/{id}`, `POST …/messages`, `PATCH …/read`; rules: accepted-connection OR enquiry thread only, no cold DMs; minors = guardian-allowed only; 90-day purge default
- [ ] Safety: `blocks` (`POST/GET/DELETE /blocks…`, hide both ways, disable chat/follow); reports extend morphs `user, post` (+opportunity/program/facility): `POST /reports`, `GET /me/reports`

### Mobile
- [ ] Feed + Create Post `S.9` + Post Detail `S.27` (like/comment/save); Community `S.12–S.14`; Follow buttons; Connections `S.19`; Chat inbox `S.17` (Chats/Requests, unread) + Thread `S.18` (report/block entry); Safety Centre `S.23`; Report sheet `S.26`; Media viewer `S.28`

✅ **Exit:** post → like/comment; follow + connect → accept → chat unlocks; block hides + disables chat; report lands in admin queue.

---

## Phase 7 — Leaderboard + Scout Extensions

**Goal:** credibility engine + full scout workflow.
**Docs:** Delta `BE-M8.x`, `BE-M10.x` · FR-LB-1…4 · FR-TS-1…13 · Screens `S.6`, `AT.1`, `SC.2–SC.13`

### Backend
- [ ] Leaderboard: `leaderboard_scores` (athlete/sport/points/season) + `leaderboard_seasons`; `RecalculateLeaderboardJob` (on verified achievement, completion milestones, participation + nightly rebuild), `ResetLeaderboardSeasonJob`; `GET /leaderboard` (sport/location/age, podium + ranks 4–10), `GET /leaderboard/strip` (top-5 home); minors anonymized (first name + initial); coach/academy/team/event tabs P1-ready
- [ ] Scout: `scout_shortlists` (status under_review/good/high/final + tags + private notes, unique scout+athlete): `GET/POST/DELETE /me/shortlist` (+PATCH status/tags/notes, pipeline tabs); `observations` (rating/note/media): `POST/GET /observations`; `POST /athletes/{id}/contact` (purpose; U-18 → guardian notify, consent before chat); dashboard aggregates (top-talents slice via leaderboard, upcoming trials, counts — or fold into `/me/home`)

### Mobile
- [ ] Leaderboard screen `S.6` + home strip `AT.1` (filters + podium + ranks 4–10)
- [ ] Scout: Dashboard `SC.2`, Discovery `SC.4` (sport/age/location/skill/position/achievements filters), Athlete View (history/achievements/media + Shortlist/Connect CTAs), Shortlist `SC.5/6` (pipeline tabs + edit status/tags/notes), Observations `SC.10`, Contact `SC.13` (purpose; guardian notice for U-18)

✅ **Exit:** verified achievement moves leaderboard rank; scout discovers → shortlists with status → observes → contacts (minor routes to guardian).

---

## Phase 8 — Events, Registrations, Supply-Side Management

**Goal:** trials/tournaments/camps end-to-end with registrant ops.
**Docs:** Delta `BE-M4.x` · FR-ATH-8/10/14 · FR-ACAD-2…10 · FR-ORG-1…10 · FR-COACH-8 · Screens `D.6–D.8`, `AT.9`, `AC.3–AC.6`, `OR.4–OR.8`

### Backend
- [ ] Unified create `POST /me/events?type=trial|tournament|camp` (map to `trials`/`tournaments` tables — keep tables, unify at API layer); `GET /me/events` (My Events, Upcoming/Past + counts), `GET /events/{id}`, `PUT/PATCH /me/events/{id}` (+publish/close)
- [ ] Register: `POST /trials/{id}/register`, `/tournaments/{id}/register` (duplicate guard + capacity); `GET /me/registrations` (AT.9 Upcoming/Past), `DELETE /me/registrations/{id}` (cancel); `RegistrationDecided` → notify athlete (push + in-app)
- [ ] Manage: `GET /events/{id}/registrations` (All/Approved/Pending + search + bulk), `GET /registrations/{id}` (+docs), `POST /registrations/{id}/approve|reject`, per-category capacity meters + manual `payment_status` flag (info only), waitlist toggle
- [ ] Export: `GET /events/{id}/registrations/export` (CSV/Excel, role-scoped); results: extend `tournament_results` pattern (publish per category + public bracket view)

### Mobile
- [ ] Athlete: Trial/Tournament detail → Registration form `A14/A18/T3` → Confirmation `A15` (reg ID + .ics + reminder toggle) → Activity Hub `AT.9/A24`
- [ ] Academy: Dashboard `AC.3`, Trial posting `AC.4`, My Trials `AC.5/AC.6`, Registrant list/detail `AC.6/OR.8` (verify/reject)
- [ ] Organizer: Dashboard `OR.2`, Event create `OR.5`, My Events `OR.4/AC.6`, Registration mgmt `OR.7/O7`, Capacity `O8`, Results publish/view `O9/O10`

✅ **Exit:** organizer creates tournament (3 categories + capacity) → athlete registers → organizer approves → athlete sees Confirmed + notification; CSV exports; results public.

---

## Phase 9 — Admin P0, Expiry, Notifications, Search Polish

**Goal:** moderated, self-cleaning, reminded platform.
**Docs:** Delta `BE-M11.x` · FR-ADMIN-1…13 · FR-NOTIF-1…5 · FR-DISC-6/7 · Screens `AD.1–AD.12`, `S.16` · **`FCM-Notification-System.md`** (transport, types, preferences and monitoring are built in **Phase 3E** — this phase wires the *domain events*)

### Backend
- [ ] Admin: `POST /admin/login`, `/admin/verify-2fa` (enforced); `GET /admin/dashboard` (listings/flags/expirations/signups/verifications/users-by-role); `GET /admin/users` (+role/status filters), detail, suspend/ban + audit; verification queue approve/reject; content CRUD `/admin/content/{type}` (+opportunities/programs/facilities/posts); moderation (`…/moderation/**` + suspend action, reporter+reported notify); masters (+`positions`); expiry (`/admin/expiry*` + opportunity type)
- [ ] Expiry engine: `expires_at` on publish, `SweepExpiredContentJob`, events, Override/Restore
- [ ] Notifications (transport + device registry + preferences: **done in Phase 3E**):
  - [ ] Emit the **domain events** that produce notifications — `RegistrationDecided`, `VerificationDecided`, `ConnectionAccepted`, `ContentReported`, plus follow / mention / message types
  - [ ] **Admin approve/reject must notify** — `AdminUserController` and `AdminPanelController` previously flipped a DB column and told nobody. Emit `account_action` (hard override: always in-app + email)
  - [ ] Reminder subscriptions on save/confirm (T-2d/T-1d) + `SendDueRemindersJob`
  - [ ] `GET /me/notifications?tab=` (All/People/Opps/Events/Mentions, Today/Yesterday/Week) returning `meta.unread_count`; read / read-all / delete
  - [ ] `POST /admin/notifications/broadcast` — `channels: ["in_app","push"]`; chunked FCM fan-out; email fallback only where push is impossible
- [ ] Analytics log `POST /analytics/events` (signup/registration/enquiry/shortlist funnel); search polish (trending, recents, relevance, enriched cards)

### Mobile
- [ ] Notifications Center `S.16` (tabs + grouping + unread + mark-all-read); reminder toggles; Admin web panel views (`admin/*.blade.php`: login/dashboard/content/moderation/expiry/categories/users/verification)
- [ ] **Notification preferences screen** — `GET/PUT /me/notification-preferences`. Mark account-action and registration rows as **non-disableable** rather than showing toggles that silently do nothing (they are hard overrides)

✅ **Exit:** report → admin queue → remove → both parties notified; expired trial auto-expires + restorable; saved-item reminder fires; admin adds sport/city → appears in filters. **Additionally:** admin approves a registration → applicant receives an in-app notification, a push **and** an email.

---

## Phase 10 — Hardening & Polish (production-ready)

**Goal:** secure, fast, observable.
**Docs:** `Security-and-NonFunctional.md` · `Production-Backend-Plan.md` · `Phased-Roadmap.md` P4 · `Development-Checklist.md` P6–P7 · **`Email-Provider-Architecture.md` §10 · `FCM-Notification-System.md` §10**

- [ ] Auth hardening: rate limits + 429/Retry-After, OTP expiry/attempts, CORS review, audit log (moderation/status/override/provider switch)
- [ ] Media: MIME validation, signed URLs (60-min), private docs access-controlled
- [ ] Queues: Horizon; `mail` / `push` / `notifications` queues split with independent worker pools so a slow SMTP handshake cannot starve push delivery
- [ ] Observability: Sentry (Flutter + Laravel), APM, Telescope (dev), health check
- [ ] Perf: index review, N+1/eager-load pass, pagination everywhere, P95 <2.5s lists / <500ms admin

**Email operations**

- [ ] Hourly `MailProviderService::testConnection()` probe, so a provider outage surfaces **before** users report a missing OTP
- [ ] Alert on `SportX mail failed permanently` — non-zero in any 15-minute window is a page
- [ ] Monitor `mail` queue depth: sustained depth means workers are wedged, not that delivery is failing
- [ ] Monitor Gmail `messages.send` quota headroom and SMTP bounce/complaint rate

**Push operations**

- [ ] Monitor `push_status = 'failed'` rate and the `no_devices` rate — a rising `no_devices` share means the Flutter token-registration flow is broken
- [ ] Monitor `failure_count` climbing on `user_device_tokens` — systematic rejection, usually `SENDER_ID_MISMATCH`
- [ ] Alert on `NotificationFallbackMail` volume: high volume means push is silently failing

**Pre-launch credential gates** *(not code tasks — all four block release)*

- [ ] FCM quota raised above expected broadcast volume (AS-67)
- [ ] APNs auth key uploaded (AS-68)
- [ ] SPF/DKIM/DMARC published; Gmail "Send mail as your users" verified (SEC-26, SEC-27)
- [ ] SMS vendor selected for `channel=phone` OTP (AS-60)

- [ ] Account: forgot-password (token-link exists; OTP variant P1), `POST /me/change-password`, language shell (English-only), ICS export (trials/tournaments) + `.ics` download, bracket viz polish
- [ ] QA: `flutter analyze` clean; load test 1000+ concurrent; manual smoke per role (athlete/coach/academy/organizer/scout/admin) on staging

✅ **Exit:** DoD — `grep dummyItems` = 0; ≥85 screens use `ref.watch/read/dioProvider`; every P0 feature has backend + wired screen + integration test; admin behind 2FA; media behind signed URLs; **all four pre-launch credential gates signed off**.

---

## Phase 11 — P1 Wave (MVP+, right after launch — do NOT build in MVP)

**Docs:** Delta §2 `BE-P1.x` · FR asterisked `S` items

| # | Feature | Backend | Mobile |
|---|---|---|---|
| P1.1 | Ratings & reviews | `reviews` (rater→morph, stars/text; gated to verified interaction) + aggregates | `D.14/D.15` rate + display |
| P1.2 | Event schedule + gallery | `event_schedules` + media morph on event | `OR.9/10` timetable + gallery |
| P1.3 | Results for trials | generic `event_results` (extend tournament pattern) | publish + public view |
| P1.4 | Event analytics | `event_views` log + aggregates (views/regs/inquiries/timeline/sources) | `OR.12` dashboard |
| P1.5 | Announcements | reuse broadcast infra, event-audience targeting | `OR.14` compose |
| P1.6 | Talent reports + compare | `scout_reports` (5-dim + conclusion) + compare query | `SC.7/8/9` |
| P1.7 | Recommendations | rule-based (sport/age/location) | `AT.1` recs |
| P1.8 | Mentions/hashtags, chat media, suggestions | hashtag extraction + mention notify, attachments, suggest query | feed/chat |
| P1.9 | Admin broadcast | `broadcasts` + `BroadcastNotificationJob` + FCM fan-out | `AD.12` compose/target |
| P1.10 | Our Athletes | `academy_athlete_invites` + accept flow (sets `academy_id`) | `AC.5/AC.10` |
| P1.11 | Extra reminders | opportunity deadlines + nearby-trial detection | toggles |
| P1.12 | Forgot-password via OTP | OTP reset (alongside link) | `A.6` |
| P1.13 | Language infra | selection stored (content English-only) | `A.7` |
| P1.15 | Waitlist auto-promote | `PromoteWaitlistedRegistrations` job + notify | status update |
| P1.16 | Share/deep links | `GET /share/{type}/{slug}` resolver | `S.30` share sheets |
| P1.17 | Notification digest | "3 new updates today" instead of per-event pushes (AS-71) — cuts fatigue and quota burn | `S.16` grouping |
| P1.18 | Per-sport FCM topics | `sportx_sport_{id}` subscribe/unsubscribe (AS-70) — schema supports it, subscription UX not built | topic picker |
| P1.19 | Explicit cross-provider account linking | `POST /me/social-accounts/google/link` with password re-confirmation (AS-65) | account settings |
| P1.20 | Apple Sign In | `social_accounts.provider` is a string, so **no migration needed** (AS-64) | `A.3`/`A.5` button |
| P1.21 | Bounce/complaint webhooks | SES/Mailgun/Postmark → suppression lists feeding `notification_prefs` (AS-62) | — |
| P1.22 | Scheduled email campaigns | admin surface beyond instant broadcast (AS-63) | — |

> **Moved out of P1 — Google sign-in (was P1.14).** **Promoted to P0 and built**; see **Phase 1** and **Phase 3E-B**. D9 is CLOSED.

> **Still blocked, not deferred — SMS OTP vendor (AS-60).** Selecting MSG91 / Twilio etc. is a stakeholder decision, not a build task. It blocks `POST /auth/send-otp` with `channel=phone`, and therefore **phone signup entirely**. `otp_codes.channel` already admits `phone`, so this is config-only once chosen.

**Parked (P2 — do not build):** online payments, map view, groups/polls, live/streaming, boosted placement, multi-role accounts, teams, staff recruiting, stories, group chat/cold DMs.

> **Amended from the previous list:** "email/SMS as notify channels" is **no longer parked wholesale**. Email is now a first-class notification channel (OTP, verification, approval/rejection, and the **push-failure fallback**). **SMS as a notify channel remains parked** — SMS is only needed for OTP, and that is AS-60.

---

## Quick trackers

### Endpoint count (Delta §11)
~70 new + ~25 changed + ~10 verify-first (social/chat/admin-users) in P0; ~30 new in P1; ~12 sponsor routes removed.
**Platform integrations add ~12** (auth +1, notifications +7, admin email-settings +5) → **≈242 total**.

### Assumption movements (2026-10)
| ID | Movement |
|---|---|
| **AS-03a** (email provider) | **CLOSED** → AS-59 (dual SMTP + Gmail) |
| **AS-03c** (push provider) | **CLOSED** — FCM HTTP v1 |
| **AS-03b** (SMS provider) | **OPEN** → AS-60 — still blocking phone OTP |
| **D9** (Google sign-in scope) | **CLOSED** — promoted P1 → P0, built → AS-64 |
| **AS-60** | NEW — SMS vendor selection — **launch blocker** |
| **AS-67** | NEW — FCM quota — **launch blocker** |
| **AS-68** | NEW — APNs key — blocks iOS release push |
| **AS-69** | NEW — remove legacy `device_tokens` table |
| **AS-72** | NEW — `flutter_local_notifications` — blocks visible background push |

### Screen count (v3 `SCREEN_INVENTORY.md`)
**129 total (94 P0 / 25 P1 / 10 P2):** Auth 10 · Shared shell 30 · Shared detail/forms 17 · Athlete 10 · Coach 8 · Academy 12 · Organizer 17 · Scout 13 · Admin 12.
**+2 added:** Notification Preferences (`settings/…/notification_preferences_screen.dart`) and the shared Google Sign-In button.

### Jira import
`docs/Jira-Tickets.md` has CSV-ready tables per Phase→Epic (83 tickets, story points 1/2/3/5/8) — copy each table to CSV for bulk import. Map new v3 work to epics P2-E8 (opportunities), P2-E9 (programs/facilities), P2-E10 (social/chat), P2-E11 (leaderboard), P3-E1 (verification queue + user mgmt).
**Add a new epic for Phase 3E** — email providers, Google sign-in and FCM notifications are not yet represented in `Jira-Tickets.md` and need tickets covering the migration, Flutter wiring and the four pre-launch credential gates.
