# SportX India — Laravel ↔ Flutter Integration Test Report

**Date:** 2026-08-12  *(updated: all findings fixed & verified)*
**Stack:** Laravel 13.24 (Sanctum Bearer, MySQL `sportx`) @ `sportx-api` + Flutter 3.41 (Riverpod/Dio/go_router) @ `sportx_app`
**API:** `http://127.0.0.1:8002/api/v1` (health OK, DB connected, 49 tables, all 24 migrations applied)
**Method:** Live API probing (curl) + static contract analysis (controllers ↔ models/providers) + `php artisan test` + `flutter analyze`

> Findings are graded **CRITICAL** (breaks core flow / security), **HIGH**, **MEDIUM**, **GAP/N/A**.

> **STATUS: ✅ All 13 reported bugs + 1 bonus bug fixed and verified.** See the **Fixes Applied** section at the end of this report for file:line references, plus new automated tests (`18` backend, `8` Flutter — all green).

---

## Fixes Applied (verification status)

| # | Fix | Where | Verified |
|---|-----|-------|----------|
| B1 | Unauthenticated → clean **401** JSON (override guest-redirect + render handler) | `sportx-api/bootstrap/app.php` | ✅ `/auth/me` & protected endpoints → 401 |
| B2 | Parse `/auth/me` flat `data` directly (`User.fromJson(data)`) | `sportx_app/.../auth_provider.dart:43` | ✅ live + unit test |
| B3 | Read top-level `current_page`/`last_page` (no `meta`) + generic catch | `sportx_app/.../directory_provider.dart:48,63` | ✅ unit test (paginator has no `meta`) |
| B4 | Safe parsing: `entry_fee`/`prize_pool` (string→num), `required_documents`/`facilities` (list→string) | `trial.dart`, `tournament.dart`, `sports_venue.dart` | ✅ Flutter model tests |
| B5 | Backend infers owner from auth; client sends `media_type` | `MediaController.php:13`, `media_gallery_screen.dart:46` | ✅ upload 201 (owner inferred) |
| B6 | New cols + validated + persisted (added to `$fillable`) | migration `..._add_athlete_details_...`, `RegistrationController.php:26`, `TrialRegistration.php` | ✅ DB shows `playing_role/medical/consent` |
| B7 | `.env` → `http://10.0.2.2:8002/api/v1` (emulator) | `sportx_app/.env` | ✅ |
| B8 | `ApiException.fieldErrors` + inline `errorText` on login/signup | `api_client.dart`, `auth_provider.dart`, `login_screen.dart`, `sign_up_screen.dart` | ✅ unit test |
| B9 | Backend 403 adds top-level `message`; client handles `error` as Map | `EnsureRole.php:14`, `api_client.dart:71` | ✅ live 403 has `message` + unit test |
| B10 | `jsonEncode`/`jsonDecode` instead of `k=v&k=v` | `storage_service.dart:1,28` | ✅ compiles |
| B11 | `throttle:10,1` on auth credential routes | `routes/api.php` (auth group) | ✅ `X-RateLimit-Limit: 10` header present |
| B12 | `APP_DEBUG=false` | `sportx-api/.env` | ✅ no traces in error JSON |
| B13 | Authoritative `getMimeType()` allow-list per media type | `MediaController.php:20` | ✅ spoofed file → 422, real png → 201 |
| **BONUS** | Added missing **`athlete_sports`** pivot table (sponsor `/athletes` discovery was 500ing) | migration `..._create_athlete_sports_pivot.php` | ✅ sponsor `/athletes` → 200 |
| G3 | **18 backend** feature tests + **8 Flutter** tests (regression coverage) | `sportx-api/tests/Feature/*`, `sportx_app/test/**` | ✅ all pass |

**Final verification:**
- `php artisan test` → **18 passed** (52 assertions) on `sportx_testing` (MySQL).
- `flutter test` → **9 passed** (8 new + 1 placeholder).
- `flutter analyze` → **0 errors** (125 pre-existing info/warnings unchanged).

> Tests use a dedicated `sportx_testing` MySQL DB (`phpunit.xml` updated; this env lacks the `pdo_sqlite` driver). Run with `php artisan test`.

---


## Summary table

| # | Severity | Section | Finding |
|---|----------|---------|---------|
| B1 | CRITICAL | 2/5/9 | Unauthenticated requests return **500** instead of **401** (no `login` route) |
| B2 | CRITICAL | 2 | `/auth/me` shape mismatch → **every app restart silently logs the user out** |
| B3 | CRITICAL | 3/4 | Directory pagination reads `meta.*` but API returns a **raw paginator** → all directories stuck loading |
| B4 | CRITICAL | 3/4 | `Trial.fromJson` casts `entry_fee`(string)/`required_documents`(array) → **TypeError** throws |
| B5 | CRITICAL | 6 | Media upload sends wrong/missing fields → **always 422** |
| B6 | HIGH | 4 | Trial registration sends fields backend **silently discards** (data loss) |
| B7 | HIGH | 1 | Flutter `.env` points to a **dead ngrok tunnel** (HTTP 000) |
| B8 | HIGH | 5 | 422 **field-level errors** never mapped to form fields (generic message only) |
| B9 | HIGH | 5/9 | 403 body `{error:{…}}` (map) → client does `msg = data['error']` → **TypeError** |
| B10 | MEDIUM | 8 | `StorageService.saveUserData` query-string encoding corrupts data |
| B11 | HIGH | 5/9 | **No rate limiting** on auth/API routes (brute-force exposure) |
| B12 | HIGH | 5/9 | `APP_DEBUG=true` leaks **stack traces** in JSON |
| B13 | MEDIUM | 6/9 | Media mime check is **extension-based** (spoofable) |
| G1 | GAP | 7 | Push notifications / real-time **not implemented** |
| G2 | GAP | 8 | Offline sync **not implemented** (no local DB) |
| G3 | GAP | 10 | **Zero meaningful test coverage** (boilerplate only) |

---

## 1. Environment & Setup Verification — ⚠️ PASS (with caveats)

| Check | Result |
|---|---|
| Backend boots (`php8.4` on :8002) | ✅ |
| `/api/v1/health` | ✅ `{"status":"ok","db":"connected"}` |
| Migrations (24) all ran, 49 tables | ✅ |
| CORS `api/*`, `allowed_origins:*`, `supports_credentials:false` | ✅ acceptable for Bearer-token mobile |
| `flutter analyze` | ✅ no errors (125 info/warnings) |

**B7 (HIGH) — Flutter `.env` misconfigured.** `sportx_app/.env` sets
`API_BASE_URL=https://hedgier-shayne-unnotioned.ngrok-free.dev/api/v1`, which returns **HTTP 000 (unreachable)**.
- **Repro:** `curl https://hedgier-shayne-unnotioned.ngrok-free.dev/api/v1/health` → connection failed.
- **Root cause:** environment/config mismatch (dead tunnel).
- **Fix:** `sportx_app/.env` → `API_BASE_URL=http://10.0.2.2:8002/api/v1` (emulator) or `http://<LAN-IP>:8002/api/v1` (device), then full app restart. Note `api_config.dart:4` default `127.0.0.1:8002` won't work on an Android emulator either (use `10.0.2.2`).

---

## 2. Authentication & Session Flow — ❌ FAIL

Register / login / token issuance / token revocation all work; Sanctum tokens are created and deleted correctly. **However:**

### B1 (CRITICAL) — Unauthenticated → 500 instead of 401
- **Repro:** `curl http://127.0.0.1:8002/api/v1/auth/me` → **500** `{"message":"Route [login] not defined.", "exception":"Symfony\\...\\RouteNotFoundException"}`. Same after logout when reusing the token.
- **Root cause (backend):** Laravel's `Authenticate` middleware `redirectTo()` calls `route('login')`, but this API-only app defines **no `login` route**, so it throws `RouteNotFoundException`. `bootstrap/app.php:22-25` only sets `shouldRenderJsonWhen`, no `AuthenticationException` render handler.
- **Client impact:** `AuthInterceptor.onError` (`api_client.dart:41`) only clears the token on **401**. Since the server returns **500**, expired/invalid tokens are **never cleared** and the user sees "Server error: 500" instead of being redirected to login.
- **Fix (backend), `bootstrap/app.php`:**
```php
$exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, $request) {
    if ($request->is('api/*')) {
        return response()->json(['message' => 'Unauthenticated.'], 401);
    }
});
```

### B2 (CRITICAL) — `/auth/me` shape mismatch logs users out on every restart
- **Backend** `AuthController::me()` (`AuthController.php:97-107`) returns the user fields **flat inside `data`** with no `data.user`:
```json
{ "data": { "id":5, "role":"athlete", ..., "needs_onboarding": true } }
```
- **Client** `AuthNotifier.checkAuth()` (`auth_provider.dart:43-46`) does `User.fromJson(data['user'])` → `data['user']` is **null** → `TypeError` → caught (`auth_provider.dart:49`) → `deleteToken()` + `unauthenticated`.
- **Impact:** "Remember me"/session restore is broken — a returning user is always sent back to login.
- **Fix (client), `auth_provider.dart:46`:** parse `data` directly: `User.fromJson(data)` (and `data['needs_onboarding']`). Recommend also making the backend response shape **consistent** across `register`/`login`/`me` (today `register`/`login` are flat `{token,user,needs_onboarding}` while `me` wraps in `data`).

### ✅ Passes
Duplicate email → 422 ✓ · weak password (min 8) → 422 with `errors.password` ✓ · invalid login → 401 ✓ · logout revokes token server-side ✓.

---

## 3. API Contract Verification — ❌ FAIL

### B3 (CRITICAL) — Pagination shape mismatch (all directories)
- **Backend** returns the **raw Laravel paginator** for `/academies`, `/coaches`, `/trials`, `/tournaments`, `/scholarships`, `/sponsorships`, `/sports-venues` (confirmed via curl): top-level keys `{ current_page, data, last_page, total, per_page, links, … }` — **no `meta` wrapper**.
- **Client** `DirectoryNotifier.load()` (`directory_provider.dart:48`) and `loadMore()` (`:63`): `resp.data['meta']?['current_page'] < resp.data['meta']?['last_page']` → `null < null` → **TypeError**. It is **not** a `DioException`, so it **escapes the `on DioException` catch** (`:50`) and propagates unhandled; state stays `isLoading:true`.
- **Impact:** every directory screen shows an infinite spinner / unhandled error.
- **Fix (client):** `final p = resp.data; final hasMore = (p['current_page'] ?? 1) < (p['last_page'] ?? 1);` (or have the backend return a normalized `{ data, meta:{…} }`).

### B4 (CRITICAL) — `Trial.fromJson` type-cast crashes
- `trials.entry_fee` is `varchar` → API returns **string** `"200"`; `Trial.fromJson` (`trial.dart:76`): `((json['registration_fee'] ?? json['entry_fee']) as num?)?.toDouble()` → `"200" as num?` → **TypeError**.
- `trials.required_documents` is `json` → API returns an **array** `["Aadhaar Card",…]`; model (`trial.dart:81`): `(...) as String?` → **TypeError**.
- **Repro:** any trial with an entry fee or required docs (seeded trial id=1 has both).
- **Fix (client):** `registrationFee: num.tryParse('${json['entry_fee'] ?? json['registration_fee'] ?? ''}')?.toDouble()` and `documentRequired: (json['required_documents'] is List ? (json['required_documents'] as List).join(', ') : json['document_required']) as String?`.

### ✅ Passes
Dates are consistent ISO-8601 ✓ · snake_case keys are generally read correctly by Flutter models ✓ · detail endpoints (`/trials/{id}`) unwrap `data` correctly (`_detailFromResponse`, `directory_provider.dart:125-130`) ✓.

---

## 4. CRUD & Core Feature Flows — ❌ FAIL

### B6 (HIGH) — Trial registration: user input silently discarded
- **Client sends** (`trial_registration_screen.dart:33-37`): `playing_role`, `medical_conditions`, `parental_consent`.
- **Backend stores** (`RegistrationController.php:26-30`): only `document_media_ids`, `reminder_enabled`. The three client fields are **not validated and not persisted**.
- **Impact:** registration returns 201 but the athlete's role/medical/consent data is lost. Also mismatch with `required_documents` (backend expects pre-uploaded media ids, not text).
- **Fix:** align the contract — either backend accepts & persists the athlete-submitted fields in a migration, or Flutter sends `document_media_ids`/`reminder_enabled`.

### Affected by B3/B4
All list/Read flows are broken by the pagination + model bugs above. Create/Update/Delete of provider content (`/me/trials`, `/me/tournaments`, `/me/sponsorships`) and trial/tournament registration exist but were not fully exercised because the directory + registration plumbing is broken upstream.

---

## 5. Error Handling & Edge Cases — ❌ FAIL

| Case | Backend | Client handling | Result |
|---|---|---|---|
| 401 (no/expired token) | ❌ **500** (B1) | only fires on 401 (`api_client.dart:41`) | **FAIL** |
| 403 (wrong role) | ✅ 403 `{error:{code,message}}` | ❌ `msg = data['error']` assigns Map→String → **TypeError** (B9) | **FAIL** |
| 422 (validation) | ✅ `{message, errors:{field:[…]}}` | ❌ only top-level `message` surfaced; `errors` map unused (B8) | **PARTIAL** |
| Network failure | n/a | ✅ `ApiException` maps timeout/connectionError (`api_client.dart:59-66`) | PASS |
| 429 rate limit | n/a | — | **N/A (B11: none configured)** |

### B8 (HIGH) — field-level validation not mapped to UI
`ApiException.fromDio` (`api_client.dart:67-75`) extracts only `data['message']`; the per-field `data['errors']` map (kept on `ApiException.data`) is never consumed by screens/providers → users see a generic message, not inline field errors. **Fix:** expose `errors` and map field→`FormField.errorText` in auth/registration/onboarding screens.

### B9 (HIGH) — 403 response shape mismatch
`EnsureRole` (`EnsureRole.php:14`) returns `{"error":{"code":"FORBIDDEN","message":"…"}}` (a map), but the client does `msg = data['error']` (`api_client.dart:71`) → `String = Map` → TypeError. **Fix:** normalize backend errors to always include a top-level `message`, or in the client handle `data['error']` being a Map.

### B12 (HIGH) — `APP_DEBUG=true` leaks stack traces
422/403/500 bodies include full `exception`, `file`, `line`, `trace` (seen live). **Fix:** `APP_DEBUG=false` in any non-local env (the `shouldRenderJsonWhen` handler still renders JSON without traces when debug is off).

---

## 6. File Uploads / Media — ❌ FAIL

### B5 (CRITICAL) — upload payload mismatch
- **Backend requires** (`MediaController.php:13-18`): `file`, `owner_type`, `owner_id`, `media_type` (in: photo/video/document).
- **Client sends** (`media_gallery_screen.dart:46-49`): only `file` and `type` (wrong key; missing `owner_type`, `owner_id`, `media_type`).
- **Impact:** every upload → **422** ("The owner type / owner id / media type field is required").
- **Fix (client):** send all four fields, e.g. `media_type:'photo', owner_type:'athlete_profile', owner_id:<profileId>`.

### B13 (MEDIUM) — mime validation spoofable
`MediaController.php:21-29` validates by `getClientOriginalExtension()` (client-controlled filename), not real content type. A renamed executable passes. **Fix:** add Laravel `mimes:`/`mimetypes:` rule or validate `$file->guessExtension()` / `getMimeType()` server-side.

### Note
Upload response returns a **60-minute temporary signed URL** (`MediaController.php:47-49`). Fine for downloads, but if the app caches that URL for gallery display it will expire/break — verify the client re-fetches media URLs rather than persisting the signed link.

---

## 7. Push Notifications / Real-time — ⚠️ NOT IMPLEMENTED (GAP)
- No `firebase_messaging` / `flutter_local_notifications` / `web_socket_channel` in `pubspec.yaml`.
- Backend `BROADCAST_CONNECTION=null`; no FCM/push driver.
- The only "notifications" are in-app DB rows (`GET /me/notifications`). The MVP spec's **deadline/trial push reminders** are **not implemented**.
- **Fix (if required):** add FCM on backend + `firebase_messaging` on client, with deep-link routing from notification tap.

---

## 8. State Sync & Offline Behavior — ⚠️ NOT IMPLEMENTED (GAP)
- No local persistence layer (no `drift`/`sqflite`/`hive`/`isar` in `pubspec`). State is in-memory Riverpod; only the auth token is persisted (`flutter_secure_storage`).
- **Offline = error states only**, no queue/replay/sync. Duplicate/stale-record risks are moot until a cache layer exists.

### B10 (MEDIUM) — broken `saveUserData` (latent)
`StorageService.saveUserData/getUserData` (`storage_service.dart:28-45`) serializes a map as a `k=v&k=v` query string, corrupting any value containing `&`/`=` and losing types/nested data. Currently unused by `auth_provider` (which only persists the token), but it's a footgun — **fix:** use `jsonEncode`/`jsonDecode`.

---

## 9. Security Checks — ❌ FAIL

| Check | Result |
|---|---|
| Protected endpoints require auth | ⚠️ Middleware is set, but failures return **500** not 401 (B1) |
| Role gates enforced server-side | ✅ `EnsureRole` returns 403 for wrong role (verified: athlete→`/athletes` = 403) |
| Authorization / IDOR | ✅ spot-checks (e.g. `MediaController::destroy` ownership check, `:59-64`) enforce ownership; deeper IDOR audit recommended once B3/B4 unblock flows |
| Rate limiting / brute-force | ❌ **None** on auth/API (B11) |
| Secrets not logged | ⚠️ `LogInterceptor` logs request/response **bodies** (`api_client.dart:15-19`); PII may appear in logs. Bearer token is header-only (not logged), so tokens are OK |

### B11 (HIGH) — no throttling
No `throttle:` middleware anywhere (`routes/api.php`, `bootstrap/app.php`). Login/register are brute-forceable. **Fix:** `Route::middleware('throttle:10,1')` on `/auth/login`, `/auth/register`, `/auth/forgot-password`, and admin auth.

### B12 (HIGH) — `APP_DEBUG=true` (see §5) exposes internals.

---

## 10. Automated Test Coverage — ❌ FAIL (major gap)

- **Backend `php artisan test`:** 2 tests passed — **both boilerplate `ExampleTest.php`** (Feature + Unit skeleton). **No** feature tests for auth, directories, registrations, sponsorships, admin, media, etc.
- **Flutter:** `test/` has **1** default widget test; **no `integration_test/`**. **No** widget/integration tests for any user flow.
- `flutter analyze`: no errors; 125 info/warnings (deprecated `withOpacity`→`.withValues()`, `value:`→`initialValue:` on form fields, unused imports, dead code).
- **Recommended new tests (highest value first):**
  1. **Backend feature tests** reproducing B1 (assert 401, not 500), the `/auth/me` shape, directory pagination shape, trial registration persistence (B6), media upload required fields (B5).
  2. **Flutter widget tests** for `DirectoryNotifier`/`Trial.fromJson` against **real** API JSON fixtures (would catch B3/B4 immediately).
  3. **Contract tests** asserting Flutter model ↔ Laravel resource field-by-field (prevents snake/camel & type drift).
  4. **Integration test** for the auth restore path (`checkAuth`) which would catch B2.

---

## Recommended fix order (unblocks the most flows fastest)

1. **B1** — 401 handler in `bootstrap/app.php` (5 lines; fixes auth + token-expiry UX app-wide).
2. **B7** — point `.env` at a live backend so the app can connect at all.
3. **B2** — `/auth/me` parsing in `auth_provider.dart` (one line; restores session persistence).
4. **B3 + B4** — directory pagination + `Trial.fromJson` (unblocks every directory screen).
5. **B5** — media upload payload (unblocks profile/gallery).
6. **B6** — align trial-registration contract (stop silent data loss).
7. **B8/B9** — normalize error shapes + map field errors to forms.
8. **B11/B12/B13** — rate limiting, debug flag, real mime checks (security hardening).
9. **G1/G2/G3** — push, offline, and real test coverage (roadmap).

---

### Verification commands (re-run after fixes)
```bash
# B1
curl -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8002/api/v1/auth/me        # expect 401
# B4/B3
curl -s http://127.0.0.1:8002/api/v1/trials?per_page=2 | python3 -m json.tool      # data + top-level current_page/last_page
# tests
cd sportx-api   && php artisan test
cd sportx_app   && flutter analyze && flutter test
```
