> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

# Google Authentication — SportX India ("Continue with Google")

> **Status:** Implemented in `sportx-api` + `sportx_app`. Promotes `POST /auth/google` from the deferred `P1` state recorded in `API-Specification.md` §1 and `Integration-Architecture.md` §6.1 to **P0**.
>
> **Scope:** Google **sign-in and account linking only**. Google as an **email delivery provider** is a separate concern documented in `Email-Provider-Architecture.md`.
>
> **Related docs:** `Security-and-NonFunctional.md` §1.1 (auth) · `Database-Design.md` §1 (`social_accounts`) · `Mobile-Architecture.md` §4 (packages).

---

## 1. Summary

SportX accepts a Google **ID token** from the mobile app, verifies it server-side against Google's published signing keys, and signs the user in — creating or linking a SportX account as needed.

| Decision | Value |
|---|---|
| Token type accepted | **ID token** (`credential`) — not an access token |
| Verification | Server-side against Google's JWKS, audience-checked against `GOOGLE_CLIENT_ID` |
| Backend libraries | `google/auth` for JWKS + signature verification |
| Client library | `google_sign_in` Flutter plugin |
| Provider storage | New `social_accounts` table (one row per linked identity) |
| Scope | `email`, `profile` — read-only, no Drive/Gmail/Calendar access |
| Account linkage | Auto-links to an existing SportX account **only** on a verified matching email |
| No Socialite | Verification is performed directly; Socialite is not required |

> **Deviation from `Integration-Architecture.md` §6.1:** the earlier spec named Laravel Socialite. Socialite is skipped because the flow is **native mobile → backend**, not a server-side OAuth redirect. Socialite's redirect-based flow adds a browser hop the Flutter app does not need, and direct verification keeps the audience check explicit and auditable.

---

## 2. Why ID tokens

The mobile app already has a Google credential in hand. Sending an **access token** would force the backend to call Google's userinfo endpoint on every login — an extra network round trip, an extra rate-limit surface, and a token whose only purpose is reading an email address that the ID token already carries as a verified claim.

An ID token is **self-verifying**: it contains the user's email *and* Google's assertion that it was issued for a specific `audience`. Verifying signature + `aud` + `exp` + `email_verified` proves the identity cryptographically, with no third-party call.

**Access tokens are still stored** (encrypted) because Google optionally returns them alongside the ID token, enabling future provider APIs without a re-consent prompt. They are never used for authentication.

---

## 3. Flow

```
┌──────────────┐                        ┌──────────────────┐              ┌──────────────┐
│ Flutter app  │                        │  Laravel API     │              │   Google     │
└──────┬───────┘                        └────────┬─────────┘              └──────┬───────┘
       │                                         │                               │
       │  1. GoogleSignIn.signIn()               │                               │
       ├────────────────────────────────────────┼──────────────────────────────►│
       │                                         │      (native account picker)  │
       │  ◄──────────────────────────────────────┼──────────────────────────────┤
       │     GoogleSignInAuthentication          │                               │
       │                                         │                               │
       │  2. POST /auth/google                   │                               │
       │     { id_token, role? }                │                               │
       ├────────────────────────────────────────►│                               │
       │                                         │  3. Verify JWT signature      │
       │                                         │     against JWKS             │
       │                                         │     (cached 24h)              │
       │                                         ├──────────────────────────────►│
       │                                         │  4. aud == GOOGLE_CLIENT_ID   │
       │                                         │  5. exp not elapsed           │
       │                                         │  6. email_verified == true    │
       │                                         │                               │
       │                                         │  7. Resolve account:          │
       │                                         │     a. social_accounts match  │
       │                                         │     b. users.email match      │
       │                                         │        (verified → link)      │
       │                                         │     c. create user + role      │
       │                                         │                               │
       │  ◄──────────────────────────────────────┤                               │
       │  200 { token, user, needs_onboarding,  │                               │
       │        linked, created }                │                               │
       │                                         │                               │
       │  8. POST /me/device-tokens              │                               │
       │     (register FCM token — §FCM doc)    │                               │
       ├────────────────────────────────────────►│                               │
```

Steps 1–2 are the only client-side work. Everything from step 3 is server-side and synchronous; **no browser redirect is ever involved.**

---

## 4. Data model

### `social_accounts`

Replaces the prototype `users.google_id` column. A join table rather than a column, so a second provider (Apple Sign In is the obvious candidate for an iOS-first app) needs no migration.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | bigint unsigned | PK | |
| `user_id` | FK → `users.id` | `constrained()`, `cascadeOnDelete` | |
| `provider` | `string(32)` | index | `google` today; a string, not an enum, so providers can be added freely |
| `provider_user_id` | `string(191)` | **unique with `provider`** | Google's `sub` claim — stable for the life of the Google account |
| `email` | `string(191)` | nullable | Snapshot at link time; used for conflict detection |
| `name` | `string(191)` | nullable | |
| `avatar_url` | `string(500)` | nullable | |
| `access_token` | `text` | nullable | **`encrypted` cast** |
| `refresh_token` | `text` | nullable | **`encrypted` cast** |
| `token_expires_at` | `timestamp` | nullable | |
| `scopes` | `string` | nullable | |
| `created_at` / `updated_at` | timestamp | | |

**Indexes**

| Name | Columns | Purpose |
|---|---|---|
| `social_accounts_provider_user_unique` | `provider`, `provider_user_id` | login lookup; guarantees one identity → one user |
| `social_accounts_user_id_provider_index` | `user_id`, `provider` | "linked accounts" screen |

> **Why `sub` and not `email` as the key.** Email addresses are mutable and, for consumer `@gmail.com` accounts, **not actually unique** — `a.b@gmail.com` and `ab@gmail.com` are distinct mailboxes. Google's `sub` is a stable opaque identifier. Keying on email would let one person hold two accounts and, worse, allow an account-takeover if a provider ever allowed address reassignment.

> **`users.google_id` is dropped.** Two columns storing the same fact drift apart, and the drop is the only way to guarantee the composite unique constraint is actually enforced. Handled by `2026_10_01_000001_create_social_accounts_table`.

### Model

`App\Models\SocialAccount`

- `$fillable`: `user_id, provider, provider_user_id, email, name, avatar_url, access_token, refresh_token, token_expires_at, scopes`
- `$hidden`: `access_token`, `refresh_token`
- Casts: `access_token` / `refresh_token` → `encrypted`; `token_expires_at` → `datetime`
- Relations: `user()` (BelongsTo), plus `google()` and `forProvider()` scopes
- Registered in the morph map as `social_account` for polymorphic notification/audit targets

> **`encrypted` cast on `SocialAccount` is not a nicety.** SportX stores one live OAuth credential pair per linked account. Unencrypted, a database dump would yield refresh tokens for the entire user base — enough to impersonate every linked user at Google.

---

## 5. Token verification

`App\Services\GoogleAuthService::verifyIdToken()` performs six checks, and **any** failure aborts the request:

| # | Check | Rejection reason |
|---|---|---|
| 1 | JWT structure (3 parts, decodable header) | `Malformed token` |
| 2 | `alg` is **RS256** — never `none`, never HS256 | `Unsupported algorithm` |
| 3 | Signature against Google's JWKS (fetched from `https://www.googleapis.com/oauth2/v3/certs`, cached 24h, refetched on unknown `kid`) | `Invalid signature` |
| 4 | `aud` contains the configured `GOOGLE_CLIENT_ID` | `Token issued for another app` |
| 5 | `exp` in the future (with a 60s clock-skew allowance) | `Token expired` |
| 6 | `email_verified === true` | `Google has not verified this email` |

Optional seventh check: `hd` must equal `GOOGLE_WORKSPACE_HD` when set — restricts sign-in to a single Workspace domain for a B2B/private deployment.

> **Check 2 is non-negotiable.** Accepting `alg` from the token header without pinning it to RS256 is the classic JWT vulnerability — an attacker can re-sign a token with HMAC using the public key as the secret. `google/auth` pins the algorithm internally, but the service asserts it explicitly as defence in depth and so the failure is legible in logs.

> **Check 6 is the security foundation of §6.** Everything about account linking rests on the fact that Google, not the user, asserts this email is theirs.

### JWKS caching

| Setting | Value | Rationale |
|---|---|---|
| Cache key | `google.jwks.{sha1(audience)}` | Separate caches per client ID |
| TTL | 24h | Google rotates keys rarely |
| Unknown `kid` | Immediate refetch, then fail if still absent | Handles rotation without waiting for TTL |
| Failure mode | Fail closed | Never "skip verification" on network trouble |

---

## 6. Account resolution

```
verified Google profile (sub, email, email_verified=true)
        │
        ▼
 social_accounts WHERE provider='google' AND provider_user_id=sub
        │
        ├── FOUND ──────────────────────► update snapshot, sign in (step 6a)
        │
        └── NOT FOUND
             │
             ▼
       users WHERE LOWER(email) = LOWER(google email)
             │
             ├── FOUND, status active ─────► link identity, sign in (6b)
             ├── FOUND, status pending ────► link identity, return 403
             │                                PENDING_APPROVAL — do NOT
             │                                bypass the approval gate
             ├── FOUND, suspended/deleted ──► 403 ACCOUNT_DISABLED
             │
             └── NOT FOUND
                  │
                  ▼
             GOOGlE_ALLOW_SIGNUP ?
             ├── no  ──────────────────────► 403 SIGNUP_DISABLED
             └── yes ──► create user + social_accounts row (6c)
```

### 6a. Known identity

`sub` matches an existing `social_accounts` row → sign in. The snapshot columns (`email`, `name`, `avatar_url`, tokens) are refreshed, so a Google profile rename propagates.

### 6b. Link to an existing SportX account

A SportX user already exists with that email and the Google email is verified → the identity is **linked** and the user is signed in.

This is safe *because* `email_verified` was checked at step 6: Google is asserting control of the mailbox, and SportX independently treats that address as verified, so the two identities provably describe the same person.

Rules:

- **Only auto-link accounts that have already verified their email.** Linking to an unverified SportX account would let an attacker who registers the address first (before the owner does) capture the Google identity.
- **`status = 'pending'` accounts are linked but refused login** with `PENDING_APPROVAL` — Google sign-in must not become a way around the coach/scout approval gate.
- **`status = 'suspended' | 'deleted'` → 403 `ACCOUNT_DISABLED`**, even though the identity matched.

### 6c. New registration

`GOOGLE_ALLOW_SIGNUP=true` (default) creates the account. The role comes from:

1. `role` in the request body — **validated against `GOOGLE_ALLOWED_ROLES`**, an allow-list. An unvalidated `role` here is a privilege-escalation hole.
2. Otherwise `GOOGLE_DEFAULT_ROLE` (default `athlete`).

The approval gate applies exactly as for password registration:

| Role | Initial `status` |
|---|---|
| `athlete`, `academy`, `organizer` | `active` |
| `coach`, `scout` | `pending` unless the corresponding `auto_approve_*` platform setting is on |

A `WelcomeMail` is queued and — when the account is `pending` — `AccountApprovedMail` / `AccountRejectedMail` fire on the admin decision (see `Email-Provider-Architecture.md` §7).

---

## 7. API contract

### `POST /auth/google`

Unauthenticated. Throttled at `10,1` alongside the other credential endpoints.

**Request**

```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ii4uLiJ9...",
  "role": "athlete"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `id_token` | string | **yes** | The `credential` returned by `GoogleSignIn.authentication.idToken` |
| `role` | string | no | Ignored on an existing account. Validated against `GOOGLE_ALLOWED_ROLES` on signup |

**Response 200**

```json
{
  "token": "1|abcdefghijklmnop...",
  "user": {
    "id": 42,
    "role": "athlete",
    "name": "Kiran Patel",
    "email": "kiran@example.com",
    "phone": null,
    "email_verified_at": "2026-10-04T09:12:00+00:00",
    "status": "active",
    "social_links": null
  },
  "needs_onboarding": true,
  "linked": false,
  "created": true
}
```

| Field | Meaning |
|---|---|
| `linked` | `true` when an existing SportX account was linked rather than created |
| `created` | `true` when this call created the SportX account |
| `needs_onboarding` | Role profile incomplete → the client routes to onboarding (6b/6c both commonly return `true`) |

**Errors**

| Code | HTTP | Meaning | Client behaviour |
|---|---|---|---|
| `INVALID_ID_TOKEN` | 401 | Malformed, bad signature, wrong `aud`, expired | Clear error; do not retry |
| `EMAIL_NOT_VERIFIED` | 401 | `email_verified` not true | Prompt to verify with Google |
| `ACCOUNT_DISABLED` | 403 | Matched a `suspended`/`deleted` account | Show support contact |
| `PENDING_APPROVAL` | 403 | Matched a `pending` account | Show pending-approval screen |
| `SIGNUP_DISABLED` | 403 | Unknown identity and `GOOGLE_ALLOW_SIGNUP=false` | Fall back to password registration |
| `INVALID_ROLE` | 422 | `role` outside `GOOGLE_ALLOWED_ROLES` | Field error on `role` |
| — | 429 | Throttle exceeded | Back off |

### Supporting endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/me/social-accounts` | Any | Linked identities for the current user |
| DELETE | `/me/social-accounts/{provider}` | Any | Unlink. **Refuses to unlink the only credential when `users.password` is null** |
| POST | `/me/social-accounts/google/refresh` | Any | Re-consent to refresh revoked tokens |

---

## 8. Independence from the Gmail email provider

Google supplies two entirely separate capabilities, and they are configured, credentialed and failure-scoped independently:

| | Google **sign-in** | Google **email** |
|---|---|---|
| Google credential | OAuth **client ID** + optional secret | Gmail API **refresh token** or service account |
| Env | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI`, `GOOGLE_WORKSPACE_HD` | `GMAIL_*` (§`Email-Provider-Architecture.md` §8.3) |
| Network dependency | Google JWKS endpoint (cached 24h) | Gmail API endpoint (every send) |
| Failure impact | **Sign-in** unavailable; email/password login unaffected | **Email** unavailable; sign-in unaffected; push/in-app unaffected |
| Admin control | `GOOGLE_ALLOW_SIGNUP`, `GOOGLE_ALLOWED_ROLES` | `MAIL_PROVIDER` switch |

A valid deployment: Google sign-in + Zoho SMTP. Equally valid: no Google sign-in + Gmail API email delivery. Neither implies the other.

---

## 9. Security summary

| Threat | Control |
|---|---|
| Forged / re-signed token | `alg` pinned to RS256; signature verified against JWKS |
| Token minted for another app | `aud` checked against `GOOGLE_CLIENT_ID` |
| Replayed token | `exp` enforced with 60s skew allowance |
| Unverified mailbox as identity | `email_verified` must be `true` |
| Account takeover via auto-link | Link only to an **already-verified** SportX account |
| Approval-gate bypass | `pending` accounts linked but refused login |
| Privilege escalation via `role` | `role` validated against `GOOGLE_ALLOWED_ROLES` |
| Cross-tenant `sub` confusion | `provider` + `provider_user_id` unique composite |
| Token theft via API | `access_token`/`refresh_token` in `$hidden` and never in any response |
| Token theft via database | `encrypted` cast (AES-256-GCM, app key) |
| Token theft via logs | Claims logged by `sub`/`aud` only — no raw token, no PII beyond email |
| Verification bypass on network error | Fail closed; no "skip verify if JWKS unreachable" path |
| Abuse / brute force | `throttle:10,1` on the endpoint |

> **Distinct from `SocialLinksController`.** `PUT /me/social-links` stores *display* URLs a user pastes into their profile. Those are never used for authentication — anyone can write a URL. `GoogleAuthService` verifies cryptographically and accepts nothing a client supplies as identity. Keeping the two separate prevents a future refactor from accidentally treating a display field as a credential.

---

## 10. Flutter implementation

### Packages

```yaml
google_sign_in: ^6.2.1      # account picker + native credential
google_fonts: ^6.2.1        # already present
```

`google_sign_in: ^7+` changes the API surface — pin explicitly rather than relying on `^`.

> **Web caveat.** `google_sign_in` does not support the Firebase Auth path on web; Flutter web falls back to the standard password flow. The API endpoint is provider-agnostic, so enabling Google sign-in on web later needs no backend change.

### Auth flow

```dart
// 1. Native account picker
final GoogleSignIn googleSignIn = GoogleSignIn(
  clientId: Platform.isIOS ? DefaultFirebaseOptions.currentPlatform.iosClientId : null,
  scopes: ['email', 'profile'],
);

final GoogleSignInAccount account = await googleSignIn.signIn();
final idToken = account.authentication.idToken;

// 2. Exchange with the backend
final response = await dio.post('/auth/google', data: {
  'id_token': idToken,
  if (selectedRole != null) 'role': selectedRole,
});

// 3. Persist the Sanctum token exactly as password login does
await storage.saveToken(response.data['token']);
```

`AuthNotifier` gains `signInWithGoogle()` alongside `login()` and `register()`. On success it must run the **same** post-login sequence as password login — persist the token, call `checkAuth()`, and call `_registerFcmToken()` so push notifications attach to the new session.

### Platform configuration

| Platform | Requirement |
|---|---|
| Android | `serverClientId` in `android/app/build.gradle.kts` (from `google-services.json` → `oauth_client`) |
| iOS | `REVERSED_CLIENT_ID` in `Info.plist` **and** the URL scheme from `Info.plist`'s `CFBundleURLSchemes` |
| Both | The package name / bundle ID must match the OAuth client's authorised application exactly |

> **Android trap.** `google-services.json` in the repo currently has an **empty `oauth_client` array**. Without a web client entry there is no `serverClientId`, and Android sign-in fails with `DEVELOPER_ERROR` / "Default FirebaseApp is not initialized" even though the app otherwise works. Populate `oauth_client` in the Firebase console first.

### Screen placement

`Continue with Google` appears on **Login** and **Sign Up**, below the primary action, separated by an "or" rule. Google returns the user *and* their verified email, so there is no account-linking friction for a returning user.

Per `API-Specification.md` §1, sign-up must still capture the **role** before the Google button, since role drives approval routing. Suggested behaviour: role picker → "Continue with Google" → pre-filled profile during onboarding.

---

## 11. Testing

| Suite | Coverage |
|---|---|
| `GoogleAuthServiceTest` | Valid token accepted; each of the six checks rejects with its own reason; JWKS cached and refetched on unknown `kid` |
| `GoogleAuthTest` | New signup; link to a verified existing account; `pending` → 403 `PENDING_APPROVAL`; `suspended` → 403 `ACCOUNT_DISABLED`; `role` outside the allow-list → 422; repeat login reuses `social_accounts` |
| `SocialAccountTest` | Token encryption round-trip; `$hidden` excludes tokens from `toArray()` |

Verification is a single injectable boundary (`GoogleAuthService`), so feature tests fake the verified-claims array rather than minting real RS256 JWTs:

```php
$this->mock(GoogleAuthService::class)
     ->shouldReceive('verifyIdToken')
     ->andReturn(['sub' => '1009…', 'email' => 'kiran@example.com', 'email_verified' => true]);

$this->postJson('/api/v1/auth/google', ['id_token' => 'x'])
     ->assertOk()
     ->assertJsonPath('created', true);
```

The RSA/JWKS path itself is covered by a unit test using a locally generated key pair against a stubbed JWKS endpoint.

---

## 12. Rollout checklist

1. Create a Google Cloud project; enable the **People API** and **Gmail API** if email is also being delivered (§`Email-Provider-Architecture.md` §5.2).
2. Configure the OAuth consent screen (External, with test users for dev).
3. Create **three** OAuth clients: Android (`package_name` + SHA-1), iOS (bundle ID), and Web.
4. Set `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_ALLOW_SIGNUP=true`, `GOOGLE_DEFAULT_ROLE=athlete`.
5. Run `php artisan migrate` — `2026_10_01_000001` creates `social_accounts` and drops `users.google_id`.
6. Populate `oauth_client` in `google-services.json` so Android gets a `serverClientId`.
7. Add `google_sign_in` to `pubspec.yaml`; configure `serverClientId` and `REVERSED_CLIENT_ID`.
8. Add the button to Login and Sign Up; wire `signInWithGoogle()` in `AuthNotifier`.
9. Set `GOOGLE_WORKSPACE_HD` if the deployment is single-tenant.
10. Confirm `users.google_id` is absent from `User::$fillable` and `$hidden`.

---

## 13. Open items

| ID | Item | Status |
|---|---|---|
| **D9** | Google sign-in in MVP scope | **CLOSED** — P0, implemented |
| AS-64 | Apple Sign In | **OPEN** — `social_accounts.provider` is a string precisely so this needs no migration |
| AS-65 | Cross-provider account linking ("link Google to an existing account" with a password step) | **OPEN** — current flow links automatically on verified email only; explicit linking with a credential re-confirmation is safer but adds a step |
| AS-66 | Google People API for contact import | **OUT OF SCOPE** — consent-heavy, no MVP requirement |