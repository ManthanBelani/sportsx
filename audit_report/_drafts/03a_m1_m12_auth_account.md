# Audit — M1 (Accounts, Onboarding & Trust) and M12 (Account, Settings & Platform)

Scope: end-to-end trace (Flutter UI → provider → API client → Laravel route → controller → validation/auth → model → response → UI update).
Read-only audit, 2026-11-02. Evidence: `file:line`.

---

## M1.1 Sign up / login — **PARTIAL** (Severity: HIGH)

Backend
- `POST /auth/register` — `sportx-api/routes/api.php:114`, throttled `throttle:10,1` (routes/api.php:113). Controller `sportx-api/app/Http/Controllers/AuthController.php:20-81`. Requires email + password (min:8) + role; phone optional. **Marks the account `email_verified_at = now()` at registration (line 62) — the email is never actually verified on the password path.**
- `POST /auth/login` — AuthController.php:147-224. Password check → status checks → **OTP step enforced by default outside unit tests** (`$enforceOtp = ... !app()->runningUnitTests()`, line 194-196) → emails `PURPOSE_LOGIN` code. Flutter sends `require_otp: true` explicitly (`sportx_app/lib/features/auth/presentation/providers/auth_provider.dart:321-325`).
- Passwordless OTP login: `POST /auth/otp-login/request|verify` — AuthController.php:245-317; uniform responses prevent account enumeration (line 264-266).
- OTP signup: `POST /auth/send-otp|verify-otp` — `sportx-api/app/Http/Controllers/OtpController.php:34-139`. `verify-otp` creates the account on `purpose=signup` (line 115-126) — password is `required_if:purpose,signup` (line 92), so "password optional" is not true anywhere; every path requires a password (Google sign-in excepted).
- Google: `POST /auth/google` — GoogleAuthController.php (role resolution guarded at line 38-46).
- Token issued = Sanctum plainTextToken (AuthController.php:68/185/217/310).

Flutter
- Screens: `sign_up_screen.dart`, `login_screen.dart`, `otp_screen.dart`, `landing_screen.dart`; provider `auth_provider.dart` (register:117, login:318, otpLoginRequest:353, otpLoginVerify:367, sendOtp:197, verifyOtp:216).
- Session persistence: `flutter_secure_storage` (EncryptedSharedPreferences on Android) — `sportx_app/lib/core/utils/storage_service.dart:14-31`; `flutter_secure_storage: ^9.2.2` in `pubspec.yaml:17`. On cold start `/auth/me` revalidates the token (`auth_provider.dart:55-105`); invalid token → deleted → unauthenticated.

Gaps
1. **T&C/privacy consent is NOT captured server-side.** UI checkbox gates submit (`sign_up_screen.dart:24,35,155-204`) but no `terms`/`consent` field is sent, no column exists (`users` migrations have no consent field; grep for `terms_accepted|consent` in `sportx-api/database/migrations` returns only guardian-consent migrations). No timestamp/IP stored. Regulatory gap. (HIGH)
2. **Email is auto-verified on the password registration path** (AuthController.php:62) — `verify-email`/`resend-verification` (AuthController.php:83-145) exist but are dead code for new accounts. (MEDIUM)
3. **Phone/SMS login is not available** — OtpService throws `OtpDeliveryException` for any non-email destination (`sportx-api/app/Services/OtpService.php:deliver()`); "Phone or email" per spec is effectively email-only (AS-60). (MEDIUM, known limitation)
4. Sanctum tokens never expire (`config/sanctum.php:53 'expiration' => null`). (LOW)

## M1.2 Role selection — **DONE**

- UI: `role_selection_screen.dart:57-108` — exactly 5 role cards: athlete, coach, academy, organizer, scout (scout at line 100-112). Sponsor removed.
- Server-side one-account-one-role: role is only set at creation (`AuthController.php:42-44,56-57`, `OtpController.php:251,276`) and validated `in:...` (AuthController.php:23). **No endpoint mutates `users.role`** (ProfileController `update` has no role field; grep confirms). Onboarding endpoints abort on role mismatch (`OnboardingController.php:20,58,86,130`) and role-guarded routes use `role:` middleware (routes/api.php:233-263).
- Sponsor explicitly refused with 410 (AuthController.php:33-40, OtpController.php:242-249).

## M1.3 Role-based onboarding wizard — **DONE**

- Backend: `POST /onboarding/{athlete|coach|academy|organizer|sponsor|talent-scout|scout}` all behind `auth:sanctum` (routes/api.php:171-178) with per-role validation (OnboardingController.php:17-176+); `GET /onboarding/{role}` schema (routes/api.php:530).
- Flutter: `multi_step_onboarding_provider.dart:68-118` (per-role step lists + required keys), `multi_step_onboarding_screen.dart` posts to `/onboarding/<role>` (provider:204-212); dedicated screens also exist (`coach_onboarding_screen.dart:107`, `academy_onboarding_screen.dart:85`, `organizer_onboarding_screen.dart:106`, `talent_scout_provider.dart:61`).
- Router forces onboarding when `needs_onboarding` (`core/router.dart:270-277`); `needs_onboarding` derived server-side from `hasRoleProfile()` (`Models/User.php:144-157`, returned in every auth response).
- Gap: athlete `bio` intentionally soft-required (OnboardingController.php:30-33). (LOW)

## M1.4 Guardian consent for minors — **PARTIAL** (Severity: HIGH)

Backend (strong)
- Routes (routes/api.php:143-151) with throttles; controller `GuardianController.php:35-79` (athlete-only, guardian email ≠ athlete email at line 50-57).
- `GuardianConsentService.php`: minor = `CarbonImmutable::parse($dob)->age < 18` (isMinor, line 27-38); pending consents superseded on new request (line 45-49); OTP sent to **guardian's** email with `PURPOSE_GUARDIAN_CONSENT` (line 57-64); verify marks consent verified (line 71-100). Record persisted via `GuardianConsent` model (statuses/relationship/marks: `Models/GuardianConsent.php:13-117`); migration `2026_10_02_000001_create_guardian_consents_table.php` (FK cascade to users, line 29-30).
- Enforcement is real, in the consuming features:
  - Chat: `ConversationController::minorChatGate()` blocks conversations/messages involving a minor athlete without verified consent with `allow_messages=true` (`ConversationController.php:~96-104, ~148-160, minorChatGate at ~232-260`).
  - Privacy defaults + hard floor for minors: `PrivacyController.php:24-32, 48-65` (minors cannot loosen `who_can_message`, `profile_visibility`, `who_can_connect`).
  - Leaderboard name masking: `LeaderboardController.php:75-110` (first-name+initial unless verified guardian opt-in).
  - Discovery: `AthleteDiscoveryController::maskMinor()` strips DOB/phone for non-self/admin viewers (lines ~110-140).

Gaps
1. **`PUT /me/guardian-controls` is callable by the minor's own session** (routes/api.php:149; `GuardianController::update` line 184-207 only checks that a verified consent exists). The athlete can flip `allow_messages` / `allow_public_profile` themselves, defeating "guardian controls messaging & visibility". (HIGH)
2. `GuardianController::request` does not check `isMinor` — an adult athlete can also add a guardian; harmless but sloppy. (LOW)
3. Consent verification is only on the athlete's device/session — a minor who has the guardian's email password can self-consent; accepted design trade-off but worth noting. (LOW)
4. Account is `active` even when a minor skips the guardian step (verification only forces `status=active` at line 92-94; it never blocks) — mitigated by the restricted defaults above. (MEDIUM)
5. `GuardianConsentService::allowsMessages/allowsPublicProfile/leaderboardNameMode` (the service-level helpers) are dead code — enforcement is duplicated inline in controllers; drift risk. (LOW)

Flutter: `guardian_consent_screen.dart` posts `/guardian/consent`, `/guardian/resend`, `/guardian/verify-otp` (lines 68, 105, 128); minor detection after athlete onboarding computes age client-side and routes to `/guardian-consent` (`multi_step_onboarding_screen.dart:243-263`); `/guardian-controls` route exists (router.dart:350).

## M1.5 Profile completion meter — **DONE**

- Backend: `GET /me/completion-checklist` (routes/api.php:159) — `CompletionChecklistController::show()` returns `completion`, `missing[]`, per-check `deep_link` (lines 28-51, 118-200); per-role checks incl. guardian consent and verification. Static `completionFor()` embedded in `GET /me/home` (`HomeController.php:45`).
- Flutter: Home nudge with deep link `/profile-completion` (`home_screen.dart:75,86`); Profile screen shows `% Complete` + progress bar (`athlete/profile_screen.dart:44,166-168,349-383`); More screen shows "Profile %" computed from profile fields (`more_screen.dart:105-120,211`).
- Gap: backend checklist deep links are API-relative strings (`'profile/edit'`, `'settings/guardian'`), not the app's go_router paths — the mapping to Flutter routes is ad-hoc. (LOW)

## M1.6 Verification request & blue check — **DONE** (Severity: LOW)

- Request: `POST /me/verification` (routes/api.php:155) — `VerificationController::store()` validates morph type against a whitelist (lines 27-34, 48-54), **ownership check line 57-61** (entity must belong to the user), one live request per entity (63-75). User can never self-set verified: only `PATCH /admin/verification/{id}/approve|reject` (routes/api.php:543-544) inside `auth:sanctum + role:admin + admin.2fa` (routes/api.php:535) can flip it — `VerificationRequest::approve/reject` set `reviewed_by`, `reviewed_at` and push the badge column (`Models/VerificationRequest.php:106-142`).
- Badge read-back: `User::isVerified()` = approved VerificationRequest exists (`Models/User.php:98-102`); exposed as `is_verified` in auth/user payloads (AuthController.php:400).
- Notification on result: NotificationService on approve and reject with mandatory reject reason (`VerificationController.php:153-159, 178-184`).
- Document privacy: proof docs are `media_items` rows (uploaded with `context=credential`, `verification_screen.dart:51-54`); files stored on `local` disk (`media_items` migration, `disk default 'local'`); access only via `GET /media/{id}/signed-url` which is **owner-or-admin gated** (`MediaController.php:389-406`) and `download` requires a valid signed URL (379-387). Not public. Good.
- Gaps: `athlete_profile` / `talent_scout_profile` have no badge column in `BADGE_COLUMNS` (`VerificationRequest.php:31-36`) — approval for those types only flips `is_verified` via the request row; per-entity badge flag is not written. (LOW)

## M1.7 Forgot password (P1) — **BROKEN** (Severity: HIGH)

- API: `POST /auth/forgot-password` (AuthController.php:330-347) generates a **64-char random token** (`Str::random(64)`, line 339) and emails `PasswordResetMail` whose template is a **button/link** to `deepLink('/reset-password?token=…')` (`app/Mail/PasswordResetMail.php:20-30`, `resources/views/emails/password-reset.blade.php:10-13`). `POST /auth/reset-password` (AuthController.php:349-384) validates email+token (60-min expiry via `reset_password_sent_at`, line 365), rehashes password and **revokes all existing tokens** (line 375) — the backend logic itself is sound.
- Flutter: `forgot_password_screen.dart` step 2 asks the user to **"Enter the code"** in a short OTP-style field (`_otp` controller, lines 29, 57-60) and posts it as `token` (`auth_provider.dart:398-407`). **No numeric code is ever emailed — only a 64-char link token.**
- The email link points to `config('app.frontend_url', config('app.url'))` (`SportXMail.php:73-83`); `.env` has **no FRONTEND_URL**, so it resolves to the ngrok APP_URL (`.env:5`), and the Flutter router has **no `/reset-password` route** (grep of `core/router.dart` = no match). The link goes nowhere and the typed "code" field can't hold a 64-char token.
- An OTP purpose `reset_password` exists in the OTP machinery (`OtpCode.php:22`) but is not wired into password reset (`/auth/verify-otp` with that purpose merely returns a session token; it never resets a password).

## M1.8 Language selection (P1) — **UI-ONLY** (Severity: MEDIUM)

- UI screen exists listing English/हिन्दी/ગુજરાતી (`language_screen.dart:9-23, 37-58`) — but "Continue" merely pops/goes home (line 84-90): **the selection is never saved** (not to storage, not to `/me/settings`).
- No localization framework: no `AppLocalizations`, no `flutter_localizations`, no l10n arb files in `sportx_app`.
- Backend accepts only `language|in:en,hi` (`SettingsController.php:49`) — Gujarati would be rejected if it were ever sent.
- Settings screen has its own language picker that *does* PUT `/me/settings` (`settings_provider.dart:114-119`) — inconsistent with the auth-flow screen.

## M1.9 Permissions primer (P1) — **UI-ONLY** (Severity: LOW)

- `permissions_primer_screen.dart` is a static rationale-card screen ("A.8 Permissions Primer — rationale cards", lines 9-41); it requests no permissions itself (no `Permission.request` / geolocator calls). Actual permission requests happen elsewhere (FCM etc.). Reachable at route `/permissions` (router.dart:342).

---

## M12.1 Settings & privacy — **DONE** (Severity: LOW)

- UI: `settings_screen.dart` — notification toggles (push/email/in-app/location), Change Password dialog (lines 96-98), Privacy section with `profile_visibility` / `who_can_message` / `who_can_connect` pickers (lines 136-175), Language, Help, Terms, Privacy Policy entries.
- API: `GET/PUT /me/settings` (`SettingsController::show/update`, lines 29-66), `PUT /me/settings/password` + alias `/me/change-password` (routes/api.php:449-451) verifying current password (`SettingsController.php:68-82`); `GET/PUT /me/privacy` (routes/api.php:437-438) with minor-restricted validation (PrivacyController.php:48-65). Flutter provider wires all of it (`settings_provider.dart:61,114-119,176`).
- Gap: password change does not invalidate other sessions/tokens. (LOW)

## M12.2 Delete account — **PARTIAL** (Severity: HIGH)

- Reachable in-app: Settings → Delete Account with password confirmation dialog (`settings_screen.dart:236-238, 509-541`); calls `DELETE /me/account` (`settings_provider.dart:135-137`).
- Backend: `SettingsController::destroy()` (lines 84-97) verifies password then `$user->delete()` — **hard delete**. FK cascades wipe profile/social/guardian/device rows (`athlete_profiles` migration line 13, `user_device_tokens` line 13, `guardian_consents` lines 29-30, social tables `2026_08_11_000001`). Compliant direction (in-app, hard delete).
- Gaps:
  1. **Google-only accounts (password null) cannot delete themselves** — `Hash::check($password, null)` always fails → 401. No OTP/email-code alternative path. (HIGH)
  2. Sanctum tokens are not explicitly revoked; `personal_access_tokens` has no FK (`2026_08_05_080023` morph table) → orphaned token rows (they become unusable only because the tokenable is gone). (MEDIUM)
  3. Media files on disk (`media_items` owner morph, soft-deletes) are not purged/anonymized. (MEDIUM)
  4. Content authored by the user (posts, messages, enquiries, registrations) — several `users` FKs are `nullOnDelete`/no-FK; attribution becomes null rather than anonymized; not a compliance violation but worth noting. (LOW)

## M12.3 Help, About, legal — **DONE**

- `help_support_screen.dart`, `legal_screen.dart` (comments confirm Settings wiring, line 12), Settings entries Terms (`/legal?tab=terms`) and Privacy (`/legal?tab=privacy`) at `settings_screen.dart:214-224`; "SportX India v1.0.0" about footer (line ~248). Routes registered in router.dart.

## M12.4 Logout with confirmation — **PARTIAL** (Severity: MEDIUM)

- More screen: confirmation dialog then logout (`more_screen.dart:60, 71-81`). Settings screen: **no confirmation** — direct `await logout()` on tap (`settings_screen.dart:228-231`). Spec says "with confirmation"; one of the two entry points skips it.
- Logout mechanics are correct: unregisters the FCM token server-side (`auth_provider.dart:472-487`), `POST /auth/logout` with `auth:sanctum` (routes/api.php:136) which deactivates all device tokens and deletes the current Sanctum token (`AuthController.php:319-328`), then clears secure storage (`auth_provider.dart:442`). Server-side failure still clears local state (catch at 436-441).

## M12.5 Empty / loading / error / offline states — **PARTIAL** (Severity: MEDIUM)

- Loading: skeleton widgets shared (`shared/presentation/widgets/skeleton.dart`), settings screen shows loading placeholder (`settings_screen.dart:53`).
- Errors: API exceptions surfaced via snackbars/dialogs (`auth_provider._fail` → `fieldErrors`, `settings_screen.dart:459`, OTP screen error snackbar at `otp_screen.dart:79-81, 99-101`).
- Empty states: `EmptyState` widget exists (`shared/presentation/widgets/sportx_cards.dart`) and is used in list screens.
- **Offline: no connectivity detection at all** — no `connectivity_plus` in pubspec.yaml, no offline banner/retry anywhere in auth or settings. Offline surfaces only as raw request errors.

## M12.6 Analytics & crash reporting — **NOT STARTED (API-ONLY)** (Severity: HIGH)

- Backend funnel endpoint exists: `POST /analytics/events` → `AnalyticsController::store()` (`FUNNEL = ['signup','registration','enquiry','shortlist']`, lines 14-32), persisted to `analytics_events` (migration `2026_10_19_000001_phase9_analytics_events.php`).
- Flutter: helper `logAnalyticsEvent()` defined (`notification_prefs_provider.dart:46-57`) but has **zero call sites** in the entire app (grep). No Firebase Analytics dependency.
- **Crash reporting removed**: comment in `lib/main.dart:12-15` and `pubspec.yaml:36` — `sentry_flutter` was removed because it broke the Android debug build. Nothing records crashes today.

## M12.7 Deep links — **UI-ONLY / BROKEN** (Severity: MEDIUM)

- Share text is generated: profile `${ApiConfig.webBaseUrl}/profile/{id}` (`athlete/profile_screen.dart:459-463`), posts `${webBaseUrl}/post-detail/{id}` (`post_detail_screen.dart:47`, `community_feed.dart:58`); `webBaseUrl` defaults to `https://sportx.in` (`core/config/api_config.dart:11`).
- **The app cannot receive links**: `android/app/src/main/AndroidManifest.xml` has only the MAIN/LAUNCHER intent-filter (lines 26-29) — no `https` app-link or custom scheme; GoRouter is constructed without deep-link route recovery for these paths; no route named `/profile/:id` as a shared web entry (the informative-site is a static Google-Apps-Script site — `informative-site/Code.gs, Index.html` — with no `/profile/{id}` handler).
- Transactional-email "deep links" (password reset, verify email) point at `APP_URL` (ngrok) with no client route to catch them (see M1.7).
- Notification `action_url`s are stored and returned (NotificationService.php:77,147) but the app does not resolve them into routes as external links.

---

## Cross-cutting: OTP security posture (supports M1.1/M1.4) — **STRONG**

- Codes are bcrypt-hashed at rest (`OtpService.php:generateAndSend` → `Hash::make($code)`, `OtpCode` model hides `code_hash`, `Models/OtpCode.php:38-41`); plaintext only in the outbound mail. Test-mode fixed code gated to non-production (`OtpService.php:testMode()`).
- Expiry: 10 min default, enforced in `scopePending` (`OtpCode.php:94-98`); single active code per tuple — new sends burn previous pending codes (`OtpService.php:49-56`), preventing replay.
- Brute force: per-code `attempts` counter incremented **before** check, max 5 (`OtpService.php:103-113`, `OtpCode::maxAttemptsReached` with `sportx.otp.max_attempts`); per-destination verify limiter 10/5min (`OtpController.php:306-315`); send limiter 5/hour/destination (`OtpController.php:289-298`); resend cooldown 60s server-enforced (`OtpService.php:resend`, 429); route throttles on top (routes/api.php:113-135). Cryptographically random codes via `random_int` (`OtpService.php:randomCode`).
- Enumerability: uniform responses on login-request/reset (`AuthController.php:264-266, 336, 346`), masked destination echoes (`OtpController.php:mask`).

## Minor UX: wrong/expired OTP, resend timer — **DONE**

- 6-box code entry with auto-advance, disabled verify until 6 digits, resend countdown `0:59` with disabled state (`otp_screen.dart:247-258, 304-317`); wrong/expired code surfaces backend message via snackbar (`otp_screen.dart:99-101` → backend "That code is incorrect or has expired.", OtpController.php:105-110). No remaining-attempt counter shown (attempt exhaustion just returns the same 422) — minor. (LOW)

---

## Summary table

| ID | Feature | Status | Severity of top gap |
|----|---------|--------|---------------------|
| M1.1 | Sign up / login | PARTIAL | HIGH (no T&C consent stored; email auto-verified; SMS absent) |
| M1.2 | Role selection (1:1) | DONE | LOW |
| M1.3 | Onboarding wizard per role | DONE | LOW |
| M1.4 | Guardian consent | PARTIAL | HIGH (minor can edit own guardian controls) |
| M1.5 | Completion meter | DONE | LOW (deep-link strings not app routes) |
| M1.6 | Verification / blue check | DONE | LOW (no badge column for athlete/scout profiles) |
| M1.7 | Forgot password | BROKEN | HIGH (link/code mismatch, dead deep link) |
| M1.8 | Language selection | UI-ONLY | MEDIUM (selection not saved; no l10n; backend rejects Gujarati) |
| M1.9 | Permissions primer | UI-ONLY | LOW |
| M12.1 | Settings & privacy | DONE | LOW |
| M12.2 | Delete account | PARTIAL | HIGH (Google-only accounts cannot delete) |
| M12.3 | Help/About/legal | DONE | — |
| M12.4 | Logout + confirmation | PARTIAL | MEDIUM (settings entry skips confirmation) |
| M12.5 | Empty/loading/error/offline | PARTIAL | MEDIUM (no offline detection) |
| M12.6 | Analytics & crash reporting | NOT STARTED | HIGH (helper never called; Sentry removed) |
| M12.7 | Deep links | UI-ONLY | MEDIUM (no intent-filter; shares dead-end) |

## Top 10 issues (blunt)

1. **M12.6 is vaporware**: `/analytics/events` endpoint ships but `logAnalyticsEvent()` has zero callers; Sentry was ripped out (main.dart:12). No funnel data, no crash data, in production.
2. **M1.7 forgot password cannot be completed as designed**: email delivers a link (64-char token) to an ngrok URL with no matching Flutter route; the app asks for a "code" that never exists (PasswordResetMail.php:20-30 vs forgot_password_screen.dart:57-60).
3. **M1.1 T&C consent is a checkbox in memory only** — nothing sent, nothing stored, no timestamp/IP (sign_up_screen.dart:155-204; no users-table consent column anywhere).
4. **M1.4 a minor can unlock themselves**: `PUT /me/guardian-controls` is authorized to the athlete's own session and mutates `allow_messages`/`allow_public_profile` (GuardianController.php:184-207, routes/api.php:149). The chat gate then passes (ConversationController minorChatGate reads the same row).
5. **M12.2 Google-only users cannot delete their account** (SettingsController.php:88-92 requires a password they never set) — app-store compliance risk.
6. **M1.1 password registration auto-verifies the email** (AuthController.php:62) — the entire verify-email flow is bypassed on the primary path.
7. **M12.7 deep links don't open the app**: no app-link intent-filter in AndroidManifest; shared `https://sportx.in/...` URLs dead-end; email deep links hit ngrok APP_URL.
8. **M1.8 language selection is a fake screen** — selection not persisted; backend validates `in:en,hi` so Gujarati would 422; no localization framework in the app at all.
9. **Sanctum tokens never expire** (config/sanctum.php:53) and delete-account leaves orphaned token rows — combined with no expiry, stolen tokens are forever.
10. **No offline handling** (no connectivity_plus): M12.5's "offline state" requirement is unmet on auth and settings screens.
