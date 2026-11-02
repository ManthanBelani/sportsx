# 04b — Backend Security Audit (sportx-api)

Scope: `D:\SportX Project\sportx-api` (Laravel 13-style structure, Sanctum, PHP 8.3, Blade admin panel at `/panel`).
Business rules audited against: `sportsx-design-v3/new_design_docs/MVP_FEATURE_LIST.md` §6 (esp. rule 2 minors, rule 3 no cold DMs, rule 6 capacity/duplicates, rule 10 scout data private).
Audit date: 2026-11-02. READ-ONLY audit; no code modified.

Severity legend: BLOCKER > HIGH > MEDIUM > LOW.

---

## Executive summary

The app shows unusually deliberate authorization engineering (ownership helpers, uniform error envelopes, content-derived MIME checks, hashed OTPs). However there are three BLOCKERs: committed secrets (`CREDENTIALS.md` with a real APP_KEY/DB password, and the Android release keystore tracked in git), client-controllable OTP bypass on password login, and suspended/pending users retaining full API access because no middleware re-checks user status and Sanctum tokens never expire. File uploads (including verification documents) land on the **public** disk, defeating the signed-URL access control built on top.

---

## 1. Authentication

### 1.1 OTP design — mostly strong
- Hashed at rest: `app/Services/OtpService.php:47` (`'code_hash' => Hash::make($code)`), plaintext never stored. Cryptographically random via `random_int` (`app/Services/OtpService.php:255-265`).
- Expiry: 10 min default (`config/sportx.php:110`), consumed on use, prior live codes burned on reissue (`app/Services/OtpService.php:41-45`).
- Max attempts: 5 per code (`app/Models/OtpCode.php:94-97`, `config/sportx.php:111`), counter incremented *before* checking (`app/Services/OtpService.php:88-91`).
- Send throttle: per-destination 5/hour (`app/Http/Controllers/OtpController.php:289-298`); resend cooldown 60s (`app/Services/OtpService.php:135-152`); verify throttle 10 per 5 min per destination (`OtpController.php:306-315`) plus route-level `throttle:20,1` (`routes/api.php:131-135`).
- OTP is never returned in responses — destination is masked (`OtpController.php:320-329`). Logs never contain the code; only metadata (`OtpService.php:60-68`, `OtpService.php:204-207`). **No `Log::` call contains an OTP value** (grep across `app/` confirmed).
- Weakness: throttling is per-destination only; no per-IP limiter inside `OtpController` (only the shared route throttle). A distributed brute force is bounded to 10 guesses/5 min/destination — acceptable, but a per-IP counter would be cheap. **LOW**.
- Fixed test code: `config/sportx.php:120` `OTP_TEST_MODE` + guard `! app()->isProduction()` (`OtpService.php:239-243`). Correctly gated. **Info**.

### 1.2 BLOCKER — client can disable login OTP
`app/Http/controllers/AuthController.php:194-196`:
```php
$enforceOtp = $request->has('require_otp')
    ? $request->boolean('require_otp')   // client decides
    : !app()->runningUnitTests();
```
The client sends `require_otp=false` and password login returns a full token with no second factor (`AuthController.php:217-223`). The "credentials + email OTP" flow is advisory only. Fix: remove the request parameter; decide server-side (env/config only), never per-request.

### 1.3 HIGH — registration marks unverified email as verified
`app/Http/Controllers/AuthController.php:62`: `'email_verified_at' => now()` in `register()` — no proof of control. Anyone can claim any address (incl. someone else's) and get a "verified" account that unlocks verified-channel flows (`OtpController.php:128-129` does the same *after* a real OTP check, which is correct; `register()` is not). This also lets a user skip OTP entirely: register → token immediately (`AuthController.php:68`).

### 1.4 MEDIUM — reset/verification tokens stored in plaintext
- `AuthController.php:338-341` (`Str::random(64)` stored raw to `reset_password_token`), compared with a direct `where` (`AuthController.php:357-359`). Same for `verification_token` (`AuthController.php:136-138`). A DB leak yields usable account-takeover tokens. Hash them (the OTP team already knows how — `code_hash`).
- Reset tokens expire in 60 min (`AuthController.php:365`) and all sessions are killed on reset (`AuthController.php:375`). Good.

### 1.5 MEDIUM — Sanctum tokens: no expiry, no abilities, no refresh
- `config/sanctum.php:53` `'expiration' => null`. Tokens are eternal.
- All tokens minted without abilities (`AuthController.php:68,185,217,310,377`; `OtpController.php:131`; `AdminAuthController.php:44`) and no route uses an `abilities`/`tokenCan` check — role middleware is the only gate.
- No refresh-token mechanism. Mitigation: logout deletes current token (`AuthController.php:325`). Combined with §9 below this is the biggest blast-radius amplifier in the API.

### 1.6 Admin 2FA (TOTP) — enforced, but brittle and brute-forceable
- API admin routes gated by `auth:sanctum, role:admin, admin.2fa` (`routes/api.php:535`); `EnsureAdmin2FAVerified` requires a fresh (12h) `admin_2fa_verified_at` (`app/Http/Middleware/EnsureAdmin2FAVerified.php:11-22`).
- **MEDIUM — no rate limit on `/api/v1/admin/login` or `/api/v1/admin/verify-2fa`** (`routes/api.php:640-645` — no throttle middleware; `AdminAuthController.php:17-60,62-112`). A 6-digit TOTP with window ±1 (`app/Services/TotpService.php:14-25`) gives 3/1,000,000 per guess; unthrottled attempts make online brute force feasible. The Blade panel *does* throttle (`routes/web.php:15,17`).
- **MEDIUM — `ADMIN_2FA_ENFORCE` read via runtime `env()`** (`AdminAuthController.php:70`, `AuthenticateAdminPanel.php:28`): when `false` any 6 digits pass (`AdminAuthController.php:71-79`). Also `env()` at runtime is fragile under config caching. Move to `config()` with a safe default of `true`.
- **MEDIUM — TOTP secret stored plaintext**: `google2fa_secret` has no `encrypted` cast (`app/Models/User.php:24-34`), written at `AdminAuthController.php:86`. It is not mass-assignable (not in `$fillable`, `User.php:15-21`) — good.
- First enrollment provisions a secret and returns `otpauth_url` (`AdminAuthController.php:84-93`) without requiring the *old* secret — expected for first-time setup, but note that anyone with the password + a token can enroll their own device.
- Panel session flow: session auth + `admin.panel` middleware + 2FA redirect (`routes/web.php:21`, `AuthenticateAdminPanel.php`); CSRF present in Blade forms (`resources/views/admin/categories.blade.php:11`). Good.

### 1.7 Google auth — solid
ID token verified server-side; role validated against an allowlist (`GoogleAuthController.php:35-46`); pending accounts refused on returning sign-in (`GoogleAuthController.php:69-76`); last-credential unlink protection (`GoogleAuthController.php:146-153`). No findings.

---

## 2. Authorization / IDOR sweep (~20 highest-risk endpoints)

Verdict per endpoint (check quoted or stated):

| Endpoint | Result |
|---|---|
| GET/POST `/registrations/{id}/approve\|reject` | OK — `assertOwner` / `authorizeOwner` on the parent event (`EventRegistrationController.php:93-103`; `RegistrationController.php:185-187`), admin bypass. |
| GET `/registrations/{id}` | OK — `assertCanView` in all three resolution branches (`EventRegistrationController.php:142-173`); athlete-owner allowed (`RegistrationController.php:244`). |
| `/events/{id}/registrations` index/bulk/export | OK — `assertOwner` before every action (`EventRegistrationController.php:117-119, 209-212, 272-274`). |
| DELETE `/me/registrations/{id}` (cancel) | OK — scoped `where('athlete_id', $athleteId)` (`EventRegistrationController.php:289-300`). |
| Conversation read/send/read-mark | OK — `authorizeAccess` participant check (`ConversationController.php:45,141,204,215-216`); send gated by connection/enquiry (`privateSendGate`), block checks and minor gate (`ConversationController.php:144-165`). Rule 3 enforced. |
| Scout shortlist CRUD | OK — all methods resolve *the caller's* `talentScoutProfile` (`ScoutShortlistController.php:15,41,88,107`). Rule 10 respected. |
| Observations | OK — own-scout-profile gate (`ObservationController.php:14-15,30-31`). |
| Guardian consent | OK — athlete-role only, operates on `$request->user()` (`GuardianController.php:37-39,89-91,159,186,216`). |
| Verification requests | OK — ownership via relation `whereKey` (`VerificationController.php:57-61`); queue/approve/reject admin-gated by route (`routes/api.php:535`). |
| Notifications | OK — `user_id` checks on every mutation (`NotificationController.php:62,78`). |
| Saved items | OK — all queries scoped to caller (`SavedItemController.php:22,42,49,61`). |
| Media destroy / reorder / signed-url | OK — per-row owner match + admin bypass (`MediaController.php:323-325,358-369,393-403`). |
| Media upload attribution | OK — client-supplied `owner_type/owner_id` verified via `ownsOwner` (`MediaController.php:246-251`). |
| Profile (self) | OK — all `/me/*` operate on `$request->user()` (`ProfileController.php:13,46,142,202`). |
| Opportunity apply / applications / review | OK — owner check `created_by_user_id` (`OpportunityController.php:70, 274, 355-358`); apply is athlete-role + athlete-profile gated (`OpportunityController.php:193-196`). |
| Coaching enrollments approve/reject | OK — coach must own the enrollment (`CoachingEnrollmentController.php:243-246`); athlete scoping at 110. |
| Results store/publish/unpublish | OK — organizer ownership (`ResultsController.php:73-80`). Minor inconsistency: no `posted_by` legacy path compared to EventController — see below. |
| Event update/publish/close | OK — trial owner or tournament organizer, admin bypass (`EventController.php:114,142,165-168`). |
| Program/Facility/Enquiry | OK — `created_by_user_id` (`ProgramController.php:178-181`) / academy-organizer profile resolution (`FacilityController.php:82-108`) / `authorizeAccess` (`EnquiryController.php:98,108,140,157`). |
| Posts update/delete/comment-delete | OK — `post->user_id === user` + admin (`PostController.php:218,277`); visibility='followers' enforced (`PostController.php:113-116`). |
| AdminUserController | OK — entire group behind `role:admin` + `admin.2fa` (`routes/api.php:535`). |
| **`/observations` etc. role drift** | Note: `GET /observations`, `POST /athletes/{id}/contact`, `GET /scout/dashboard` are behind `auth:sanctum` only, NOT `role:talent_scout` (`routes/api.php:505-508`) — controllers compensate with scout-profile gates (`ObservationController.php:14`), but the route surface is inconsistent. **LOW**. |

**No missing ownership check found in the sweep.** The one architectural risk: several cross-type "auto" resolvers (e.g. `EventRegistrationController::eventOf`, `RegistrationController::authorizeOwner`) rely on subtle id-space collision logic; all current paths were verified safe, but this pattern is fragile — see `EventRegistrationController.php:20-56`.

---

## 3. File uploads

- **HIGH — everything is stored on the `public` disk, including verification documents.** `MediaController.php:266`: `$file->store("media/{ownerType}/{ownerId}", 'public')`; `disk` saved as `'public'` (`:272`). `public/storage` symlink exists, and `MediaItem::url()` returns `/storage/...` (`app/Models/MediaItem.php:25-33`). Documents use `context = credential|document` (`config/sportx.php:198`) — i.e. blue-check proof documents are publicly downloadable by anyone with the URL. The path contains a random Laravel store name (not guessable), but URLs leak (screenshots, proxies, referrers) and there is zero access control on `/storage/*`. The signed-URL mechanism (`media.download`, `MediaController.php:379-387`) is only theater for public-disk files. **Fix: store `media_type=document` / `context=credential|document` on a private disk and serve exclusively via signed URLs.**
- MIME validation is good: content-derived `getMimeType()` against allowlists + extension allowlist (`MediaController.php:221-238`); size cap 10 MB (`config/sportx.php:190`, `MediaController.php:191`); single-file endpoint (no count bypass); video refused (`MediaController.php:186-188`). No SVG anywhere — no XSS-via-SVG risk. **OK**.
- Image processing: Intervention/GD `scaleDown` runs in a queued job (`app/Jobs/CompressPhoto.php:30-47`, `app/Services/PhotoCompressor.php:66-68`) — off the request path, 2 tries. No pixel-dimension precheck, but the 10 MB cap bounds decompression bombs. **LOW**.
- `GET /media/download/{id}` requires a valid signature only (`MediaController.php:381-383`) — correct given the URL is only minted after an ownership check.

## 4. Input validation / injection / mass assignment

- Raw SQL: no user input interpolated anywhere dangerous. The one dynamic `orderByRaw` is cast via `array_map('intval', $ids)` (`app/Http/Controllers/PostController.php:143`) — safe. All other `DB::raw`/`selectRaw` uses are constants (`AthleteLeaderboardController.php:180-303`, `AdminPanelController.php:588-630`, etc.).
- Create endpoints are validated with rule arrays (e.g. results `ResultsController.php:26-31`, facilities `FacilityController.php:114-123`, OTP verify `OtpController.php:85-94`). Whitelist sort columns in directories (`DirectoryController.php:70-74`). Good.
- **MEDIUM — mass assignment in admin content API**: `AdminContentController.php:184,228` uses `$request->all()` → `$model::create($validated)` when a model defines no `rules()`. Admin-only (`routes/api.php:547-552`) and Eloquent `fillable` bounds columns, but an admin request can set any fillable column (including `status`, `owner_user_id`) without audit of intent. Replace with `fillable()`-intersected input.
- `User::$fillable` includes `status`, `email_verified_at`, `verification_token`, `reset_password_token` (`app/Models/User.php:15-21`) — controllers construct attributes explicitly everywhere checked, but this fillable list is a landmine; trim it.

## 5. Admin surface

- Blade panel `/panel`: `auth` + `admin.panel` middleware (`routes/web.php:21`), role check + session 2FA flag (`AuthenticateAdminPanel.php:15-31`), login & 2FA POST throttled 10/min (`routes/web.php:15,17`), CSRF on all forms (`@csrf` present throughout `resources/views/admin/*`). **OK**.
- API admin: `routes/api.php:535` group — but login/2FA endpoints unthrottled (see §1.6).
- TOTP secrets: plaintext at rest (§1.6); known dev secret `JBSWY3DPEHPK3PXP` for seeded admins documented in the tracked file `sportx-api/TEST_CREDENTIALS.md` — must never run seeder against production.
- `AdminAuditController` exists for admin actions; panel write actions themselves are not uniformly audited (spot check). **LOW**.

## 6. Rate limiting / CORS

- **MEDIUM — no global API rate limit.** No `RateLimiter::for('api')` anywhere (grep across `app/`, `bootstrap/` is empty); public unauthenticated reads (`/academies`, `/coaches`, `/trials`, `/tournaments`, `/search`, `/explore`, `/meta/*` — `routes/api.php:163-208`) have zero throttling and can be scraped/hammered. Per-user throttled routes are explicit ad-hoc `throttle:N,M` (good where present: posts 30/min, messages 120/min, connections 30/min, etc.).
- CORS: `config/cors.php:20` defaults to `*` when `CORS_ALLOWED_ORIGINS` is unset; `supports_credentials=false` and token auth, so impact is limited to browser-reading public API responses. **LOW/MEDIUM** — must set explicit origins in production.
- No TrustProxies configured (grep: none in `bootstrap/app.php` / `config/`) — behind a tunnel/load balancer, `throttle` keys on the proxy IP, so *all* clients share one rate-limit bucket, and logs record the wrong IP. **MEDIUM** when deployed behind the Cloudflare tunnel used in `CREDENTIALS.md`.

## 7. Privacy

- **HIGH — athlete discovery leaks email + phone through the nested `user` relation.** `AthleteDiscoveryController.php:60` loads `with(['user', ...])` and the response serializes `athlete.user`; `User::$hidden` is only `password/remember_token` (`app/Models/User.php:24`). `maskMinor()` hides `date_of_birth` and the *athlete profile's* phone (`AthleteDiscoveryController.php:132`) but **not** `user->email` / `user->phone` — so a minor's account email/phone (and any adult's) is returned by `/athletes/{id}` and `/athletes` to any authenticated viewer. Contrast: `DirectoryController.php:57-59` explicitly `unsetRelation('user')` — the coach directory got this right, athlete discovery did not. MVP rule 2 ("no precise location", contact via guardian-mediated request) is undermined.
- Verification documents: see §3 (public disk). Access *control* on the signed-url path is correct; the storage layer betrays it.
- Logs: no OTP codes, no passwords, no raw PII in `Log::` calls (grep: only provider errors, FCM status codes, mail-probe failures). **OK**.
- OTP destination masked in API responses (`OtpController.php:320-329`). **OK**.
- Minors' location: only city/state references in discovery; no lat/lng columns found in athlete profiles. **OK (rule 2, location part)**.
- Guardian consent OTP goes to the guardian's email, not the minor's (`app/Services/GuardianConsentService.php:63-71`). **OK**.
- Leaderboard first-name+initial for minors (rule 8): implemented per seed docs; not independently verified in `LeaderboardService` during this pass. **Unverified**.

## 8. Secrets (BLOCKER findings)

- **BLOCKER — `CREDENTIALS.md` is git-tracked** (`git ls-files` confirms) and contains a real `APP_KEY` (`base64:GS4p4UN9tpdkzR4C7PmhcLMY2Q41+QDAQ1s4NOmk+YM=`), DB `root`/`password`, and the live tunnel URL. The APP_KEY signs Sanctum URLs and encrypts cookies — rotate it and purge history.
- **BLOCKER — `my-release-key.jks` (Android release signing key) is git-tracked** (commit `251082b`). Anyone with repo access can sign malicious app updates. Revoke/regenerate the key, remove from history.
- `sportx-api/TEST_CREDENTIALS.md` git-tracked: all seed passwords (`password`) and the seeded admin TOTP secret. Ensure production never runs `AllSeeder`.
- `sportx-api/.env` itself is correctly git-ignored (`git check-ignore` → ignored; only `.env.example` tracked).
- No hardcoded API keys/secrets found in `app/` or `config/` (grep for `apiKey|secret|password =>` clean; Gmail/FCM credentials all via `env()`).
- `.env.example:2-4` ships `APP_ENV=local`, `APP_DEBUG=true` as defaults — fine for dev, but the production checklist must force `APP_DEBUG=false`; local `.env` currently `APP_DEBUG=true` with `config/app.php:42` honoring it. The API exception renderer suppresses stack traces for `api/*` even in debug (`bootstrap/app.php:96-105` returns a generic message unless `app.debug`), good.

## 9. User status enforcement (BLOCKER)

- Login paths block non-`active` accounts (`AuthController.php:162-171, 294-303`; `GoogleAuthController.php:69-85`). **But there is no per-request status check**: `bootstrap/app.php` registers no global middleware, no status middleware exists in `app/Http/Middleware/` (directory contains only the 3 admin/role middlewares).
- **Suspension does not revoke tokens**: `AdminUserController.php:72-76` sets `status='suspended'` and notifies, but never calls `$user->tokens()->delete()`. With `sanctum.expiration=null` (§1.5) a suspended or banned user keeps working API access **indefinitely** until they manually log out.
- **Pending users can act**: `register()` returns a live token for `status=pending` (`AuthController.php:55,68`), and the comment claims "middleware will block writes until approved" (`AuthController.php:66`) — **no such middleware exists** (grep of `app/Http/Middleware` for `pending|suspended|status` is empty). A pending coach/scout can create listings, shortlists, apply, etc., immediately.
- Fix: add a `EnsureUserActive` middleware (reject `suspended|banned`, and writes for `pending`) to the `auth:sanctum` group, and delete tokens on suspend/ban.

## 10. Headers / HTTPS / transport

- No `URL::forceScheme('https')`, no `TrustProxies`, no HSTS anywhere (grep: empty). The APP_URL in use is a trycloudflare tunnel (`CREDENTIALS.md`); `.env.example:5` is `http://localhost`. Cookies: `SESSION_SECURE_COOKIE` unset (`config/session.php:172`) — panel session cookie not forced Secure. **MEDIUM** for production.
- Debug off in prod assumed but unenforced (see §8).

## 11. Ops: backups, health, monitoring, queue, Horizon

- **Backups: none.** No `spatie/laravel-backup` in `composer.json`; no backup command/console entries. A DB-only disaster = total data loss. **MEDIUM/HIGH (operational)**.
- Health: `GET /api/v1/health` and `/system/health` publicly reveal DB connectivity (`routes/api.php:93-109`); Laravel `/up` also enabled (`bootstrap/app.php:16`). **LOW** — fine to keep, but consider unauthenticated-minimal or IP-allowlisted.
- Sentry: wired — `Sentry\Laravel\Integration` in `bootstrap/app.php:10`, `config/sentry.php:4` DSN from env. `.env.example:96-97` has `SENTRY_DSN=` (empty) and `SENTRY_ENABLED=false` — production must fill both or errors are invisible.
- Queue: `database` driver (`QUEUE_CONNECTION=database`, `.env.example:38`); OTP mails and photo compression queue through it — requires a running worker (`queue:listen`/Horizon). Note: `laravel/horizon` is in `composer.json:13` and `config/horizon.php` exists, **but the Horizon service provider is not registered** (`bootstrap/providers.php:5-7` lists only `AppServiceProvider`, no `Horizon::auth` gate anywhere) — the dashboard is therefore **not mounted** (no `/horizon` route). Not exposed (good), but also not usable; if you enable it you MUST register the provider *and* define the view gate.
- Session/queue/cache on database store — consistent with single-DB deploy.

---

## Findings table

| # | Severity | Finding | Evidence |
|---|---|---|---|
| 1 | BLOCKER | Release keystore `my-release-key.jks` committed to git | `git ls-files`; repo root |
| 2 | BLOCKER | `CREDENTIALS.md` committed with real APP_KEY, DB creds, tunnel URL | `CREDENTIALS.md`; `git ls-files` |
| 3 | BLOCKER | Suspended/pending users keep full API access (no status middleware; suspend doesn't delete tokens; tokens never expire) | `AdminUserController.php:72-76`; `config/sanctum.php:53`; `bootstrap/app.php` (no middleware); `app/Http/Middleware/` (no status check) |
| 4 | HIGH | Login OTP bypass — client sends `require_otp=false` | `AuthController.php:194-196, 217-223` |
| 5 | HIGH | Registration marks email verified without proof | `AuthController.php:62` |
| 6 | HIGH | Verification/credential documents stored on public disk; signed URLs decorative | `MediaController.php:266,272`; `MediaItem.php:25-33`; `config/sportx.php:198` |
| 7 | HIGH | Athlete discovery exposes email/phone via nested user relation incl. minors | `AthleteDiscoveryController.php:60,132`; `User.php:24` |
| 8 | MEDIUM | No rate limit on API admin login / 2FA verify | `routes/api.php:640-645`; `AdminAuthController.php:17-60,62-112` |
| 9 | MEDIUM | TOTP secret plaintext in DB; `ADMIN_2FA_ENFORCE` runtime `env()` escape hatch | `AdminAuthController.php:70,86`; `User.php:24-34` |
| 10 | MEDIUM | Sanctum: no expiration, no abilities, no refresh | `config/sanctum.php:53`; token mint sites §1.5 |
| 11 | MEDIUM | Reset/verification tokens stored unhashed | `AuthController.php:136-138, 338-341, 357-359` |
| 12 | MEDIUM | No global/per-user API rate limiting on public reads; no TrustProxies | `routes/api.php:163-208`; grep `RateLimiter::for` empty |
| 13 | MEDIUM | Admin content API mass assignment via `$request->all()` | `AdminContentController.php:184,228` |
| 14 | MEDIUM | No HTTPS forcing / Secure cookies / HSTS | grep `forceScheme` empty; `config/session.php:172` |
| 15 | MEDIUM | No database backups configured | `composer.json` |
| 16 | MEDIUM | CORS defaults to `*` when env unset | `config/cors.php:20` |
| 17 | LOW | Sentry disabled by default in `.env.example` | `.env.example:96-97` |
| 18 | LOW | Public health endpoint reveals DB status | `routes/api.php:93-109` |
| 19 | LOW | Scout-only endpoints under generic `auth:sanctum` (compensated in controllers) | `routes/api.php:505-508` |
| 20 | LOW | OTP/verify throttle is per-destination only, no per-IP | `OtpController.php:289-315` |
| 21 | LOW | User::$fillable includes security-sensitive columns | `User.php:15-21` |

## What is done well (worth preserving)

- OTP pipeline: hashed, single-use, attempt-capped, cooldown, replay-burned, uniform errors, never logged (`OtpService.php` throughout).
- Ownership helpers with explicit admin bypass, and the auto id-space resolution comments (`EventRegistrationController.php:20-56`).
- Content-derived MIME validation and quota enforcement inside the same transaction as the counter (`MediaController.php:205-216, 293-303`).
- Uniform JSON error envelope that suppresses stack traces and paths for `api/*` (`bootstrap/app.php:96-140`).
- Coach directory strips the user relation (`DirectoryController.php:57-59`).
- Minor chat gates, block checks and enquiry-thread-only messaging in `ConversationController.php`.

## Priority remediation order

1. Rotate/remove committed secrets: APP_KEY, DB password, release keystore (BLOCKERs #1-2) + git history purge.
2. Add `EnsureUserActive` middleware + token deletion on suspend/ban (BLOCKER #3).
3. Remove `require_otp` client override; make registration actually verify email (HIGH #4-5).
4. Move documents to a private disk served by signed URLs (HIGH #6).
5. Strip user PII from discovery responses (HIGH #7).
6. Throttle admin auth endpoints; hash reset tokens; set Sanctum expiration; configure TrustProxies, CORS origins, HTTPS, backups, Sentry in prod config.
