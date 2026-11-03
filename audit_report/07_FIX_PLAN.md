# 07 — Fix Plan (prioritised backlog)

Order = fastest path to "MVP READY". Effort: S ≤ half day · M ≤ 3 days · L > 3 days (single dev, familiar with code). "Blocks launch" per the MVP-ready definition (all P0 DONE, zero BLOCKER, zero HIGH in auth/minors/chat/registration/moderation).

## Wave 1 — Security & secrets (do before anything touches production)

| ID | Problem | Where | Exact change | Perspective | Sev | Effort | Blocks | Depends |
|---|---|---|---|---|---|---|---|---|
| F-01 | Signing keystore committed | `my-release-key.jks` (git-tracked) | Rotate key; purge from history (filter-repo); generate per-env keystores outside repo; document custody | Tech | BLOCKER | S | **Y** | — |
| F-02 | Live APP_KEY, DB root password, seeded admin TOTP secret committed | `CREDENTIALS.md`, `sportx-api/TEST_CREDENTIALS.md`, `AdminProfileSeeder.php:19` | Rotate APP_KEY + DB password; gate admin seeder behind `!production()`; purge files from history; move test creds to untracked doc | Tech | BLOCKER | S | **Y** | — |
| F-03 | Suspended/pending users keep API access | `bootstrap/app.php`, `AdminUserController.php:72-76`, `config/sanctum.php:53` | Add `EnsureUserActive` middleware (reject status ≠ active) on authed routes; delete tokens in suspend()/reject(); set Sanctum `expiration` (e.g. 30d) | Tech | BLOCKER | S | **Y** | — |
| F-04 | Login OTP bypass flag | `AuthController.php:194-196` | Remove `require_otp` request override; OTP always enforced outside unit tests | Tech | BLOCKER | S | **Y** | — |
| F-05 | ID/certificates + all media on public disk | `MediaController.php:266-273`, `MediaItem::url()` | Store sensitive contexts (credential/document/achievement-cert) on private disk; serve via existing signed-URL endpoint; keep public avatars/posts if desired | Tech | BLOCKER | M | **Y** | — |
| F-06 | Registration capacity unenforced | `RegistrationController::storeTrial/storeTournament` | Wrap store in transaction + `lockForUpdate` on trial/tournament row; check vacancies + per-category capacity; catch unique-violation → 409 | Backend | BLOCKER | M | **Y** | — |
| F-07 | Moderation remove 500s on posts/facilities; Blade resolve leaves content live | `AdminModerationController.php:141`, `AdminPanelController.php:329` | Add `status` column (or `listing_status`) to posts/facilities + fillable; filter it in public queries; make Blade resolve require an action; align Blade remove with API (soft-hide + notify) | Tech | BLOCKER | M | **Y** | F-08 |

## Wave 2 — Child safety & trust rules

| ID | Problem | Where | Exact change | Perspective | Sev | Effort | Blocks | Depends |
|---|---|---|---|---|---|---|---|---|
| F-08 | Minors' contact requests reach the minor, not a guardian | `AthleteContactController.php:39-49`, `ScoutConnectionController::store` | Add guardian email/phone channel (consent row already stores both): send outreach notice to guardian contact for <18; reject scout-connect for minors unless guardian-approved | Tech | BLOCKER | M | **Y** | — |
| F-09 | Minor can edit own guardian controls | `GuardianController.php:184-207` | Require guardian re-verification (OTP to guardian email) for `allow_messages`/`allow_public_profile`/`leaderboard_name_mode` changes; log changes | Tech | HIGH | S | **Y** | — |
| F-10 | Cold DMs allowed by default | `ConversationController.php:318`, `PrivacyController.php:29` | Change adult default to `connections`; or enforce: `everyone` still requires an accepted connection OR existing enquiry/registration thread — per spec rule 3 | Tech | HIGH | S | **Y** | — |
| F-11 | `who_can_connect` never enforced | `ConnectionController`, `ScoutConnectionController` | Read target's setting in request paths (mirror `who_can_message` check at `ConversationController.php:297-299`); minors locked to `nobody` | Tech | HIGH | S | **Y** | — |
| F-12 | No block/report reachability (app-store + safety) | `follow_block_provider.dart:57`, `chat_screen.dart`, `post_detail_screen.dart`, `detail_page_template.dart:363` | Add overflow Block+Report to: chat thread, profile screens, post detail, opportunity/event details (report target types already exist server-side) | Mobile | HIGH | M | **Y** | — |
| F-13 | Blocked users visible in discovery/search/profiles | `AthleteDiscoveryController`, `DirectoryController`, `SearchController`, `ProfileController` | Central `BlockedScope` (whereNotIn blocked ids) applied to all read paths — chat/feed already have it | Backend | HIGH | M | **Y** | F-12 |
| F-14 | Leaderboard integrity: no verified flag, uncapped points | `achievements` migration, `LeaderboardService.php:81-90`, `AthleteLeaderboardController.php` | Add `is_verified` + admin verification queue for achievements; filter both boards; cap achievement points; delete or fix name-matching winCounts; add index | Backend | HIGH | L | **Y** | — |
| F-15 | PII leaks: discovery nested user email/phone; organizer public card; scout dashboard minor names; google2fa_secret in /admin/users | `AthleteDiscoveryController.php:60,132`, `OrganizerProfileController.php:59-70`, `ScoutDashboardController.php:28-31`, `User.php:20` | `unsetRelation('user')` or explicit field whitelists in all public serializers; add `google2fa_secret` to `$hidden` | Tech | HIGH | S | **Y** | — |

## Wave 3 — P0 flow breakers

| ID | Problem | Where | Exact change | Perspective | Sev | Effort | Blocks | Depends |
|---|---|---|---|---|---|---|---|---|
| F-16 | Enquiry never notifies provider | `EnquiryController::store :12-48` | Send NotificationService row + FCM (type `enquiry`, hard-override) to listing owner; action_url → enquiry thread | Backend | HIGH | S | **Y** | — |
| F-17 | Registration outcome notifications suppressible + deep links 404 | `RegistrationController` (6 call sites), `NotificationService.php:22`, router.dart | Use `registration_approved/rejected` types; add routes `/registrations/trials/:id`, `/registrations/tournaments/:id`, `/account-status`, `/my-reports` to router.dart | Backend+Mobile | HIGH | S | **Y** | — |
| F-18 | T&C/privacy consent not captured | `sign_up_screen.dart`, `AuthController::register` | Send `terms_version + accepted_at` from app; store columns; include in audit | Both | HIGH | S | **Y** | — |
| F-19 | Forgot-password broken | `AuthController.php:339`, `PasswordResetMail.php`, `forgot_password_screen.dart` | Send 6-digit OTP-style code (reuse hardened OtpService) instead of link; wire reset screen to `/auth/reset-password` | Both | HIGH | S | **Y** | — |
| F-20 | Delete account fails for Google-only users | `SettingsController::destroy` | Skip password check when `password === null` (confirm via recent re-auth/Google token instead); also purge media files + revoke all tokens | Backend | HIGH | S | **Y** | — |
| F-21 | Bulk approve/reject unusable | `registration_management_screen.dart:715-743`, `EventRegistrationController::bulk:190-234` | Wire checkboxes to `bulkDecideRegistrations()` with confirm + reason prompt (bulk reject requires reason); fix sub-request type passing (call decision handlers directly per id) | Mobile+Backend | HIGH | M | **Y** | — |
| F-22 | Posts: video rejected; no edit/delete; save not wired | `PostController.php:156-158`, `posts_provider.dart:256-276`, `home_kit.dart:788` | Either restore video or amend spec; add overflow menu (edit/delete/report) in post detail; wire save to `/me/saved` type=post | Mobile | HIGH | M | Y (P0 M7.1/7.3 correctness) | — |
| F-23 | Analytics/crash reporting absent (P0 M12.6) | `notification_prefs_provider.dart:46-57`, `pubspec.yaml:36`, `AnalyticsController` | Call `logAnalyticsEvent()` at: signup done, registration submitted, enquiry sent, shortlist added (FUNNEL types already defined); re-add Sentry (or Crashlytics) with a build that doesn't break AGP | Mobile | HIGH | M | **Y** | — |
| F-24 | Admin 2FA hardening | `routes/api.php:640-645`, `AdminAuthController.php:70-86`, `TotpService.php:14` | Throttle admin login+verify (5/min); set `ADMIN_2FA_ENFORCE=true`; encrypt cast for `google2fa_secret`; remove seeded secret | Tech | HIGH | S | **Y** | F-02 |
| F-25 | Release build ships ngrok URL + cleartext | `sportx_app/.env`, `AndroidManifest.xml:8` | Introduce flavor/dart-define env split (dev/prod base URLs); remove cleartext; point prod at real API domain | Mobile | HIGH | M | **Y** | human: prod domain (08) |

## Wave 4 — HIGH P0 correctness / UX (launch-week)

| ID | Problem | Where | Exact change | Sev | Effort |
|---|---|---|---|---|---|
| F-26 | Opportunity apply: doc upload missing + dup race | apply screen; `opportunity_applications` migration | Add document picker reusing media upload; add unique `(opportunity_id, athlete_id)` index | HIGH | S |
| F-27 | Trial form: DOB dead field; docs not enforced; team fields dropped; payment_status client-settable | `trial_registration_screen.dart:70-75`, `RegistrationController:305-311` | Send DOB + validate against eligibility; enforce required_documents server-side; accept team fields or remove them; make payment_status server-defaulted | HIGH | M |
| F-28 | Draft events readable | `EventController::show():93-106` | Filter `published()` for non-owners | HIGH | S |
| F-29 | Universal search pagination + error-as-empty | `SearchController.php:146-149`, `search_provider.dart:292-304`, `universal_search_screen.dart:154` | Return real paginators per group (or `has_more` flags); map client; distinct error state | MEDIUM | M |
| F-30 | Saved + opportunity lists truncate | `saved_provider.dart:68-94`, `opportunity_list_screen.dart:87` | Add loadMore pagination to both | MEDIUM | S |
| F-31 | Suspended-at-login vs live sessions: notify user on suspension with `/account-status` route | covered by F-03 + F-17 | — | MEDIUM | S |
| F-32 | Near-me absent (P0 M3.8) | migrations + DirectoryController + filters | Minimum viable: use profile city + geocode table for city-level distance; defer GPS. Or formally descoped with sign-off | HIGH | L |
| F-33 | Mini-fixes batch | various | settings-logout confirm dialog; `/media/download` auth; observation media_id ownership check; expiry owner notification + reschedule-on-edit; message-icon unread badge; admin dashboard missing tiles; Blade moderation Warn/Suspend buttons | MEDIUM | M |

## Wave 5 — P1 / hardening (post-launch)
Language/l10n (M1.8) · reminders wiring (M9.3: call `ReminderService::arm()` on save/register) · ratings (M2.12) · view-as-public un-mock + public share routes + app-links (M2.10/M12.7) · talent report/compare backend (M10.6/7) · schedule editor (OR.9) · announcements endpoint (OR.14) · TrustProxies + global rate limiter + HTTPS/HSTS + backups + Sentry DSN + CI (GitHub Actions: flutter analyze/test + phpunit + pint) · kill dead deps (`pretty_dio_logger`, `pull_to_refresh`, `riverpod_generator` if staying manual) · split `home_kit.dart`.

## Top 10 fixes to reach MVP READY fastest
1. F-01/F-02 — rotate and purge all committed secrets.
2. F-03 — status middleware + token revocation (suspend actually works).
3. F-04 — remove OTP bypass.
4. F-06 — transactional capacity enforcement.
5. F-08/F-09 — real guardian mediation + lock guardian controls.
6. F-10/F-11 — enforce chat/connection rules server-side.
7. F-12/F-13 — block & report reachable everywhere + enforced in discovery.
8. F-05 — private storage for documents/certificates.
9. F-16/F-17 — enquiry + registration notifications with working deep links.
10. F-07/F-14 — moderation remove works; leaderboard verified-only.

Effort to Wave 1–3 completion: roughly 3–4 dev-weeks. Everything in Waves 1–3 is mechanical — no architectural rework required.
