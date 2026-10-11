> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

# SportX India — Production Backend Plan

**Date:** 2026-08-09
**Current Status:** old spec ~130/141 endpoints implemented — **superseded by the v3 delta** (≈70 new P0 + ≈25 changed + ≈10 verify-first; `Backend-Feature-Delta.md` §11)
**Target:** Production Ready — ship the v3 P0 delta first, then P1 (`Backend-Feature-Delta.md` §9)

> **⚠️ v3 READ FIRST:** the biggest old decisions are now reversed. See §0 below.

---

## 0. v3 Delta Overlay (supersedes parts of this plan)

| Old decision in this doc | v3 status | Where |
|---|---|---|
| "Auth System Redesign (Email/Password)" and **`Schema::dropIfExists('otp_codes')`** (§2) | **[SUPERSEDED — see Backend-Feature-Delta.md]** OTP is **P0 again** (phone **or** email). `otp_codes` is **re-created**; password login is **kept**. | delta D1/D5, BE-M1.1 |
| ~141-endpoint old catalog | **~230 endpoints** under the new design; `sponsor` role routes (~12) removed; unified `opportunities`. | delta §11 |
| Admin console "built later" | Verification queue (AD.4) + user management (AD.3) are **P0**. | delta D6, BE-M1.5/BE-M11.3 |
| Social feed / chat "excluded" | Feed + posts + likes/comments + follow/connect + 1:1 chat are **P0**. | delta D7, BE-M7.x |
| Ratings/reviews/leaderboard "non-goals" | Leaderboard points engine **P0**; reviews P1. | delta D8, BE-M8.1 |

### 0.1 New P0 build blocks (must ship)

| Block | Delta IDs | Summary |
|---|---|---|
| Roles & auth | BE-M1.1, BE-M1.2 | `UserRole`: remove `sponsor`, add `scout`; OTP stack (`/auth/send-otp`, `/auth/verify-otp`, `/auth/resend-otp`); keep password login. |
| Guardian consent (minors) | BE-M1.4 | `guardian_consents` + enforcement (chat/discovery/leaderboard). Closes AS-34. |
| Verification queue | BE-M1.5, BE-M11.3 | `verification_requests` + admin approve/reject; admin user management. |
| Profiles (30 fields) | BE-M1.3, BE-M2.1/2.2 | Per-role 30 fields; scout onboarding; per-sport role/level; typed achievements. |
| Opportunities | BE-M5.1 | Unified `opportunities` (scholarship/sponsorship/tryout/camp) + applications; migrate scholarships/sponsorships. |
| Programs & facilities | BE-M6.1/6.3 | `programs` + `facilities` tables/CRUD + program enquiry thread. |
| Social core | BE-M7.1–7.5 | posts/feed/likes/comments, follows, connections, 1:1 chat, blocks. **Verify partial builds first.** |
| Leaderboard | BE-M8.1 | `leaderboard_scores` + points engine + `/leaderboard` + `/leaderboard/strip`. |
| Discovery/search | BE-M3.1/3.2, M2 | `/me/home`, `/explore`, athlete group in search, enriched cards, distance sort. |
| Safety & notifications | BE-M11.1/11.2/11.4, notifications enum | report user/post, block, suspend; extended notification types. |

> Build order: `Backend-Feature-Delta.md` §9. P1 wave: delta §2.

---

## 1. Current Backend Status

### 1.1 Endpoint Coverage

> **[SUPERSEDED — see Backend-Feature-Delta.md]** The table below is the **old-spec** coverage snapshot. Under the v3 design the catalog grows to ~230 endpoints; the "Sponsor Engagement" module (10 endpoints) is **REMOVED** and its function migrates to Opportunities.

| Module | Total | Implemented | Missing |
|--------|-------|-------------|---------|
| Auth (User) | 8 | 8 | 0 |
| Meta/Master Data | 4 | 4 | 0 |
| Onboarding | 6 | 6 | 0 |
| Directory (Public) | 12 | 12 | 0 |
| Search | 2 | 2 | 0 |
| Media | 3 | 3 | 0 |
| Saved Items | 3 | 3 | 0 |
| Reports | 1 | 1 | 0 |
| Profile | 3 | 3 | 0 |
| Provider Self-Service | 4 | 4 | 0 |
| Enquiries | 5 | 5 | 0 |
| Athlete Discovery | 2 | 2 | 0 |
| Trial Registrations | 6 | 6 | 0 |
| Tournament Registrations | 6 | 6 | 0 |
| Results | 4 | 4 | 0 |
| Provider Trials | 5 | 5 | 0 |
| Provider Tournaments | 6 | 6 | 0 |
| Sponsor Engagement | 10 | 10 | 0 |
| Notifications | 4 | 4 | 0 |
| Settings | 4 | 4 | 0 |
| Activity | 1 | 1 | 0 |
| Admin Auth | 4 | 4 | 0 |
| Admin Dashboard | 1 | 1 | 0 |
| Admin Content CRUD | 6 | 6 | 0 |
| Admin Moderation | 5 | 5 | 0 |
| Admin Expiry | 5 | 5 | 0 |
| Admin Categories | 12 | 12 | 0 |
| **Total** | **141** | **~130** | **~11** |

### 1.2 Missing Endpoints (old spec) + v3 P0 additions

| Module | Missing Endpoint | Priority |
|--------|------------------|----------|
| Auth | Email verification (`/auth/verify-email`) | ~~HIGH~~ SUPERSEDED by OTP |
| Auth | Password reset email link | HIGH (P1 OTP variant) |
| Auth (v3) | `/auth/send-otp`, `/auth/verify-otp`, `/auth/resend-otp` (phone + email) | **P0** |
| Auth (v3) | `/guardian/consent`, `/guardian/verify-otp`, `/me/guardian-controls` | **P0** |
| Auth (v3) | `/me/completion-checklist`, `/me/change-password` | P0 |
| Onboarding (v3) | `/onboarding/scout` | **P0** |
| Profiles (v3) | `/me/achievements`, `/me/media`, `/me/verification`, `/me/privacy` | **P0** |
| Discovery (v3) | `/me/home`, `/explore`, `/leaderboard`, `/leaderboard/strip`, `/me/recent-searches` | **P0** |
| Opportunities (v3) | `/opportunities*`, `/me/opportunities*` (unified) | **P0** |
| Programs/Facilities (v3) | `/me/programs`, `/me/facilities`, `/programs/{id}`, `/facilities/{id}` | **P0** |
| Social (v3) | `/feed`, `/posts*`, `/follow*`, `/connections*`, `/conversations*`, `/blocks*` | **P0** (verify partial first) |
| Scouting (v3) | `/me/shortlist` (status/tags), `/observations`, `/athletes/{id}/contact` | **P0** |
| Admin (v3) | `/admin/users`, `/admin/verification`, registrant export CSV | **P0** |
| Admin | 2FA session enforcement middleware | HIGH |
| Media | Signed URL generation | MEDIUM |
| System | Health check endpoint | MEDIUM |
| System | Exception tracking (Sentry) | MEDIUM |
| Calendar | .ics export for registrations | LOW |
| OAuth | Google Socialite integration | LOW (P1 / confirm D9) |

---

## 2. Auth System Redesign (Email/Password) — [SUPERSEDED — see Backend-Feature-Delta.md]

> **⚠️ SUPERSEDED (v3, D1/D5):** this section describes the **old** "email-only, no OTP" redesign and includes `Schema::dropIfExists('otp_codes')`. Under the new design **OTP is restored to P0** (phone **or** email) and `otp_codes` is **re-created**. Keep the **email/password** parts of this section (password login, reset-link, mailables) — **do NOT drop `otp_codes`** and **do NOT drop password auth**. The OTP stack is specified in §2.6 below and in `Backend-Feature-Delta.md` BE-M1.1.

### 2.6 OTP Stack (v3 P0 — replaces the "no OTP" decision)

| Item | Spec |
|---|---|
| Table | `otp_codes` (re-created): `purpose`, `channel`, `destination`, `code_hash`, `expires_at`, `attempts` (max 5), `resend_available_at` (60s), `consumed_at` (`Database-Design.md` §1). |
| Endpoints | `POST /auth/send-otp`, `POST /auth/verify-otp`, `POST /auth/resend-otp`. |
| Channels | `email` **and** `phone` (SMS). **Vendor selection (AS-03) becomes blocking** (delta §8 D1). |
| Purposes | `signup`, `login`, `reset_password`, `guardian_consent`, `verify_contact`. |
| Verification | Hashed 6-digit code; sets `email_verified_at`/`phone_verified_at`; returns Sanctum token + `needs_onboarding`. |
| Rate limit | `RateLimitOtp`: 60s resend cooldown, max 5 attempts, per-destination + per-IP. |
| Guardian | `guardian_consents` + `POST /guardian/consent` / `/guardian/verify-otp`; minor profiles stay `pending` until verified (BE-M1.4). |
| Kept | Email/password login **stays**; reset via OTP (P1) alongside the token-link flow (BE-P1.12). |

### 2.1 Current Flow vs Target Flow

**Current (Phone/OTP):**
```
register(phone) → verify-otp → token
login(phone+password OR email+OTP) → token
```

**Target (Email/Password):**
```
register(name, email, phone, password) → verify-email → token
login(email, password) → token
forgot-password(email) → reset-email → reset-password(token) → token
```

### 2.2 Database Migration

```php
// database/migrations/2026_08_09_000001_update_users_for_email_auth.php

Schema::table('users', function (Blueprint $table) {
    // Add email verification fields
    $table->timestamp('email_verified_at')->nullable()->after('password');
    $table->string('verification_token', 64)->nullable()->after('email_verified_at');
    
    // Make phone optional for login (but required for profile)
    // Note: Don't drop phone column - needed for profile
    
    // Add password reset fields
    $table->string('reset_password_token', 64)->nullable();
    $table->timestamp('reset_password_sent_at')->nullable();
});

// [SUPERSEDED — see Backend-Feature-Delta.md] DO NOT drop otp_codes.
// v3 restores OTP to P0: re-create otp_codes (see §2.6 / Database-Design.md §1).
// Schema::dropIfExists('otp_codes');
```

### 2.3 New AuthController Methods

```php
// app/Http/Controllers/Auth/AuthController.php

class AuthController extends Controller
{
    // REGISTER - Create account with email verification
    public function register(RegisterRequest $request)
    {
        $user = User::create([
            'name' => $request->name,
            'email' => strtolower($request->email),
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'role' => 'athlete',
        ]);
        
        // Send verification email
        $token = Str::random(64);
        $user->verification_token = $token;
        $user->save();
        
        Mail::to($user->email)->send(new VerifyEmail($user, $token));
        
        return response()->json([
            'message' => 'Registration successful. Please check your email to verify your account.',
            'user' => new UserResource($user),
        ], 201);
    }
    
    // VERIFY EMAIL - Verify with token
    public function verifyEmail(VerifyEmailRequest $request)
    {
        $user = User::where('verification_token', $request->token)->first();
        
        if (!$user) {
            return response()->json(['message' => 'Invalid verification token'], 400);
        }
        
        $user->email_verified_at = now();
        $user->verification_token = null;
        $user->save();
        
        $token = $user->createToken('auth_token')->plainTextToken;
        
        return response()->json([
            'message' => 'Email verified successfully',
            'token' => $token,
            'user' => new UserResource($user),
        ]);
    }
    
    // LOGIN - Email/Password only
    public function login(LoginRequest $request)
    {
        $user = User::where('email', strtolower($request->email))->first();
        
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }
        
        // Check email verified (optional - uncomment if required)
        // if (!$user->email_verified_at) {
        //     return response()->json(['message' => 'Please verify your email first'], 403);
        // }
        
        $token = $user->createToken('auth_token')->plainTextToken;
        
        return response()->json([
            'token' => $token,
            'user' => new UserResource($user),
        ]);
    }
    
    // FORGOT PASSWORD - Send reset email
    public function forgotPassword(ForgotPasswordRequest $request)
    {
        $user = User::where('email', strtolower($request->email))->first();
        
        if (!$user) {
            // Don't reveal if email exists
            return response()->json(['message' => 'If an account exists, a reset link has been sent']);
        }
        
        $token = Str::random(64);
        $user->reset_password_token = $token;
        $user->reset_password_sent_at = now();
        $user->save();
        
        Mail::to($user->email)->send(new PasswordResetMail($user, $token));
        
        return response()->json(['message' => 'If an account exists, a reset link has been sent']);
    }
    
    // RESET PASSWORD - Reset with token
    public function resetPassword(ResetPasswordRequest $request)
    {
        $user = User::where('email', strtolower($request->email))
            ->where('reset_password_token', $request->token)
            ->first();
        
        if (!$user) {
            return response()->json(['message' => 'Invalid reset token'], 400);
        }
        
        // Token expires after 60 minutes
        if ($user->reset_password_sent_at->addMinutes(60)->isPast()) {
            return response()->json(['message' => 'Reset token has expired'], 400);
        }
        
        $user->password = Hash::make($request->password);
        $user->reset_password_token = null;
        $user->reset_password_sent_at = null;
        $user->save();
        
        // Revoke all existing tokens
        $user->tokens()->delete();
        
        $token = $user->createToken('auth_token')->plainTextToken;
        
        return response()->json([
            'message' => 'Password reset successfully',
            'token' => $token,
            'user' => new UserResource($user),
        ]);
    }
}
```

### 2.4 Email Notifications

```bash
# Create mailables
php artisan make:mail VerifyEmail
php artisan make:mail PasswordResetMail
```

```php
// app/Mail/VerifyEmail.php
class VerifyEmail extends Mailable
{
    public function build()
    {
        return $this->subject('Verify your SportX account')
            ->view('emails.verify-email')
            ->with([
                'name' => $this->user->name,
                'verifyUrl' => config('app.frontend_url') . '/verify-email?token=' . $this->token,
            ]);
    }
}

// app/Mail/PasswordResetMail.php
class PasswordResetMail extends Mailable
{
    public function build()
    {
        return $this->subject('Reset your SportX password')
            ->view('emails.password-reset')
            ->with([
                'name' => $this->user->name,
                'resetUrl' => config('app.frontend_url') . '/reset-password?token=' . $this->token,
            ]);
    }
}
```

### 2.5 Route Updates

```php
// routes/api.php - Auth routes

Route::prefix('v1/auth')->name('auth.')->group(function () {
    // Public routes
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/verify-email', [AuthController::class, 'verifyEmail']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    
    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
    });
});
```

---

## 3. Admin 2FA Enforcement

### 3.1 2FA Verification Middleware

```php
// app/Http/Middleware/EnsureAdmin2FAVerified.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureAdmin2FAVerified
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        
        // Non-admin users pass through
        if ($user->role !== 'admin') {
            return $next($request);
        }
        
        // Check if admin has verified 2FA in current session
        if (!$request->session()->has('admin_2fa_verified') || 
            $request->session()->get('admin_2fa_verified') !== true) {
            
            // If requesting JSON API, return 403
            if ($request->expectsJson()) {
                return response()->json([
                    'message' => '2FA verification required. Please verify your identity.'
                ], 403);
            }
            
            return redirect()->route('admin.2fa.verify');
        }
        
        return $next($request);
    }
}
```

### 3.2 Register Middleware

```php
// bootstrap/app.php or app/Http/Kernel.php

// In Kernel.php $routeMiddleware
protected $routeMiddleware = [
    // ...
    'admin.2fa' => \App\Http\Middleware\EnsureAdmin2FAVerified::class,
];

// In routes/web.php - Apply to admin routes
Route::middleware(['auth:sanctum', 'role:admin', 'admin.2fa'])->group(function () {
    Route::get('/dashboard', [AdminController::class, 'dashboard']);
    Route::get('/users', [AdminController::class, 'users']);
    // etc...
});
```

### 3.3 Session-based 2FA Storage

```php
// In AdminController@verify2fa
public function verify2fa(Verify2FARequest $request)
{
    $request->validate([
        'code' => 'required|string|size:6',
    ]);
    
    // Verify the 2FA code (using your 2FA library)
    if ($this->verify2FACode($request->user(), $request->code)) {
        // Store verification in session
        $request->session()->put('admin_2fa_verified', true);
        $request->session()->put('admin_2fa_verified_at', now()->timestamp);
        
        return response()->json(['message' => '2FA verified']);
    }
    
    return response()->json(['message' => 'Invalid 2FA code'], 401);
}
```

---

## 4. Signed URLs for Media

### 4.1 Media Signed URL Controller

```php
// app/Http/Controllers/MediaController.php

class MediaController extends Controller
{
    public function download(DownloadMediaRequest $request, MediaItem $media)
    {
        // Verify ownership or admin
        if ($media->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            abort(403);
        }
        
        // Check file exists
        if (!Storage::exists($media->file_path)) {
            abort(404);
        }
        
        // Return signed URL (expires in 5 minutes)
        $signedUrl = Storage::temporaryUrl(
            $media->file_path,
            now()->addMinutes(5)
        );
        
        return response()->json([
            'url' => $signedUrl,
            'expires_at' => now()->addMinutes(5)->toISOString(),
        ]);
    }
    
    public function stream(MediaItem $media)
    {
        if (!Storage::exists($media->file_path)) {
            abort(404);
        }
        
        return Storage::response($media->file_path);
    }
}
```

### 4.2 Routes

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/media/{media}/signed-url', [MediaController::class, 'download']);
    Route::get('/media/{media}/stream', [MediaController::class, 'stream']);
});
```

---

## 5. Health Check & Monitoring

### 5.1 Health Check Endpoint

```php
// routes/api.php
Route::get('/health', function () {
    $checks = [
        'database' => false,
        'cache' => false,
        'storage' => false,
    ];
    
    // Database check
    try {
        DB::connection()->getPdo();
        $checks['database'] = true;
    } catch (\Exception $e) {
        $checks['database_error'] = $e->getMessage();
    }
    
    // Cache check
    try {
        Cache::store('redis')->put('health_check', true, 10);
        Cache::store('redis')->forget('health_check');
        $checks['cache'] = true;
    } catch (\Exception $e) {
        $checks['cache'] = 'unavailable (redis)';
    }
    
    // Storage check
    try {
        Storage::disk('local')->put('health_check.txt', 'ok');
        Storage::disk('local')->delete('health_check.txt');
        $checks['storage'] = true;
    } catch (\Exception $e) {
        $checks['storage_error'] = $e->getMessage();
    }
    
    $healthy = $checks['database'] && $checks['storage'];
    
    return response()->json([
        'status' => $healthy ? 'healthy' : 'degraded',
        'timestamp' => now()->toISOString(),
        'version' => config('app.version', '1.0.0'),
        'environment' => app()->environment(),
        'checks' => $checks,
    ], $healthy ? 200 : 503);
});
```

### 5.2 Sentry Integration

```bash
composer require sentry/sentry-laravel
```

```php
// config/sentry.php (auto-generated)
composer require sentry/sentry-laravel
php artisan sentry:publish
```

```php
// bootstrap/app.php
use Sentry\Laravel\Integration;

Integration::init();
```

### 5.3 Laravel Telescope (Dev Only)

```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

```php
// app/Providers/TelescopeServiceProvider.php
protected $devEnvironments = ['local', 'development'];
```

---

## 6. Calendar Export (.ics)

### 6.1 ICS Service

```php
// app/Services/IcsService.php

namespace App\Services;

class IcsService
{
    public function generateTrialRegistration(TrialRegistration $registration): string
    {
        $trial = $registration->trial;
        $user = $registration->user;
        
        $startDate = \Carbon\Carbon::parse($trial->trial_date);
        $endDate = $startDate->copy()->addHours(4); // Assume 4 hours
        
        return $this->buildIcs([
            'uid' => "trial-{$registration->id}@sportx.app",
            'summary' => "Trial: {$trial->title}",
            'description' => "Registration ID: {$registration->registration_id}\nVenue: {$trial->venue}",
            'location' => $trial->venue_address ?? $trial->venue,
            'dtstart' => $startDate->format('Ymd\THis'),
            'dtend' => $endDate->format('Ymd\THis'),
            'organizer' => config('app.name') . ' <noreply@sportx.app>',
        ]);
    }
    
    public function generateTournamentRegistration(TournamentRegistration $registration): string
    {
        $tournament = $registration->tournament;
        
        $startDate = \Carbon\Carbon::parse($tournament->start_date);
        $endDate = \Carbon\Carbon::parse($tournament->end_date);
        
        return $this->buildIcs([
            'uid' => "tournament-{$registration->id}@sportx.app",
            'summary' => "Tournament: {$tournament->title}",
            'description' => "Registration ID: {$registration->registration_id}\nCategory: {$registration->category}",
            'location' => $tournament->venue_address ?? $tournament->venue,
            'dtstart' => $startDate->format('Ymd\THis'),
            'dtend' => $endDate->format('Ymd\THis'),
            'organizer' => config('app.name') . ' <noreply@sportx.app>',
        ]);
    }
    
    private function buildIcs(array $data): string
    {
        $ics = "BEGIN:VCALENDAR\r\n";
        $ics .= "VERSION:2.0\r\n";
        $ics .= "PRODID:-//SportX//NONSGML v1.0//EN\r\n";
        $ics .= "BEGIN:VEVENT\r\n";
        $ics .= "UID:{$data['uid']}\r\n";
        $ics .= "DTSTAMP:" . now()->format('Ymd\THis') . "\r\n";
        $ics .= "DTSTART:{$data['dtstart']}\r\n";
        $ics .= "DTEND:{$data['dtend']}\r\n";
        $ics .= "SUMMARY:{$data['summary']}\r\n";
        $ics .= "DESCRIPTION:{$data['description']}\r\n";
        $ics .= "LOCATION:{$data['location']}\r\n";
        $ics .= "ORGANIZER;CN={$data['organizer']}:mailto:{$data['organizer']}\r\n";
        $ics .= "END:VEVENT\r\n";
        $ics .= "END:VCALENDAR\r\n";
        
        return $ics;
    }
}
```

### 6.2 ICS Endpoint

```php
// app/Http/Controllers/RegistrationController.php

public function downloadIcs(TrialRegistration $registration)
{
    $this->authorize('view', $registration);
    
    $ics = app(IcsService::class)->generateTrialRegistration($registration);
    
    return response($ics, 200, [
        'Content-Type' => 'text/calendar; charset=utf-8',
        'Content-Disposition' => "attachment; filename=\"trial-{$registration->registration_id}.ics\"",
    ]);
}
```

```php
// routes/api.php
Route::get('/registrations/trials/{registration}/ics', [RegistrationController::class, 'downloadIcs']);
Route::get('/registrations/tournaments/{registration}/ics', [RegistrationController::class, 'downloadTournamentIcs']);
```

---

## 7. OAuth (Google Sign-In) — Phase 4 / confirm D9

> **v3 note (D9):** the Sign Up wireframe (A.3) shows Google sign-in. Old spec defers it to Phase 4. **Recommendation: keep deferred** unless a stakeholder overrides — it is not part of the P0 delta. Confirm per `Backend-Feature-Delta.md` §8 D9.

### 7.1 Laravel Socialite Setup

```bash
composer require laravel/socialite
```

```php
// config/services.php
'google' => [
    'client_id' => env('GOOGLE_CLIENT_ID'),
    'client_secret' => env('GOOGLE_CLIENT_SECRET'),
    'redirect' => env('APP_URL') . '/auth/google/callback',
],
```

### 7.2 Google OAuth Controller

```php
// app/Http/Controllers/Auth/GoogleAuthController.php

class GoogleAuthController extends Controller
{
    public function redirect()
    {
        return Socialite::driver('google')->stateless()->redirect();
    }
    
    public function callback(Request $request)
    {
        $googleUser = Socialite::driver('google')->stateless()->user();
        
        // Find or create user
        $user = User::where('email', $googleUser->email)->first();
        
        if (!$user) {
            $user = User::create([
                'name' => $googleUser->name,
                'email' => $googleUser->email,
                'google_id' => $googleUser->id,
                'password' => Hash::make(Str::random(24)), // Random password
                'email_verified_at' => now(), // Google verifies email
            ]);
        } else {
            $user->google_id = $googleUser->id;
            $user->save();
        }
        
        $token = $user->createToken('auth_token')->plainTextToken;
        
        return response()->json([
            'token' => $token,
            'user' => new UserResource($user),
        ]);
    }
}
```

```php
// routes/api.php
Route::get('/auth/google', [GoogleAuthController::class, 'redirect']);
Route::get('/auth/google/callback', [GoogleAuthController::class, 'callback']);
```

---

## 8. Auto Waitlist Promotion

```php
// app/Jobs/PromoteWaitlistedRegistrations.php

class PromoteWaitlistedRegistrations implements ShouldQueue
{
    public function handle()
    {
        // Find expired/cancelled registrations with waitlisted candidates
        $registrations = TournamentRegistration::where('status', 'confirmed')
            ->whereNotNull('cancelled_at')
            ->with(['tournament', 'waitlisted'])
            ->get();
        
        foreach ($registrations as $registration) {
            $tournament = $registration->tournament;
            $category = $registration->category;
            
            // Find waitlisted in same category
            $waitlisted = TournamentRegistration::where('tournament_id', $tournament->id)
                ->where('category', $category)
                ->where('status', 'waitlisted')
                ->orderBy('created_at')
                ->first();
            
            if ($waitlisted && $tournament->hasCapacity($category)) {
                $waitlisted->update(['status' => 'confirmed']);
                
                Notification::send($waitlisted->user, new WaitlistPromotedNotification($waitlisted));
            }
        }
    }
}
```

---

## 9. Production Deployment Checklist

### 9.1 Pre-Deployment

- [ ] All endpoints tested with Postman
- [ ] Auth flow tested end-to-end
- [ ] Admin 2FA tested
- [ ] Database migrations run on production
- [ ] Email/SMS drivers configured for production
- [ ] Redis/Cache configured
- [ ] Storage (S3/Disk) configured
- [ ] Environment variables set
- [ ] SSL certificates installed

### 9.2 Server Requirements

| Component | Specification |
|-----------|---------------|
| OS | Ubuntu 22.04 LTS |
| PHP | 8.2+ |
| Database | MySQL 8.0+ |
| Cache | Redis 7+ |
| Queue | Redis + Laravel Horizon |
| Storage | S3 or local with CDN |
| Web Server | Nginx |
| SSL | Let's Encrypt |

### 9.3 Environment Variables

```env
# .env.production
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.sportx.india

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=sportx
DB_USERNAME=sportx_user
DB_PASSWORD=secure_password

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_FROM_ADDRESS=noreply@sportx.india
MAIL_FROM_NAME="SportX India"

SENTRY_LARAVEL_DSN=https://xxx@sentry.io/xxx

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=ap-south-1
AWS_BUCKET=sportx-media

GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

### 9.4 Nginx Configuration

```nginx
server {
    listen 80;
    server_name api.sportx.india;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.sportx.india;
    
    root /var/www/sportx-api/public;
    index index.php;
    
    ssl_certificate /etc/letsencrypt/live/api.sportx.india/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.sportx.india/privkey.pem;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.(?!well-known) {
        deny all;
    }
}
```

---

## 10. Implementation Timeline

> **[SUPERSEDED — see Backend-Feature-Delta.md §9]** The timeline below covered the old spec's remaining work. The v3 build order is:
> 1. Roles & auth (enum change, OTP stack, scout onboarding, guardian consent) · 2. Verification + admin queue · 3. Opportunities + migration + applications · 4. Programs + facilities · 5. Social core (posts/feed/chat/follows/blocks — verify partial first) · 6. Leaderboard engine · 7. Scout extensions · 8. Admin P0 (users, verification, content types, export) · 9. Notifications matrix + reminders + policies · 10. Search/discovery enrichment + saved morphs + completion checklist + share. Then the P1 wave (delta §2).

| Phase | Task | Duration | Priority |
|-------|------|----------|----------|
| 1 | Roles + OTP stack + guardian consent (replaces "Email/Password Auth") | 3-4 days | CRITICAL |
| 2 | Opportunities + migration (scholarships/sponsorships) | 3 days | CRITICAL |
| 3 | Verification queue + admin user mgmt | 2 days | CRITICAL |
| 4 | Social core + chat (verify first) | 4-5 days | CRITICAL |
| 5 | Leaderboard engine + discovery (`/me/home`, `/explore`) | 3 days | CRITICAL |
| 6 | Programs/facilities + scout extensions | 3 days | HIGH |
| 7 | Admin 2FA Middleware | 1 day | HIGH |
| 8 | Signed URLs + Health Check + Monitoring | 2 days | HIGH |
| 9 | Notifications matrix + reminders + policies | 2 days | HIGH |
| 10 | ICS Calendar Export | 1 day | MEDIUM |
| 11 | Google OAuth | 2 days | LOW (P1 / confirm D9) |
| 12 | P1 wave (reviews, schedule/gallery, analytics, reports, broadcast) | — | P1 |
| 13 | Load Testing + Production Deployment | 3 days | ONGOING |

---

## 11. Testing Requirements

### 11.1 API Testing Checklist

- [ ] Register with phone **and** email; OTP send/verify/resend (v3 P0)
- [ ] Guardian consent flow for minors (v3 P0)
- [ ] Login with email/password **and** phone/email OTP
- [ ] Forgot/reset password flow (token link + OTP variant)
- [ ] Admin 2FA verification; admin user suspend/ban; verification queue approve/reject
- [ ] Opportunities create/apply/review; program/facility CRUD; feed/posts/chat/follows; leaderboard
- [ ] All CRUD operations
- [ ] File upload with signed URLs
- [ ] ICS calendar download
- [ ] Rate limiting enforcement
- [ ] Error responses

### 11.2 Load Testing Targets

| Endpoint | Target RPS | Notes |
|----------|-----------|-------|
| Login | 100 | Auth heavy |
| Directory List | 500 | Read heavy |
| Search | 200 | Complex query |
| Registration | 50 | Write heavy |

### 11.3 Security Testing

- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF (if web routes)
- [ ] Rate limiting bypass attempts
- [ ] Token brute force
- [ ] File upload exploits
