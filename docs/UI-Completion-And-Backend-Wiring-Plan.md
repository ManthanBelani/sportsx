# SportX India — UI Completion & Backend Wiring Plan

**Date:** 2026-08-09
**Status:** UI Partially Implemented + Backend Wiring Needed
**Target:** Production Ready

---

## Part A: Flutter UI Completion

### A.1 Critical UI Fixes Required

Based on audit against `sportsx-design-v1/` designs:

| Priority | Screen | Issue | Fix Required |
|----------|--------|-------|--------------|
| **HIGH** | Home Dashboard | Missing bottom navigation bar | Add 5-tab bottom nav: Home, Search, Saved, Activity, Profile |
| **HIGH** | Sign Up | Missing "Full Name" field, wrong field order | Add name field, reorder: Name → Email → Phone → Password |
| **HIGH** | Academy Detail | Missing phone contact button in CTA | Add phone icon button alongside "Enquire Now" |
| **MEDIUM** | Splash Screen | Uses CircularProgressIndicator | Replace with 3-dot animated loader from design |
| **MEDIUM** | Role Selection | Header padding 36px vs 60px | Increase header top padding to 60px |
| **MEDIUM** | Academy Detail | Report link position wrong | Move report link above CTA bar |
| **LOW** | Login | Initial toggle state differs | Match HTML hardcoded active state |

### A.2 UI Completion Checklist

```dart
// 1. Home Dashboard - Add Bottom Navigation Bar
// File: sportx_app/lib/features/home/presentation/screens/home_screen.dart
// Add: BottomNavigationBar with 5 items (Home, Search, Saved, Activity, Profile)

// 2. Sign Up - Add Full Name Field & Reorder
// File: sportx_app/lib/features/auth/presentation/screens/sign_up_screen.dart
// Add: TextFormField for 'full_name' as first field
// Reorder: full_name → email → phone → password

// 3. Academy Detail - Add Phone Contact Button
// File: sportx_app/lib/features/academy/presentation/screens/academy_detail_screen.dart
// Add: Row with [PhoneIcon button, EnquireNow button] in CTA bar

// 4. Splash Screen - Replace Loader
// File: sportx_app/lib/features/auth/presentation/screens/splash_screen.dart
// Replace: CircularProgressIndicator with custom 3-dot pulse animation

// 5. Role Selection - Fix Header Padding
// File: sportx_app/lib/features/auth/presentation/screens/role_selection_screen.dart
// Change: header top padding from 36px to 60px

// 6. Academy Detail - Fix Report Link Position
// File: sportx_app/lib/features/academy/presentation/screens/academy_detail_screen.dart
// Move: report_modal below hero, above CTA bar
```

### A.3 Files Needing Updates

| File | Action |
|------|--------|
| `lib/features/home/presentation/screens/home_screen.dart` | Add bottom nav |
| `lib/features/auth/presentation/screens/sign_up_screen.dart` | Add name field |
| `lib/features/auth/presentation/screens/splash_screen.dart` | Replace loader |
| `lib/features/auth/presentation/screens/role_selection_screen.dart` | Fix padding |
| `lib/features/academy/presentation/screens/academy_detail_screen.dart` | Add phone btn, fix report |
| `lib/features/coach/presentation/screens/coach_detail_screen.dart` | Similar phone btn check |
| `lib/shared/presentation/widgets/directory_list_template.dart` | Ensure search connected |
| `lib/shared/presentation/widgets/detail_page_template.dart` | Ensure report position |

---

## Part B: Backend Wiring

### B.1 Current API Status

| Module | Endpoints | Flutter Connected |
|--------|-----------|-------------------|
| Auth | 8 | ⚠️ Partial (phone/OTP) |
| Meta | 4 | ✅ Complete |
| Onboarding | 6 | ✅ Complete |
| Directory | 12 | ⚠️ Partial |
| Search | 2 | ✅ Complete |
| Media | 3 | ✅ Complete |
| Saved Items | 3 | ✅ Complete |
| Reports | 1 | ✅ Complete |
| Profile | 3 | ⚠️ Partial |
| Enquiries | 5 | ⚠️ Partial |
| Trial Registrations | 6 | ✅ Complete |
| Tournament Registrations | 6 | ✅ Complete |
| Results | 4 | ✅ Complete |
| Sponsor Engagement | 10 | ⚠️ Partial |
| Notifications | 4 | ✅ Complete |
| Settings | 4 | ✅ Complete |
| Admin | 33 | ✅ Complete |

### B.2 Wiring Checklist by Feature

#### Auth Flow
- [ ] `POST /auth/register` → Register with email (currently phone-based)
- [ ] `POST /auth/verify-otp` → OTP verification (needed for email verification)
- [ ] `POST /auth/login` → Email/password login (currently phone/OTP)
- [ ] `GET /auth/me` → Get current user

#### Directory & Search
- [ ] `GET /academies` → Academy directory list
- [ ] `GET /academies/{id}` → Academy detail
- [ ] `GET /coaches` → Coach directory list
- [ ] `GET /coaches/{id}` → Coach detail
- [ ] `GET /trials` → Trial listings
- [ ] `GET /trials/{id}` → Trial detail
- [ ] `GET /tournaments` → Tournament listings
- [ ] `GET /search` → Universal search

#### Profile & Settings
- [ ] `GET /profile` → Current user profile
- [ ] `PUT /profile` → Update profile
- [ ] `GET /settings` → Get settings
- [ ] `PUT /settings` → Update settings

#### Enquiries
- [ ] `POST /enquiries` → Send enquiry
- [ ] `GET /enquiries/inbox` → Enquiry inbox
- [ ] `GET /enquiries/{id}` → Enquiry detail
- [ ] `POST /enquiries/{id}/reply` → Reply to enquiry

#### Saved Items
- [ ] `GET /saved` → List saved items
- [ ] `POST /saved` → Save item
- [ ] `DELETE /saved/{id}` → Unsave item

#### Media
- [ ] `POST /media/upload` → Upload media
- [ ] `DELETE /media/{id}` → Delete media

---

## Part C: Auth System Change (Phone/OTP → Email/Password)

### C.1 Current Auth Flow (Phone/OTP)

```
User Registration:
1. POST /auth/register (phone) → Send OTP
2. POST /auth/verify-otp → Verify OTP → Get token

User Login:
3. POST /auth/login (phone/OTP) → Send OTP
4. POST /auth/verify-otp → Verify OTP → Get token
OR
5. POST /auth/login (email/password) → Direct login (stub exists)
```

### C.2 Target Auth Flow (Email/Password)

```
User Registration:
1. POST /auth/register (name, email, phone, password) → Create account + send verification email
2. POST /auth/verify-email/{token} → Verify email → Get token
OR (if phone still used for login):
3. POST /auth/register (name, email, phone, password) → Create account
4. POST /auth/verify-otp (phone) → Verify phone → Get token

User Login:
5. POST /auth/login (email/password) → Direct login → Get token
6. POST /auth/forgot-password (email) → Send reset link
7. POST /auth/reset-password (token, password) → Reset password
```

### C.3 Auth API Changes Required

#### New/Modified Endpoints

| Method | Endpoint | Change | Description |
|--------|----------|--------|-------------|
| POST | `/auth/register` | **Modify** | Accept name, email, phone, password; send verification email |
| POST | `/auth/verify-email` | **New** | Verify email with token |
| POST | `/auth/login` | **Modify** | Email/password only (remove phone option) |
| POST | `/auth/forgot-password` | **Modify** | Send reset email link instead of OTP |
| POST | `/auth/reset-password` | **Modify** | Accept email token (not phone OTP) |
| DELETE | `/auth/otp-code` | **Remove** | Remove OTP verification endpoint |

#### Database Changes

```php
// users table - add email_verified_at
Schema::table('users', function (Blueprint $table) {
    $table->timestamp('email_verified_at')->nullable();
    $table->string('verification_token', 64)->nullable();
});

// Remove phone as required for login (make optional)
// phone stays for profile but not for auth
```

#### Controller Changes

**AuthController.php:**
```php
// register()
- Validate: name, email (unique), phone, password
- Create user with hashed password
- Send verification email (not OTP)
- Return success message

// verifyEmail()
- Accept verification token
- Set email_verified_at
- Return token

// login()
- Validate: email, password only
- Return token on success
- Remove phone/OTP logic

// forgotPassword()
- Send password reset email with token link

// resetPassword()
- Accept: email, token, password
- Validate token
- Update password
```

#### Request Validation Changes

**RegisterRequest:**
```php
'name' => 'required|string|max:255'
'email' => 'required|email|unique:users,email'
'phone' => 'required|phone|unique:users,phone'  // Keep for profile
'password' => 'required|string|min:8|confirmed'
```

**LoginRequest:**
```php
'email' => 'required|email'
'password' => 'required|string'
```

---

## Part D: Production Readiness

### D.1 Security Hardening

| Item | Status | Action Required |
|------|--------|-----------------|
| Rate limiting | ✅ Implemented | Auth endpoints rate limited |
| CORS | ✅ Implemented | Configured for Flutter origins |
| File upload validation | ✅ Implemented | Type + size checks |
| Admin 2FA enforcement | ❌ Missing | Add `2fa_verified` middleware to admin routes |
| Signed URLs | ❌ Missing | Implement for private documents |
| SQL injection | ✅ Protected | Using Eloquent ORM |
| XSS | ✅ Protected | Laravel CSRF + validation |

### D.2 Admin 2FA Enforcement

```php
// app/Http/Middleware/EnsureAdmin2FAVerified.php
class EnsureAdmin2FAVerified
{
    public function handle($request, Closure $next)
    {
        $user = $request->user();
        
        if ($user->role !== 'admin') {
            return $next($request);
        }
        
        // Check if admin has verified 2FA in this session
        if (!$request->session()->has('admin_2fa_verified')) {
            return redirect()->route('admin.2fa.verify');
        }
        
        return $next($request);
    }
}

// Register in bootstrap/app.php or Kernel.php
```

### D.3 Signed URLs for Documents

```php
// Generate signed URL
$url = URL::temporarySignedRoute(
    'media.download',
    now()->addMinutes(5),
    ['media' => $media->id]
);

// Verify signed URL middleware
class VerifyMediaSignature
{
    public function handle($request, Closure $next)
    {
        if (!$request->hasValidSignature()) {
            abort(401, 'Invalid or expired link');
        }
        return $next($request);
    }
}
```

### D.4 Health Check & Monitoring

```php
// routes/api.php
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toISOString(),
        'database' => DB::connection()->getPdo() ? 'connected' : 'disconnected',
    ]);
});

// For production monitoring (New Relic, Sentry, etc.)
// composer require sentry/sentry-laravel
```

### D.5 Production Checklist

- [ ] Implement email/password auth (Part C)
- [ ] Add admin 2FA middleware enforcement
- [ ] Implement signed URLs for media downloads
- [ ] Add health check endpoint
- [ ] Configure Sentry for exception tracking
- [ ] Add .ics calendar export for registrations
- [ ] Implement auto-waitlist promotion
- [ ] Complete Help/Support Center screen
- [ ] Load testing (1000+ concurrent users)
- [ ] Configure Laravel Horizon for queues
- [ ] Set up Laravel Forge/Envoyer for deployment

---

## Part E: Implementation Sequence

### Phase 1: UI Fixes (1-2 days)
```bash
1. Home screen - add bottom navigation
2. Sign up - add name field, reorder
3. Splash - replace loader
4. Role selection - fix padding
5. Academy/Coach detail - add phone btn
```

### Phase 2: Auth System Change (2-3 days)
```bash
1. Modify AuthController for email/password
2. Add email verification endpoint
3. Update registration/login requests
4. Update Flutter auth provider for new flow
5. Update Flutter screens (remove OTP if applicable)
```

### Phase 3: Backend Wiring (2-3 days)
```bash
1. Connect all Flutter screens to API
2. Test all auth flows end-to-end
3. Test directory browsing flows
4. Test enquiry flows
5. Test registration flows
```

### Phase 4: Production Hardening (2-3 days)
```bash
1. Admin 2FA middleware
2. Signed URLs for documents
3. Health check endpoint
4. Exception tracking setup
5. Performance optimization
```

---

## Appendix: API Endpoint Reference

### Auth Endpoints (New)

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| POST | `/api/v1/auth/register` | `{name, email, phone, password, password_confirmation}` | `{message, user}` |
| POST | `/api/v1/auth/verify-email` | `{token}` | `{token, user}` |
| POST | `/api/v1/auth/login` | `{email, password}` | `{token, user}` |
| POST | `/api/v1/auth/forgot-password` | `{email}` | `{message}` |
| POST | `/api/v1/auth/reset-password` | `{email, token, password, password_confirmation}` | `{token, user}` |
| POST | `/api/v1/auth/logout` | - | `{message}` |
| GET | `/api/v1/auth/me` | - | `{user}` |

### Flutter Auth Provider Changes

```dart
// lib/features/auth/presentation/providers/auth_provider.dart

class AuthNotifier extends StateNotifier<AuthState> {
  
  // Register with email/password
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // POST /auth/register
    // Handle email verification or phone verification
  }
  
  // Login with email/password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // POST /auth/login
    // Returns token + user directly
  }
  
  // Forgot password - sends reset email
  Future<void> forgotPassword(String email) async {
    // POST /auth/forgot-password
  }
  
  // Reset password with token
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    // POST /auth/reset-password
  }
}
```
