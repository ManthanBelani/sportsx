# Guardian Email-OTP Consent + OTP Login with Dev Test Mode

Implementation plan for two related features:

1. **Guardian consent via email OTP** — every athlete under 18 must register a
   parent/guardian email; the system sends a one-time code to that email; chat
   and social features unlock only after the guardian's code is verified.
   (Required for Google Play **Families policy** compliance — "adult action
   required" before minors can exchange information.)
2. **OTP login for all users** with an **env-controlled test mode**: in
   development the OTP is always `123456` and no email is sent; in production a
   real OTP is emailed.

> Status: **complete (2026-10-31).** Both backend and Flutter frontend fully
> implemented, verified with PHPUnit test suite against MySQL and `flutter analyze`.
> See [Implementation status](#implementation-status) below for all details.
> All file paths below are relative to the repository root (`sportx-api/` for
> backend, `sportx_app/` for Flutter).

---

## Part 0 — Current state (what already exists)

| Piece | Status | Location |
|---|---|---|
| OTP issue/verify service (hashed codes, expiry, attempt limit, resend cooldown) | ✅ Working | `sportx-api/app/Services/OtpService.php` |
| Email delivery via SMTP/queued mailable | ✅ Working (`MAIL_MAILER=log` in dev) | `sportx-api/app/Mail/EmailOtpMail.php` |
| Generic OTP endpoints (send / resend / verify) | ✅ Working | `sportx-api/app/Http/Controllers/OtpController.php`, routes `auth/send-otp`, `auth/resend-otp`, `auth/verify-otp` |
| Guardian consent model + service + controller + routes | ✅ Exists | `sportx-api/app/Models/GuardianConsent.php`, `app/Services/GuardianConsentService.php`, `app/Http/Controllers/GuardianController.php` |
| Guardian consent Flutter screen + guardian controls screen | ✅ Exists | `sportx_app/lib/features/auth/presentation/screens/guardian_consent_screen.dart`, `lib/features/athlete/presentation/screens/guardian_controls_screen.dart` |
| Minor chat gate (chat blocked until consent `verified`) | ✅ Exists | `ConversationController::minorChatGate()` |
| **Broken bit** | ❌ Consent code is sent to **phone/SMS**, but no SMS vendor is configured (AS-60) → `OtpDeliveryException` → 503 | `GuardianConsentService::request()` line ~65 |
| OTP login (passwordless) | ❌ Not yet built (login is password-based) | `AuthController::login()` |
| Dev test mode (fixed OTP) | ❌ Not yet built | — |

The single most important fix: **switch the guardian consent code from the
phone channel to the email channel.** Email already works; SMS does not.

---

## Implementation status

### ✅ Completed changes (2026-10-31)

#### Backend — `sportx-api/`

| # | File | Change |
|---|---|---|
| 1 | `database/migrations/2026_10_31_000001_add_guardian_email_to_guardian_consents_table.php` | **New & Ran.** Adds `guardian_email` (nullable) and `verification_method` (default `otp`) to `guardian_consents`. Made `guardian_phone` nullable (`->nullable()->change()`) to prevent SQL integrity errors when phone is omitted. |
| 2 | `app/Models/GuardianConsent.php` | Added `METHOD_OTP` / `METHOD_LINK` constants; `guardian_email` + `verification_method` added to `$fillable`. |
| 3 | `app/Services/GuardianConsentService.php` | `request()` now stores `guardian_email`/`verification_method` and sends the OTP over the **email** channel (was `phone`, which always failed 503 — no SMS vendor, AS-60). `verify()` now verifies against the email channel + `guardian_email`. |
| 4 | `app/Http/Controllers/GuardianController.php` | `request()`: `guardian_email` required, `guardian_phone` now optional; **rejects the athlete's own email** as guardian (422 `GUARDIAN_EMAIL_INVALID`); response includes `guardian_email`. **New `resend()`** — re-sends the confirmation email for a pending consent (429 `RESEND_COOLDOWN` inside the 60s cooldown, 422 `NO_PENDING_CONSENT` otherwise). `show()` exposes `guardian_email`. |
| 5 | `app/Services/OtpService.php` | **Dev test mode:** new `testMode()` helper (`OTP_TEST_MODE` env **and** `!app()->isProduction()`); `randomCode()` returns the fixed test code in test mode; `sendEmail()` skips mail entirely (logs instead). `verify()` untouched — the stored hash is simply the hash of the fixed code, so every purpose works with zero further changes. |
| 6 | `config/sportx.php` | `otp.test_mode` + `otp.test_code` keys (env-driven, default off). |
| 7 | `.env` / `.env.example` | Appended `OTP_TEST_MODE=true` + `OTP_TEST_CODE=123456` for local dev (commented-out in the example). |
| 8 | `app/Http/Controllers/AuthController.php` | **New `otpLoginRequest()`** (`POST /auth/otp-login/request`) and **`otpLoginVerify()`** (`POST /auth/otp-login/verify`) — passwordless login with the same response shape, token creation and account-status checks as `login()`; uniform responses so accounts cannot be enumerated. |
| 9 | `app/Http/Controllers/PrivacyController.php` | Made `settings()` and `defaultsFor()` `public static` so `ConversationController::peerChatGate` can call `PrivacyController::settings($b)` without non-static method invocation errors. |
| 10 | `routes/api.php` | Added `/auth/otp-login/request` (throttle 5,1), `/auth/otp-login/verify` (throttle 10,1) and `/guardian/resend` (throttle 5,1). |
| 11 | `phpunit.xml` | Pins `OTP_TEST_MODE=false` so a developer's `.env` can never leak the fixed code into the test suite. |

#### Tests — updated to the email & OTP login flow

| # | File | Change |
|---|---|---|
| 12 | `tests/Feature/GuardianConsentTest.php` | All 19 tests passing. Tested email dispatch, pending consent, own-email rejection, cooldown rate limiting, and email code verification. |
| 13 | `tests/Feature/AuthTest.php` | Added comprehensive feature tests for `/auth/otp-login/request`, queued email mailable verification, `/auth/otp-login/verify`, wrong-code rejection (422), and nonexistent email safety. (All 10 tests passed). |
| 14 | `tests/Feature/Phase1To10CoverageTest.php` & `Phase6SocialChatSafetyTest.php` | Updated to email flow; verified all chat safety, connection gates, and privacy settings tests (17 passed). |

#### Flutter — `sportx_app/`

| # | File | Change |
|---|---|---|
| 15 | `lib/features/auth/presentation/providers/auth_provider.dart` | Added `otpLoginRequest(email)` and `otpLoginVerify(email, code)` which persist authentication token, user object, and FCM registration identically to password login. |
| 16 | `lib/features/auth/presentation/screens/otp_screen.dart` | Added `isLogin` mode (title "Log In with Code", dynamic helper text and CTA button) supporting passwordless login verification and code resending. |
| 17 | `lib/features/auth/presentation/screens/login_screen.dart` | Added "OR" separator and "Continue with email code" secondary button with email validation and navigation to `/verify-otp`. |
| 18 | `lib/core/router.dart` | Unblocked `/guardian-consent` for authenticated users (removed from blocking `onboardingScreens`); wired `isLogin` extra flag into `/verify-otp`. |
| 19 | `lib/features/chat/presentation/providers/chat_provider.dart` | Surfaced `GUARDIAN_REQUIRED` in `startConversationResult`; implemented `handleChatStartError(context, err)` which presents the parental consent explanatory dialog and one-tap routing to `/guardian-consent`. |
| 20 | `lib/features/connections/presentation/screens/*` & `lib/features/shared/presentation/screens/*` | Updated all chat start points (`athlete_directory_screen`, `my_connections_screen`, `network_screen`, `scout_directory_screen`, `scout_requests_view`, `view_profile_screen`, `talent_scout_connections_screen`, `talent_scout_athlete_profile_view_screen`) to call `handleChatStartError`. |
| 21 | `lib/features/onboarding/presentation/screens/multi_step_onboarding_screen.dart` | Enforced minor athlete flow: detects age < 18 from DOB, displays informational banner in Step 1, and routes under-18 athletes directly to `/guardian-consent` upon submitting onboarding. |
| 22 | `lib/features/auth/presentation/screens/guardian_consent_screen.dart` | Guardian email field required, phone optional, email OTP verification, resend email with cooldown, and proper post-verification routing to `/home`. |

#### Verification performed

- `artisan migrate --force`: Migration `2026_10_31_000001_add_guardian_email_to_guardian_consents_table` **Ran & Done** on MySQL.
- `phpunit GuardianConsentTest.php`: **19 passed** (56 assertions).
- `phpunit AuthTest.php`: **10 passed** (42 assertions).
- `phpunit Phase1To10CoverageTest.php Phase6SocialChatSafetyTest.php`: **17 passed** (224 assertions).
- `phpunit OtpTest.php`: **passed**.
- `flutter analyze` on all changed files: **0 errors, 0 warnings**.

### ⏳ Next operational steps (deployment & compliance)

1. **Production cutover** — on the server `.env`: leave `OTP_TEST_MODE` unset/false, configure real SMTP (`MAIL_MAILER=smtp` + credentials), run `php artisan config:clear`, then do one live consent + one live OTP login end-to-end.
2. **Play Console** — Families self-declaration + Data safety form (declare guardian email collection, message content, deletion), and reply to the policy issue describing: chat restricted to accepted connections + verified guardian consent (email OTP), safety reminder before chat/media/post, guardian controls screen.
3. *(Optional, later)* **Signed-link consent flow** — the `verification_method = 'link'` value and column are already reserved for it.

---

## Part A — Guardian consent via email OTP

### A1. Flow

```
Minor (athlete, DOB < 18) registers / onboards
        │  (guardian email is a MANDATORY field for minors)
        ▼
POST /guardian/consent  { guardian_name, guardian_email, relationship, guardian_phone }
        │
        ▼
GuardianConsentService::request()
  - supersedes any previous pending consent
  - creates consent row (status = pending)
  - OtpService::generateAndSend(null, 'email', guardian_email, PURPOSE_GUARDIAN_CONSENT)
        │
        ▼
Guardian receives 6-digit code by email
        │
        ▼
Guardian enters the code on the minor's device
   (screen copy: "Hand the phone to your parent/guardian")
        │
        ▼
POST /guardian/verify-otp  { code }
        │
        ▼
Consent row → verified, verified_at set; athlete.status → active
        │
        ▼
minorChatGate() now allows chat (governed by allow_messages toggle)
```

### A2. Backend changes

#### A2.1 Migration — add guardian email

```bash
php artisan make:migration add_guardian_email_to_guardian_consents_table
```

```php
Schema::table('guardian_consents', function (Blueprint $table) {
    $table->string('guardian_email')->nullable()->after('guardian_phone');
    // 'otp' | 'link' — leaves room for the future signed-link flow
    $table->string('verification_method')->default('otp')->after('guardian_email');
});
```

Keep `guardian_phone` as optional metadata (useful later if an SMS vendor is
added), but it is **no longer required** for consent.

#### A2.2 `GuardianConsentService::request()` — send by email

```php
public function request(User $athlete, array $data, OtpService $otp): GuardianConsent
{
    $athlete->guardianConsents()
        ->where('consent_status', GuardianConsent::STATUS_PENDING)
        ->update(['consent_status' => GuardianConsent::STATUS_REVOKED, 'revoked_at' => now()]);

    $consent = $athlete->guardianConsents()->create([
        'guardian_name'       => $data['guardian_name'],
        'guardian_email'      => $data['guardian_email'],
        'guardian_phone'      => $data['guardian_phone'] ?? null,
        'relationship'        => $data['relationship'] ?? 'parent',
        'consent_status'      => GuardianConsent::STATUS_PENDING,
        'verification_method' => 'otp',
    ]);

    // Email channel — SMS has no vendor configured (AS-60). Throws
    // OtpDeliveryException if mail transport is down; the controller
    // surfaces that as 503 so no consent is created that can't be verified.
    $otp->generateAndSend(
        null,
        'email',
        $data['guardian_email'],
        OtpCode::PURPOSE_GUARDIAN_CONSENT,
    );

    return $consent;
}
```

#### A2.3 `GuardianConsentService::verify()` — verify against email

```php
$verified = $otp->verify(
    null,
    'email',
    $consent->guardian_email,   // was: $consent->guardian_phone
    $code,
    OtpCode::PURPOSE_GUARDIAN_CONSENT,
);
```

Everything else in `verify()` (activate the athlete, restricted defaults) stays
unchanged.

#### A2.4 `GuardianController::request()` — validation

```php
$validated = $request->validate([
    'guardian_name'  => 'required|string|max:120',
    'guardian_email' => 'required|email|max:255',
    'guardian_phone' => 'nullable|string|max:20',
    'relationship'   => ['required', Rule::in(GuardianConsent::RELATIONSHIPS)],
]);
```

Also: **reject if `guardian_email` equals the athlete's own account email.**
The minor must not be able to "consent" to themselves:

```php
abort_if(
    strcasecmp($validated['guardian_email'], $request->user()->email) === 0,
    422,
    'The guardian email must belong to a parent or guardian, not the athlete.'
);
```

Routes (`routes/api.php` lines 142–146) and `GuardianController::verify()`,
`show()`, `update()`, `revoke()` need **no changes** — they are
destination-agnostic.

### A3. Flutter changes

1. **`guardian_consent_screen.dart`**
   - Add a mandatory **Parent/Guardian email** field (replace the phone field
     or keep phone as optional).
   - After submit, show: *"We've emailed a 6-digit code to your parent or
     guardian. Hand the phone to them so they can enter it."*
   - Code entry stays as-is (`POST /guardian/verify-otp`).
   - Keep polling `GET /me/guardian-controls` so the screen flips to
     **Approved** automatically once verified.
   - Add a **Resend email** button → `POST /guardian/resend` (new, see A2.5)
     with the server-side 60s cooldown already provided by `OtpService::resend()`.

2. **`POST /guardian/resend`** (new controller method + route, auth-required):

   ```php
   public function resend(Request $request): JsonResponse
   {
       $consent = $this->guardians->activeFor(...); // or latest pending row
       abort_if(!$consent || $consent->consent_status !== GuardianConsent::STATUS_PENDING, 422);

       $this->otp->resend(null, 'email', $consent->guardian_email, OtpCode::PURPOSE_GUARDIAN_CONSENT);
       return response()->json(['data' => ['message' => 'Confirmation email re-sent.']]);
   }
   ```

3. **Onboarding** — make guardian email mandatory for athletes whose entered
   DOB puts them under 18 (the DOB field itself is already mandatory).

### A4. Compliance notes (for the Play review reply)

- Consent is **verifiable**: control of the guardian's email inbox is proven by
  the OTP; the code is entered by the guardian on the minor's device.
- Chat is **hard-gated server-side**: `minorChatGate()` blocks every
  conversation start for an unverified minor, independent of the app UI.
- Keep the audit trail: `consent_status`, `verified_at`, `verification_method`.
  (Optional: add `verified_ip` / `verified_user_agent` columns.)
- Document the flow with screenshots in the Play Console policy reply:
  consent screen → email → verified state → chat enabled.

---

## Part B — OTP login for all users + dev test mode

### B1. Test mode: fixed `123456` OTP in development

The cleanest place is `OtpService::randomCode()` + `OtpService::sendEmail()`.
Because `verify()` checks `Hash::check($code, $otp->code_hash)`, simply
**issuing** `123456` in test mode makes verification work with zero changes to
`verify()`, `OtpController`, or the guardian flow — one switch governs every
OTP purpose (login, signup, reset, guardian consent).

#### Config — `config/sportx.php`

Inside the existing `'otp'` block (currently at line ~108):

```php
'otp' => [
    // ... existing keys (expiry_minutes, resend_cooldown_seconds, code_length)

    // DEV ONLY. When true, every OTP is the fixed test code and no email is
    // sent. Guarded so it can never be enabled on production.
    'test_mode' => env('OTP_TEST_MODE', false) && !app()->isProduction(),
    'test_code' => env('OTP_TEST_CODE', '123456'),
],
```

#### `.env` (development machine only)

```env
OTP_TEST_MODE=true
OTP_TEST_CODE=123456
```

#### `.env` (production server)

```env
OTP_TEST_MODE=false
```

(Don't set the key at all — the default is false. `app()->isProduction()` is
the belt-and-braces guard: even a misconfigured prod `.env` cannot enable it.
Remember `php artisan config:clear` after changing env.)

#### `OtpService.php` changes

```php
protected function randomCode(): string
{
    if (config('sportx.otp.test_mode')) {
        return (string) config('sportx.otp.test_code', '123456');
    }

    $length = (int) config('sportx.otp.code_length', 6);
    $code = '';
    for ($i = 0; $i < $length; $i++) {
        $code .= (string) random_int(0, 9);
    }
    return $code;
}

protected function sendEmail(string $destination, string $code, string $purpose): void
{
    if (config('sportx.otp.test_mode')) {
        Log::info('OTP test mode — code not emailed', [
            'destination' => $destination, 'purpose' => $purpose,
        ]);
        return;
    }

    // ... existing throttle + Mail::to(...)->queue(...)
}
```

In test mode the app screens will show "code sent" and the developer simply
types `123456`. No email is sent, so `MAIL_MAILER=log` noise disappears too.

> **Note:** `randomCode()` normally produces `code_length` digits. With the
> fixed code, the code field length in the UI must accept 6 digits — it already
> does.

### B2. OTP (passwordless) login for all users

New endpoints, reusing the existing OTP machinery. Add to `AuthController`
(or a small `OtpLoginController`):

#### Routes — `routes/api.php`

```php
Route::post('/auth/otp-login/request', [AuthController::class, 'otpLoginRequest'])
    ->middleware('throttle:5,1');
Route::post('/auth/otp-login/verify', [AuthController::class, 'otpLoginVerify'])
    ->middleware('throttle:10,1');
```

#### Controller

```php
/** POST /auth/otp-login/request  { email } */
public function otpLoginRequest(Request $request)
{
    $data = $request->validate(['email' => 'required|email|max:255']);

    $user = User::where('email', strtolower($data['email']))->first();

    // Uniform response whether or not the account exists (no account
    // enumeration), same principle as OtpController.
    try {
        $this->otp->generateAndSend(
            $user, 'email', $data['email'], OtpCode::PURPOSE_LOGIN
        );
    } catch (OtpDeliveryException $e) {
        return response()->json(['error' => ['code' => 'CHANNEL_UNAVAILABLE', 'message' => $e->getMessage()]], 503);
    }

    return response()->json(['data' => ['message' => 'If the address is registered, a code has been sent.']]);
}

/** POST /auth/otp-login/verify  { email, code } */
public function otpLoginVerify(Request $request)
{
    $data = $request->validate([
        'email' => 'required|email|max:255',
        'code'  => 'required|string|max:10',
    ]);

    $user = User::where('email', strtolower($data['email']))->first();

    if (!$user || !$this->otp->verify($user, 'email', $data['email'], $data['code'], OtpCode::PURPOSE_LOGIN)) {
        return response()->json(['error' => ['code' => 'INVALID_CODE', 'message' => 'That code is incorrect or has expired.']], 422);
    }

    // Same token shape as AuthController::login() so the Flutter client
    // needs no special handling.
    $token = $user->createToken('otp-login')->plainTextToken;

    return response()->json([
        'data' => [
            'token' => $token,
            'user'  => $user->only(['id', 'name', 'email', 'role', 'status']),
        ],
    ]);
}
```

(Inject `OtpService $otp` and `OtpCode` in the controller exactly as
`GuardianController` does.)

#### Flutter client

- Add "Continue with email code" on the login screen →
  `POST /auth/otp-login/request` → code entry screen →
  `POST /auth/otp-login/verify` → store the token the same way password login
  does (`auth_provider.dart`).
- Reuse the existing OTP entry widget used for email verification, if present.

#### Security notes

- Rate limits: `throttle:5,1` on request, `throttle:10,1` on verify — plus the
  per-destination cooldown and 5-attempt limit already inside `OtpService`.
- OTP login bypasses passwords; ensure the response payload is identical in
  shape to password login so downstream role routing works unchanged.
- `PURPOSE_LOGIN` is already in the allowed purpose list in `OtpCode`.

---

## Testing checklist

Development (`OTP_TEST_MODE=true`):

- [ ] Register an athlete with DOB < 18 → guardian email required.
- [ ] `POST /guardian/consent` with a **different** email → 201; no email sent; OTP `123456` works.
- [ ] `POST /guardian/consent` with the athlete's own email → 422.
- [ ] Before verification: `POST /me/conversations` with any peer → 403 `GUARDIAN_REQUIRED`.
- [ ] `POST /guardian/verify-otp { code: "123456" }` → consent verified, athlete active.
- [ ] After verification: conversation start succeeds (subject to connection gates).
- [ ] Wrong code 5× → code exhausted; resend after cooldown → new code.
- [ ] `OTP_TEST_MODE=false` locally → real email delivered to Mailtrap/SMTP; `123456` rejected.
- [ ] OTP login: request + verify with `123456` in dev; token works on `/me`.
- [ ] Grep the logs: no plaintext OTP codes logged in either mode.

Production cutover:

- [ ] `OTP_TEST_MODE=false` (or unset) on the server.
- [ ] Real SMTP credentials configured (`MAIL_MAILER=smtp`, provider creds).
- [ ] `php artisan config:clear` after env changes.
- [ ] Run one live consent + one live login end-to-end.

---

## Rollout order

1. Migration + `GuardianConsentService` email switch + `GuardianController` validation (Part A) — **this unblocks the currently-broken consent flow**.
2. Test mode in `OtpService` + config + `.env` (Part B1) — makes 1 testable instantly.
3. OTP login endpoints + Flutter login option (Part B2).
4. Flutter consent screen email field + resend + polling copy (Part A3).
5. Onboarding: mandatory guardian email for minors.
6. Play Console: update Families self-declaration + Data safety form, then reply to the policy issue describing the consent gate (see `PRIVACY_POLICY.md` §5.1 — it already documents this flow).
