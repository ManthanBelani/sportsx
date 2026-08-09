# Integration Architecture — SportX India

How the Flutter mobile app and Laravel backend connect: API contracts, auth flow, error handling, third-party integrations.

> **Scope:** Payments are **excluded** from MVP (stakeholder decision). Third-party integrations are limited to: OTP/email delivery (vendor undecided), push notifications (vendor undecided), Google OAuth, object storage, and a map preview embed. All undecided vendors are abstracted behind interfaces.

---

## 1. Architecture Overview

```
┌──────────────────┐         HTTPS / JSON         ┌──────────────────────┐
│   Flutter App     │◄────────────────────────────►│   Laravel API         │
│   (Mobile)        │  Sanctum Bearer Token        │   (Backend)           │
│                   │                              │                       │
│  - go_router      │                              │  - Controllers        │
│  - Riverpod       │                              │  - Services           │
│  - Dio HTTP       │                              │  - Eloquent Models    │
│                   │                              │  - Jobs / Queues      │
└──────────────────┘                              └──────────┬───────────┘
                                                             │
                              ┌──────────────────────────────┤
                              │                              │
                     ┌────────▼──────┐              ┌────────▼──────┐
                     │  MySQL / DB    │              │ Object Storage │
                     │                │              │ (S3 compat)    │
                     └───────────────┘              └────────────────┘
                                                             │
                              ┌──────────────────────────────┤
                              │                              │
                     ┌────────▼──────┐              ┌────────▼──────┐
                     │  Email/OTP    │              │  Push         │
                     │  Provider     │              │  Provider     │
                     │  (interface)  │              │  (interface)  │
                     └───────────────┘              └────────────────┘
                              │                              │
                              │  (vendor TBD — AS-03)        │
                              ▼                              ▼
                        ┌──────────┐                   ┌──────────┐
                        │ ?Mailer  │                   │ ?Push Svc│
                        │ (SMS/    │                   │ (FCM /   │
                        │  Email)  │                   │  other)  │
                        └──────────┘                   └──────────┘
```

---

## 2. Communication Protocol

| Aspect | Specification | Assumption |
|---|---|---|
| **Transport** | HTTPS (TLS 1.2+) | — |
| **Format** | JSON (UTF-8) | — |
| **API versioning** | URI prefix `/api/v1` | AS-15 |
| **Base URL** | Environment-configured (dev/staging/prod) | Per deployment |
| **Content-Type** | `application/json` for all API calls; `multipart/form-data` for media upload | — |
| **Compression** | Accept-Encoding: gzip (server responds gzip if available) | Could |
| **Timeout** | Dio default: 30s connect, 60s receive. Upload: 120s. | AS-27 |

---

## 3. Authentication Flow

### 3.1 Email OTP Registration & Login

```
┌────────┐          ┌────────┐          ┌────────┐          ┌────────┐
│ Flutter│          │  API   │          │  DB    │          │  Email │
└───┬────┘          └───┬────┘          └───┬────┘          └───┬────┘
    │                    │                    │                    │
    │ POST /auth/register│                    │                    │
    │ {email, role}      │                    │                    │
    │───────────────────►│                    │                    │
    │                    │ INSERT user        │                    │
    │                    │───────────────────►│                    │
    │                    │ Queue SendOtpJob    │                    │
    │                    │───────────────────►│                    │
    │                    │                    │ Send OTP code      │
    │                    │                    │───────────────────►│
    │ ◄── 202 {email}   │                    │                    │
    │                    │                    │                    │
    │ POST /auth/verify  │                    │                    │
    │ {email, code}      │                    │                    │
    │───────────────────►│                    │                    │
    │                    │ Validate code hash │                    │
    │                    │───────────────────►│                    │
    │ ◄── 200 {token}   │                    │                    │
    │                    │                    │                    │
    │ GET /onboarding/..│                    │                    │
    │ [Bearer token]     │                    │                    │
    │───────────────────►│                    │                    │
    │ ◄── 200 {form}    │                    │                    │
    │                    │                    │                    │
    │ POST /onboarding/..│                    │                    │
    │───────────────────►│                    │                    │
    │ ◄── 201 {profile} │                    │                    │
```

### 3.2 Login (Password or OTP)

- **Password:** `POST /auth/login {email, password}` → validate bcrypt → issue token.
- **OTP login:** `POST /auth/login {email, otp_code: true}` → API sends OTP to email → user submits `POST /auth/verify-otp` → token.
  - Alternative: single-step `POST /auth/login {email, otp_code: "123456"}` if OTP already sent — design choice left to implementation (AS-28).
- **Google:** OAuth 2.0 redirect; backend exchanges code for Google token → find-or-create user → issue Sanctum token. `email_verified_at` set from Google account.

### 3.3 Token Lifecycle

| Event | Behavior |
|---|---|
| Issue | On verify-OTP, login, Google callback. Token returned in response body. |
| Send | Flutter `Authorization: Bearer <plain_token>` header on every request. |
| Refresh | No refresh mechanism at MVP — token lifetime is long (AS-28: configurable, default 1 year). Shorter lifetime + refresh can be added post-MVP. |
| Revoke | `POST /auth/logout` → `currentAccessToken()->delete()`. |
| Expire | Server checks `token->last_used_at` vs `token_lifetime` config. Returns 401 if expired. |
| Admin 2FA | Admin login issues a **restricted** token; `POST /admin/verify-2fa` upgrades it to full admin access (AS-26). |

### 3.4 Dio Interceptor Setup (Flutter)

```dart
// app/core/network/api_client.dart (conceptual)
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = authProvider.token; // Riverpod read
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      authProvider.logout(); // redirect to login
    }
    handler.next(err);
  }
}
```

---

## 4. Error Handling Contract

### Server → Client

All errors follow the standard error envelope (see `API-Specification.md` §21).

| Category | HTTP range | Flutter handling |
|---|---|---|
| Validation | 422 | Show field-level errors inline on form (map `fields` key to form widgets). |
| Auth | 401, 403 | 401 → force logout + login screen. 403 → show "access denied" snackbar. |
| Not found | 404 | Show "not found" / navigate back. |
| Conflict | 409 | Show specific message (e.g. "already registered"). |
| Rate limit | 429 | Show "try again in N seconds" (from `Retry-After` header — AS-29). |
| Server error | 500 | Generic "something went wrong" + optional retry button. |
| Network error | — (Dio catch) | Connectivity banner; retry queue (AS-30 — no offline-first at MVP). |

### Error localization

Error messages from the API are English strings. Flutter displays them as-is at MVP (NFR-9). Localization of error messages is a post-MVP enhancement.

---

## 5. Media Upload Flow

### Upload Contract

```
Flutter                                    Laravel API                    Object Storage
  │                                           │                              │
  │ POST /media/upload                         │                              │
  │ multipart/form-data:                       │                              │
  │   file: <binary>                           │                              │
  │   owner_type: "athlete_profile"            │                              │
  │   owner_id: 1                              │                              │
  │   media_type: "photo"                      │                              │
  │──────────────────────────────────────────►│                              │
  │                                           │ Validate file type/size     │
  │                                           │ Store to disk (S3)          │
  │                                           │─────────────────────────────►│
  │                                           │                              │
  │ ◄── 201 { id, url }                       │ Create media_items row      │
  │                                           │                              │
```

- File validation: type whitelist (jpg, jpeg, png, webp, mp4, pdf), max size from `config/sportx.php`.
- Storage: `Storage::disk('s3')->put(...)` for production; `public` disk for local dev.
- CDN: URL points to CloudFront/custom CDN domain (AS-07). Signed URLs for private/verification documents.
- Flutter stores the returned `media_id` and references it in subsequent API calls (e.g. trial registration `document_media_ids[]`, onboarding verification docs).

---

## 6. Third-Party Integrations (Current & Placeholder)

### 6.1 Google OAuth (S3 — "Continue with Google")

| Aspect | Detail |
|---|---|
| SDK | `google_sign_in` Flutter plugin + Laravel Socialite |
| Flow | Flutter gets Google ID token → sends to backend → backend verifies via Socialite → finds/creates user |
| Scope | `email`, `profile` (read-only) |
| Data stored | `google_id` on `users` table; email and name from Google account |

### 6.2 OTP/Email Provider (abstract)

| Aspect | Detail |
|---|---|
| Interface | `App\Services\OtpProvider` — `send(destination, code): bool` |
| Dev default | `LogOtpProvider` — writes to Laravel log |
| Production swap | Bind implementation in `AppServiceProvider` when vendor chosen |
| Candidates | MSG91, Twilio, Amazon SES, SendGrid, Postmark (none committed — AS-03) |

### 6.3 Push Notification Provider (abstract)

| Aspect | Detail |
|---|---|
| Interface | `App\Services\NotificationProvider` — `push(user, payload): void` |
| Dev default | `DatabaseNotificationProvider` — writes to `notifications` table only |
| Production swap | Bind implementation when vendor chosen |
| Candidates | Firebase Cloud Messaging, OneSignal, Pusher Beams (none committed — AS-03) |
| Flutter side | `flutter_local_notifications` for in-app display; FCM plugin when vendor selected |

### 6.4 Object Storage (media files)

| Aspect | Detail |
|---|---|
| Driver | Laravel Filesystem `s3` disk (AWS S3, Cloudflare R2, or compatible) |
| CDN | CloudFront or similar in front of bucket (AS-07) |
| Public assets | Academy photos, coach photos, trial/tournament banners — public-read ACL |
| Private assets | Verification documents (organizer/sponsor onboarding), trial registration documents — signed URL on access |

### 6.5 Map Preview (T2 "Location" section)

| Aspect | Detail |
|---|---|
| Wireframe | T2 shows "[ Map preview ]" on Academy/Trial/Tournament detail pages |
| Implementation | Static map image embed or a lightweight map SDK (AS-31) |
| Candidates | Google Static Maps API, Mapbox Static Images, or a platform-native map view via `flutter_map` + OpenStreetMap tiles |
| Data | `city_id` + `venue` text address. Geocoding to lat/lng is an assumption (AS-32 — not specified in sources) |

---

## 7. Notification Delivery Pipeline

```
Trigger (event/listener)
  │
  ▼
NotificationService::send(user, NotificationDto)
  │
  ├─► INSERT notifications row (DB channel — always)
  │
  └─► NotificationProvider::push(user, payload)  (vendor — when selected)
        │
        ▼
      FCM / other → user's device
```

**Deep linking:** Notifications carry `notifiable_type` + `notifiable_id`. Flutter uses these to navigate to the relevant screen (e.g. tap enquiry reply notification → open thread).

---

## 8. No Payment Integration

By stakeholder decision, **no payment gateway is integrated in this MVP**. The implications:

| Concept | MVP handling |
|---|---|
| Trial entry fee | Display-only string on trial detail and registration form ("payment note") — no checkout flow |
| Tournament entry fee | Same as trial; organizer manually tracks `payment_status` flag |
| Sponsorship stipend | Display-only string in the sponsorship listing |
| Scholarship amount | Display-only on the scholarship feed |

This is documented as **AS-33** in `Glossary-and-Assumptions.md`.

---

## 9. Environment Configuration

| Env | Flutter `.env` | Laravel `.env` |
|---|---|---|
| `API_BASE_URL` | `https://api.sportx.dev/api/v1` | — |
| `GOOGLE_CLIENT_ID` | iOS/Android OAuth client ID | — |
| `GOOGLE_CLIENT_SECRET` | — | Laravel Socialite |
| `DB_*` | — | MySQL credentials |
| `AWS_*` / `S3_*` | — | Object storage |
| `OTP_PROVIDER` | — | `log` (dev) / `sms91` (prod) |
| `PUSH_PROVIDER` | — | `database` (dev) / `fcm` (prod) |
| `FCM_SERVER_KEY` | — | FCM push (when selected) |
| `SANCTUM_TOKEN_LIFETIME` | — | Minutes (default 525600 = 1 year) |

---

## 10. Security in Transit & at Rest

- All API communication over HTTPS (TLS 1.2+).
- Sanctum tokens hashed in DB (Laravel default — SHA-256).
- OTP codes stored hashed (never plaintext) — `code_hash` column.
- Passwords: bcrypt with Laravel default cost (10 rounds).
- Media files: server-side validation (type + size); storage ACL per sensitivity.
- 2FA secrets: encrypted at rest (Laravel's encrypt()).
- Detailed security model in `Security-and-NonFunctional.md`.
