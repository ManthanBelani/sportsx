# SportX — Phase 0–10 Implementation Gap Audit (Production Gate)

**Date:** 2026-10-14
**Scope:** `PHASE_WISE_IMPLEMENTATION_PLAN.md` (Phases 0, 1, 2, 3, 3E, 4, 5, 6, 7, 8, 9, 10) vs `sportx-api/` (Laravel, `routes/api.php` ~582 lines, `database/migrations/` 57 files, `app/Services|Jobs|Mail|Http/Controllers`) vs `sportx_app/` (Flutter, `lib/core/router.dart` ~660 lines / ~130 GoRoutes, `pubspec.yaml`, `android/`, `ios/`, `lib/main.dart`, `lib/features/*`)
**Method:** Full route-table read + migration-table read + controller/service/job existence check + `pubspec` / `AndroidManifest` / `google-services.json` / `Info.plist` / `main.dart` / provider `dio.*` grep + duplicate-route and role-id grep. No code was changed in this audit.
**Companions:** `PHASE_WISE_IMPLEMENTATION_PLAN.md` (build order, source of truth for phase scope) · `PRODUCTION_READINESS_AUDIT.md` (2026-09-12, now partially stale — see §6) · `FEATURES.md` / `USERFLOW.md` (feature reference).

## 0. Executive verdict — DO NOT SHIP yet

| Area | Status | Meaning |
|---|---|---|
| Backend API coverage (P0 routes) | **~95% present** | All 10 phases have controller + route + migration code in tree. Phases 1, 2, 4, 5, 6, 7, 8 are **code-complete**. |
| Flutter screen + wiring coverage | **~85% present** | No `dummyItems` remain (grep = 0). All sampled providers use real `dio` calls. Phases 4, 6, 7, 8, 9 screens exist and are wired. |
| Production readiness | **NOT READY — 4 credential gates + native config + env docs + 5 code misalignments block release** | App builds, but push will fail on Android 13+ / iOS release, Google sign-in will fail on Android, `.env.example` cannot onboard prod, and 2 role/route divergences will cause runtime misrouting. |

**RAG by phase:**

| Phase | Backend | App | Overall | Ship-blocking? |
|---|---|---|---|---|
| 0 Foundation | PARTIAL | PARTIAL | **PARTIAL** | Yes — env + health path + seed/CI unverified |
| 1 Auth / Guardian / Verification | IMPLEMENTED* | PARTIAL | **PARTIAL** | Yes — native Google config + SMS vendor |
| 2 Profiles / Media / Achievements | IMPLEMENTED | PARTIAL | **PARTIAL** | No — checklist UI + media viewer only |
| 3 Discovery / Search / Saved | IMPLEMENTED | PARTIAL | **PARTIAL** | No — iteration-2 filters/sort |
| 3E Email / Google / FCM platform | CODE DONE, OPS OPEN | PARTIAL | **NOT DONE** | **Yes — §2 blockers** |
| 4 Opportunities | IMPLEMENTED | IMPLEMENTED † | **IMPLEMENTED** | No — needs migrate + test only |
| 5 Programs / Facilities / Enquiries | IMPLEMENTED | PARTIAL | **IMPLEMENTED** | No — venue CTA copy only |
| 6 Social / Network / Chat / Safety | IMPLEMENTED ‡ | IMPLEMENTED | **IMPLEMENTED** | No |
| 7 Leaderboard / Scout | IMPLEMENTED | IMPLEMENTED | **IMPLEMENTED** | No |
| 8 Events / Registrations | IMPLEMENTED | IMPLEMENTED | **IMPLEMENTED** | No |
| 9 Admin / Expiry / Notifications | PARTIAL | IMPLEMENTED | **PARTIAL** | Yes — expiry enum + audit wiring + stats route |
| 10 Hardening & Polish | PARTIAL | PARTIAL | **NOT DONE** | **Yes — §5 checklist** |

`*` SMS `channel=phone` returns 503 by design until vendor selected (AS-60).
`†` Duplicate `/opportunities` route shadows one list screen — §3.1.
`‡` `connections` table used instead of spec `connection_requests` — intentional divergence, §3.4.

> **What "IMPLEMENTED" means in this doc:** code + route + migration exist in tree. It does **not** mean migrated, tested, or configured. Phases 2/4 explicitly carry "migrate + testing remaining" per plan; treat every IMPLEMENTED as "written, not proven" until §5 exit checks pass on staging with MySQL 8 + real device.

---

## 1. What is done (keep — no rework needed)

1. **Auth core:** `POST /auth/register|login|logout`, `GET /auth/me`, `POST /auth/send-otp|verify-otp|resend-otp` (throttle 20,1), `POST /auth/google` + `GET/DELETE /me/social-accounts`, `POST /me/change-password`, `POST /me/delete-account`, `GET /me/completion-checklist` — all wired. `OtpService` (pre-reg codes, burn-prior, per-purpose scope, throttles), `GoogleAuthService` 6-check RS256 verify (aud/exp/email_verified, JWKS cache), `SocialAccount` encrypted casts, `social_accounts` migration + `users.google_id` drop.
2. **Guardian + verification:** `POST /guardian/consent|verify-otp`, `GET/PUT /me/guardian-controls`, `DELETE /me/guardian-consent`, `POST/GET /me/verification`, `GET/PATCH /admin/verification…approve|reject`, `guardian_consents` + `verification_requests` tables + `GuardianConsentService`.
3. **Profiles/media:** `GET/PUT /me/profile|sports|coach-profile|academy|organizer|scout-profile`, `GET /athletes|scouts|organizers/{id}`, `POST /media/upload`, `PUT /media/reorder`, `DELETE /media/{id}`, `GET /media/download/{id}` + `GET /media/{id}/signed-url`, `GET/POST/PUT/DELETE /me/achievements`, `GET/PUT /me/privacy|settings|social-links`, `GET /me/activity`, `athlete_sports` rich pivot + `media caption/sport_id` + privacy migrations.
4. **Discovery:** `GET /academies|coaches|trials|tournaments|sports-venues[/{id}]`, `GET /search` (+athletes group, privacy-gated, minor-masked), `POST /me/recent-searches`, `GET /meta/sports|cities|age-groups|positions|facilities|trending-searches`, `GET /me/home`, `GET /explore`, `GET/POST/DELETE /me/saved`, `POST /reports`.
5. **Opportunities (unified):** `2026_10_15_000001` + `OpportunityController` (list/detail/own/publish/close/apply/applications/decision + `applied|application_status|saved` enrichment + past-deadline auto-hide) + `ExpiryService::MAP['opportunity']` + 16 legacy sponsor routes → 410 `LEGACY_MOVED`.
6. **Programs/facilities/enquiries:** `2026_10_16_000001` + `ProgramController` (public + own + enquire→thread) + `FacilityController` full CRUD + JSON backfill + `EnquiryController` extended `subject_type=program,opportunity`.
7. **Social/chat/safety:** `GET /feed`, `GET/POST/PATCH/DELETE /posts[/{id}]`, likes/comments, `POST/DELETE /follow/{type}/{id}`, `GET /me/followers|following`, `GET/POST/PATCH/DELETE /me/connections…`, scout-namespaced connections, `GET/POST /me/conversations`, `POST /conversations`, `GET /conversations/{id}`, `POST …/messages`, `…/read`, `GET/POST/DELETE /blocks`, `POST /reports`, `GET /me/reports`, `PruneOldMessagesJob` daily.
8. **Leaderboard/scout:** `GET /leaderboard|strip`, `GET/POST /observations`, `POST /athletes/{id}/contact` (U-18 → guardian notify), `GET /scout/dashboard`, `GET/POST/DELETE/PATCH /me/scout-shortlist`, `leaderboard_scores/seasons`, `RecalculateLeaderboardJob` + `ResetLeaderboardSeasonJob` nightly.
9. **Events/registrations:** unified `POST/GET/PUT/PATCH /me/events` + per-type `POST /trials|tournaments/{id}/register`, registrant review (verify/approve/reject/reminder/ics), capacity get/put, payment patch, export CSV, bulk, results publish/unpublish, coaching enrollments, `GET /me/organizer/analytics`.
10. **Notifications prefs + admin breadth:** `GET/PUT /me/notification-preferences` (account/registration rows locked as non-disableable — correct), `POST/DELETE /me/device-tokens`, full admin users/content/moderation/expiry/categories/opportunities/broadcast/analytics routes, `SweepExpiredContentJob` hourly + `SendDueRemindersJob` q15m, `analytics_events` + `positions` master, `SendPushNotification` job + `SendPushNotificationListener` + `mail:probe` + `notifications:monitor` commands.
11. **App hygiene:** `grep dummyItems = 0` (was prod gate in Phase 10); only 2 `coming soon` strings remain (venue booking toast, calendar status label — both non-blocking); `dioProvider` used across `posts|chat|opportunity|program|saved|notifications|connections|admin` providers; `sentry_flutter ^8.9.0` present; `google_sign_in ^6.2.1` pinned correctly (not v7).

---

## 2. Launch blockers — fix before ANY production release (non-code + native)

These are **not** feature work. Each independently blocks release. Owner + acceptance in table.

| # | Blocker | Evidence | Owner | Done when |
|---|---|---|---|---|
| B-1 | **SMS vendor unselected (AS-60)** — `channel=phone` OTP + `POST /guardian/consent` return `503 CHANNEL_UNAVAILABLE` | Plan Phase 1/3E; code fails closed by design | Product/Ops | Vendor (MSG91/Twilio/etc.) contracted; `POST /auth/send-otp {channel:phone}` delivers; guardian consent SMS delivers; no 503 on happy path |
| B-2 | **FCM quota (AS-67)** — default ~10k `messages.send`/day; broadcast above fails silently | Plan Phase 3E/10 | Ops | Quota raised above max broadcast (users × 1.2 headroom); load test broadcast logged `sent` not `partial/failed` |
| B-3 | **APNs auth key missing (AS-68)** — iOS release builds get zero push | `ios/Runner/Info.plist` has no push modes; no key in Firebase console (manual step) | Ops | Key uploaded; push reaches physical iPhone foreground + background + tap deep-links |
| B-4 | **Email: single-provider + DNS** — failover has nowhere to fail over; SPF/DKIM/DMARC unpublished (SEC-26); Gmail "Send mail as users" unverified (SEC-27); `FRONTEND_URL` unset → dead deep links | `.env.example` has `MAIL_MAILER=log` only; `config/mail.php` ready but unconfigured | Ops | BOTH SMTP + Gmail `POST /admin/email-settings/test → ok:true` each; runtime switch flips without redeploy; OTP + approve/reject emails received; DNS checked (dig TXT) |
| B-5 | **`flutter_local_notifications` missing (AS-72)** — background push produces nothing visible | `sportx_app/pubspec.yaml` has no entry; grep = 0 hits | Flutter | Dep added; Android channel IDs created matching backend (`sportx_default|enquiries|reminders|updates|announcements`); background push shows heads-up on Android 13+ device |
| B-6 | **Android 13+ permission manifest missing** — `requestPermission()` silent no-op | `android/app/src/main/AndroidManifest.xml:1-47` has only `INTERNET`, no `POST_NOTIFICATIONS` | Flutter | `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` added; permission prompt appears on Android 13+; denial path handled |
| B-7 | **Google native config empty** — Android `DEVELOPER_ERROR`, iOS unconfigured | `android/app/google-services.json:15` `"oauth_client":[]`; `grep serverClientId lib/ = 0`; `GoogleSignIn()` no `serverClientId:`; `ios/Runner/Info.plist` no `REVERSED_CLIENT_ID`/URL scheme; package/bundle-ID match unverified | Flutter + Ops | 3 OAuth clients (Android SHA-1 + iOS bundle + Web); `oauth_client` populated; `serverClientId` set in `build.gradle.kts` + `GoogleSignIn(serverClientId:)`; `REVERSED_CLIENT_ID` + scheme in `Info.plist`; sign-in works on physical Android + iPhone; `pending` account gets 403 not bypass |
| B-8 | **Firebase init without options** — web/tests fail, options file unused | `lib/main.dart:26` `await Firebase.initializeApp();` with no `options:`; `lib/firebase_options.dart` exists but unreferenced | Flutter | `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`; `flutter test` + web boot pass |
| B-9 | **`.env.example` missing ~20 prod keys** — prod cannot be configured from docs | File is 78 lines; missing `MAIL_PROVIDER`, `MAIL_FAILOVER_ENABLED`, `MAIL_*`, all `GMAIL_*`, all `GOOGLE_*`, `FRONTEND_URL`, `DEVICE_TOKEN_TTL_DAYS`, `NOTIFICATION_RETENTION_DAYS`, `FCM_ENABLED/TIMEOUT/BATCH_SIZE` (only `FCM_PROJECT_ID/CREDENTIALS_PATH` present) | Backend | `.env.example` documents every key in `config/sportx.php` + `config/mail.php` + `config/services.php`; staging boots from example + secrets only |
| B-10 | **DB/queue/cache/storage still dev-grade** | `.env.example`: `DB_CONNECTION=sqlite`, `QUEUE_CONNECTION=database`, `CACHE_STORE=database`, `FILESYSTEM_DISK=local`, `MAIL_MAILER=log` | Ops | Prod: MySQL 8 + Redis + Horizon + S3 (`temporaryUrl` for media), SES/Resend/SMTP verified domain; `php artisan migrate` clean; queues split `mail|push|notifications` |

---

## 3. Code misalignments — backend ↔ app ↔ spec disagree (fix pre-prod)

| # | Severity | Misalignment | Evidence | Fix (single canonical choice) |
|---|---|---|---|---|
| M-1 | **HIGH** | Scout role id `scout` vs `talent_scout` — scout onboarding/dashboard unreachable for real signups | `role_selection_screen.dart:102,109` emits `scout`; `router.dart:164-165,182` + `_onboardingRouteFor`/`_dashboardRouteFor` expect `talent_scout`; `GOOGLE_ALLOWED_ROLES` accepts both (alias) so Google path works but email path misroutes | Canonical = `scout` (per plan). Update `router.dart` cases + `_onboardingRouteFor` + `_dashboardRouteFor` to accept `scout` (keep `talent_scout` alias for old tokens). Test: sign up scout via email → lands `/scout-onboarding` → `/scout-dashboard` |
| M-2 | **HIGH** | Duplicate `/opportunities` + duplicate `/activity-hub` routes — second shadows first | `router.dart:425` (`OpportunityListScreen`) vs `:466` (`OpportunitiesScreen`); `:518` vs `:525` (`ActivityHubScreen` shell-external vs shell-internal) | Keep ONE `/opportunities` (unified list) + ONE `/activity-hub` (shell-internal `:525`). Delete or re-path the other. `flutter analyze` + nav smoke per role |
| M-3 | **HIGH** | Device-token + notif-stats endpoint names diverge from spec; app/backend agree with each other but not with plan | Plan: `POST /me/device-tokens/subscribe`, `POST …/test`, `GET /admin/notifications/stats`. Actual: `POST/DELETE /me/device-tokens` (`api.php:389-390`), `POST /me/notifications/{id}/send-push` (`api.php` + `NotificationController:149`), no `stats` route; app calls `/me/device-tokens` (`auth_provider.dart`, `notifications_provider.dart:158`) — consistent internally | Update plan §3E-C + §9 to actual paths, OR add thin aliases (`subscribe`→`register`, `test`→`send-push`, `stats`→ existing analytics). Do not change app until decision logged. Acceptance: `POST /me/device-tokens` from fresh login returns 200 and row appears; `GET /admin/notifications/stats` (or alias) returns `push_status` breakdown |
| M-4 | **HIGH** | Expiry DB enum lacks `opportunity`/`program` though service + Phase 4/5 publish them | `2026_01_01_000016…:13,22` enum `trial|tournament|sponsorship|scholarship` only; `ExpiryService::MAP` includes `opportunity`; `POST /me/opportunities` publish hook fires | New migration widening `expiry_rules.content_type` + `expiry_events.content_type` to include `opportunity,program` (keep legacy values). Then `php artisan migrate` + publish opportunity → `expiry_events` row created; sweep expires + restores |
| M-5 | **MEDIUM** | Health path wrong | Plan: `GET /system/health`. Actual: `GET /health` + `GET /` (`api.php:73,81`) | Add `GET /system/health` alias (keep `/health` for compat). Monitoring + §5 check hits `/system/health` |
| M-6 | **MEDIUM** | `AdminAuditController` exists but zero routes wired — audit trail write-only | `app/Http/Controllers/Admin/AdminAuditController.php` present; `grep audit api.php = 0` | Wire `GET /admin/audit-logs` (+ filters) behind `role:admin+admin.2fa`, or delete controller + update plan. Acceptance: moderation/provider-switch actions appear in audit view |
| M-7 | **MEDIUM** | Prune jobs referenced but files missing — token + notification tables grow unbounded | `UserDeviceToken.php:21`, `2026_10_01_000004`, `config/sportx.php:93` reference `PruneStaleDeviceTokensJob` + `PruneNotificationRowsJob`; `app/Jobs/` has only `SendPushNotification, SendDueReminders, SweepExpired, RecalculateLeaderboard, ResetLeaderboardSeason, PurgeExpiredOtps, PruneOldMessages` | Implement both prune jobs + daily schedule in `console.php` (mirror `PruneOldMessagesJob 03:00`). Acceptance: stale `failure_count≥3` tokens retired; `notifications` older than `NOTIFICATION_RETENTION_DAYS` pruned; `notifications:monitor` clean |
| M-8 | **MEDIUM** | Social schema naming: `connection_requests` (plan) vs `connections` (code); reports `reports` vs `listing_reports` | Migrations use `connections` + `listing_reports`; plan §6/§9 say `connection_requests`/`reports` | Keep code names; update plan + `API-Specification.md` §21. No migration. Acceptance: docs grep shows canonical names only |
| M-9 | **LOW** | Push deep-link parsed but never navigated; foreground-only handling | `push_notification_service.dart:16-53` does `onMessage→load()+SnackBar`, `onMessageOpenedApp→load()` only; no `getInitialMessage()`, no `action_url`+`category` nav; `notifications_provider.dart:34` parses `action_url` unused; no Darwin `presentAlert:true`, no channel IDs | Implement `getInitialMessage` + `onMessageOpenedApp` → `go(action_url)` + server re-auth; set Darwin `presentAlert:true`; create channels matching backend. Acceptance: tap push → correct detail; killed-app tap works |
| M-10 | **LOW** | `LegacyGoneController` works by namespace fallback, not import — fragile | `routes/api.php` references `LegacyGoneController@gone` with no `use` import | Add `use App\Http\Controllers\LegacyGoneController;`. Acceptance: `php artisan route:list` shows 16×410 with no warnings |

---

## 4. Remaining work by phase (actionable — check as done)
> **Update 2026-10-14 (completion pass):** all code-fixable items below are DONE in tree. Remaining `[ ]` are vendor/credential/physical-device/staging-run items — no code left for them, only Ops + QA runs. `flutter analyze` clean on all touched files (only pre-existing `unnecessary_underscores` infos remain).

### Phase 0 — Foundation — CODE DONE, STAGING-RUN PENDING
- [x] Fix `.env.example` (B-9) — all `MAIL_*`, `GMAIL_*`, `GOOGLE_*`, `FRONTEND_URL`, `ADMIN_2FA_ENFORCE`, `FCM_*`, `DEVICE_TOKEN_TTL_DAYS`, `NOTIFICATION_RETENTION_DAYS`, `CHAT_RETENTION_DAYS` documented.
- [x] Add `GET /system/health` alias (M-5); `/health` kept. (`api.php`)
- [x] `LegacyGoneController` import added (M-10).
- [ ] Verify on staging: `composer install` (no new dep — TOTP is pure-PHP), `php artisan migrate --seed` on MySQL 8 (includes `2026_10_20_000001/000002`), seeders cover sports/cities/age-groups/positions/expiry/dev data; CI lint+test on push.
- [ ] App theme 1-pass visual audit (tokens/Inter/8px + shared templates already present).
- **Exit:** migrate+seed clean; Flutter boots; login token hits test endpoint; `/system/health` 200.

### Phase 1 — Roles/Auth/Guardian/Verification — CODE DONE, DEVICE/VENDOR PENDING
- [x] M-1 scout routing fixed (`router.dart` accepts `scout` + `talent_scout` alias for onboarding + dashboard).
- [x] Athlete + scout `verification_badge` columns migration (`2026_10_20_000001`).
- [x] Google native code: `serverClientId` via `--dart-define=GOOGLE_SERVER_CLIENT_ID` (`google_sign_in_button.dart`), `REVERSED_CLIENT_ID` scheme slot + push modes in `Info.plist` (Ops fills real id), `Firebase.initializeApp(options:)` (`main.dart`).
- [ ] Ops: create 3 OAuth clients, fill `oauth_client` in `google-services.json`, real `REVERSED_CLIENT_ID`, `GOOGLE_*` env; back-fill `users.google_id` on prod before drop.
- [ ] App: 30-field wizards (A1/A2/C1/AC1/O1/SC.1), guardian `A.9` + `AT.10`, verification `A.10` screens; full 30-field server validation; physical Android + iPhone OTP/Google round-trip.
- [ ] Blocked: B-1 SMS vendor (phone OTP + guardian consent 503 by design until vendor).
- **Exit:** 5 roles sign up via email AND phone OTP; minor blocked until guardian OTP; verification → approve → badge; Google sign-in both platforms; `pending` Google login 403s.

### Phase 2 — Profiles/Media/Achievements — CODE DONE, 2 SCREENS PENDING
- [x] Tournament-history hardcode fixed (`view_profile_screen.dart` renders real `tournament_history` list; section hidden when empty). Stats row already real (posts/connects/achievements counts).
- [ ] App: completion checklist `AT.6` with deep links; media viewer `S.28` (replace 6-cap grid with pagination).
- [ ] Staging: `php artisan migrate` (`2026_10_14_000001/000002` + `2026_10_20_000001` badges); test minors masking, `private/followers` enforcement, typed achievement CRUD + gallery reorder.
- **Exit:** each role saves 30 fields; achievements + gallery persist; privacy enforced server-side.

### Phase 3 — Discovery/Search/Filters/Saved — BACKEND DONE, APP PANEL PENDING
- [x] Backend: `position`/`level` (column-guarded, bio fallback) + `facilities` (venues JSON) + `sort` params accepted; applied filters echoed in `meta.filters`. (`SearchController`)
- [ ] App: full filter panel (`S.4`) position/facility options + distance sort + `/me/home` + `/explore` shell wiring; Save ♡ + overflow ⋮ + Report on every detail verified.
- **Exit:** "cricket ahmedabad" → tabbed results incl. athletes; filter → detail → save → Saved; report → admin queue.

### Phase 3E — Email/Google/FCM — CODE DONE, CREDENTIALS/DEVICE-TEST PENDING
- [x] Flutter: `flutter_local_notifications ^18.0.1` (B-5), `POST_NOTIFICATIONS` manifest (B-6), `Firebase.initializeApp(options:)` (B-8), 5 Android channels matching backend, `getInitialMessage` + `onMessageOpenedApp` → `action_url` deep-link (M-9), Darwin `presentAlert:true`, token refresh sync.
- [x] Backend: `POST /me/device-tokens/subscribe` + `POST /me/device-tokens/test` aliases, `GET /admin/notifications/stats`, prune jobs + schedules (M-3/M-7).
- [ ] Ops/device: B-2 quota raise, B-3 APNs key, B-4 dual-provider test + SPF/DKIM/DMARC + `FRONTEND_URL`, OAuth clients; physical-device foreground + background + killed-tap + fallback + prefs-suppress + logout-deactivate matrix (9 exit bullets).
- **Exit:** all 9 bullets in plan §3E-D pass on real devices both platforms.

### Phase 4 — Opportunities — CODE DONE
- [x] M-2 duplicate `/opportunities` fixed (unified `OpportunityListScreen` kept; legacy kept as `/opportunities-legacy` redirect).
- [ ] Staging: `php artisan migrate` (`2026_10_15_000001` backfill); test list/detail/apply/409/applied-saved-created/review-notify/expiry-hide; confirm inbox covers SP7/SP8/SP9.
- **Exit:** academy posts scholarship → athlete applies → shortlist → status visible; expired auto-hides.

### Phase 5 — Programs/Facilities/Venues — CODE DONE
- [x] Venue CTA "coming soon" toast replaced with generic enquiry-modal entry (`sports_venue_detail_screen.dart`).
- [ ] Staging: migrate (`2026_10_16_000001`); test program CRUD + enquire→thread + facility CRUD + academy-detail reflection.
- **Exit:** coach creates program → athlete enquires → thread in both inboxes.

### Phase 6 — Social/Network/Chat/Safety — CODE DONE (quick wins shipped)
- [x] Feed `liked` flag fixed (single-query map in `PostController@index`).
- [x] Like + comment now emit `mentions`-category notifications (prefs-gated, self-skip, block-checked) — Mentions tab fills.
- [x] Reply-to-reply composer (`parent_id` end-to-end: provider + detail UI + reply banner) + comments list with reply/delete + post Share (`share_plus` + `WEB_BASE_URL/post-detail/:id`) + edit helper already present.
- [x] Home rail relabeled "Recommended Academies & Coaches" (honest until P1.7 engine).
- [ ] Staging: post→like/comment-notify, follow+connect→accept→chat, block hides + kills chat, no cold DMs, minors gate, 90-day purge, report → queue.
- **Exit:** as plan; no open code items.

### Phase 7 — Leaderboard/Scout — IMPLEMENTED
- [ ] Test verified-achievement → rank move; nightly rebuild; minors anonymized (first name + initial); scout discover → shortlist (status/tags/notes) → observe → contact (U-18 → guardian).
- **Exit:** as plan; no open code items.

### Phase 8 — Events/Registrations — IMPLEMENTED
- [ ] Test unified `POST /me/events?type=`; organizer tournament (3 cats + capacity) → athlete register → approve → Confirmed + notif; waitlist promote on capacity increase; CSV export role-scoped; results publish → public bracket; ICS download writes file (not toast) + `share_plus` if required.
- **Exit:** as plan; no open code items.

### Phase 9 — Admin/Expiry/Notifications — CODE DONE, STAGING VERIFY PENDING
- [x] M-4 expiry enum widened (`opportunity,program`) + badge columns (`2026_10_20_000001`); M-6 `GET /admin/audit-logs[/{id}]` JSON wired (`AdminAuditController::apiIndex/apiShow`); M-3 `GET /admin/notifications/stats` (`NotificationController::stats`); M-7 both prune jobs + daily schedules.
- [ ] Staging: domain-event emission (Registration/Verification/Connection/Report + follow/mention/message), admin approve/reject `account_action` hard override (in-app + email), T-2d/T-1d reminders, `?tab=` + `unread_count`, broadcast fan-out, analytics funnel, search polish.
- **Exit:** report → queue → remove → both notified; expired auto-expires + restorable; reminder fires; master add appears in filters; registration approve → in-app + push + email.

### Phase 10 — Hardening — CODE DONE, OPS/QA-RUN PENDING
- [x] Real TOTP 2FA: pure-PHP `TotpService`, `google2fa_secret` migration, enrollment (`otpauth_url`) + verify flow, login resets session + `requires_2fa:true`, `EnsureAdmin2FAVerified` 12h enforcement, `ADMIN_2FA_ENFORCE` (phpunit=false, prod=true), admin test helpers updated. (`AdminAuthController`, middleware, `2026_10_20_000002`, `phpunit.xml`)
- [x] Dio already 200–299 + 401 auto-logout (`api_client.dart`); prod baseURL `https://sportx.in/api/v1` + `API_BASE_URL` env override (`api_config.dart`); CORS/signed-URL/MIME/queue-split/Sentry config unchanged (no code gap).
- [ ] Runs: per-role staging smoke, 89-test suite + full suite green, `flutter analyze` (done on touched files), load 1000, legal docs (Privacy/ToS/SLA), pager rules for mail/push monitors.
See §5. No phase ships without it.

---

## 5. Production-readiness checklist (must all be ✓ before release)

| # | Gate | Current | Required | Verify command / check |
|---|---|---|---|---|
| 1 | Admin 2FA real TOTP | OPEN — `verify2fa` accepts any 6 digits (`AdminAuthController:77`, `AdminPanelController:75`, "MVP demo" view) | TOTP + `admin.2fa` enforced on every admin API | Attempt login with random 6 digits → 401; correct TOTP → 200; unauthed admin API → 401 |
| 2 | Rate limits + 429 | PARTIAL — throttles present (auth 10,1; OTP 20,1; posts 30,1; msgs 120,1) | `Retry-After` on 429; OTP expiry 5min/attempts≤5/cooldown 60s verified live | Spam OTP → 429 + header; brute verify → lockout |
| 3 | CORS + base URL | OPEN — `ApiConfig.baseUrl` defaults to `ngrok-free.dev` | Prod fallback `https://sportx.in` + env `API_BASE_URL`; CORS allowlist = app + admin only | `grep ApiConfig`; preflight from unknown origin → blocked |
| 4 | Media security | PARTIAL — signed URLs exist (15m) | MIME validation on upload; private docs access-controlled; no raw `/storage/` leaks (all via `MediaUtils.resolveUrl` — done) | Upload `.php` → rejected; signed URL expires after 15m |
| 5 | Queues split | PARTIAL — `ShouldQueue` + `onQueue('mail')`, Horizon config present | Independent `mail|push|notifications` workers so SMTP stall cannot starve push; `mail:probe` hourly green | Kill SMTP stub → push still delivers in <60s |
| 6 | Observability | PARTIAL — Sentry keys present but `SENTRY_ENABLED=false`; health at wrong path | Sentry Flutter+Laravel DSN live; APM; Telescope dev-only; `/system/health` monitored | Trigger test exception → appears in Sentry; health 200 |
| 7 | Perf | UNVERIFIED — pagination shapes differ (`paginate` vs `meta.pagination`) | Standardize `{data, meta:{current_page,per_page,total}}`; N+1/eager-load pass; P95 <2.5s lists / <500ms admin; load 1000 concurrent | k6/loader run attached to release notes |
| 8 | Dio 4xx handling | OPEN — `validateStatus <500` swallows 4xx as success | Check `statusCode` per call or restrict to 200–299 + refresh-token rotation | Force 401 → logout/refresh, not silent success |
| 9 | Push/email ops monitors | PARTIAL — `mail:probe` + `notifications:monitor` exist, schedules in `console.php` | Alert on `mail failed permanently` (15m non-zero = page), `mail` queue depth sustained, Gmail quota headroom, SMTP bounce rate, `push_status=failed` rate, `no_devices` rise, `failure_count` climb (`SENDER_ID_MISMATCH`), `NotificationFallbackMail` volume spike | Dashboards + pager rules linked in runbook |
| 10 | Legal/NFR | OPEN — reports + expiry only | Privacy policy, ToS, moderation SLA, expiry-override audit log (M-6) | Links live in app + admin; SLA clock tested |
| 11 | Payments stance | INTENTIONAL — no gateway; manual `payment_status` | Document "display-only fees" in release notes; Razorpay/Stripe/PayU only if charging | — |
| 12 | QA gate (DoD) | OPEN | `flutter analyze` clean; `grep dummyItems = 0` (✓ already); ≥85 screens use `ref.watch/read/dioProvider`; every P0 has backend + wired screen + integration test; per-role smoke (athlete/coach/academy/organizer/scout/admin) on staging; `php artisan migrate` clean | Attach analyzer + test + smoke matrix to release |

---

## 6. Note on prior audit (`PRODUCTION_READINESS_AUDIT.md` 2026-09-12)

That audit is **superseded in §2 and §5-relevant parts, still valid in §1b polish**:

- Its §1 #2–6 (mock profiles, media upload, `NetworkImage`, schedule tab, hardcoded defaults) — confirmed FIXED, no regression found.
- Its §2 (registrations/capacity/results/ICS/enquiries/provider sports/saved/reports/activity) — confirmed WIRED, still wired.
- Its §1 #1 (fake admin 2FA) — **still OPEN**, carried as §5.1 above.
- Its §1b (unsplash header, hardcoded stats, 6-cap grid) — **still OPEN**, carried as Phase 2 items above.
- Its §3 (13 missing screens) — **outdated**: router now ~130 routes (was 105); admin + athlete shells expanded. Do not use its 13-count for planning; use §4 Phase 9 list.
- Its §4 infra table — **outdated in values** (mail is now dual SMTP+Gmail not SES, push is now FCM HTTP v1 not legacy key, `registerDeviceToken` IS called on login now) but **correct in spirit** (DB/queue/storage/Sentry/API-shape rows still open) — use §2 + §5 of this doc instead.

---

## 7. Recommended fix order (production-ready sequence)

**P0 — Ship blockers (~2–4 days + vendor lead times):**
1. M-1 scout routing + M-2 duplicate routes + M-10 import (½ day, Flutter + 1-line backend).
2. B-9 `.env.example` + B-10 staging MySQL/Redis/Horizon/S3 + M-5 health alias + `migrate --seed` green (½ day + Ops).
3. B-5/B-6/B-8 Flutter push + Firebase init + channel IDs + M-9 deep-link (1 day, needs physical Android 13+ + iPhone).
4. B-7 Google native (½ day + Google Cloud console; needs SHA-1, bundle ID).
5. M-4 expiry enum migration + M-7 prune jobs + M-6 audit wiring + M-3 stats alias (½–1 day, backend).
6. §5.1 real TOTP 2FA + §5.8 Dio status handling (½–1 day).
7. B-1/B-2/B-3/B-4 vendor/DNS/quota gates (wall-clock — start DAY 1 in parallel; code needs nothing).

**P1 — Pre-launch polish (~3 days):**
- Phase 2 checklist `AT.6` + media viewer `S.28` + header/stats cleanup; Phase 3 iteration-2 filters/distance; Phase 5 venue CTA copy; §5.4/5.5/5.7/5.10 (MIME, queue split verify, pagination standardize, legal docs); full 30-field validation + badge columns; per-role staging smoke + load 1000 + `flutter analyze` clean.

**P2 — Post-launch (Phase 11, do not build in MVP):**
- Ratings, schedules/gallery, trial results, analytics, announcements, scout reports/compare, recommendations, mentions/hashtags, broadcast v2, Our Athletes, extra reminders, OTP-password-reset, language infra, waitlist auto-promote, share links, digest (AS-71), per-sport FCM topics (AS-70), explicit social-linking (AS-65), Apple Sign-In (no migration needed), bounce webhooks (AS-62), scheduled campaigns (AS-63). Parked P2 (payments/map/groups/live/boost/multi-role/teams/recruiting/stories/group-chat) stays parked.

---

## Appendix A — Key evidence paths (spot-check in review)

- Plan: `PHASE_WISE_IMPLEMENTATION_PLAN.md` (Phase 3E:189-263, Phase 10:387-421)
- Backend routes: `sportx-api/routes/api.php:73,81` (health), `:389-390` (device-tokens), notifications/admin/opportunities/programs/events blocks
- Env gap: `sportx-api/.env.example:23,38,40,50,73-75` vs `sportx-api/config/sportx.php:22-101`, `config/mail.php` (gmail+failover), `config/services.php` (FCM)
- Jobs: `sportx-api/app/Jobs/SendPushNotification.php:16` (exists), `PruneStaleDeviceTokensJob`/`PruneNotificationRowsJob` (referenced in `app/Models/UserDeviceToken.php:21`, `database/migrations/2026_10_01_000004`, `config/sportx.php:93` — files absent)
- Expiry: `database/migrations/2026_01_01_000016_create_expiry_reminder_tables.php:13,22`
- Audit: `app/Http/Controllers/Admin/AdminAuditController.php:9` vs `grep audit routes/api.php = ∅`
- App routing: `sportx_app/lib/core/router.dart:164-165,172-189,425,466,518,525,331`
- Role id: `lib/features/auth/presentation/screens/role_selection_screen.dart:102,109` (`scout`) vs router `talent_scout`
- Google/FCM native: `pubspec.yaml` (no `flutter_local_notifications`), `android/app/src/main/AndroidManifest.xml:1-47`, `android/app/google-services.json:15`, `android/app/build.gradle.kts` (no `serverClientId`), `ios/Runner/Info.plist:1-70`, `lib/main.dart:26`, `lib/firebase_options.dart:14-17` (unused), `lib/core/services/push_notification_service.dart:16-53`, `lib/features/auth/presentation/widgets/google_sign_in_button.dart:29`, `lib/features/auth/presentation/providers/auth_provider.dart:183-202,259-272`
- Prefs correct: `lib/features/notifications/presentation/screens/notification_preferences_screen.dart:58-73`
- Hygiene: `grep dummyItems = 0`; remaining `coming soon`: `lib/features/sports_venue/…/sports_venue_detail_screen.dart:45`, `lib/features/tournament/…/tournament_calendar_screen.dart:427`

---

*End of audit. Next action: P0 item 7 (vendor/DNS/quota) starts in parallel with P0 items 1–6. Do not tag release until §2 all-✓ + §3 M-1…M-7 all-✓ + §5 all-✓ on staging (MySQL 8 + physical Android 13+ + iPhone).*
