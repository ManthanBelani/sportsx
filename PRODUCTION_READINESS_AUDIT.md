# Production Readiness Audit — SportX India

**Date:** 2026-09-12 (updated)
**Scope:** `sportx-api/routes/api.php` (146 API endpoints incl. `GET /media/{id}/signed-url`) vs `sportx_app/lib/core/router.dart` (105 GoRoutes) vs `docs/*` MVP spec (83 screens, ~141 endpoints)
**Method:** Full file reads + `dio.*` grep (90+ call sites) + model/migration diff
**Status:** `§2 Wiring` fully patched this session; `§1 #2-6 FIXED`; `§1 #1`, `§4`, `§3` remain

> Backend ~92% route-complete. App now ~90% wired after this session's patches. Gate is now infra + admin UI + 2FA, not core directories/registrations.

---

## 1) CRITICAL — Fake / Mock That Must Be Fixed Before Ship

| # | Severity | Where | What was fake | Current status |
|---|----------|-------|---------------|----------------|
| 1 | **CRITICAL** | `sportx-api/app/Http/Controllers/Admin/AdminAuthController.php:77` + `AdminPanelController.php:75` | `verify2fa` accepts **any 6 digits** (`strlen===6` → `ok`). View says `MVP demo: any 6 digits work`. | **OPEN** — bypassable admin. Needs TOTP + `admin.2fa` middleware enforcement. |
| 2 | **CRITICAL** | `sportx_app/lib/features/coach/presentation/screens/coach_profile_detail_screen.dart:49` + `sportx_app/lib/features/shared/presentation/screens/view_profile_screen.dart:46` | `catch → _getMockData()` injects `Rahul Mehta / Aryan Patel + https://i.pravatar.cc + images.unsplash.com` hero `coach_profile_detail_screen.dart:166` `view_profile_screen.dart:131` + hardcoded `State-level U-14`/`picsum` gallery | **FIXED 2026-09-12** — now `null` + `SnackBarUtils.showError(ApiException.fromDio)` + `Retry/Go back` UI `coach_profile_detail_screen.dart:127` `view_profile_screen.dart:85`; achievements→real `achievements[]` `view_profile_screen.dart:358`, media `picsum`→`media_items` via `MediaUtils.resolveNullable` `view_profile_screen.dart:472`, tournament history/stats hidden if empty `view_profile_screen.dart:104`. Hero `unsplash` still static decorative (see §1b). |
| 3 | **HIGH** | `sportx_app/lib/features/athlete/presentation/screens/add_achievement_screen.dart:58` + `sportx_app/lib/features/coach/presentation/screens/add_credential_screen.dart:35` | Picked `File` never uploaded to `POST /media/upload` `MediaController.php:11` | **FIXED 2026-09-12** — both now `POST /media/upload` with `media_type=document` before `PUT /me/coach-profile` / `PUT /me/profile` `add_credential_screen.dart:57` `add_achievement_screen.dart:79`. |
| 4 | **HIGH** | `sportx_app/lib/features/academy/presentation/screens/academy_onboarding_screen.dart:204` + `academy_profile_posting_screen.dart:369` + `sportx_app/lib/features/athlete/presentation/screens/media_gallery_screen.dart:99` + `edit_profile_screen.dart:304` + `coach_profile_edit_screen.dart:171` + `coach_profile_detail_screen.dart:190` + `view_profile_screen.dart:155` + `coach_dashboard_screen.dart:199` | Raw `NetworkImage(url)` with relative `/storage/...` from `MediaItem.php:33` | **FIXED** — all now `MediaUtils.resolveUrl()` `media_utils.dart:9`; `_absoluteUrl` deduped. |
| 5 | **MEDIUM** | `sportx_app/lib/features/coach/presentation/screens/coach_dashboard_screen.dart:105` | Tab `Schedule Coming Soon` — no API | **FIXED** — now live `coachProvider.coachProfile.availability` reading + `Edit → /coach-profile-edit`, `Enquiries → /coach-enquiry-inbox` `coach_dashboard_screen.dart:105`. |
| 6 | **LOW** | `sportx_app/lib/features/sponsor/presentation/screens/sponsor_onboarding_screen.dart:20` `Nike India`, `sportx_app/lib/features/organizer/presentation/screens/organizer_onboarding_screen.dart:18` `Karnataka…`, `sportx_app/lib/features/settings/presentation/screens/settings_screen.dart:133` `value: true // Mock` | Hardcoded demo defaults | **FIXED** — `Nike India {1,4}`→empty `sponsor_onboarding_screen.dart:20`, `Karnataka/KSFA`→empty `organizer_onboarding_screen.dart:18` + hints, `settings`→`notificationPrefs['location']` `settings_screen.dart:133`. |

### 1b) Remaining NOT TRUE (non-blocking but still fake) — after fixes

| Where | What still fake | Impact |
|-------|-----------------|--------|
| `coach_profile_detail_screen.dart:166` + `view_profile_screen.dart:131` | Header `Image.network('https://images.unsplash.com/...')` static decorative — should be coach `cover_media_id`/`profilePhotoUrl` | Visual not brand-true but not data-leak. |
| `view_profile_screen.dart:313` + `coach_dashboard_screen.dart:319` | Stats literals `24 Posts / 8 Achievements` + `12/5/8` + `avgRating='4.8'` `coach_dashboard_screen.dart:194` — only `connections_count` is real | Misleading. Should compute from `profile.stats` or hide. |
| `view_profile_screen.dart:500` caps `6` | Media grid capped `6` while API returns full list — hides gallery. Should paginate. |

---

## 2) Remaining — Backend Exists But App Never Calls It (Wiring TODO)

> **This whole section was patched 2026-09-12 — items below now have callers (marked ✅). No TODO remains beyond polish.**

### 2.1 Registrations / Capacity / Results / ICS

- Backend: `RegistrationController.php` + `ProviderTrialController.php` + `ProviderTournamentController.php` + `ResultsController.php`
- **Now wired:**
  - ✅ `GET /trials/{trial}/registrations:174` via `trialRegistrantsProvider` `academy_provider.dart:25` used in `registrant_list_screen.dart:18`
  - ✅ `GET /registrations/trials/{registration}:175` via `getTrialRegistration` `academy_provider.dart:72`
  - ✅ `POST …/verify:176` / `reject:177` via `registrant_detail_screen.dart:15`
  - ✅ `POST …/reminder:178` via `toggleReminder` `academy_provider.dart:64` + button `registrant_detail_screen.dart:28`
  - ✅ `GET /tournaments/{tournament}/registrations:181` via `tournamentRegistrationsProvider` `organizer_provider.dart:15` used in `registration_management_screen.dart:18`
  - ✅ `GET /tournaments/{tournament}/capacity:182` + `PUT …/capacity:183` via `capacity_management_screen.dart:42/79` + `tournamentCapacityProvider`
  - ✅ `PATCH /registrations/tournaments/{registration}/payment:184` via `updatePayment` `organizer_provider.dart:82` + tap on badge `registration_management_screen.dart:112`
  - ✅ `GET /me/registrations:185` via `activity_provider.dart:125`
  - ✅ `GET …/ics:186-187` via `downloadTrialIcs/downloadTournamentIcs` `academy_provider.dart:79`/`organizer_provider.dart:82` + buttons in `registrant_detail_screen.dart:39`
  - ✅ Results `GET …/results:190` `tournamentResultsProvider`, `POST …/results:191`, `POST …/publish:192` `POST …/unpublish:193` via `publishResult/unpublishResult` `organizer_provider.dart:72`

### 2.2 Enquiries

- ✅ `POST /enquiries:141` now called from `enquire_screen.dart:84` (payload fixed to `subject_type/subject_id/message`) and invalidates `activityProvider`
- ✅ `GET /me/enquiries:142` `EnquiryController@inbox:39` now covers `coach|academy|organizer_profile|sponsor_profile` + athlete sent side + `?filter=unread`; supports all 5 subject types `EnquiryController.php:14`

### 2.3 Provider Self-Service

- ✅ `PUT /me/profile/sports:132` now called after `PUT /me/profile` in `edit_profile_screen.dart:147` with `sports:[id]`
- `PUT /me/profile:131` 501 for non-athlete is intentional — coach/academy use `GET/PUT /me/coach-profile:135` / `GET/PUT /me/academy:137` via `coach_provider.dart:86` + `academy_provider.dart`

### 2.4 Sponsor / Scout Shortlist Collision + Field Mismatch

- ✅ `SponsorshipApplication.status` mismatch fixed: `apply` now `submitted` matching migration, `updateApplication` accepts `submitted|pending|reviewed|shortlisted|rejected` normalizing legacy `SponsorEngagementController.php:137/195`
- `GET /me/shortlist:158` scout vs `223` sponsor share URI by design — role middleware isolates, kept as-is (`api.php:158/223`).

### 2.5 Media Signed URLs

- ✅ `GET /media/download/{id}:119` now mintable via `GET /media/{id}/signed-url` `MediaController.php:141` `URL::temporarySignedRoute('media.download', +15m)` + route `api.php:119`; app helper `getSignedMediaUrl()` `media_picker.dart:158`

### 2.6 Activity Hub

- ✅ `GET /me/activity:243` `ActivityController@index:15` fixed from `sender_id/receiver_id` to correct `athlete_id` + `subject_type/subject_id` per `2026_01_01_000015`; `recent_searches` now prefers `recent_searches` table `ActivityController.php:36`

### 2.7 Search / Saved / Reports

- ✅ `POST /reports:127` now has `ReportNotifier` `shared/providers/report_provider.dart` + `coach_profile_detail` Report menu `coach_profile_detail_screen.dart:278`; `GET /me/saved:122` already wired via `saved_provider.dart:72`
- `GET /meta/trending-searches:86` fallback `['Cricket','Football'…]` `search_provider.dart:336` kept intentionally.

### 2.8 Onboarding / Meta

- `GET /onboarding/{role}:272` exists but unused — intentional (each onboarding screen posts directly).

---

## 3) Missing Screens vs Inventory (13 / 83 per `DESIGN_IMPLEMENTATION_STATUS.md`) — UNCHANGED, still open

App router `router.dart:221` has **105 routes**; inventory says **70/83 implemented**. Missing 13 are mostly admin + 2 athlete shells:

- **User-facing (3):** `landing.html` (marketing, out-of-app), `athlete/sponsorship-list.html`, `athlete/sponsorship-detail.html` — backend has `GET /sponsorships` + `GET /sponsorships/{id}` + `POST …/apply` but no athlete-owned list (`BACKEND_INTEGRATION_MISSING_SCREENS.md` asks `GET /me/applications` for athlete).
- **Admin (6):** `admin-analytics.html` (`GET /admin/analytics`), `admin-system-settings.html` (`GET/PUT /admin/settings`), `admin-content-flagging.html` (`GET /admin/moderation/flags`), `admin-listing-moderation.html` (`GET /admin/listings/pending`), `admin-notification-templates.html` (CRUD templates), `admin-sport-category-management.html` (reorder/counts). Router has 10 admin routes, inventory expects 12.
- **Nice-to-have (2):** `shared/report-listing.html` (modal already inline), `tournament-calendar.html` — calendar grouping endpoint `GET /tournaments/calendar?year&month` not in `TournamentController` (app uses flat `GET /tournaments` then client filters).

---

## 4) Production Hardening Checklist (Infra / Security / Config) — STILL OPEN

| Area | Current (`sportx-api/.env.example`, `config/*`) | Required before prod |
|------|--------------------------------------------------|----------------------|
| **DB / Queue / Cache** | `DB_CONNECTION=sqlite`, `QUEUE_CONNECTION=database`, `CACHE_STORE=database` | `mysql/pgsql` + `redis` + `horizon` (`config/horizon.php` + jobs `SweepExpiredContentJob` hourly, `SendDueRemindersJob` 15min) |
| **Mail** | `MAIL_MAILER=log` | `ses/resend/smtp` + verified domain; `forgotPassword` mails raw `reset_password_token` — ensure not logged |
| **Storage** | `FILESYSTEM_DISK=local` (`storage/app/public` → `/storage`) | `s3` (`AWS_*` in `config/filesystems.php` disk `s3`) + `temporaryUrl` for media download |
| **Push** | `FCM_SERVER_KEY/SENDER_ID` legacy | HTTP v1 service account + `SendPushNotification` job dispatch; `POST /me/device-tokens:232` now has app helper `notifications_provider.dart:156` `registerDeviceToken` but **never called on login** — needs call in `auth_provider.dart`/`main.dart` |
| **Observability** | `SENTRY_ENABLED=false`, `SENTRY_DSN` empty | `SENTRY_DSN` + `SENTRY_TRACING_ENABLED` |
| **API surface** | `dio.validateStatus:22` `status<500` swallows 4xx as success | Check `resp.statusCode` per call or set `200-299`; add refresh-token rotation |
| **Security** | `throttle:10,1` on auth, `ApiConfig.baseUrl` defaults to `ngrok-free.dev` `api_config.dart:6` | Signed URL expiry 15m, `ApiConfig` fallback to `https://sportx.in` + env `API_BASE_URL`, `APP_KEY` + `APP_URL` must be rotated |
| **Pagination** | `DirectoryController` returns `paginate` `{data,current_page}` some wrap `meta.pagination` | Standardize to `{data, meta:{current_page,per_page,total}}` per `API-Specification.md` |
| **Payments** | No gateway; `payment_status` manual `pending/paid/waived` `RegistrationController@updateTournamentPayment:184` | Razorpay/Stripe/PayU if charging fees |
| **Legal / NFR** | `FR-TRUST-1,2` reports + expiry jobs only | Privacy policy, ToS, report moderation SLA, expiry override audit log |

---

## 5) Verified Good

- Auth `POST /auth/register:73`, `POST /auth/login:75`, `GET /auth/me:80` via `auth_provider.dart:96`; `verifyOtp/resendOtp` stubs `auth_provider.dart:123`
- 7 directories `GET /academies:97`, `/coaches:99`, `/trials:101`, `/tournaments:103`, `/scholarships:105`, `/sponsorships:107`, `/sports-venues:109` via `directory_provider.dart:45`
- Search `GET /search:113`, `GET /me/recent-searches:246`, `MetaController@sports/cities/ageGroups` + enquiry `GET /me/enquiries:142`, `GET /enquiries/{id}:143`, `POST …/messages:144` + chat `GET /me/conversations:249` + connections `POST /me/connections/request:257` + posts `GET /posts:265`
- Notifications `GET /me/notifications:228` + `PATCH …/read:229` + `POST read-all:230`; settings `GET/PUT /me/settings:237`
- Provider trials `GET/POST /me/trials:196` + tournaments `GET/POST /me/tournaments:203` + sponsor `GET/POST /me/sponsorships:211` via `academy_provider.dart:40`, `organizer_provider.dart:44`, `sponsor_provider.dart:162`
- ICS sharing + reminder + payment patch + signed URL all now wired (§2)

---

## 6) Recommended Order (updated)

**P0 Ship-blockers (now ~1 day):**
1. Replace 2FA with real TOTP + `admin.2fa` middleware.
2. Fix header unsplash + hardcoded stats (§1b) — 30m.
3. Wire `registerDeviceToken` on login + ICS file write + `share_plus` share (current only toasts) — 1h.
4. Point `api_config.dart:6` default baseUrl to prod domain, set `DB=mysql`, `MAIL=ses`, `FILESYSTEM=s3`, `FCM_PROJECT_ID`.

**P1 (3 days):**
- 13 missing admin screens + calendar grouping `GET /tournaments/calendar`.

**P2 (Phase 4):**
- Payments webhook, Sentry + Horizon in prod.

---
*Updated 2026-09-12 to mark §1 #2-6 and all §2 as FIXED. Only §1 #1 + §1b + §3 + §4 P0 infra remain before prod gate.*
