# Integration Architecture — SportX India

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

How the Flutter mobile app and Laravel backend connect: API contracts, auth flow, error handling, third-party integrations.

> **Scope:** Payments are **excluded** from MVP (stakeholder decision). Third-party integrations are limited to: OTP delivery (**phone + email — P0**), transactional email, push notifications, Google sign-in, object storage, and a map preview embed.
>
> **✅ Three vendor decisions now CLOSED (2026-10).** §6.1–6.3 and §7 below are superseded by dedicated documents:
>
> | Concern | Was | Now |
> |---|---|---|
> | Email delivery | abstract `OtpProvider`, vendor TBD | **`Email-Provider-Architecture.md`** — dual SMTP + Gmail API, runtime switchable (AS-03a closed) |
> | Google sign-in | Socialite, deferred P1 | **`Google-Authentication.md`** — ID-token verification, P0 (D9 closed) |
> | Push notifications | abstract `NotificationProvider`, vendor TBD | **`FCM-Notification-System.md`** — FCM HTTP v1 + in-app + email fallback (AS-03c closed) |
>
> **Still open:** the **SMS/phone OTP vendor** (AS-03b) remains unselected, which blocks `channel=phone` on `POST /auth/send-otp`.
>
> **Role model:** `athlete`, `coach`, `academy`, `organizer`, `scout`, `admin`. The `sponsor` role is **REMOVED** (sponsorship is now an `opportunities.type`); `scout` is added.

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

### 3.1 OTP Registration & Login (phone or email)

> **P0 (D1/D5):** OTP is the primary signup/login path over **phone OR email**. `POST /auth/register` triggers an OTP instead of issuing an instant token; `POST /auth/send-otp` / `resend-otp` are rate-limited (60s cooldown, max 5 attempts — `otp_codes`).

```
┌────────┐          ┌────────┐          ┌────────┐          ┌────────────┐
│ Flutter│          │  API   │          │  DB    │          │ Email / SMS│
└───┬────┘          └───┬────┘          └───┬────┘          └───┬────────┘
    │                    │                    │                    │
    │ POST /auth/register│                    │                    │
    │ {email|phone, role}│                    │                    │
    │───────────────────►│                    │                    │
    │                    │ INSERT user (pending)                   │
    │                    │───────────────────►│                    │
    │                    │ POST /auth/send-otp │                    │
    │                    │ Queue SendOtpJob    │                    │
    │                    │───────────────────►│                    │
    │                    │                    │ Send 6-digit code  │
    │                    │                    │───────────────────►│
    │ ◄── 202 {channel} │                    │                    │
    │                    │                    │                    │
    │ POST /auth/verify-otp                   │                    │
    │ {email|phone, code}│                    │                    │
    │───────────────────►│                    │                    │
    │                    │ Validate code hash │                    │
    │                    │───────────────────►│                    │
    │ ◄── 200 {token,   │                    │                    │
    │      needs_onboarding}                  │                    │
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

- **Password:** `POST /auth/login {email, password}` → validate bcrypt → issue token. (Password auth is **kept** alongside OTP.)
- **OTP login:** `POST /auth/login {email|phone, otp_code: true}` → API sends OTP → user submits `POST /auth/verify-otp` → token.
  - Alternative: single-step `POST /auth/login {email|phone, otp_code: "123456"}` if OTP already sent — design choice left to implementation (AS-28).
- **Google:** OAuth 2.0 redirect; backend exchanges code for Google token → find-or-create user → issue Sanctum token. `email_verified_at` set from Google account. (**Confirm P0 — decision D9.**)

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

### 3.5 Guardian Consent (minors, DOB < 18)

> **P0 (D4 — closes AS-34).** An athlete account with DOB < 18 cannot activate its profile until a guardian consent is verified.

- `POST /guardian/consent` → guardian name/phone/relationship stored; OTP sent to the guardian's phone.
- `POST /guardian/verify-otp` → verifies consent; unlocks the minor's profile.
- `GET/PUT /me/guardian-controls` → parent controls: `allow_messages`, `allow_public_profile`, `leaderboard_name_mode`.
- **Enforcement:** backend policies gate chat (guardian-allowed connections only), discovery visibility, and leaderboard name anonymization for minors.

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

### 6.1 Google OAuth (S3 — "Continue with Google") — **[SUPERSEDED by `Google-Authentication.md`]**

| Aspect | Detail |
|---|---|
| SDK | `google_sign_in` Flutter plugin + `google/auth` on the backend. **Socialite is not used** — the flow is native-mobile → backend, so a server-side OAuth redirect would add a browser hop the app does not need |
| Flow | Flutter gets a Google **ID token** → `POST /auth/google` → backend verifies signature (JWKS), `aud`, `exp`, `email_verified` → finds/creates/links the user |
| Scope | `email`, `profile` (read-only) |
| Data stored | **`social_accounts` join table** (replaces the prototype `users.google_id`) — see `Database-Design.md` §1 |
| Status | **P0 — D9 CLOSED.** Full contract, account-resolution rules and the six verification checks are in `Google-Authentication.md`. |

### 6.2 OTP Provider — phone + email, P0 — **[EMAIL BUILT, SMS OPEN]**

| Aspect | Detail |
|---|---|
| Interface | `App\Services\OtpService` — `generateAndSend()`, `verify()`, `resend()` |
| Channels | **email** ✅ built · **phone (SMS)** ⚠️ blocked on **AS-03b** |
| Email transport | Active provider from **`Email-Provider-Architecture.md`** — SMTP **or** Gmail API, switchable at runtime. A user is never locked to one vendor |
| Phone transport | Not selected. `otp_codes.channel` is already an enum admitting `phone`, so adding it is config-only |
| Cooldown / attempts | 60s resend cooldown, 5 attempts max, 10-minute expiry — enforced at the endpoint **and** at the mailable |
| Storage | bcrypt `code_hash`; plaintext exists only in the outbound message |
| Dev default | `MAIL_MAILER=log` renders the mail to the log, so OTP is inspectable without a provider |
| Candidates (SMS) | MSG91, Twilio — selection still blocking |

### 6.3 Push Notification Provider — **[SUPERSEDED by `FCM-Notification-System.md`]**

| Aspect | Detail |
|---|---|
| Provider | **Firebase Cloud Messaging HTTP v1** — committed. AS-03c CLOSED |
| Interface | `App\Services\FCMService` — `sendPushNotification()`, `sendToTopic()`, `deactivateTokens()` |
| Channels | in-app (DB row, source of truth) + FCM push + email fallback |
| Auth | `google/auth` service account → `firebase.messaging` scope; access token cached |
| Device registry | `user_device_tokens`, **`token` UNIQUE**; TTL pruning; invalid-token retirement |
| Preferences | `users.notification_prefs` honoured before dispatch; account/registration decisions are hard overrides |
| Flutter side | `firebase_messaging` (present) + `flutter_local_notifications` (**to add**) for system-tray display |
| Quota | ≈ 10,000 `messages.send`/day on the default quota — **a large broadcast needs a quota increase (AS-67)** |

### 6.4 Object Storage (media files)

| Aspect | Detail |
|---|---|
| Driver | Laravel Filesystem `s3` disk (AWS S3, Cloudflare R2, or compatible) |
| CDN | CloudFront or similar in front of bucket (AS-07) |
| Public assets | Academy photos, coach photos, trial/tournament banners — public-read ACL |
| Private assets | Verification documents (`verification_requests` — provider/org onboarding), trial registration documents, guardian consent artefacts — signed URL on access |

### 6.5 Map Preview (T2 "Location" section)

| Aspect | Detail |
|---|---|
| Wireframe | T2 shows "[ Map preview ]" on Academy/Trial/Tournament detail pages |
| Implementation | Static map image embed or a lightweight map SDK (AS-31) |
| Candidates | Google Static Maps API, Mapbox Static Images, or a platform-native map view via `flutter_map` + OpenStreetMap tiles |
| Data | `city_id` + `venue` text address. Geocoding to lat/lng is an assumption (AS-32 — not specified in sources) |

---

## 7. Notification Delivery Pipeline — **[SUPERSEDED by `FCM-Notification-System.md`]**

> The abstract-provider pipeline below has been replaced by a concrete three-channel system. The **database row is written first and is the source of truth**; the FCM payload and the email fallback are both derived from it, which is what guarantees the notification centre and the push tray cannot disagree.

```
Trigger (event / listener / controller)
  │
  ▼
NotificationService::send(user, type, title, body, …)
  │
  ├─► 1. INSERT notifications row            ← ALWAYS, transactionally
  │        push_status = 'queued'
  │
  ├─► 2. dispatch NotificationCreated
  │        └─► SendPushNotificationListener
  │              ├─ read users.notification_prefs   ← honour opt-outs
  │              ├─ hard overrides (account_action,
  │              │   registration_*) always deliver
  │              ├─ load active device tokens
  │              └─► SendPushNotification job
  │                    ├─ FCM messages:send per token
  │                    ├─ Android channel_id by type
  │                    ├─ APNs headers (priority/push-type/sound)
  │                    └─ retire tokens FCM reports dead
  │
  └─► 3. on push_status ∈ { no_devices, failed }
           └─► NotificationFallbackMail
                 (delivered via SMTP or Gmail — see
                  Email-Provider-Architecture.md)
```

**Deep linking:** notifications carry `notifiable_type` + `notifiable_id`, plus `action_url` and `category`. Flutter uses these to route to the relevant screen (tap an enquiry reply → open the thread).

> **A push payload is routing metadata, never an authorization grant.** `action_url: /registrations/9` in a push body grants no access; the tapped screen re-checks ownership server-side.

**Full detail** — type vocabulary, channel mapping, Android channel IDs, token lifecycle, preference resolution, API contract, Flutter setup, monitoring and the list of gaps closed: **`FCM-Notification-System.md`**.

---

## 7A. Email Delivery Pipeline — **[NEW — `Email-Provider-Architecture.md`]**

```
Trigger (OTP / verify-email / approval / rejection / push fallback)
  │
  ▼
Mail::to(...)->queue(new SomeSportXMail(...))        [ 'mail' queue ]
  │
  ▼
MailProviderService::activeMailer()        ← resolved at SEND time,
  │                                          so a runtime switch
  │                                          affects queued mail too
  ├─► sportx_failover (default ON)  ──►  [1] gmail  → Gmail REST API
  │                                   [2] smtp   → ESMTP/STARTTLS
  │                                   [3] log    → never drop silently
  └─► direct provider (failover OFF)
```

**Provider selection order:** `platform_settings.json` override (admin panel) → `MAIL_PROVIDER` env → `smtp`.

**Why two providers:** Google Workspace accounts with enforced 2FA reject app-password logins over SMTP, so the Gmail REST API (OAuth2) is the only option for them. Consumer Gmail SMTP is capped at 500 sends/day, far below what a national broadcast needs. Having both configured means an ops team is never locked into one vendor.

**Failure handling:** every mailable implements `ShouldQueue` with `$tries = 3` and `$backoff = [10, 30, 90]`; terminal failures are logged with the mailable, provider and recipients. Full catalogue, template rules and a troubleshooting runbook: **`Email-Provider-Architecture.md`**.

---

## 8. No Payment Integration

By stakeholder decision, **no payment gateway is integrated in this MVP**. The implications:

| Concept | MVP handling |
|---|---|
| Trial entry fee | Display-only string on trial detail and registration form ("payment note") — no checkout flow |
| Tournament entry fee | Same as trial; organizer manually tracks `payment_status` flag |
| Opportunity amount (sponsorship/scholarship) | Display/sort-only numeric `opportunities.amount` in the unified opportunities listing |
| Program price / facility booking | Display-only strings (`programs.price`, `sports_venues.pricing`) |

This is documented as **AS-33** in `Glossary-and-Assumptions.md`.

---

## 9. Environment Configuration

| Env | Flutter `.env` | Laravel `.env` |
|---|---|---|
| `API_BASE_URL` | `https://api.sportx.dev/api/v1` | — |
| `DB_*` | — | MySQL credentials |
| `AWS_*` / `S3_*` | — | Object storage |
| `FRONTEND_URL` | — | Root for deep links inside every email |
| `SANCTUM_TOKEN_LIFETIME` | — | Minutes (default 525600 = 1 year) |

**Google sign-in** — `Google-Authentication.md` §12

| Env | Where | Purpose |
|---|---|---|
| `GOOGLE_CLIENT_ID` | both | Android/iOS/Web client ID; also the `aud` the backend pins to |
| `GOOGLE_CLIENT_SECRET` | Laravel | Web client secret (device clients have none) |
| `GOOGLE_REDIRECT_URI` | Laravel | OAuth consent redirect |
| `GOOGLE_WORKSPACE_HD` | Laravel | *(optional)* restrict sign-in to one Workspace domain |
| `GOOGLE_ALLOW_SIGNUP` | Laravel | `true` (default) = unknown identity creates an account |
| `GOOGLE_DEFAULT_ROLE` | Laravel | Role used when signup does not specify one (`athlete`) |
| `GOOGLE_ALLOWED_ROLES` | Laravel | **Allow-list** that `role` on signup is validated against |

**Email delivery** — `Email-Provider-Architecture.md` §8

| Env | Purpose |
|---|---|
| `MAIL_PROVIDER` | `smtp` (default) or `gmail` |
| `MAIL_FAILOVER_ENABLED` | Wrap the provider chain in a failover transport (default `true`) |
| `MAIL_HOST` / `MAIL_PORT` / `MAIL_SCHEME` / `MAIL_USERNAME` / `MAIL_PASSWORD` | SMTP relay |
| `MAIL_FROM_ADDRESS` / `MAIL_FROM_NAME` | Global sender |
| `GMAIL_AUTH_MODE` | `user` (refresh token) or `service_account` (domain-wide delegation) |
| `GMAIL_CLIENT_ID` / `GMAIL_CLIENT_SECRET` / `GMAIL_REFRESH_TOKEN` | Gmail API — user mode |
| `GMAIL_SERVICE_ACCOUNT_EMAIL` / `GMAIL_PRIVATE_KEY` / `GMAIL_IMPERSONATE_USER` | Gmail API — service-account mode |
| `MAIL_TEST_RECIPIENT` | Default recipient for admin connection tests |

**Push notifications** — `FCM-Notification-System.md` §4

| Env | Purpose |
|---|---|
| `FCM_PROJECT_ID` | Firebase project |
| `FCM_CREDENTIALS_PATH` | Path to the service-account JSON key |
| `FCM_ENABLED` / `FCM_DRY_RUN` / `FCM_TIMEOUT` | Feature flags |
| `FCM_BATCH_SIZE` / `FCM_MAX_RETRIES` | Tokens per queued job (500) / failures before retirement (3) |
| `FCM_DEFAULT_CHANNEL_ID` | Android fallback channel (`sportx_default`) |
| `FCM_TOPIC_BROADCAST` | Broadcast topic name (`sportx_broadcast`) |
| `DEVICE_TOKEN_TTL_DAYS` | Days of inactivity before a token is pruned (120) |
| `NOTIFICATION_RETENTION_DAYS` | Inbox retention (180) |

---

## 10. Security in Transit & at Rest

- All API communication over HTTPS (TLS 1.2+).
- Sanctum tokens hashed in DB (Laravel default — SHA-256).
- OTP codes stored hashed (never plaintext, **bcrypt**) — `code_hash` column.
- Google ID tokens verified server-side (RS256 pinned, `aud` checked, `email_verified` required) — `Google-Authentication.md` §5.
- Google OAuth tokens encrypted at rest (`encrypted` cast) and excluded from every API response.
- Email provider credentials are environment-only; no secret is reachable through any API response.
- FCM device tokens are per-user and never accepted as an addressable identifier; a push payload is routing metadata, not an authorization grant.
- Passwords: bcrypt with Laravel default cost (10 rounds).
- Media files: server-side validation (type + size); storage ACL per sensitivity.
- 2FA secrets: encrypted at rest (Laravel's encrypt()).
- Detailed security model in `Security-and-NonFunctional.md`.
