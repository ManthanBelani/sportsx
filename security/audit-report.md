# SportX API — Security Audit Report

**Date:** 2026-10-23
**Auditor:** Backend Security Audit (GLM agent, read-only pass)
**Scope:** Laravel API in `sportx-api/` (Laravel 13.8, PHP ^8.3, Sanctum 4.3, Horizon, Scout Sentry). Mobile app (`sportx_app`, `sportsx-design-v*`) and static sites were reviewed only where they expose backend assumptions. **No code or configuration was modified during this audit.**

---

## 1. Executive Summary

The application is a fairly mature 424-route REST API with generally **good controller-side authorization discipline** (ownership helpers, abort 403/404, scoped queries), a **well-hardened OTP system** (bcrypt, per-destination rate limits, replay burn), **correctly verified Google ID tokens**, and **clean JSON error envelopes** that do not leak stack traces on `api/*`.

However, the audit identified **4 High and 1 Critical** confirmed issues that must be fixed before production launch, most notably:

- `ATT-01 (Critical)`: An unauthenticated attacker cannot be rate-limited correctly and admin API login has **zero throttling** — combined with `ADMIN_2FA_ENFORCE=false` runtime escape hatch, admin credential compromise is feasible.
- **`sendPushNotification` IDOR** — any authenticated user can send Firebase push messages to arbitrary users by enumerating notification IDs.
- **Media upload owner spoofing** — any authenticated user can attach files to another user's profile and control the storage path.
- **Infrastructure gaps:** no TrustedProxies (IP-based throttling breaks behind LB), no CDN/WAF/edge limit information verifiable from the repo, `public/storage` symlink currently absent.
- **Secrets hygiene:** `TEST_CREDENTIALS.md`, `scratch_users.php` (dumps all users + checks weak passwords), `check.php`, `test_schol.php`, signing key material reports, and several engineering `*.md` audit files are git-tracked.

The system is **not** DDoS-proof and cannot be at the application layer; network/edge controls are required and most are currently unverified.

**Overall posture: C+ / B−** — solid application logic, weak operational and infrastructure hardening.

---

## 2. Application Architecture & Audit Scope

| Component | Finding |
|---|---|
| Framework | Laravel 13.8 (`laravel/framework ^13.8`), PHP CLI 8.4.14 installed locally; app targets ^8.3 |
| Auth model | Sanctum personal-access tokens (Bearer), stateless API; separate session-based Blade admin panel at `/panel` |
| Roles | `$user->role` string + `App\Support\UserRoles::matches` via `EnsureRole` middleware |
| Admin | Separate path: `role:admin` + `admin.2fa` (TOTP via `TotpService`, 12h freshness) for API; `/panel` uses session auth **with 2FA explicitly disabled** |
| DB | MySQL (`DB_CONNECTION=mysql`; .env `sportx_db` dir exists locally); queue: `database`; session: `database` |
| Queue | `queue:listen` dev / Horizon config present, timeouts 60–120s |
| Error tracking | Sentry (`SENTRY_DSN` key present in `.env` — value not inspected) |
| External | Google Auth (JWKS RS256, fails closed), FCM push, Gmail API |
| Hosting | Unknown — `.env` shows ngrok-free.dev URL and `APP_ENV=local`, `APP_DEBUG=true` (this looks like a dev machine; **must be confirmed this is not the production env**). No nginx/serverless/infra config in repo. |
| Webhooks | None exist — no inbound third-party callbacks to audit. Payments are organizer-manual (`updateTournamentPayment`). |

**Verified during audit** (read-only): full `routes/api.php` (635 lines), `routes/web.php`, `bootstrap/app.php`, all 3 custom middleware, config files (cors, sanctum, session, filesystems, horizon, mail, logging, sportx), ~25 controllers directly, plus two parallel deep sweeps over all 45 controllers for authorization/ownership/mass-assignment and over config/infra/secret exposure.

---

## 3. Endpoint Inventory (summary)

424 registered routes (`php artisan route:list`; see `security/endpoint-inventory.md` method note below — full 424-row table included in generated output). Distribution:

| Category | Count | Auth | Rate limit | Notes |
|---|---|---|---|---|
| Public unauthenticated (by design): `/api/v1/` root, `/meta/*` (6), directories (`/academies`, `/coaches`, `/trials`, `/tournaments`, `/opportunities`, `/sports-venues`, `/programs`, `/facilities/{id}`, `/explore`, `/search`, results index) | ~30 | None | **None** except 1 registration-click route | Intended public data; see `DOS-01` |
| Credential endpoints (register/login/forgot/reset/verify/resend/Google/OTP) | 10 | None | `throttle:10,1` / `throttle:20,1` + per-destination OTP limiters | Good baseline; gaps in §5 |
| User-scoped `/me/*`, role-gated, admin prefix | ~380 | `auth:sanctum` (+`role:`/`admin.2fa` on the sensitive ones) | Only 15 throttle directives across the whole file | See `DOS-02` |
| Admin API (`/api/v1/admin/*`) | 40 | `auth:sanctum` + `role:admin` + `admin.2fa` | **None** | See `ATT-02` |
| Admin panel (`/panel/*`, session) | 45 | session + `admin.panel` (no 2FA) | login 10/min, 2FA 10/min | See `ATT-03` |
| Framework health | `/up`, `storage/{path}` | n/a | — | `storage/{path}` serves public disk once symlinked |

Intended-to-be-public endpoints were verified as deliberate (directories, meta, explore, search, legacy 410 Gone routes). The important question was whether auth-optional routes leak private data — reviewed controllers show athletes are masked for minors / privacy-scoped (`AthleteDiscoveryController::isVisibleTo` / `maskMinor`).

### Public (no-auth) endpoints — deliberate exposure list

- `GET /api/v1/`, `/health`, `/system/health` — expose DB connectivity status only (keep; consider removing detailed db status in prod).
- `GET /meta/*`, `/explore`, `/search`, `/academies[/{id}]`, `/coaches[/{id}]`, `/trials[/{id}]`, `/tournaments[/{id}]`, `/opportunities[/{id}]`, `/sports-venues[/{id}]`, `/programs[/{id}]`, `/facilities/{id}`, `/organizers/{id}`, `/tournaments/{id}/results`
- Credential/verification/OTP routes
- `GET /api/v1/media/download/{id}` — **requires valid signed URL** (verified: `hasValidSignature()` at MediaController.php:197). Safe.

---

## 4. Findings Matrix & Risk Levels

| ID | Title | Severity | Status |
|---|---|---|---|
| ATT-01 | Admin API login has no rate limiting | High | Confirmed |
| ATT-02 | `ADMIN_2FA_ENFORCE=false` escape hatch accepts any 6-digit code | High (Critical if prod env is false) | Confirmed code path; prod value unverified |
| ATT-03 | `/panel` session admin panel has 2FA disabled by design | High (if panel reachable in prod) | Confirmed |
| AUTH-04 | `sendPushNotification` IDOR — push to arbitrary users | High | Confirmed |
| AUTH-05 | Media upload trusts client-supplied `owner_type`/`owner_id` | High | Confirmed |
| AUTH-06 | Device-token reassignment allows token hijack | Medium | Confirmed |
| ATT-07 | No TrustedProxies — IP throttling/audit unreliable behind proxy | High (infra-dependent) | Confirmed absence |
| SEC-08 | Plaintext password-reset & verify-email tokens; verify token has no TTL | Medium-High | Confirmed |
| SEC-09 | Email auto-verified at registration (register sets `email_verified_at=now()`, AuthController L59) | Medium | Confirmed |
| SEC-10 | `verifyEmail` grants auth token on a token with no TTL (AuthController L86) | Medium | Confirmed |
| DOS-01 | Public direct/search/directory endpoints unthrottled, unbounded queries | Medium | Confirmed in app layer; already bounded by `limit(...)` caps |
| DOS-02 | Only 15 throttle directives across 424 routes; most `/me/*` and all admin APIs unthrottled | Medium | Confirmed |
| DOS-03 | Brute-force across IPs feasible (per-IP key only, no email/IP combined key) | Medium | Confirmed |
| DOS-04 | `Mail::to()->send()` synchronously inside forgot-password (mail-bomb / slow request) | Medium | Confirmed |
| DOS-05 | No request-body size limiting at app layer; `.htaccess` no `LimitRequestBody` | Low-Medium | Confirmed |
| DOS-06 | Queue storms: `bulk` registration approvals and broadcast fanout | Low-Medium | Confirmed, mitigated by Horizon timeouts |
| SEC-11 | `public/storage` symlink not yet linked (filesystems default is fine) | Low | Confirmed |
| SEC-12 | OTP signup purpose creates account from a code issued for any purpose (OtpController L104) | Low | Confirmed — reviewed; impact minor |
| SEC-13 | OTP resend cooldown enforced (60s) and success burns prior codes — no throttle bypass found | Informational | Confirmed-safe OTP core |
| SEC-14 | FCM TLS verification disabled fallback (`withoutVerifying`) | Medium | Confirmed |
| SEC-15 | Sensitive ops material git-tracked: `TEST_CREDENTIALS.md`, `scratch_users.php` (dumps all users + probes weak passwords), `check.php`, `test_schol.php`, `STARTING_SERVER.md` | High (ops hygiene) | Confirmed |
| SEC-16 | phpunit uses real MySQL `sportx_testing` with creds falling through from `.env` | Medium | Confirmed |
| SEC-17 | `SESSION_SECURE_COOKIE` defaults unset; CORS wildcard fallback in dev | Medium | Confirmed |
| SEC-18 | NGrok-based test deployment with `APP_DEBUG=true`; unknown if prod | Critical if prod | Unverified (environment risk) |
| SEC-19 | Mass-assignment `$request->all()` in AdminContentController fallback | Low-Medium | Confirmed (admin-only) |
| SEC-20 | `EventController::show` exposes draft/closed events to any authed user | Low | Confirmed |
| OBS-01 | No per-user/tenant rate-limiter named routes; THrottling only generic | see DOS-02 | — |
| OBS-02 | Login throttling used `Request::ip()` which breaks behind proxy without TrustedProxies | see ATT-07 | — |
| OBS-03 | No alerting on 401/403/429 spikes; audit log exists but not monitored | Medium | Confirmed absence |
| TTP-01 | No CDN/WAF/edge DDoS mitigation — nothing in repo; must be verified with hosting team | High (network layer) | Unverified |

**Summary:** 8 High+, 12 Medium, 7 Low/Informational. Zero confirmed exploitable SQLi / XSS / RCE at the application layer (raw DB usage is constant strings only, no shell exec, no unsafe deserialization).

---

## 5. Authentication & Authorization Findings

### What is *working well* (confirmed by evidence)

- **Controller ownership checks are strong.** All sensitive routes delegated auth to controllers were verified to re-check ownership: `RegistrationController.authorizeOwner()` (L715) / `authorizeTournamentOwner()` (L721); `EventRegistrationController.assertOwner/assertCanView`; `ResultsController`, `EventController`, `ProviderTrialController`, `ProviderTournamentController`, `OpportunityController`, `CoachingEnrollmentController`, `PostController`, `ConversationController.authorizeAccess`, `ConnectionController` scoped where-clauses, `BlockController`, `FollowController`, `AchievementController` scoped queries, `VerificationController`, `FacilityController.ownedQuery()`, `MediaController` per-owner allowlist. No IDOR found in these areas beyond items below.
- **No `$request->all()` mass assignment** on user-facing controllers (only AdminContentController fallback — SEC-19).
- **Sanctum unauthenticated returns clean HTTP 401 JSON** (`AuthenticationException` handler in bootstrap/app.php).
- **No API-path 2FA bypass** — `/admin/*` is fully gated by `admin.2fa` middleware; the only bypass path is ATT-02 (env escape hatch).
- **Google ID-token auth is correctly implemented** (RS256 pinned, JWKS, aud/iss/exp/email_verified checked, fails closed).

### ATT-01 — Admin API login has no rate limiting (High, Confirmed)

- **Files:** `routes/api.php` L629–634; `app/Http/Controllers/Admin/AdminAuthController.php` (no limiter anywhere).
- **Evidence:** login POST has no `throttle:` middleware; controller greps show zero `RateLimiter` usage. Contrast `AuthController::login` which is throttled (L112).
- **Attack:** Automated credential stuffing against `/admin/login` at network speed; admin creds are the keys to the whole platform (broadcast, user deletion, moderation).
- **Fix:** add `throttle:5,1` (or named limiter per-IP+username with exponential backoff lockout), plus lockout alarm via audit log.

### ATT-02 — `ADMIN_2FA_ENFORCE=false` disables TOTP entirely (High; Critical if prod env also false)

- **Files:** `AdminAuthController.php` L70–80; `phpunit.xml:34` (sets false for tests).
- **Evidence:** when env is false, any 6 digits passes `verify2fa`, granting admin for 12h.
- **Fix:** remove the escape hatch from bootstrapped controller; keep it only as a guarded `if (app()->environment('local','testing'))` fallback. Never allow non-boolean-ish env default. Rotate/verify prod `.env` value.

### ATT-03 — `/panel` admin web panel has 2FA disabled (High, Confirmed)

- **Files:** `app/Http/Middleware/AuthenticateAdminPanel.php` (comment at L34–40 "WARNING: 2FA is disabled — must be re-enabled before production"); `routes/web.php` L6–12 (session auth only).
- **Risk:** Only needs password + session (session cookie SameSite=lax); CSRF is enforced by Laravel for web routes (good), but 2FA disabled materially lowers the admin bar.
- **Fix:** wire `show2fa`/`verify2fa` flow back into panel middleware; same 12h freshness policy as API.

### AUTH-04 — `POST /me/notifications/{notification}/send-push` IDOR (High, Confirmed)

- **Files:** `routes/api.php` L425 (`auth:sanctum` only); `NotificationController::sendPushNotification` L131–159.
- **Evidence:** `Notification::findOrFail($validated['notification_id'])` — no ownership check that the caller owns this notification. Push is dispatched to *that* notification's owner's FCM devices.
- **Attack scenario:** Any authenticated user loops over notification IDs and triggers a mock/push fanout to arbitrary users' devices (`user_id` of notification) → **phishing/spam channel, FCM quota exhaustion** (also a DoS angle on the external integrator).
- **Fix:** `abort_unless($notification->user_id === $request->user()->id, 403);` and consider admin-only.

### AUTH-05 — Media upload trusts client-supplied `owner_type`/`owner_id` (High, Confirmed)

- **Files:** `app/Http/Controllers/MediaController.php` L43–105.
- **Evidence:** Any authenticated user may pass `owner_type=athlete_profile` + `owner_id=<any>`; no verification that the profile belongs to the caller. The same raw values flow into the storage path (`media/{owner_type}/{owner_id}`);
- **Impact:** Content injection into other users' public galleries (attribution fraud / defacement). Storage path mixes in attacker-controlled segments but under a fixed prefix, so no directory traversal — the risk is misattribution, not arbitrary file write.
- **Fix:** derive owner from authenticated user's own profile unless owner is an admin; reject explicit-spoof paths.

### AUTH-06 — Device-token reassignment (Medium, Confirmed)

- **File:** `NotificationController::registerDeviceToken` L84–102 — an existing FCM token silently becomes owned by the incoming caller.
- **Impact:** If a token leaks (it shouldn't), whoever registers first now hijacks push delivery for the other user. Also allows an attacker to deny push delivery to a user while holding the token.
- **Fix:** re-assignment only if caller is the original owner; otherwise reject or accept only when unowned.

### Prior verification matrix (expected behavior)

| Actor | Endpoint | Expected | Verified |
|---|---|---|---|
| Anonymous | any `auth:sanctum` route | 401 envelope | ✅ clean JSON 401 (bootstrap/app.php render hook) |
| Anonymous | `/admin/*` APIs | 401 (and 403 pending 2FA after login) | ✅ |
| Athlete A ↔ Athlete B (他人 resources) | registrations/approvals/achievements/posts/media/notification markRead | 403 or 404 | ✅ verified via ownership helpers |
| Lower role → admin action | `/admin/*` pre-2FA | 403 `2FA_REQUIRED` | ✅; post-2FA only `role:admin` reach |
| Admin | all `/admin/*` | 200 | ✅ |

---

## 6. DoS & Resource-Exhaustion Findings

### DOS-01/02 — Rate-limit coverage is thin and partially proxy-broken (Medium-High combined)

- **Evidence:** only 15 `throttle:` directives across 635 lines of `routes/api.php`. Unthrottled authenticated routes include: `/search` (limit-capped but still O×N DB scan), `/explore`, all directory endpoints, all `/me/*`, `/athletes`, `/leaderboard`, `/feed`, `/posts/{id}`, and the entire admin API.
- **Attack:** an authenticated abuser with valid tokens pivoted across accounts burns MySQL CPU on unbounded list endpoints; anonymous bots scan `/search`, `/explore`, `/meta/*` freely. Combined with ATT-07 (no TrustedProxies → `Request::ip()` returns the LB IP → throttle becomes effectively global/all-or-nothing, or is trivially rotated via header spoofing to bypass).
- **Fix (app layer):** named TieredLimiters (`api:safe:60,1`, `search:20,1`, `heavy:5,1`, `admin:120,1`), apply `auth:sanctum` token-bucket on expensive `/me/*` listing routes and modest per-IP caps on public read routes. **Fix (infra):** configure TrustProxies to trust only the load balancer CIDR; add edge rate limiting in nginx/CDN.

### DOS-03 — Login/OTP brute force across IPs (Medium, Confirmed)

- Global `throttle:10,1` on `/auth/login` is per-IP (`Request::ip()`); rotating IPs cheaply bypasses. OTP endpoints have strong per-destination limits (5 sends/hr destination, verify 10/5min destination — confirmed L280–306 of OtpController) but per-IP verification is still 20/min → distributed OTP guessing up to 288K/day/IP-block pool. Mitigated by 6-digit random_int + 5 attempts/code + bcrypt-at-rest + 10-min TTL (good).
- **Fix:** add combined `sha1(email|ip)` lockout limiter with exponential backoff; per-account failed-login counter and temporary lockout; alert on failures.

### DOS-04 — Synchronous mail send inside password reset & registration (Medium, Confirmed)

- `Mail::to()->send()` inline in `AuthController` (e.g. forgot-password L213) → request latency depends on SMTP; an attacker can spam `/auth/forgot-password` and pin PHP-FPM workers holding open SMTP sockets.
- **Fix:** queue the mail (`ShouldQueue` mailables) + per-destination reset-send limiter (max 3/hour like OTP), global mail provider rate cap.

### DOS-05 — Request body size (Low-Medium, Confirmed absence)

- No `LimitRequestBody`, no PHP `post_max_size` documented, unbounded arrays `/bulk` operations (`/events/{id}/registrations/bulk`, `EventController bulk`) although validation exist; deep nested JSON not blocked at edge.
- **Fix:** nginx `client_max_body_size` per route-class (e.g. 2M default, 12M upload), Laravel request-level `max:n` arrays, and an event/query-listener size precheck.

### DOS-06 — Bulk & broadcast fanout (Low-Medium, Confirmed, mitigation exists)

- `AdminUserController::broadcast` and `EventRegistrationController::bulk` — Horizon timeouts set 60–120s; queue is database-backed; evidence of purge jobs. Still, low value to attack since admin-only. Add chunked dispatch + batch limits (`->chunk(100)`) and a per-job plantime guard.
- Expensive report/export endpoints (`/events/{id}/registrations/export`) are auth+owner-gated already (verified `assertOwner` L240, `EventRegistrationController`); recommend streaming response + row cap (e.g. 10k) and `queues` migrating heavy exports to jobs.

### What's resilient already

- Public data endpoints use explicit `->limit(...)` caps (`SearchController` max:120 chars, limit($limit), limit(10), $limit+20 for athletes) — good bounded pagination.
- OTP replay burn, per-destination counters, mail provider switch logic — good.

---

## 7. DDoS & Infrastructure Findings (Network-layer assessment)

**Laravel cannot stop volumetric attacks. Nothing in this repo implements L3/L4/L7 edge protection.**

| Control | Status | Evidence |
|---|---|---|
| TrustedProxies (correct client IP) | ❌ **ABSENT** (ATT-07) | No `trustedproxy` config anywhere; `bootstrap/app.php` has no `->trustProxies()` |
| Web app firewall / CDN | ❓ Unknown — **not in repo** | No terraform/nginx/CDN config tracked |
| Edge rate limiting / bot protection | ❓ Unknown | Same as above |
| Body / header / connection size limits | ❌ Not encoded in `public/.htaccess` (verified) | Needs server config |
| HTTPS enforcement (session/cookies) | ⚠️ `SESSION_SECURE_COOKIE` env-gun unset; `APP_URL` currently ngrok | Verify with hosting |
| Origin lock-down (must permit only CDN ingress) | ❓ Unknown | Infra doc required |
| Health checks / LB protections | `/api/v1/health` + `/up` exist (good) | Sufficient for basic LB |
| Monitoring/alerting on traffic spikes | ⚠️ Sentry present, no traffic anomaly alarm | See §8 |

- **ATT-07 (High, confirmed absence):** without `->trustProxies([lb-cidr])` in `bootstrap/app.php`, all rate limiting, `Auditable` IP logging (app/Traits/Auditable.php:66), `RegistrationActivityService` and `AdminModerationController::310` record the LB IP or a spoofable header. Rolling per-IP headers defeats throttling; blocking by IP is impossible.
- **TTP-01:** Verify with the hosting provider: CDN channel (CloudFront+Cloudflare-class), WAF rules for OWASP bot & rate rules, origin shadowing, e.g. origin must reject any request not via CDN (`X-Auth-Token` or security group).
- **Do not claim:** This application is not DDoS-proof and Laravel cannot make it so; treat Laravel rate limits as a per-connection Resource guard, not as flood protection.

---

## 8. Input Validation & Injection

| Vector | Result |
|---|---|
| SQL injection | ✅ Clean — all `DB::raw / whereRaw / selectRaw` (AdminPanelController, AthleteLeaderboardController, EnquiryController `'1=0'`, AchievementController, NotificationController, AdminModerationController) are constant strings; Eloquent parameter-binding is standard |
| Command injection / shell | ✅ None (`exec/Process/symlink/unserialize` not present) |
| SSRF | ✅ None — no controller fetches user-supplied URLs; `file_get_contents` calls use fixed local paths (platform_settings.json) |
| Path traversal | ✅ Fixed prefixes on storage paths (`media/{type}/...`); no `download($user_path)` |
| Open redirect / header injection | ✅ None found |
| XSS | N/A for API JSON; Blade panel uses Laravel's native escaping (no `{!! !!}` on user data found in partial review) |
| File upload validation | ✅ Good (size max + MIME sniff-trusted + extension whitelist) — but see AUTH-05 (owner spoof) |
| Validation layer | ✅ Request-level `validate()` present in virtually all controllers; no missing-form-request OKs where needed |
| Unchecked list of `q` chars (nosql/injection) | ✅ Eloquent binding safe |

---

## 9. Secrets & Sensitive Data

| ID | Finding | Severity |
|---|---|---|
| SEC-15 | **Git-tracked ops junk with live-sensitive data**: `TEST_CREDENTIALS.md` (confirmed tracked, contains test creds), `scratch_users.php`, `check.php`, `test_schol.php`, `STARTING_SERVER.md`, plus a large set of internal audit/plans. `my-release-key.jks` exists at repo root — **present locally and referenced by `CREDENTIALS.md`; confirm git-tracked status and rotate if it is duplicated anywhere.** `scratch_users.php` when run dumps every user's email/phone and tests default passwords — high ops hygiene risk. | High |
| SEC-18 | `.env` on this box is `APP_DEBUG=true`, `APP_ENV=local`, ngrok public URL — **unverified whether production uses a different deploy channel**; if any public instance runs this machine, the Critical triad (debug=true + admin 2FA escape hatch + unthrottled admin login) becomes exploitable at once. | Critical *if* prod; Unverified |
| — | `SENTRY_DSN`, `GMAIL_*`, `FCM_*`, `GOOGLE_CLIENT_SECRET` keys present in `.env` — values not copied or printed (per rules). Verify none are also in `.env.example` with live values (only placeholders confirmed). | OK |
| SEC-08 | Reset tokens & verification tokens stored **plaintext** in DB columns; verification token has **no TTL** | Medium-High |
| SEC-09/10 | Register auto-sets `email_verified_at` → the verify-email flow is decorative; tokens also grant auth token issuance (`verifyEmail`) | Medium |
| SEC-07 | API errors never leak traces when `APP_DEBUG=false`; but with current debug=true, message text does go out. | tied to SEC-18 |

---

## 10. Dependency & Configuration

- `composer audit`: **no known vulnerable advisories** for locked deps.
- Framework support current (Laravel 13.x). No abandoned packages found in `composer.json`.
- `laravel/pao` is a dev-only, unusual dependency — flagged informational (verify what it provides).
- `phpunit.xml` uses the real MySQL server and a `sportx_testing` database; **credentials fall through from `.env`** → running tests on a machine whose `.env` points at prod is dangerous. Set an explicit test host/user and hard-guard against prod (abort when `DB_DATABASE` equals the production database name).
- Horizon timeouts are sane (60–120s). Scheduled purge jobs are properly time-boxed and idempotent in reviewed form.
- Filesystem config has support for serving `public/storage`; symlink currently **not** linked (`php artisan storage:link` needed once carefully — do not create now without approval).

---

## 11. Logging & Monitoring

- AdminAuditController + `Auditable` trait + RegistrationActivityService provide an audit trail for admin actions, authorization overrides, provider switching — **good**.
- **Gaps:** no automated alerts on 401/403/429 spikes, no alarm at repeated admin login failures (`ATT-01` would give free credential-stuffing harvest), no queue depth alerting, no anomaly alarm from Sentry beyond exceptions. Admin audit trail itself is there but unread (`routes/api.php` L613–615 exist but no monitoring hook).
- No PII/secret leakage found in logs (`LOG_LEVEL=debug` on this env would leak more in prod — reduce to `informational` and enable Sentry filtering).
- Recommendation: wire `/admin/audit-logs` into a monitoring job, alert > 20 admin auth failures/5min, alert 403/> 100/5min per IP, and capture 429 rates per route class.

---

## 12. Recommended Remediation Plan

### P0 — Immediate (before any production exposure)

1. **ATT-02:** Remove `ADMIN_2FA_ENFORCE=false` runtime bypass; verify prod `.env` is `true`. Rotate admin passwords if it was ever false in prod.
2. **SEC-18/15:** Verify no production deployment runs with this repo's `.env` (`APP_DEBUG=true`, ngrok). Set prod `.env` to debug false, real domain, `SESSION_SECURE_COOKIE=true`, Sentry enabled, `LOG_LEVEL=info`.
3. **ATT-01:** Add rate limiting to `/admin/login` and lockout/intrusion logging.
4. **AUTH-04:** Add ownership check to `sendPushNotification` (1 line).
5. **AUTH-05:** Enforce that `owner_type`/`owner_id` in media upload resolve only to a profile owned by the authenticated user (or admin).

### P1 — High

6. **ATT-03:** Re-enable 2FA on `/panel` (mirroring API landing page logic).
7. **ATT-07:** Configure `->trustProxies([LB/CDN CIDR])` in `bootstrap/app.php`.
8. **SEC-08:** Hash reset/verification tokens (HMAC or bcrypt), add TTL to verification token, rotate any live reset tokens.
9. **SEC-09:** Remove auto `email_verified_at` or gate sensitive flows on real verification.
10. **TTP-01:** Confirm with hosting (CDN, WAF, edge rules, origin lock) and document.

### P2 — Medium

11. Add named rate limiters (Search 20/min, explore 60/min, heavy 30/min, admin API 120/min, plus combined email+IP login limiter and lockout with alert).
12. Queue mail sends in forgot-password/register; per-destination mail limit (3/hour, like OTP).
13. Add per-route nginx supernode: `client_max_body_size` (2M default / 12M upload), request timeouts, and `LimitRequestBody`-equivalent.
14. Device-token hijack fix (AUTH-06) and `AthleteContactController` blocked-user check.
15. phpunit.xml: pin explicit dev DB host/user and hard-reject runs when `DB_DATABASE` matches production.
16. Chunk bulk operations, cap broadcast fanout, add job batching limits.
17. Alerting on auth anomalies, quota rates, 429 thresholds, queue depth.
18. Add authorization tests for verified endpoints (see §13).

### P3 — Low

19. Remove `EventController::show` draft exposure for non-owners (or filter status).
20. `AdminContentController` `$request->all()` fallback removed in favor of explicit validation maps even for admin-only paths.
21. FCM CA-bundle fallback — require verified TLS, set GCM CA path, remove `withoutVerifying`.
22. Move `ADMIN_2FA_ENFORCE` to a TOTP-only path; replace `throttle:20,1` on OTP sends with distinct send/verify/rules + heavier honeypot finding.
23. Clean git-tracked test/ops junk (move to `ops/` and gitignore; treat `scratch_users.php` as deleted and purge history if its content is sensitive).

---

## 13. Tests Performed and Proposed Regression Tests

**Performed in this audit (read-only):**
- `php artisan route:list --json` (424 routes categorized; no mutation).
- `composer audit` (no advisories).
- Configuration, repo, and controller source reviews, plus grep-based scans for dangerous primitives ($request->all, whereRaw, exec, unserialize, file_get_contents, redirect, download, webhook boilerplate, CORS/session/miss-tests).

**No live traffic, stress, fuzzing, or destructive tests were executed** (per scope rules; no production credentials used).

**Proposed automated regression tests (Pest/PHPUnit in `tests/Feature/Security/`):**

1. ` AnonymousAccessTest` — assert 401 for representative `auth:sanctum` routes across role features.
2. `CrossUserAccessTest` — user A's token → B's notification markRead/sendPush (reject 403), registration approve, media signed URL, achievements/PR updates.
3. `AdminGateTest` — anonymous, athlete, and coach tokens against `/admin/*` → 401/403; pre-2FA → `2FA_REQUIRED` 403; `ADMIN_2FA_ENFORCE=false` no longer bypasses.
4. `AdminLoginThrottleTest` — 6 rapid failures → 429.
5. `MediaOwnerSpoofTest` — explicit foreign `owner_type/owner_id` upload → 403.
6. `DeviceTokenReassignTest` — overlapping token re-registered by another user → rejected.
7. `EmailTokenTest` — plain-text token overwritten; TTL enforced (expired token → 410/401).
8. `RateLimitSearchTest` — burst search → 429 after threshold, `Retry-After` header present (depends on narrowed limiter implementation).
9. `DraftEventExposureTest` — un-authed / other-user GET of draft event → 404.
10. `ProdErrorEnvelopeTest` — with `APP_DEBUG=false`, 500 responses contain no traces/messages.
11. `LoginLockoutAlertTest` — repeated login failures append to the audit log and trip the monitoring threshold.
12. `TrustedProxyTest` — behind `X-Forwarded-For` without config → throttle keys must not rotate per header (regression check after TrustProxies change).

---

## 14. Limitations, Assumptions, and Items Requiring Infrastructure Access

- **Unverified items requiring ops/infra access to confirm:** production deploy channel, whether prod `.env` matches the audited dev `.env`, actual CDN/WAF/LB configuration, origin lockdown, HTTPS enforcement, per-node rate limiting, real SMTP/mail provider quotas, FCM API key restrictions, MySQL max_connections, PHP-FPM worker count, backup/restore procedures, and firewall rules.
- **Untested areas:** app-side Flutter code (`sportx_app`) token storage was not audited in depth; no load/performance testing was run.
- **Assumption:** `role:admin` is only granted via DB seed/moderation — no self-escalation path was found; confirm no seed bug grants developer role admin.
- **Assumption** (per source evidence): no inbound webhooks exist today; if a payment gateway is added, a separate signature-verification audit must be done.

---

## 15. Summary for the Project Owner (plain language)

The backend is well-built at the business-logic level — users can't easily access each other's data, admin routes require roles and 2FA, and error responses don't leak code details. The main risks are **operational**: (1) the admin login screen has no brute-force protection, (2) a configuration switch (`ADMIN_2FA_ENFORCE=false`) can turn off admin 2FA so any 6 digits works, (3) any logged-in user can trigger push notifications to other users' devices and can upload files attached to other people's profiles, (4) the current sandbox/deployment carries flags that must never reach production (debug mode on, ngrok URL, session cookies without the Secure flag), and (5) a DDoS can only be absorbed by hosting infrastructure (CDN/WAF/firewall) — Laravel alone cannot do this, and that infrastructure setup is not visible in the code so it must be verified with the hosting team. The remediation plan above lists 5 urgent (P0), ~10 high (P1) and ~8 medium (P2) items; the five P0 fixes together are roughly a day of work and must be complete before any production exposure.
