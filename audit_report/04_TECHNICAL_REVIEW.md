# 04 — Technical Review (critical reviewer: security, rules, compliance, architecture, quality)

Full evidence: `_drafts/04b_backend_security.md`, `_drafts/03a`–`03f`. This file consolidates and assigns final severities.

## 1. Business-rule enforcement (MVP_FEATURE_LIST §6) — server-side verdict

| Rule | Verdict | Evidence |
|---|---|---|
| 1. One account = one role | ✅ ENFORCED | role set only at creation (`AuthController.php:42-56`); no endpoint mutates `users.role`; onboarding aborts on mismatch; `role:` middleware |
| 2. Minors: consent, visibility, guardian-mediated contact, no precise location | ⚠️ PARTIAL — **broken on 3 of 4 sub-rules** | Consent + verified-OTP + chat gate enforced (`ConversationController.php:239-264`, privacy floor `PrivacyController.php:48-65`, leaderboard masking `:74-110`). BUT: minor can edit own guardian controls (`GuardianController.php:184-207`); scout "guardian review" notifies the minor, not a guardian (`AthleteContactController.php:39-49`); `who_can_connect` unenforced → anyone can connect with a minor; minors' emails/phones leak via discovery nested `user` (`AthleteDiscoveryController.php:60,132`); minors' full names leak on scout dashboard (`ScoutDashboardController.php:28-31`) | 
| 3. Chat only via accepted connection or enquiry/registration thread; no cold DMs | ❌ VIOLATED (adults) | `peerChatGate` falls through when target's `who_can_message=everyone` (adult default) — no relationship check (`ConversationController.php:318`); minors are gated. Enquiry threads themselves are a separate Enquiry model, not Conversations — enquiry-thread messaging works |
| 4. Manual verification, badge admin-only | ✅ ENFORCED | admin-only approve under `auth+role:admin+admin.2fa` (api.php:535,543); ownership checks; no self-set path found |
| 5. Fees informational only | ✅ ENFORCED | no payment gateway anywhere; ⚠️ athletes can self-declare `payment_status=paid` (`RegistrationController.php:309`) |
| 6. Capacity closes at full; duplicates blocked; race-safe | ❌ VIOLATED | no capacity check in either registration store path (`RegistrationController.php:21-94,298-370`); duplicates DB-protected but race yields 500; opportunity applications lack unique index |
| 7. Auto-archive expiry job | ✅ ENFORCED | `SweepExpiredContentJob` hourly (`routes/console.php:19`), rule-driven, idempotent; ⚠️ owners not notified, edit doesn't reschedule |
| 8. Leaderboard: verified achievements only; minors masked | ❌ VIOLATED | `achievements` table has no verified column → "verified only" filter is dead code (`LeaderboardService.php:81-90`); points uncapped and self-serve (+50/POST); `/me/leaderboard` has no filter at all and matches winners by free-text name. Minor masking itself: ✅ correct on season board |
| 9. Everything reportable; moderation hides + notifies | ❌ VIOLATED | report reachable only for 4 listing types from the app (no posts/profiles); moderation `remove` on post/facility = QueryException 500 (`AdminModerationController.php:141`); Blade resolve closes reports leaving content live |
| 10. Scout data private (owner + admin) | ✅ ENFORCED | shortlists/observations owner-scoped everywhere; IDOR sweep found no gap. Erosion: shortlist-add notifies the subject with scout's name; dashboard leaks minor names |

**Score: 5 enforced / 1 partial / 4 violated.** The violated ones (2, 3, 6, 8, 9) are precisely the rules the platform's trust story depends on.

## 2. Security findings (final severities)

### BLOCKER
| ID | Finding | Evidence |
|---|---|---|
| S-1 | Release signing keystore committed to git | `my-release-key.jks` in `git ls-files` (commit 251082b) |
| S-2 | Live APP_KEY + DB root password + tunnel URLs committed | `CREDENTIALS.md` (root); seeded admin TOTP secret + all passwords in tracked `sportx-api/TEST_CREDENTIALS.md` + `AdminProfileSeeder.php:19` |
| S-3 | Suspended/pending users retain full API access — no status middleware, no token deletion on suspend, tokens never expire | `AdminUserController.php:72-76`; `bootstrap/app.php` (no middleware); `config/sanctum.php:53`; phantom middleware claimed at `AuthController.php:66` |
| S-4 | Login OTP bypass: `require_otp=false` client flag | `AuthController.php:194-196` |
| S-5 | Verification documents + all media on PUBLIC disk; signed-URL access control is theater | `MediaController.php:266,272`; `MediaItem::url()` `/storage/...` |
| S-6 | Registration capacity unenforced (data-integrity + fairness + legal exposure to registrants) | `RegistrationController.php` store paths |
| S-7 | Moderation "remove" on posts/facilities throws 500 → reported content stays live; Blade "resolve" closes reports without action | `AdminModerationController.php:141`; `AdminPanelController.php:329` |

### HIGH
- Cold DMs allowed by default (rule 3) — `ConversationController.php:318`.
- `who_can_connect` never enforced → adults can connect with minors — `PrivacyController.php` stored, never read by Connection/ScoutConnection controllers.
- Guardian-controls editable by the minor — `GuardianController.php:184-207`.
- Athlete discovery leaks email/phone incl. minors — `AthleteDiscoveryController.php:60,132`.
- Admin API login + verify-2fa unthrottled; TOTP ±1 window online-brute-forceable; TOTP secret stored plaintext (+ duplicated in `admin_profiles`); `ADMIN_2FA_ENFORCE=false` accepts any 6 digits — `routes/api.php:640-645`, `TotpService.php:14`, `AdminAuthController.php:70-86`.
- `google2fa_secret` serialized out of `/admin/users` (not in `User::$hidden`).
- Delete-account 401 for Google-only users (app-store compliance risk) — `SettingsController::destroy`.
- Draft events readable by any authed user — `EventController::show():93-106`.
- No global API rate limit; no TrustProxies (throttles collapse behind proxy IP); CORS `*` default — `config/cors.php:20`.
- Reset/verification tokens unhashed at rest — `AuthController.php:136-138,338-341`.
- Minor revokes consent → existing private chats stay open (send path doesn't re-check).

### MEDIUM
Registration `payment_status` client-settable · organizer public card leaks `registration_number`/`verification_doc_media_id` · observation `media_id` not ownership-checked · shortlist-add notifies subject with scout name · no HTTPS force/HSTS/secure-cookie config · no DB backups · Sentry disabled · `Auditable` trail switchable off via setting; Post/Program/Facility/Opportunity admin edits unaudited.

### Verified clean
IDOR sweep of ~22 endpoint families (no missing ownership checks) · OTP pipeline (bcrypt, expiry, attempts, burn, per-destination caps, never logged) · upload MIME content-sniffing + 10MB cap + quota in-transaction · no SQL injection (one guarded `orderByRaw`) · Blade panel CSRF on all forms, no `{!! !!}` XSS found · Horizon not mounted · Google sign-in verifies ID token server-side.

## 3. Child safety & compliance (India DPDP / app-store)

| Requirement | Status | Evidence |
|---|---|---|
| Verifiable parental consent (DPDP §9) | PARTIAL — guardian email OTP + stored consent, but minor can loosen own controls; no consent artifact (timestamp/IP/text version) stored | `guardian_consents` migration; `GuardianController.php:184-207` |
| No tracking/targeted ads to children | OK (no ads; analytics absent entirely) | — |
| Data minimisation | FAIL — public disk holds ID/certificates; discovery leaks contact PII | S-5, discovery leak |
| Account deletion in-app (app store) | PARTIAL — present, breaks for Google accounts; media files not purged | `SettingsController::destroy` |
| UGC reporting & blocking (app store) | FAIL — report unreachable for posts/profiles; block unreachable entirely | M11.1/M11.2 |
| Content moderation | FAIL — remove action broken on posts | S-7 |
| Privacy policy / terms | PRESENT — `PRIVACY_POLICY.md`, legal screens | — |
| Consent capture for T&C at signup | MISSING entirely | M1.1 |
| Guardian contact mediation for minors | FAIL — notifications routed to minor | `AthleteContactController.php:39-49` |

## 4. Architecture

**Good:** clean layering in the API (controllers thin-ish, services for OTP/expiry/notifications/leaderboard); unified Event API over trials/tournaments (Phase 8) is a sensible consolidation; legacy endpoints deliberately 410'd via `LegacyGoneController`; Auditable trait; scheduled jobs are idempotent and prune their own tables.

**Problems:**
1. **Dual-surface drift (Blade vs JSON API vs Flutter admin):** three admin implementations of the same operations have already diverged dangerously — Blade moderation hard-deletes silently while API remove 500s; Blade expiry rules work while API updateRules 500s; content manager covers 7 types in Blade vs 11 in API. Every fix must be applied twice or thrice.
2. **Twin leaderboards** (`LeaderboardController` vs `AthleteLeaderboardController`) with different integrity guarantees — one masked/capped-ish, one raw.
3. **Registration model sprawl:** trial/tournament registration tables + separate unified EventRegistrationController + per-type PATCH endpoints kept in parallel (api.php:314-382) — the bulk type-pinning bug lives exactly in this seam.
4. **Flutter god files:** `home_kit.dart` (1,571 lines), `multi_step_onboarding_screen.dart` (1,207), `admin_provider.dart` (1,015).
5. **Dead code/dependencies:** `riverpod_generator`, `pretty_dio_logger`, `pull_to_refresh` unused; `ApiConfig.maxRetries` unreferenced; `saveUserData` zero callers; `/explore` API unused; ReminderService never armed; `PostController` video rejection contradicts spec; P2 groups stack fully built while P0s missing (scope creep).
6. **Env reality:** APP_URL = ngrok tunnel, APP_DEBUG=true, APP_ENV=local — dev config treated as production; Flutter release builds would bundle the tunnel URL (no flavor split).

## 5. Quality

- **Tests:** Flutter `flutter test`: 90 passed / 1 failed (`test/core/session_scope_test.dart` — provider-reset drops search/notification state). Breadth: model JSON + error mapping + 6 UI tests. **No router/auth-guard, push deep-link, or 401-interceptor tests.** Backend: PHPUnit suite exists (`phpunit.xml`, `tests/`) but **could not be executed on this machine (no PHP)** — coverage unknown, UNVERIFIED.
- **CI:** none — no `.github/`, no pipeline config anywhere.
- **Static analysis:** `flutter analyze` = 49 issues, **0 errors** (the chat_provider error was fixed in commit 8e3423c), 2 warnings, 47 info. Backend: Pint configured; not run (no PHP).
- **TODO/FIXME debt:** zero occurrences in `sportx_app/lib` + `sportx-api/app` (verified by grep) — unusual and good.
- **Observability:** push health + mail probe monitors scheduled; `push_status` tracked per notification; but Sentry disabled, no crash reporting at all, no request logging in release (good for PII, bad for debugging).
- **Analytics:** `POST /analytics/events` funnel endpoint live and unused; zero client instrumentation (M12.6 NOT STARTED).

## 6. Scalability / reliability risks for the first 10k users

1. **No pagination server-side on several list endpoints** (opportunities cap 50 silently; universal search fixed `limit()->get()`; organizer trial "upcoming" unfiltered) — will degrade with data.
2. **`AthleteLeaderboardController` loads the entire `athlete_profiles` table into memory per request** (`:66-68`) — O(users) per leaderboard view; nightly rebuild + request-time scans don't mix.
3. **Feed like/media maps are batched (good), but achievements eager-load on discovery rows is wasted weight**; fee filters do string-column numeric comparisons → full scans.
4. **Database queue driver** with `queue:listen` (composer dev) — not Horizon in production (Horizon unmounted); long-task compression runs queued but worker supervision is undefined.
5. **Local/public disk storage** — no S3; multiple app servers or a restart lose uploads; signed URLs pointless on public disk.
6. **No rate limiting on public reads** + no CDN story — a single scraper can drain the DB.
7. **No backups** configured anywhere in the repo.
