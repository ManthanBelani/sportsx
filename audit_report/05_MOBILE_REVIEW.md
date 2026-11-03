# 05 — Mobile (Flutter) Review

> Full cross-cutting review below (copy of verified trace from _drafts/05_mobile_review.md, dated 2026-11-03).

# 05 — Cross-cutting Mobile Engineering Review (sportx_app)

Scope: Flutter app only (`sportx_app/`). Navigation, shell, architecture, API layer, list/form patterns, media, push, storage, UI states, config, build quality (analyze/test), Android/iOS packaging.
Read-only audit, 2026-11-03. Module-level feature traces live in 03a–03f and are not repeated; this report cross-references them where they intersect cross-cutting concerns.
Evidence: `file:line` relative to `sportx_app/` unless prefixed.

---

## 1. Navigation — **Mostly complete; deep links and 2 routes are broken**

### Route inventory vs SCREEN_INVENTORY (§1–§5 of inventory)

All ~170 routes are registered in `lib/core/router.dart` (routes list at :322-734). Mapping to screen IDs:

| Inventory ID | Route(s) | Status |
|---|---|---|
| A.1–A.5, A.6(P1), A.7(P1), A.8(P1), A.9, A.10 | `/splash`, `/role-selection`, `/sign-up`, `/verify-otp`, `/login`, `/forgot-password`, `/language`, `/permissions`, `/guardian-consent`, `/verification` (router.dart:323-344) | All present (A.6 BROKEN — see 03a M1.7) |
| S.1–S.29 | ShellRoute block (router.dart:651-733): `/home` + role dashboards, `/explore`, `/create`, `/community`, `/more`, `/universal-search`, `/search-filter`, `/leaderboard`, `/leaderboard-info`, `/notifications`, `/chat-list`, `/chat-screen`, `/my-connections`, `/connection-requests`, `/saved`, `/activity-hub`, `/settings`, `/safety`, `/help-support`, `/legal`, `/report`, `/post-detail/:id`, `/media-viewer`, `/groups`, `/group-detail`, `/reviews`, `/write-review` | All present. `/reviews`+`/write-review` are mock-data screens (defaults `average: 4.6` at router.dart:364 — no rating feature exists per 03b M2.12) |
| D.1–D.13 | `/view-profile`, `/coach-detail/:id`, `/academy-detail/:id`, `/organizer-profile`, `/scout-athlete/:id`, `/trial-detail/:id`, `/tournament-detail/:id`, `/trial-registration/:id`, `/tournament-registration/:id`, `/registration-confirmation`, `/opportunity-detail/:id`, `/program-detail/:id`, `/enquire/:subjectType/:subjectId/:title`, `/sports-venue-detail/:id` | Present |
| AT.1–AT.10 | `/home`, `/onboarding-1`, `/edit-profile`, `/manage-sports`, `/achievements`, `/profile-completion`, `/view-as-public`, `/my-opportunities`, `/my-registrations`, `/guardian-controls` | Present (AT.7 is a fully mocked screen — 03b M2.10) |
| CO.1–CO.5 | `/coach-onboarding`, `/coach-dashboard`, `/coach-profile`, `/coach-profile-edit`, `/my-programs`, `/post-program` | Present |
| AC.1–AC.9 | `/academy-onboarding`, `/academy-dashboard`, `/edit-academy-profile`, `/my-programs`, `/showcase-athletes`, `/my-trials`, `/facilities`, `/post-facility`, `/my-opportunities`, `/academy-invite-athlete` | Present (AC.10/invite-athlete is a hard-coded mock — 03d M6.4) |
| OR.1–OR.8, OR.10–OR.14 | `/organizer-onboarding`, `/organizer-dashboard`, `/organizer-profile-edit`, `/my-tournaments`, `/my-trials`, `/post-trial`, `/post-tournament`, `/organizer-event/:id`, `/registration-management`, `/registrant-detail`, `/event-gallery`, `/results-publishing`, `/results-view`, `/organizer-analytics`, `/facilities`, `/post-announcement` | Present. **OR.9 Schedule Editor has no route at all** (P1). |
| SC.x | `/scout-onboarding`, `/scout-dashboard`, `/scout-profile`(+`/edit`), `/scout-discovery`, `/scout-shortlist`, `/observations`, `/scout-connect/:athleteId`, `/scout-connections`, `/scout-compare`, `/talent-report`, `/opportunities` | Present (SC.6/SC.7 UI-only — 03e M10.6/M10.7) |
| AD.x | `/admin/login`, `/admin/dashboard`, `/admin/users`, `/admin/approvals`, `/admin/verification`, `/admin/moderation`, `/admin/content`, `/admin/master-data`, `/admin/expiry-rules`, `/admin/leaderboard-config`, `/admin/reports`, `/admin/analytics`, `/admin/settings`, … | Present, but `admin_expiry_rules_screen.dart` is a hard-coded mock (03f M11.8) |

**P0 screen IDs with no route: effectively none.** The P0 set is fully routed. The missing routes are P1 (OR.9) or P2 (S.13 groups detail real data). The real P0 gaps are functional, not navigational: no report button on posts/profiles and no block button anywhere (03f M11.1/M11.2 — confirmed at shell level, §13 below).

### Auth guard & role redirect — **Solid, with one hole**

- Guard: `redirect` at router.dart:253-321. Unauthenticated → `/role-selection` (router.dart:313-317); authenticated users bounced off auth screens to their role dashboard (router.dart:280-282); forced onboarding when `needs_onboarding` (router.dart:271-277); role-scoped route gating for `/post-opportunity` (organizer excluded, router.dart:296-299) and `/post-trial|/post-tournament|/post-program|/post-facility` (athlete excluded, router.dart:300-308) via `canCreateListings`/`canPostOpportunities` (`core/role_config.dart:50,65`).
- Role dashboards: `_dashboardRouteFor` (router.dart:200-219) — admin → `/admin/dashboard`, sponsor legacy → `/opportunities`. Session switch/login/logout resets user-scoped providers (RouterNotifier :221-243, `core/session_scope.dart`).
- **Hole (MEDIUM): unauthenticated users can open any `/admin/*` screen.** router.dart:316 — `if (loc.startsWith('/admin')) return null;` returns null for EVERYTHING under /admin when signed out, not just `/admin/login`. `/admin/dashboard`, `/admin/users` etc. render (API calls will 401) instead of redirecting to login.
- Legacy redirects cleaned up properly (sponsor → opportunities, router.dart:477,486-487,534,545-547,557-561,584,590,609).

### Deep links — **Not configured (confirmed) + broken in-app push targets**

- **No app links / custom scheme on Android**: `android/app/src/main/AndroidManifest.xml:26-29` has ONLY the MAIN/LAUNCHER intent-filter. No VIEW intent-filter, no `autoVerify`. Confirms the 03a M12.7 finding.
- **No custom scheme on iOS** beyond a Google Sign-In placeholder (`ios/Runner/Info.plist` `CFBundleURLSchemes` = `CHANGE_ME_REVERSED_CLIENT_ID` — the Google sign-in URL scheme itself is a placeholder, so iOS Google sign-in cannot work).
- GoRouter is fed by `MaterialApp.router` (main.dart:57-60) with no deep-link route mapping and `errorBuilder` printing "Page not found: {location}" (router.dart:735-737).
- **HIGH — push-notification deep links 404 inside the app.** The push handler navigates `ctx.go(action_url)` (`core/services/push_notification_service.dart:75-84, 245-247`), but several `action_url` values the backend emits have NO matching route:
  - `/account-status` (suspend/ban notices — `sportx-api/app/Http/Controllers/AdminUserController.php:93`, `Admin/AdminModerationController.php:227`)
  - `/my-reports` (moderation reporter outcome — `AdminModerationController.php:293`)
  - `/registrations/trials/{id}` and `/registrations/tournaments/{id}` (all approve/reject notifications — `sportx-api/app/Http/Controllers/RegistrationController.php:77,179,206,236,271,352`)
  Tapping "Your registration was approved" lands on the "Page not found" scaffold. Verified: none of these strings exist in `router.dart`.
  - `/chat-screen` is routed but requires an `extra` map (chatId/name/avatar, router.dart:570-577); a push tap without extras opens an empty chat thread.

### Back stack

Correct: tab switches use `context.go` (router.dart:887-901), details use `context.push`. `launchMode="singleTop"` + no deep links means no duplicated-stack weirdness. Shell keeps nav visible on hub/detail pages (router.dart:651-733).

---

## 2. Bottom nav & shell — **Matches spec; known message-badge gap stands**

- 5-item bar per spec (router.dart:767-771): Home → role `homeRoute` via `roleConfigProvider` (router.dart:891), Explore `/explore`, Create FAB, Community `/community`, More `/more`. Yellow 47px FAB pulled 28px above bar (router.dart:784-824).
- **Create inconsistency (LOW): the FAB does not navigate.** `_buildFab` opens `CreateBottomSheet.show(context, ref)` (router.dart:787) — the full `/create` tab (S.8 launcher, router.dart:731) is reachable only from the organizer dashboard shortcut (`organizer_dashboard_screen.dart:276`). `_onItemTapped` case 2 (router.dart:894) and `_calculateSelectedIndex` case 2 (router.dart:881) are dead for the FAB. Spec S.8 says "Create -> S.8 launcher"; most users get a bottom sheet instead. Either is defensible; the half-dead route path is not.
- **Community is real, not a placeholder (P1 delivered early):** `community_screen.dart:99-100` renders 4 tabs — Network / Groups / Events / Feed. Network has a "Suggested for you" section with working Follow (:162-231), Groups section has loading/error/Retry (:344-413), Events uses real trial/tournament providers (03d confirmed :546-583), Feed is paginated with load-more (:743-836).
- Header icons (`home_kit.dart:64-118`):
  - Search lives on screen bodies (Explore/Home), not the header — acceptable.
  - **Bell with live unread badge**: wired to `notificationsProvider.unreadCount` (home_kit.dart:96-105), refreshed on foreground/resume (:87-92) and on push (:150). Good.
  - **Message icon has NO unread badge — confirmed.** `home_kit.dart:99` is a plain `SportXIconButton`; the conversation list is never polled unless the screen is open (03d M7.6 gap 2). Unread counts exist per-row only (`chat_list_screen.dart:195-206`).
  - Avatar → own profile: `roleConfigProvider.profileRoute` (home_kit.dart:128-132) — per-role correct (athlete `/profile`, coach `/coach-profile`, etc., role_config.dart:185-296).
- More menu rows per role: complete and matching inventory §5–§10 (`role_config.dart:176-430`), incl. Settings & Privacy, Safety Centre via settings, Logout (`more_screen.dart:60,71-81` with confirmation).

---

## 3. Architecture — **Consistent Riverpod; 3 worst files named**

- Riverpod usage is consistent: 73 manual `Provider<...>` + 29 `StateNotifierProvider`/`ChangeNotifierProvider`/`NotifierProvider`; no setState-networking found; providers reset per session (`core/session_scope.dart`, invoked from RouterNotifier router.dart:232-236).
- **Dead tooling (LOW):** `riverpod_annotation`, `riverpod_generator`, `build_runner`, `custom_lint`, `riverpod_lint` are declared (pubspec.yaml:33-38) but `@riverpod` is used **zero** times in `lib/`. Same for `pretty_dio_logger` (pubspec.yaml:23, never imported) and `pull_to_refresh` (code uses plain `RefreshIndicator` everywhere — 0 imports found). Declared-but-unused dependencies bloat and mislead.
- Timer hygiene good: chat 4s polling `Timer.periodic` (chat_provider.dart:153) is stopped on dispose (03d verified chat_screen.dart:42-47); OTP countdown timer likewise (otp_screen.dart:57).
- Worst 3 files (size + mixed concerns):
  1. **`lib/shared/presentation/widgets/home_kit.dart` — 1,571 lines.** A grab-bag: header actions with unread-badge logic, greet cards, role lines, leaderboard section, feed tabs, event/person rails, post cards — mixing presentation, provider watching, lifecycle observers (an app-lifecycle observer lives inside a header widget, home_kit.dart:72-92) and navigation. Every home-tab change ripples through this file.
  2. **`lib/features/onboarding/presentation/screens/multi_step_onboarding_screen.dart` — 1,207 lines.** Five role onboarding wizards, per-role step lists, field validation, image upload and network submission all in one Stateful widget.
  3. **`lib/features/admin/presentation/providers/admin_provider.dart` — 1,015 lines.** One provider file holding every admin domain (users, verification, moderation, content, expiry, leaderboard config, notifications) — the admin analogue of a god-object. (Honourable mentions: `view_profile_screen.dart` 1,064 lines with dead-gated mock stats at :931-952; `registration_management_screen.dart` 961 lines with tabs+dialogs+CSV export.)
- Business logic leaks into widgets where providers are thin (e.g. settings logout without confirmation at `settings_screen.dart:228-231`, export logic in registration_management_screen.dart:170-197) — consistent with drafts; not systemic.

---

## 4. API layer — **Good single-client design; no retry, no refresh**

- **Single dio client** `dioProvider` (`core/utils/api_client.dart:73-98`) with `DeduplicationInterceptor` (:12-71, in-flight GET dedupe — nice), `AuthInterceptor` (:100-159), debug-only `LogInterceptor` (:84-93).
- **Token attach** (:128-146): Bearer from secure storage. Local pre-reject for auth-required prefixes (:108-144) prevents 401 spam. Good.
- **401 handling** (:149-158): delete token + `forceLogout()`. **No refresh — correct for Sanctum plainText tokens** (server never expires them; 03a M1.1 gap makes that worse: stolen tokens live forever).
- **No retry (LOW):** `ApiConfig.maxRetries = 1` (`core/config/api_config.dart:19`) is referenced **nowhere** — retry was declared and never implemented.
- **Timeouts**: connect/receive 30s from .env (api_config.dart:13-17; `.env` sets 30/30).
- **Error mapping**: `ApiException.fromDio` + `messageFor` (api_client.dart:161-342) is genuinely good — per-status messages, field-error extraction from both envelope shapes, socket/handshake classification, sanitization of raw Dart errors, 180-char clamp. This is one of the strongest parts of the codebase.
- **Logging/PII**: `pretty_dio_logger` is a dead dependency. The active `LogInterceptor` is gated `kDebugMode` and logs **request + response bodies** (api_client.dart:84-93) — fine for debug builds; **no logging in release**. No PII leak risk in shipped builds.
- **Base URL**: only from `.env` via `ApiConfig` (api_config.dart:4-11) with `https://sportx.in/api/v1` fallback. No hard-coded dev URLs anywhere in `lib/` (grep: zero hits for 10.0.2.2/192.168/ngrok/trycloudflare/localhost). BUT see §11 — the `.env` currently ships an ngrok tunnel and is bundled into builds.

---

## 5. Lists — **Patterns are mostly right; several truncation holes**

Shared pattern: `RefreshIndicator` + skeleton library (`shared/presentation/widgets/skeleton.dart` — 20+ named skeletons incl. `GenericListSkeleton`:401) + `EmptyState` (`shared/presentation/widgets/sportx_cards.dart:693`) + retry buttons. Verification:

| List | Pull-to-refresh | Pagination | Empty/Retry | Verdict |
|---|---|---|---|---|
| Home feed | home_screen.dart:41 | paginated `paginatedPostsProvider` with loadMore + dedupe (posts_provider.dart:138-155; community_screen.dart:743-836) | yes | OK |
| Community feed | community_screen.dart:783 | loadMore gated on `feed.hasMore` (:824-836) | retry :761-775 | OK |
| Notifications | notifications_screen.dart:113 | `meta.pagination` based loadMore (notifications_provider.dart:108-142; screen :159-162) | yes | OK (best example) |
| Chat list | chat_list_screen.dart:85 | none (server returns all conversations) | yes | OK for MVP |
| Opportunity list | opportunity_list_screen.dart:87 | **none** — server caps 50/page, no loadMore → silently truncated at 50 | yes | **MEDIUM** |
| My Registrations | my_registrations_screen.dart:136 | none | yes | MEDIUM at scale |
| Saved | — | **truncated at 20, no loadMore** (03b M3.9 — `saved_provider.dart:68-94`) | yes | **MEDIUM (stands)** |
| Universal search | — | **pagination broken end-to-end** (03b M3.6 — client reads `meta.current_page` the server never sends) | error ≡ "No results" | **MEDIUM (stands)** |
| Explore rails | — | first 20 only (03b M3.1) | yes | LOW |
| Registrations mgmt (organizer) | registration_management_screen.dart | paginated 30 server-side, client tabs+search | yes | OK |

So the drafts' list findings stand, and the same "load page 1 only" pattern also affects the opportunity list and my-registrations. Notifications proves the team knows how to paginate — the fix is mechanical.

---

## 6. Forms — **Double-submit protection solid; draft saving exists**

- **Double-submit guards**: `_submitting`/`_saving`/`_applying` flags present in 35 files. Verified: trial registration (trial_registration_screen.dart:274-294, per 03c), tournament (:67-97), opportunity apply (`opportunity_detail_screen.dart:48,55-56`), opportunity create (`post_opportunity_screen.dart:29,69,152`), posting screens use `onPressed: _saving ? null : ...` (tournament_posting_screen.dart:359). Confirms drafts.
- **Draft saving (spec ask) — EXISTS**: trial "Save as Draft" → `status: 'draft'` (trial_posting_screen.dart:101-104, button at :299); tournament (tournament_posting_screen.dart:166,359); programs active/draft (my_programs_screen.dart:160 + Drafts tab); opportunities (`post_opportunity_screen.dart:52,59`). There is **no draft-resume UX** (drafts are only reachable via the Active/Drafts lists — acceptable).
- Validation: uneven. Tournament form validates with snackbars (03c :37-57); **trial registration form has NO client validation** and its DOB field is collected but never sent (03c — dead UI field); opportunity deadline is free-text (03c M5.2). Stands.
- Keyboard: `windowSoftInputMode="adjustResize"` (AndroidManifest:19) — OK; no scroll-into-focus helper on long forms (multi-step onboarding relies on default scroll). LOW.

---

## 7. Media — **Basic compression only; no progress/cancel; iOS will crash on camera**

- **Compression**: `image_picker` with `imageQuality: 80` on every pick (add_achievement_screen.dart:41, add_credential_screen.dart:43, create_post_screen.dart:52, media_picker.dart:114). That is the only compression — no target-size compressor, no downscaling for huge photos. Adequate; server `CompressPhoto` job (03b) covers the rest.
- **No upload progress / cancel / retry** anywhere — uploads are fire-and-forget POSTs (e.g. trial doc upload trial_registration_screen.dart:205-233 "no per-file progress indicator" per 03c). For a 10MB cap on flaky rural networks, this is a real UX gap. MEDIUM.
- **Video: absent by design** — picker never calls `pickVideo`; server 422s `video_url` (03d M7.1). Spec deviation acknowledged there.
- **Permission denial**: no `permission_handler`/geolocator in pubspec. Android camera works via intents (no CAMERA permission declared — fine). **iOS: `ios/Runner/Info.plist` has NO `NSCameraUsageDescription` and NO `NSPhotoLibraryUsageDescription` — first camera/gallery tap on iOS crashes the app (HIGH).** image_picker requires those strings on iOS 10+.

---

## 8. Push — **All three app states handled correctly; token lifecycle correct; targets broken**

- **Setup**: `main.dart:25-30` — `Firebase.initializeApp` + `firebaseMessagingBackgroundHandler` registered before `runApp`. `PushNotificationService.init(ref)` after first frame (main.dart:47-51). Both wrapped in try/catch so missing config degrades gracefully.
- **Foreground — CONFIRMED** (prior trace :149-152 accurate): `FirebaseMessaging.onMessage` → bell refresh + local notification banner via flutter_local_notifications with the 5 backend-matching channels (push_notification_service.dart:27-58, 148-152). Fallback to snackbar if local show fails (:101-103).
- **Background tap**: `onMessageOpenedApp` (:155-159). **Terminated (cold start)**: `getInitialMessage` (:139-145). **Data-only background messages**: top-level `firebaseMessagingBackgroundHandler` queues to SharedPreferences (max 50) and `processPendingNotifications` replays them after auth (:221-252, called from auth_provider per 03e). All three states handled — confirmed.
- **Token registration**: on auth (`auth_provider.dart:310` → `registerTokenOnAuth` push_service.dart:189-192, duplicate-guarded); on token refresh (gated to authed sessions, :162-169); **removal on logout**: DELETE `/me/device-tokens` before the logout call (auth_provider.dart:437-437 `_unregisterFcmToken` :467-483) + server deactivates all tokens on `/auth/logout` + `clearTokenRegistration` (push_service.dart:195-197). Correct.
- **Tap → deep link routing: the weak link.** `ctx.go(action_url)` (:75-84) trusts backend `action_url`s verbatim — and 4 of them (account-status, my-reports, registrations/trials|tournaments/{id}) have no routes (see §1). HIGH.
- **Permissions**: AndroidManifest has `POST_NOTIFICATIONS` (AndroidManifest.xml:4) — good; runtime prompt requested (push_service.dart:129). iOS `UIBackgroundModes` includes `remote-notification` (Info.plist). Camera/photo strings missing (§7).

---

## 9. Local storage — **Clean**

- Tokens + user JSON in `flutter_secure_storage` with `encryptedSharedPreferences: true` (storage_service.dart:14-31). Confirmed good.
- `shared_preferences` is used ONLY for the pending-notification queue (push_notification_service.dart:225-230, 268-280) — non-sensitive. No tokens/PII in prefs.
- **Missed items (LOW):** `StorageService.saveUserData/getUserData` are **dead code** — `saveUserData` has zero callers (grep); the `_userKey` slot is never written. Logout deletes only the token (`auth_provider.dart:442`, `forceLogout` :490) — nothing else persists, so nothing is missed in practice. The dead methods should be deleted before someone starts using them as an unencrypted-by-design cache.
- Session-scoped provider reset on logout/switch (router.dart:232-236) prevents data bleed between accounts. Good.

---

## 10. UI states — **Shared widgets exist and are broadly used; offline is absent**

- Shared widgets: `EmptyState` (sportx_cards.dart:693), a comprehensive skeleton library (skeleton.dart: `SkeletonWidget`, `ShimmerSkeleton`, `GenericListSkeleton`:401, `GenericGridSkeleton`:438, `HomeSkeleton`:489, `NotificationsSkeleton`:512, plus 12 feature skeletons), retry buttons across lists. Usage is consistent in directories, explore, notifications, community, registrations (drafts corroborate).
- Inconsistencies (from drafts, still true): universal search error state indistinguishable from "No results" (03b M3.6); athlete profile screen has no full error-with-retry state (03b M2.1); `/reviews`, `/write-review`, `/map-view`, `/team`, `/groups` detail screens are mock/partial shells with real routes (router.dart:353-383,360-370).
- **Offline: confirmed absent.** No `connectivity_plus` in pubspec.yaml; no connectivity check, banner, or offline mode anywhere. Offline manifests only as the (good) error-snackbar text from `ApiException.fromDio` (api_client.dart:179-181, 235-236). For a rural-India-first product this is MEDIUM: users get no affordance that they're offline and every action fails individually. Chat additionally degrades to 4s polling failures rather than a queued send.

---

## 11. Config — **.env discipline is real but the shipped .env is a dev tunnel**

- `main.dart:19-23` loads `.env` with silent fallback to built-in defaults. Correct pattern.
- **`lib/` is clean** — no hard-coded dev IPs, tunnels, or localhost (grep verified; only `https://sportx.in` defaults in api_config.dart:4,11 and one duplicated literal share URL at `view_profile_screen.dart:508` instead of `ApiConfig.webBaseUrl` — LOW inconsistency).
- **`.env` (bundled as a Flutter asset, pubspec.yaml:71-72) currently contains:**
  - `API_BASE_URL=https://movable-washstand-ungraded.ngrok-free.dev/api/v1` — a dev tunnel. **Anyone who builds from this checkout ships an app pointing at an ngrok tunnel** whose URL dies when the dev's laptop sleeps. There is no build-variant/flavor split (single `.env`, no `--dart-define` usage).
  - Commented dev artifact: `# API_BASE_URL=http://45.196.196.118:8000/api/v1` — a raw public IP.
- `.env` is NOT git-tracked (only `.env.example`) — good — but the asset-bundling means the prod artifact equals whatever the dev last ran locally. HIGH for release process.
- `GOOGLE_SERVER_CLIENT_ID` in `.env` is a public OAuth client id (fine).
- `lib/firebase_options.dart` contains Firebase apiKeys (AIzaSy…) — expected/public by Firebase design, not a finding.
- `android/app/google-services.json` is committed — normal for Android, acceptable.

---

## 12. Quality gates — **analyze clean of errors; 1 failing test**

### `flutter analyze` — **49 issues: 0 errors, 2 warnings, 47 infos** (ran 2026-11-03)

- The baseline error at `chat_provider.dart:111` is **FIXED** — the file now compiles clean (current `markConversationRead(Ref ref, ...)` at chat_provider.dart:119-126 takes `Ref`; `sendMessage` takes `WidgetRef` and is called only from a `ConsumerState`). 03d's inference is confirmed by the analyzer.
- 0 errors today. Warnings (both trivial): `unnecessary_cast` (tournament_posting_screen.dart:169), `use_build_context_synchronously` (view_profile_screen.dart:261).
- The 47 infos are dominated by `use_null_aware_elements` (8), `curly_braces_in_flow_control_structures` (5), `use_build_context_synchronously` (3: view_profile_screen.dart:261, create_post_screen.dart:85 — guarded by an *unrelated* mounted check, media_picker.dart:108). Nothing structural.

### `flutter test` — **90 passed, 1 failed**

- Failure: `test/core/session_scope_test.dart: resetUserScopedProviders drops search results and notification state` (exit summary "00:43 +90 -1"). The suite exercises exactly the guarantee the RouterNotifier depends on — the failing test should be fixed or the test's setup updated, not ignored.
- Test breadth (24 files): `test/core/` (api client error mapping incl. validation errors, session scope, role discover links), 13 `test/models/` JSON-parsing tests, 6 `test/ui/` widget tests (kit overflow, my_programs, view_profile coach payload incl. JSON-encoded-string achievements regression, red-screen repro, external registration field), `test/widget_test.dart`.
- **What is NOT tested (MEDIUM):** the router (auth guard, role redirects — the single most security-relevant client code, including the `/admin/*` signed-out hole in §1), push deep-link routing, providers beyond session scope, no golden tests, no integration tests, zero tests for dio interceptors' 401-logout path.

---

## 13. Android / iOS / shell-level safety — **Release packaging needs work**

### android/app/build.gradle.kts

- `minSdk/targetSdk` = `flutter.minSdkVersion`/`flutter.targetSdkVersion` (defaults, no explicit pin) — acceptable but unpinned.
- **Release signing** references `my-release-key.jks` relative to `android/app/` (build.gradle.kts:44-51), resolved from `key.properties`. **The keystore and `key.properties` exist locally but are correctly git-ignored (android/.gitignore:12,14) and NOT committed** — so: no committed-secret problem, but **release builds are impossible on any other machine/CI** and the fallback `file("my-release-key.jks")` silently produces a broken release build (missing file) instead of a clear error.
- **No `isMinifyEnabled` / `isShrinkResources`** in the release build type (build.gradle.kts:53-56) — release is not minified/shrunk; Flutter's plugin does not enable R8 shrinking by default. App size and reverse-engineering surface both suffer. MEDIUM.
- **`android:usesCleartextTraffic="true"`** (AndroidManifest.xml:8) — app-wide cleartext HTTP allowed. It exists to serve the ngrok/local dev base URL; shipping this to production with `https://sportx.in` as the real endpoint is a MEDIUM security finding (any HTTP link/image resolved by the app is permitted).
- No app-link intent-filter (§1) — confirmed again.
- `POST_NOTIFICATIONS` present (AndroidManifest.xml:4); no CAMERA permission (not required via intents); no location (matches the absent near-me feature, 03b M3.8).

### ios/Runner/Info.plist

- **Missing `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` (HIGH)** — camera/gallery flows crash on iOS at first use.
- **`CFBundleURLSchemes` = `CHANGE_ME_REVERSED_CLIENT_ID`** (with a `TODO(prod)` comment) — iOS Google Sign-In cannot work; also no custom-scheme deep link.
- `UIBackgroundModes` = fetch + remote-notification — correct for FCM.
- Display name "Sportx App" (case inconsistent with Android "SportX") — cosmetic.

### Account deletion / report / block at shell level — **CONFIRMED as per drafts**

- **Account deletion reachable in-app**: Settings → Delete Account with password-confirm dialog (settings_screen.dart:236-238, 509-541 per 03a) — with the known HIGH gap that Google-only accounts cannot delete themselves (03a M12.2).
- **Block: NO block button exists anywhere in the app** — `blockUser()` (`follow_block_provider.dart:57-67`) has zero callers; no block entry in chat thread (grep of chat_screen.dart: zero hits for block/report), no block on any profile. Safety Centre can only ever show an empty list (03f M11.2). Stands, confirmed at shell level.
- **Report: only from 4 listing detail screens** via `detail_page_template.dart:363-373` (academy, sports_venue, tournament, trial — 03f M11.1). No report on posts, profiles, opportunities, programs. Stands.

---

## Severity summary (mobile-review-specific; drafts' findings not re-listed)

| # | Finding | Severity |
|---|---|---|
| 1 | Push deep links to `/account-status`, `/my-reports`, `/registrations/trials|tournaments/{id}` have no routes → "Page not found" on every registration-outcome and suspension notification tap | **HIGH** |
| 2 | iOS: missing camera/photo usage strings → camera/gallery crash on iOS; Google sign-in URL scheme is a `CHANGE_ME` placeholder | **HIGH** |
| 3 | `.env` bundled as build asset points at an ngrok dev tunnel (+ commented raw-IP artifact); no flavor/variant split — release artifact = whatever dev last ran | **HIGH** |
| 4 | No block button anywhere + report reachable from only 4 listing screens (confirmed at shell level; drafts 03f) | **HIGH** |
| 5 | Saved truncated at 20; universal search pagination broken; opportunity list & my-registrations have no pagination at all (server caps at 20–50) | **MEDIUM** |
| 6 | Unauthenticated users can open any `/admin/*` screen (guard hole, router.dart:316) | **MEDIUM** |
| 7 | `usesCleartextTraffic="true"` + no release minify/shrinkResources in gradle | **MEDIUM** |
| 8 | No offline handling (no connectivity_plus); offline = individual error snackbars | **MEDIUM** |
| 9 | No upload progress/cancel/retry for media; imageQuality 80 is the only compression | **MEDIUM** |
| 10 | 1 failing test (session_scope) + zero router/push/interceptor tests | **MEDIUM** |
| 11 | Dead dependencies & dead code: riverpod_annotation/generator, pretty_dio_logger, pull_to_refresh, `ApiConfig.maxRetries` (retry never implemented), `StorageService.saveUserData` | **LOW** |
| 12 | Create FAB opens bottom sheet while `/create` tab route is near-unreachable; header message icon has no unread badge (known) | **LOW** |
| 13 | Mock-data screens wired to real routes: reviews/write-review (default 4.6), map-view, team, view-as-public, groups detail, admin expiry rules | **MEDIUM** (misleading UI) |
| 14 | Widget god-files: home_kit.dart 1,571; multi_step_onboarding_screen.dart 1,207; admin_provider.dart 1,015 | **LOW** |

### What is genuinely good (credit where due)

- `ApiException`/`messageFor` error mapping (api_client.dart:161-342) is production-grade.
- Push service handles foreground/background/terminated + token lifecycle correctly; channels match backend; POST_NOTIFICATIONS declared.
- Role config (`role_config.dart`) is a clean single source of truth; router guard + session provider reset are correct in shape.
- Notifications list shows the correct pagination pattern the other lists should copy.
- flutter analyze has **0 errors** today (the old chat_provider error is fixed); secure storage + logout cleanup are right.
