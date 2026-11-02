# SportX — Full Production Readiness Audit (2026-11-02)

> Scope: entire repo — `sportx-api` (Laravel backend, 361 routes), `sportx_app` (Flutter, 281 dart files / ~174 screens), plus config, git hygiene, and docs.
> Method: backend route/controller audit, Flutter screen/wiring audit, screen ↔ endpoint cross-check per role, and infrastructure/secrets review. All findings verified against current code (not just docs).
> Companion docs this supersedes/updates: `PRODUCTION_READINESS_AUDIT.md` (older), `WIRING_REMAINING.md` (partially stale — see §6), `BACKEND_INTEGRATION_MISSING_SCREENS.md` (mostly stale).

---

## 1. Executive Verdict

**NOT production ready yet.** The core product is genuinely close — the majority of the app is wired end-to-end (auth, profiles, directories, trials/tournaments, registrations, enrollments, enquiries, chat, notifications, media, scouting, admin core), the backend has ~220 real feature tests, throttling, scheduled jobs, and no SQL-injection or mass-assignment risks, and `flutter analyze` is clean (0 errors).

But there are **5 security blockers**, **10 security/deployment HIGH items**, and a short list of **role features that are screens without backends** (or vice versa). Estimated fix effort before launch: the blockers are days, not weeks.

### Blocker summary

| # | Severity | Issue | Where |
|---|---|---|---|
| B1 | 🔴 BLOCKER | Login MFA bypass — any client sends `require_otp=false` and skips email OTP | `sportx-api/app/Http/Controllers/AuthController.php:194` |
| B2 | 🔴 BLOCKER | Secrets committed to git: release keystore, `CREDENTIALS.md` (APP_KEY + DB password), `TEST_CREDENTIALS.md` (+ TOTP secret in `tests/api/.admin_totp_secret.txt`) | repo root, git-tracked |
| B3 | 🔴 BLOCKER | Admin panel (Blade `/panel`) 2FA disabled; API admin 2FA has `ADMIN_2FA_ENFORCE=false` fallback that accepts **any** 6-digit code | `AuthenticateAdminPanel.php`, `AdminAuthController.php:58-72`, `AdminPanelController.php:65` (TODO) |
| B4 | 🔴 BLOCKER | Media upload IDOR — `owner_type`/`owner_id` accepted from client without ownership check; any user can attach media to someone else's profile and grief quotas | `MediaController.php:197-209` |
| B5 | 🔴 BLOCKER | Production config still local: `APP_ENV=local`, `APP_DEBUG=true`, `MAIL_MAILER=log` (OTPs would never be delivered by email), app `.env` points at a temporary ngrok tunnel | `sportx-api/.env`, `sportx_app/.env` |

---

## 2. Role × Feature Readiness Matrix

Roles in the current codebase: **Athlete, Coach, Academy, Organizer, Talent Scout, Admin** (Sponsor was cut over to unified "Opportunities"; legacy sponsor endpoints return 410). There is **no separate Guardian role by design** — guardian consent is driven from the minor-athlete's account.

Legend: ✅ READY · 🟡 PARTIAL · ❌ MISSING (screen or backend absent) · ⚠️ MISMATCH (wired but broken)

### Shared / all roles

| Feature | Verdict | Notes |
|---|---|---|
| Auth (register, login, OTP login, forgot/reset, Google, logout) | ✅ | Shapes match; but see B1 (OTP bypass) and HIGH-1 (tokens never expire) |
| Profile edit, multi-sport, images | ✅ | |
| Media uploads, quota, gallery | ✅ | Except B4 (IDOR) |
| Notifications + FCM push + preferences + device tokens | ✅ | FCM service-account JSON exists locally but is **not** git-tracked — needs provisioning story on the server |
| Chat / conversations | 🟡 | Fully wired **but app never calls `POST /conversations/{id}/read`** → server unread counts never clear (`chat_provider.dart`) |
| Connections, follow, block, report | ✅ | |
| Saved items, search, recent searches | ✅ | |
| Settings, privacy, password change, delete account, social links | ✅ | |
| Leaderboards (board, strip, mine) | ✅ | |
| Social feed (posts, likes, comments) | ✅ | |
| Groups (list, join, leave) | 🟡 | Real backend now exists (`GroupController`) — but no `GET /groups/{id}`; group detail uses client-side `extra` only |
| **Reviews / ratings** | ❌ | No endpoints exist in `routes/api.php`; `/reviews` + `/write-review` screens render with zero network calls |
| **Payments** | ❌ | No gateway (by design). Organizer manually flips `payment_status` — fine for MVP, but fees are display-only |
| **Attendance / match schedule** | ❌ | Absent on both sides (no `/tournaments/{id}/schedule` endpoint, no screens) |

### Athlete / Parent

| Feature | Verdict | Notes |
|---|---|---|
| Onboarding (sport/age → skill/location) | ✅ | |
| Home, Discover, Explore, universal search + filters | ✅ | |
| Trial & tournament registration (incl. external registration click-tracking) | ✅ | |
| My registrations, cancel, ICS calendar, reminders | ✅ | |
| Coaching enrollment (book a coach) | ✅ | |
| Programs + enquiries | ✅ | |
| Opportunities (unified scholarships/sponsorships) — browse, apply, mine | ✅ | Legacy 410 routes correctly never called |
| Achievements CRUD + certificate upload | ✅ | Backend PUT edit endpoint unused by app (minor) |
| Media gallery + quota | ✅ | |
| Blue-check verification + completion checklist | ✅ | Checklist items themselves hard-coded client-side (cosmetic) |
| Guardian consent (OTP) + guardian controls | ✅ | Revoke endpoint unused (minor) |
| Scout connections (athlete side accept/reject) | ✅ | |
| Tournament calendar | ✅ | Uses standard `/tournaments` listing (older doc's `/tournaments/calendar` never existed — doc stale) |
| Profile completion screen | 🟡 | Wired to profile data but checklist is hard-coded |

### Coach

| Feature | Verdict | Notes |
|---|---|---|
| Coach profile (view/edit/post, credentials) | ✅ | |
| Enrollment approvals (approve/reject with dates/reason) | ✅ | |
| Enquiry inbox + reply | ✅ | |
| **Showcase athletes** | ⚠️ | **Two runtime bugs:** ① `coach_provider.dart:233` calls `GET /athletes?search=` but that route is gated `role:sponsor,talent_scout,athlete` → coach gets **403**. ② Save sends `showcase_athletes` in `PUT /me/coach-profile`, but `CoachProfileController::update()` validation has **no such rule** (and no DB column) → silently dropped. Fix both or cut the screen. |
| Coach Go Live | ❌ | Screen with zero network calls; no live-session endpoint (marked P2) |
| Browse sponsorships (coach side) | ✅ | Via unified opportunities |

### Academy

| Feature | Verdict | Notes |
|---|---|---|
| Academy profile (view/edit) + dashboards | ✅ | |
| Trial posting, registrant review (verify/approve/reject, docs via signed URLs) | ✅ | Shared with coach via `ProviderTrialController` |
| Facilities CRUD | ✅ | |
| **Academy staff management** | ❌ | Screen `/academy-staff` complete; **no `/me/academy/staff` endpoints** |
| **Collaborations** | ❌ | Screen complete; no `/me/academy/collaborations` endpoints |
| **Invite athlete** | ❌ | Screen complete; no `/me/academy/invitations` endpoints |

### Organizer

| Feature | Verdict | Notes |
|---|---|---|
| Organizer profile + public org page | ✅ | |
| Team management (`/me/organizer/team`) | ✅ | Backend + app both wired |
| Unified event posting (trials + tournaments), categories, capacity + waitlist | ✅ | |
| Registration management (approve/reject, bulk, CSV export) | ✅ | |
| Results publishing (publish/unpublish, bracket image) | ✅ | |
| Organizer analytics | ✅ | |
| Announcements | ✅ | Implemented via `POST /posts` (workaround, works) |
| Payment status flip | ✅ | Manual only — no gateway |

### Talent Scout

| Feature | Verdict | Notes |
|---|---|---|
| Scout onboarding + profile | ✅ | |
| Athlete discovery + filters | ✅ | |
| Private shortlist + notes | ✅ | |
| Two-way connections (scout ↔ athlete) | ✅ | |
| Observations + athlete contact | ✅ | |
| Scout dashboard aggregate | ✅ | `GET /scout/dashboard` exists but is unused by the app (harmless surplus) |

### Admin

| Feature | Verdict | Notes |
|---|---|---|
| Admin login + 2FA (API) | ✅ | But see B3 (enforce-fallback + panel 2FA off) |
| Dashboard, verification queue, content CRUD, moderation, expiry rules/monitor/override, categories, user management, opportunity approvals, broadcast notifications, settings | ✅ | All wired both sides |
| **Notification targeting screen** | ❌ | No `POST /admin/notifications/targeted` endpoint; screen has zero network calls |
| **Leaderboard config screen** | ❌ | No `/admin/leaderboard-config` endpoint; screen has zero network calls |
| **Master data screen** | ⚠️ | `GET/POST/PUT/DELETE /admin/categories/*` **exist and are wired in `admin_provider.dart`** — but `admin_master_data_screen.dart` still renders hard-coded local lists and never calls the provider |
| **Generic record edit screen** | ❌ | No generic admin CRUD API; screen has zero network calls |
| Audit logs, email settings, registration analytics, admin approve/reject overrides | 🟡 | Backend endpoints exist and work — **no admin UI calls them** (backend-only surplus) |

---

## 3. Security Findings (backend)

| # | Severity | Finding | Location |
|---|---|---|---|
| B1 | 🔴 | **Login MFA bypass**: `$enforceOtp = $request->has('require_otp') ? $request->boolean('require_otp') : !app()->runningUnitTests();` — a client can send `require_otp=false` and get a token with just email+password | `AuthController.php:194-196` |
| B4 | 🔴 | **Media upload IDOR**: client-supplied `owner_type`/`owner_id` not verified against the authenticated user | `MediaController.php:197-209` |
| B3 | 🔴 | **Admin 2FA**: Blade panel bypassed entirely (`AuthenticateAdminPanel.php` warns "must be re-enabled before production"; `AdminPanelController.php:65` TODO for TOTP); API accepts any code when `ADMIN_2FA_ENFORCE=false` | `AdminAuthController.php:58-72` |
| H1 | 🟠 | **Sanctum tokens never expire** (`'expiration' => null`), no refresh flow; revocation only on logout/password-reset | `config/sanctum.php` |
| H2 | 🟠 | **Reset tokens stored plaintext** in `users.reset_password_token` | `AuthController.php:339-366` |
| H3 | 🟠 | **Email verification is cosmetic**: `email_verified_at = now()` set at register | `AuthController.php:62` |
| H4 | 🟠 | **Pending-account enforcement missing**: register/OTP-verify issue tokens to `pending` users; the comment says middleware will block writes — that middleware **does not exist**. A pending provider's token may still work until next login | `AuthController.php:66` |
| H5 | 🟠 | **Media on public disk**: uploads go to `storage/app/public` → guessable public URLs; signed URLs protect the *link*, not the file | `MediaController` |
| H6 | 🟠 | **No global API rate limiter** (only per-route `throttle:`); CORS defaults to `*` when `CORS_ALLOWED_ORIGINS` unset | `AppServiceProvider`, `config/cors.php` |
| H7 | 🟠 | **`/notifications/{id}/send-push`** exposed to any authenticated user | `routes/api.php:429` |
| H8 | 🟠 | **Platform settings in a local JSON file** (`storage/app/platform_settings.json`) — breaks on multi-server/immutable deploys, invisible to admin tooling | `PlatformSettings` |
| M1 | 🟡 | Sensitive provider routes rely on in-controller ownership checks instead of route-level role middleware (defense-in-depth gap; spot-checks show controllers do enforce ownership today) | e.g. `/registrations/*`, `/me/trials|tournaments` |
| M2 | 🟡 | Dev cruft git-tracked in backend: `check.php` (password-guessing probe), `scratch_users.php`, `test_schol.php`, `tests/api/.admin_totp_secret.txt` | repo |
| M3 | 🟡 | Two overlapping registration-approval migrations + future-dated migration names → fragile migration ordering | `database/migrations/2026_09_17_*` |
| L1 | ⚪ | No Form Request classes — all inline `$request->validate()` (works, but untestable/reusable) | app-wide |

**Verified clean:** no SQL injection vectors (all raw SQL is constant/aggregate), no `$guarded = []` mass assignment, centralized JSON error envelope without stack traces, OTP service is genuinely well built (bcrypt-hashed codes, attempt caps, per-destination rate limits, resend cooldown, double-gated test mode).

---

## 4. Flutter App Findings

**Good:** single Dio client with auth interceptor + GET dedup (`lib/core/utils/api_client.dart`); 401 → force logout + provider reset (no token-refresh needed for Sanctum); all data through Riverpod providers; `flutter analyze` clean (49 style infos, 1 warning, 0 errors); meaningful unit/widget tests in `test/` (models, api client, role config); go_router redirect enforces role onboarding, role-gates listing-creation routes, and redirects legacy sponsor routes to `/opportunities`.

**Issues:**

| Severity | Issue |
|---|---|
| 🟠 HIGH | `.env` committed in pubspec assets ships `API_BASE_URL` pointing at a **temporary ngrok tunnel** — a release build would call a dev tunnel. Must be swapped for the production URL at build time. |
| 🟡 MEDIUM | `WIRING_REMAINING.md` is stale: items 4, 5, 10, 14, 16, 17, 18 are now wired (organizer team, announcements, admin expiry rules, groups, verification, guardian controls, manage sports). Trust §2 of this report, not that doc. |
| 🟡 MEDIUM | Dead sponsor code (`features/sponsor/**`, `sponsor_provider.dart`) still calls endpoints that return 410 — unreachable today but a regression time bomb. Delete per WIRING doc §4. |
| 🟡 MEDIUM | Chat unread counts never clear — app never calls the read endpoint. |
| ⚪ LOW | 3 `use_build_context_synchronously` lint spots (potential crashes after async gaps); Coach/Academy/Organizer dashboards differ only via `role_config.dart` — fine, but every role shares one shell (v3.2 IA), so a route typo can expose a wrong-role screen (router currently guards the known ones). |

---

## 5. Infrastructure / Deployment

| Item | Status |
|---|---|
| Backend scheduler | ✅ Wired (`routes/console.php`): expiry sweep hourly, reminders every 15 min, OTP purge daily, leaderboard recalc daily, mail probe. **Requires** `php artisan schedule:work` / cron + Horizon queue worker in production (`QUEUE_CONNECTION=database`). |
| Mail/OTP delivery | ⚠️ Code supports SMTP + Gmail-API providers with failover and an admin runtime switch — but current `.env` is `MAIL_MAILER=log`. Must configure a real provider before launch or **OTP emails go to the log file**. |
| FCM push | ⚠️ Service-account JSON exists locally, correct path in `.env`, `FCM_ENABLED=true` — but the file is untracked, so document/provision it on the server. |
| CORS | ⚠️ Set `CORS_ALLOWED_ORIGINS` in production (defaults to `*`). |
| Android release | ⚠️ Signing config exists (`keystoreProperties` + fallback to `my-release-key.jks`) — but the keystore is **committed to git** (see B2). Rotate the key, move to a secret store, and never commit it again. |
| iOS | ⚪ Directory present; no release evidence found in this audit. |
| Server | `SERVER-SETUP.md` documents a VPS (45.196.196.118); `.env` also references an HTTP IP — confirm TLS terminates properly in production (ngrok/cloudflare tunnels are dev-only). |
| Monitoring | ⚪ Sentry was removed from the app (broke Android debug build per pubspec comment) — no crash reporting alternative in place. Backend has Sentry configured but empty DSN. |
| Load testing | `10k-user-load-test.md` exists as a plan; no results/CI evidence found. |

---

## 6. Remaining Work Checklist

### Must fix before production launch (security)

1. **B1** — Remove the `require_otp` client override in `AuthController.php:194` (server-decide only; allow test override via the existing unit-test detection).
2. **B4** — In `MediaController::upload()`, derive `owner_type/owner_id` server-side from the authenticated user (or verify ownership) — also add a negative IDOR test.
3. **B3** — Implement panel TOTP (`AdminPanelController.php:65` TODO), remove/flip the `ADMIN_2FA_ENFORCE` fallback, re-enable `admin.panel` 2FA middleware.
4. **B2** — Rotate the Android signing key, remove `my-release-key.jks`, `CREDENTIALS.md`, `TEST_CREDENTIALS.md`, `tests/api/.admin_totp_secret.txt`, `check.php`, `scratch_users.php`, `test_schol.php` from git (they remain in history — treat all rotated secrets as compromised).
5. **B5** — Production `.env`: `APP_ENV=production`, `APP_DEBUG=false`, real mail provider, real `APP_URL`; build the app against the production `API_BASE_URL` (not ngrok). Set `CORS_ALLOWED_ORIGINS`.
6. **H4** — Add a `status=active` check to `EnsureRole`/auth flow so `pending`/`suspended` users' existing tokens are rejected.
7. **H1/H2/H6** — Set a Sanctum `expiration` (or add token pruning), hash reset tokens, register a global `api` rate limiter.

### Must fix (functional bugs)

8. **Coach showcase athletes** — add `role:coach` to `GET /athletes` or give coaches their own search endpoint; add `showcase_athletes` to `CoachProfileController::update()` validation + a DB column (or remove the screen).
9. **Chat read receipts** — call `POST /conversations/{id}/read` when a thread opens (`chat_provider.dart`).

### Decide + implement (features with screens but no backend)

10. Reviews/ratings (both sides) — or hide `/reviews` + `/write-review` for launch.
11. Academy: staff, collaborations, invite-athlete endpoints — or hide those three screens.
12. Admin: notification targeting, leaderboard config, generic record edit — or hide those screens; also point `admin_master_data_screen.dart` at the already-wired `/admin/categories/*` provider.
13. Attendance/match schedule — explicitly out of scope today; confirm it's a post-MVP item.

### Should do soon

14. Delete dead sponsor feature code (`features/sponsor/**`, `sponsor_provider.dart`).
15. Move `platform_settings.json` into the DB (admin-editable, multi-server safe).
16. Wire `/admin/audit-logs`, `/admin/email-settings`, registration analytics, and admin override endpoints into admin UI (they exist but have no UI).
17. Crash reporting: re-add Sentry (or an alternative) once the Android build issue is solved.
18. Stale docs cleanup: update `WIRING_REMAINING.md`, `BACKEND_INTEGRATION_MISSING_SCREENS.md`, `FEATURES.md` (sponsor cutover, group backend, guardian endpoints) so the next developer isn't misled.
19. Consolidate the overlapping registration-approval migrations before freezing a production DB baseline.
20. Confirm iOS release path, load-test execution, and Horizon/cron supervision on the VPS.

---

## 7. What's genuinely solid (for the record)

- End-to-end wiring: auth/onboarding, athlete discovery→registration→approval loop, coach/academy/organizer provider flows, scout tooling, and the admin core all match request/response shapes across the stack.
- ~220 meaningful Laravel feature tests including role-gate, OTP, guardian-consent, quota, and 2FA regression suites; Flutter model/widget tests present.
- OTP service (hashed codes, attempt caps, per-destination limits), photo quota with transactional counters + compression pipeline, expiry engine + reminder scheduler, ICS calendar, audit/activity logging, universal approval pattern implemented consistently.
- No payment exposure (by design), no SQL injection, no mass assignment, centralized JSON error handling, per-route throttling on all sensitive endpoints.

---

## 8. Fix log (2026-11-02, same day as audit)

| Audit item | Fix |
|---|---|
| B4 — Media upload IDOR | `MediaController` now verifies client-supplied `owner_type`/`owner_id` against the authenticated user via a shared `ownsOwner()` helper (also reused by `destroy`); spoofed owners get 403. Two regression tests added (`MediaUploadTest`). |
| Chat unread counts | `chat_provider.dart` now calls `POST /conversations/{id}/read` when a thread opens and refreshes the conversation list. |
| Profile completion screen | Verified already data-driven in current code (computed from `/me/profile` via `role_requirements.dart`) — no change needed; older docs were stale. |
| Coach Go Live (stub) | Screen, route, and Create-sheet tile removed. |
| Admin web panel — 2FA (P0 TODO) | Panel now runs a real TOTP challenge: login redirects to `/panel/2fa`, first-time enrollment provisions a secret via `TotpService` and shows the otpauth URL, `AuthenticateAdminPanel` requires the `admin_2fa_ok` session flag. `ADMIN_2FA_ENFORCE=false` remains the local-dev escape hatch (matches the API). |
| Admin web panel — Leaderboard config | New `/panel/leaderboard` page (weights, active season, manual rebuild) backed by new PlatformSettings keys; `LeaderboardService` now reads runtime weights. Matching API endpoints `GET/PUT /admin/leaderboard-config` + `/reset` added. |
| Admin web panel — Targeted notifications | Broadcast form gains city/sport audience filters; shared filtering logic extracted to `App\Support\BroadcastTargeting` (handles `academies.owner_user_id` and the `athlete_sports.athlete_id` pivot correctly). API endpoint `POST /admin/notifications/targeted` added. |

Not changed (per request): Flutter admin screens (`admin_master_data_screen` etc.) — the mobile admin master-data edits were reverted.

**Follow-up (same session) — gallery excludes profile/cover/verification media:**
- `GET /me/media` and `GET /me/media/quota` now consider only gallery-context photos (legacy NULL-context rows included); the quota counter self-repairs if it has drifted from the real rows.
- The `mediaItems` relation on `AthleteProfile`/`CoachProfile` (and `Academy::photos`) is scoped to gallery context, so the profile page's Media card and discovery galleries exclude profile photos, covers, logos, and credential (verification-badge) uploads too. Delete-side quota decrement treats NULL context as gallery.
- Regression test added: uploading profile + cover + credential + gallery yields 1 gallery item in `/me/media` and `/me/profile` media_items, and quota `used = 1`.

**Follow-up 2 (same session) — social feed / follow-connect / chat hardening** (findings from the line-level review of `PostController`, `FollowController`, `ConnectionController`, `ConversationController`, `BlockController` and the matching Flutter screens):

Backend:
- Chat now notifies recipients on every message (in-app + push via `NotificationService`, type `message`, best-effort).
- `GET /me/conversations` returns a real `unread_count` per conversation (computed from `last_read_at`, NULL-safe); `GET /conversations/{id}` now paginates messages (`?messages_limit=`, default 100, `has_more` flag) instead of loading the entire history, with an `id` tiebreaker for same-second ordering.
- **Group-chat safety bypass closed**: creating a group now requires an accepted connection (or scout connection) with every participant, plus block + minor-consent checks; group sends re-check guardian consent per participant. Clients can no longer forge `type: system` messages (validation restricted to `text,image`).
- Blocks are now enforced on public posts too: blocked pairs get 404 on `show`, cannot like, cannot comment/read comments. `toggleLike` also enforces `followers` visibility. `show()`/feed now return resolved multi-image `images` URL lists; `image_url` is validated to platform `/storage/` paths only.
- Feed payload no longer hydrates every comment of every post (comments come from the paginated per-post endpoint; top-level comments now thread `replies`).
- Comment replies now notify the parent-comment owner as well.
- Connection requests: route throttled (10/min) **and** capped at 3 requests per target per day (decline-spam loop closed); self-request type-juggling bypass fixed (`(int)` cast — also in chat `store`).
- New follows notify the followed user; `ensurePrivateConversation` is lock-guarded against the duplicate-thread race.

Flutter:
- Chat screen polls every 4s while open (no more blind thread), keeps the text in the box on send failure with an error snackbar, renders system messages as centered chips, and the chat list shows per-conversation unread badges.
- Feed is paginated: new `paginatedPostsProvider` (family by filter) with load-more in the Community screen — previously only the first 15 posts were reachable. Likes update in place (no feed reload/scroll jump). Multi-photo posts render (first image + count badge on cards; swipeable gallery on detail).
- 8 new backend tests in `tests/Feature/SocialHardeningTest.php` — all passing; full suite 239 passed with the 3 pre-existing environmental failures (leaderboard ordering, GD compression, openssl keygen) reproducing on the untouched codebase; `flutter analyze` clean (0 errors).

Verification: PHP lint clean on all touched files; `php artisan test` — MediaUploadTest (incl. new IDOR tests), AdminPanelTest, PhotoQuota all pass; the one `AthleteLeaderboardTest` failure reproduces on the unmodified codebase (pre-existing). `flutter analyze` clean — no issues in touched files.

Environment note: PHP GD extension was disabled in `D:\php84\php.ini` (2 media tests failed on it); enabled during this session.
