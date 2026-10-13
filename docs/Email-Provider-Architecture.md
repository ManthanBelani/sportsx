> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

# Email Provider Architecture — SportX India (Dual SMTP + Gmail)

> **Status:** Implemented in `sportx-api`. Extends the abstract `OtpProvider` seam described in `Integration-Architecture.md` §6.2 and closes **AS-03** for the **email** half (SMS vendor selection remains open).
>
> **Scope:** every transactional and notification email SportX sends. Covers OTP delivery, email verification, password reset, account approval/rejection, welcome, and push-failure fallback email.
>
> **Related docs:** `Google-Authentication.md` (Google is both a *sign-in* provider and an *email* provider — the two are deliberately independent) · `FCM-Notification-System.md` (the email fallback channel) · `Security-and-NonFunctional.md` §2 (data protection).

---

## 1. Summary

SportX sends email over **one of two first-class providers**, selected by configuration and switchable at runtime without a deploy:

| | **Provider A — SMTP** | **Provider B — Gmail** |
|---|---|---|
| Transport | `smtp` (Symfony ESMTP) | `gmail-api` (Gmail REST API v1) |
| Transport class | framework built-in | `App\Mail\Transport\GmailApiTransport` |
| Auth | `MAIL_USERNAME` + `MAIL_PASSWORD` | OAuth2 (`refresh_token` or service account + domain-wide delegation) |
| Daily ceiling | provider-dependent (Gmail SMTP: 500/day consumer, 2000/day Workspace) | Gmail API quota (default 1,000,000 units/day; `messages.send` = 100 units → ~10,000 sends/day) |
| Works with 2FA-enforced Workspace | Only via App Password, and only if IP allow-listing permits | Yes, natively |
| Works with consumer `@gmail.com` | Yes (App Password) | Yes |
| Best for | Zoho / SES / SendGrid / Mailgun / Brevo / any relay | Accounts where SMTP login is blocked |
| Configured by | `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD` | `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN` (or `GMAIL_SERVICE_ACCOUNT_EMAIL`, `GMAIL_PRIVATE_KEY`) |

**Both are always available in parallel.** The active one is chosen at runtime; the other stays configured and becomes the automatic failover target. Ops can flip the switch from the admin panel in under a second if Gmail starts rejecting mail (or the reverse), without touching `.env` or rebuilding the config cache.

---

## 2. Why two providers

The motivating constraint is **Google Workspace with enforced 2FA**. Such accounts:

1. refuse "less secure app" passwords from unfamiliar source IPs, and
2. refuse App Passwords entirely unless an administrator pre-generates them.

The Gmail REST API sidesteps both: it authenticates with OAuth2, so no long-lived password ever leaves the secret store. Separately, the consumer Gmail SMTP cap of **500 messages/day** is far below what a national platform broadcasting to coaches and scouts can generate, while the Gmail API quota is roughly 20× higher.

Running SMTP alongside Gmail therefore gives an escape hatch in both directions — an ops team is never locked into one vendor.

> **Design decision:** the two providers are configured **independently of the Google *sign-in* integration**. Signing users in with Google says nothing about where SportX *sends* mail. A deployment may use Gmail sign-in with Zoho SMTP delivery, or Gmail SMTP with no Google sign-in at all. See `Google-Authentication.md` §8.

---

## 3. Architecture

```
                        ┌──────────────────────────────────────────┐
                        │        SportXMail (abstract mailable)    │
                        │  ShouldQueue · onQueue('mail')           │
                        │  $tries = 3 · $backoff = [10,30,90]      │
                        └───────────────────┬──────────────────────┘
                                            │
                          resolves at send time (not boot time)
                                            │
                                            ▼
                        ┌──────────────────────────────────────────┐
                        │      MailProviderService                 │
                        │  1. platform_settings.json override      │
                        │  2. MAIL_PROVIDER env                    │
                        │  3. "smtp"                               │
                        └───────────────────┬──────────────────────┘
                                            │
                            config(['mail.default' => ...])
                                            │
                     ┌──────────────────────┴───────────────────────┐
                     ▼                                              ▼
        ┌────────────────────────┐                    ┌────────────────────────┐
        │  sportx_failover       │                    │  direct provider       │
        │  (Symfony Failover)    │                    │  (MAIL_FAILOVER_ENABLED│
        │                        │                    │   =false)               │
        └───────────┬────────────┘                    └───────────┬────────────┘
                    │                                                 │
        ┌───────────┼───────────────┬──────────────────┐              │
        ▼           ▼               ▼                  ▼              ▼
   [1] Gmail   [2] SMTP        [3] log            inactive        [active]
   (gmail-api)  (smtp)        (dev/test)         (filtered out)
        │           │
        │           └─────────────────────────────────────────┐
        ▼                                                     ▼
 POST gmail.googleapis.com                        ESMTP/STARTTLS
 /gmail/v1/users/me/messages/send                (any relay)
        │                                                     │
        └──────────────────► Gmail / relay ───────────────────┘
                                    │
                                    ▼
                         User inbox (OTP, verification, ...)
```

**Key points:**

- Resolution happens **at send time**, not at boot. Because both the synchronous path (`Mailable::send`) and the queued path (`SendQueuedMailable::handle`) resolve `mail.default` when they execute, a runtime provider switch affects messages still sitting in the queue.
- The **failover chain is filtered** to providers that actually have credentials. A half-configured provider is skipped rather than tried and failed.
- `log` is always the terminal fallback, so an outage degrades to log-inspection rather than an exception.
- Everything is **queued**. A slow SMTP handshake can never add latency to an API request.

---

## 4. Provider A — SMTP

Configured in `config/mail.php` → `mailers.smtp` (standard Laravel block, unchanged apart from a configurable timeout).

### 4.1 Google / Gmail over SMTP

1. Enable 2-Step Verification on the sending Google account.
2. Generate an **App Password** (16 characters) at <https://myaccount.google.com/apppasswords>.
3. Set:

```dotenv
MAIL_PROVIDER=smtp
MAIL_SCHEME=smtps          # port 465
MAIL_HOST=smtp.gmail.com
MAIL_PORT=465
MAIL_USERNAME=no-reply@sportx.in
MAIL_PASSWORD=<16-char app password>
```

For STARTTLS on 587 use `MAIL_SCHEME=smtp`. Gmail rejects plaintext connections on port 25.

> **Limitation:** App Passwords are refused for accounts with enforced 2FA unless an admin generates them, and Google flags logins from new datacentres. **If the sender is a Workspace domain with 2FA enforced, use Provider B.**

### 4.2 Other relays

The block is vendor-neutral — only host/port/credentials change:

| Relay | Host | Port | Scheme |
|---|---|---|---|
| Amazon SES | `email-smtp.{region}.amazonaws.com` | 587 / 465 | smtp / smtps |
| SendGrid | `smtp.sendgrid.net` | 587 | smtp |
| Mailgun | `smtp.mailgun.org` | 587 | smtp |
| Zoho | `smtp.zoho.com` / `smtp.zoho.in` | 465 / 587 | smtps / smtp |
| Brevo (Sendinblue) | `smtp-relay.brevo.com` | 587 | smtp |
| Self-hosted Postfix | app host | 587 | smtp |

### 4.3 From address

The global from address is `MAIL_FROM_ADDRESS` / `MAIL_FROM_NAME`. For deliverability the sending domain must publish SPF, DKIM and (ideally) DMARC:

```
sportx.in.               TXT   "v=spf1 include:_spf.google.com ~all"
_default._domainkey      TXT   "v=DKIM1; k=rsa; p=<public key>"
_dmarc.sportx.in.        TXT   "v=DMARC1; p=quarantine; rua=mailto:dmarc@sportx.in"
```

A Gmail API sender additionally requires Google **Publish → Gmail API → Send mail as your users** (see §5.3).

---

## 5. Provider B — Gmail API (OAuth2)

Delivered through the Gmail REST API rather than SMTP, implemented as `App\Mail\Transport\GmailApiTransport` (a Symfony `AbstractTransport` subclass registered via `Mail::extend('gmail-api', …)`).

### 5.1 Why not XOAUTH2 over SMTP

Symfony's ESMTP transport cannot refresh an expired OAuth2 bearer token mid-session. Google access tokens live ~1 hour, so XOAUTH2 over SMTP needs either long-lived passwords (defeating the point) or a custom transport anyway. Calling the REST API keeps token refresh in one place with a single cache entry.

### 5.2 Auth mode `user` (recommended for MVP)

An OAuth refresh token issued by a one-time consent flow. Lowest operational overhead — no service-account key to rotate.

```dotenv
MAIL_PROVIDER=gmail
GMAIL_AUTH_MODE=user
GMAIL_CLIENT_ID=<web-app client id>.apps.googleusercontent.com
GMAIL_CLIENT_SECRET=<client secret>
GMAIL_REFRESH_TOKEN=<refresh token, offline access>
```

One-time consent (run once, locally or via the gcloud CLI):

```bash
# 1. Open this URL as the sending account and approve
#    scope=https://mail.google.com/  access_type=offline  prompt=consent
# 2. Exchange the returned code:
curl -s https://oauth2.googleapis.com/token \
  -d client_id="$GMAIL_CLIENT_ID" \
  -d client_secret="$GMAIL_CLIENT_SECRET" \
  -d refresh_token="$GMAIL_REFRESH_TOKEN_PLACEHOLDER" \
  -d grant_type=refresh_token \
  -d redirect_uri=http://localhost
```

Enable **Gmail API** in the Google Cloud project first (APIs & Services → Library).

### 5.3 Auth mode `service_account` (production / multi-sender)

Domain-wide delegation: a service account signs in *as* a Workspace user, so no human consent flow and no long-lived refresh token in the app's env.

```dotenv
MAIL_PROVIDER=gmail
GMAIL_AUTH_MODE=service_account
GMAIL_SERVICE_ACCOUNT_EMAIL=sportx-mailer@sportx-prod.iam.gserviceaccount.com
GMAIL_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
GMAIL_IMPERSONATE_USER=no-reply@sportx.in
```

Setup steps:

1. Create the service account in Google Cloud; create and download a JSON key.
2. In **Admin console → Security → Access and data control → API controls → Domain-wide delegation**, add Client ID + scope `https://mail.google.com/`.
3. In **Admin console → Apps → Google Workspace → Gmail → Send mail as your users**, verify the sender address (and its alias) before first use — unverified senders are silently rewritten or rejected.
4. Grant the service-account email permission to send as the impersonated user, or use a shared-domain address.

> **Secret handling:** `GMAIL_PRIVATE_KEY` is frequently stored with literal `\n` sequences by CI secret managers. The transport normalises both forms, so either a raw PEM or a single-line base64 body works.

### 5.4 Token caching

Access tokens are cached under `GMAIL_TOKEN_CACHE_KEY` (default `sportx.gmail.access_token`) with a 60-second safety margin on expiry. On credential rotation call `POST /admin/email-settings/clear-token-cache` — the next send mints a fresh token.

---

## 6. Provider resolution and failover

### 6.1 Resolution order

`MailProviderService::activeProvider()` returns the first match:

1. **Admin override** — `mail_provider` key in `storage/app/platform_settings.json`
2. **`MAIL_PROVIDER`** env → `config('sportx.mail.provider')`
3. Default — `smtp`

### 6.2 Failover

With `MAIL_FAILOVER_ENABLED=true` (default), `mail.default` becomes `sportx_failover`, a Symfony `FailoverTransport` whose chain is derived from `config('sportx.mail.failover.chain')` (`gmail → smtp → log`), **filtered to configured providers** and reordered so the active provider is tried first.

Set `MAIL_FAILOVER_ENABLED=false` to send strictly through the active provider — useful for local development, where you want a misconfiguration to fail loudly rather than silently succeed through `log`.

### 6.3 Switching at runtime

```http
POST /api/v1/admin/email-settings/provider
{ "provider": "gmail" }
```

Persists to `platform_settings.json`, purges resolved mailer instances, and takes effect on the next send. No queue restart, no config cache rebuild. Reversible at any time, and the change is captured by the admin audit log (`Security-and-NonFunctional.md` §9).

---

## 7. Email catalogue

All messages extend `App\Mail\SportXMail`, which supplies queueing, retry policy, deep-link construction and failure logging. Subclasses implement only `envelope()` and `content()`.

| Mailable | View | Trigger | Criticality |
|---|---|---|---|
| `EmailOtpMail` | `emails/otp` | `POST /auth/send-otp`, `/resend-otp` | **Blocking** — the API returns `sent: false` if this cannot be handed to the provider |
| `VerifyEmail` | `emails/verify-email` | `POST /auth/register` (link flow), `/auth/resend-verification` | High |
| `PasswordResetMail` | `emails/password-reset` | `POST /auth/forgot-password` | High |
| `AccountApprovedMail` | `emails/account-approved` | Admin approves a `coach` / `scout` registration | High — this is the notification the applicant is waiting on |
| `AccountRejectedMail` | `emails/account-rejected` | Admin rejects or suspends an account | High |
| `WelcomeMail` | `emails/welcome` | Post-registration / post-verification | Medium |
| `NotificationFallbackMail` | `emails/notification-fallback` | Push could not be delivered (no devices / all tokens invalid) | Medium |

> **Gap closed:** before this change `App\Mail\VerifyEmail` existed but was **never instantiated anywhere**, and the only outbound email in the entire application was `PasswordResetMail`. Admin approve/reject endpoints flipped a database column and told nobody. See §12.

### 7.1 Deep links

Every mailable builds links through `SportXMail::deepLink()`, rooted at `FRONTEND_URL` (falling back to `APP_URL`):

```
{FRONTEND_URL}/verify-email?token=...
{FRONTEND_URL}/reset-password?token=...
{FRONTEND_URL}/otp-verify
```

Set `FRONTEND_URL` in production — leaving it at `APP_URL` (the API host) produces dead links.

### 7.2 Templates

All views extend `emails/layout.blade.php`: table-based, inline-styled, no external CSS, no web fonts. This is deliberate — Gmail, Outlook and Apple Mail strip `<style>` blocks and render with an HTML engine old enough to predate flexbox.

Tone and brand rules:

| Category | Colour | Rule |
|---|---|---|
| Neutral / transactional | `#1677ff → #0d47a1` | default |
| Success / approval | `#16a34a → #15803d` | |
| Warning / rejection | `#dc2626 → #991b1b` | |

Every template carries a **never-asked-for-this** line. OTP and password-reset mails are the two most phished SportX messages; an explicit disclaimer is the cheapest control available.

---

## 8. Configuration reference

### 8.1 Provider selection

| Env | Default | Meaning |
|---|---|---|
| `MAIL_PROVIDER` | `smtp` | `smtp` \| `gmail` |
| `MAIL_FAILOVER_ENABLED` | `true` | Wrap the chain in a failover transport |
| `MAIL_FAILOVER_RETRY_AFTER` | `60` | Seconds before a failed provider is retried |
| `MAIL_TEST_RECIPIENT` | — | Default recipient for connection tests |

### 8.2 SMTP

`MAIL_SCHEME`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_TIMEOUT`, `MAIL_EHLO_DOMAIN`, `MAIL_FROM_ADDRESS`, `MAIL_FROM_NAME`.

### 8.3 Gmail API

`GMAIL_AUTH_MODE` (`user` \| `service_account`), `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN`, `GMAIL_SERVICE_ACCOUNT_EMAIL`, `GMAIL_PRIVATE_KEY`, `GMAIL_PRIVATE_KEY_ID`, `GMAIL_IMPERSONATE_USER`, `GMAIL_PROJECT_ID`, `GMAIL_TOKEN_CACHE_KEY`, `GMAIL_TIMEOUT`.

### 8.4 Frontend

`FRONTEND_URL` — root for every deep link.

---

## 9. Security

| Control | Implementation |
|---|---|
| Credentials in env only | Never written to the database, never returned by an API response. `status()` exposes host/port/username/client-id but never passwords or tokens. |
| At-rest encryption | `SocialAccount::access_token` / `refresh_token` use the `encrypted` cast. `GMAIL_PRIVATE_KEY` lives only in the deployment secret store. |
| OTP codes | bcrypt-hashed in `otp_codes.code_hash`; the plaintext exists only in the outbound email body. |
| Token display | OAuth access tokens are held in cache with a 60-second expiry margin and are never logged (only presence/absence and HTTP status). |
| Log hygiene | `GmailApiTransport` logs status codes and Gmail error messages, never payloads or credentials. |
| Admin gating | Every email-settings endpoint requires `role:admin` + `admin.2fa`. |
| Abuse control | Send-once-per-cooldown enforced twice: at the endpoint (`throttle`) **and** at the mailable (`EmailOtpMail::throttle`), so a replayed request cannot spam a mailbox. |
| Transport security | Enforced by TLS: `smtps` on 465, `smtp` + STARTTLS on 587. `MAIL_SCHEME=null` is rejected by Gmail and SES in production. |

---

## 10. Failure handling

| Stage | Behaviour |
|---|---|
| Queue dispatch | Message lands on the `mail` queue. A queue-worker outage delays but never loses mail. |
| Transient failure (421/450/451/timeout) | Failover advances to the next provider; retries up to 3× with `[10s, 30s, 90s]` backoff. |
| Permanent failure (535 auth, 550 blocked) | Same retry budget, then `SportXMail::failed()` logs mailable, provider, recipients and error. |
| All providers exhausted | `log` captures the rendered message so it can be inspected and replayed. |
| Gmail token expired mid-flight | Token is cached with a 60s margin; a stale token raises a 401 which fails the send and retries against a freshly minted token. |

**Monitoring.** Alert on:

- `log.mailer.failed` events (or `SportX mail failed permanently`) — non-zero in any 15-minute window is a page.
- Queue depth on `mail` — sustained depth means workers are wedged, not that delivery is failing.
- `MailProviderService::testConnection()` on a schedule (hourly) as an active probe, so a provider failure surfaces **before** a user reports a missing OTP.
- Gmail `messages.send` quota headroom and SMTP reputation (bounce/complaint rate).

---

## 11. Testing

Feature tests drive `MAIL_MAILER=array`, and `MailProviderService::activeMailer()` short-circuits under `runningUnitTests()` so the framework's test mailer is never overridden. `Mail::assertSent()` and `Mail::fake()` therefore work unmodified.

```php
Mail::fake();

$this->postJson('/api/v1/auth/forgot-password', ['email' => $user->email])
     ->assertOk();

Mail::assertSent(PasswordResetMail::class, fn ($mail) => $mail->hasTo($user->email));
```

| Suite | Coverage |
|---|---|
| `MailProviderServiceTest` | provider resolution order; admin override wins over env; chain filtering drops unconfigured providers; `isConfigured()` per mode |
| `GmailApiTransportTest` | `Http::fake()` against the Gmail endpoint; asserts base64 `raw` payload, headers, and `TransportException` on a 4xx |
| `EmailOtpMailTest` | cooldown throttle; `EmailOtpMail::clearThrottle()` on consumption |
| `AuthEmailTest` | verify-email, forgot/reset-password, OTP send + verify happy paths |

`MailProviderService::testConnection()` is safe to run in tests — it short-circuits to the `log` mailer when the requested provider has no credentials, so it returns a structured `{ ok: false, detail }` rather than throwing.

---

## 12. Migration impact

Schema and behavioural changes introduced alongside this architecture:

| Change | Note |
|---|---|
| `otp_codes` restored | `2026_08_09_000003` dropped the table while `OtpService`, the `OtpCode` model and `PurgeExpiredOtpsJob` still targeted it — OTP was structurally dead. Re-created by `2026_10_01_000002` with the schema the service actually writes. |
| `OtpCode::$fillable` corrected | Listed legacy columns (`phone`, `code`) that no longer existed, so every write was silently discarded by mass-assignment protection. |
| `users.google_id` dropped | Superseded by `social_accounts`; two sources of truth for identity linkage is a security hazard. See `Google-Authentication.md` §4. |
| `VerifyEmail` wired up | Previously imported but never sent. |
| Admin approve/reject now emails | `AdminUserController` and `AdminPanelController` previously returned silently. |
| `notifications.type` widened | `VARCHAR(40)` in MySQL — the enum of three values could not represent the notification vocabulary in `FCM-Notification-System.md` §2. |

> **Run `php artisan migrate` before deploying.** The OTP restore and the `type` widening both require it.

---

## 13. Runbook

**No OTP emails arriving.**

1. `GET /api/v1/admin/email-settings` → confirm `active_provider` and whether that provider reports `configured: true`.
2. `POST /api/v1/admin/email-settings/diagnostics` → distinguishes "credentials missing" from "host unreachable" from "auth rejected".
3. `POST /api/v1/admin/email-settings/test` with an explicit `recipient` → proves the full path end to end.
4. Check the `mail` queue depth and `log` mailer output.
5. Switch provider if the outage is provider-side: `POST /api/v1/admin/email-settings/provider`.

**Gmail returns `403 insufficientPermissions`.** The sending address is not verified as an authorised send-as alias in Workspace admin, or domain-wide delegation has not been granted for the `https://mail.google.com/` scope.

**Gmail returns `401 invalid_grant`.** The refresh token was revoked, was issued to a different OAuth client, or had `access_type=offline` omitted during consent. Re-run the consent flow and update `GMAIL_REFRESH_TOKEN`.

**Gmail returns `403 sender not authorised`.** API abuse detection has flagged the sending account — typically after a spike in bounces or complaints. Check SPF/DKIM/DMARC alignment first, then request a quota review.

**`NoSuchEntity` / `failedPrecondition`.** Service-account mode without an active Workspace subscription, or without the Gmail API enabled in the project.

---

## 14. Open items

| ID | Item | Status |
|---|---|---|
| **AS-59** | Email provider selected | **CLOSED** — dual SMTP + Gmail |
| **AS-60** | SMS/phone OTP vendor | **OPEN** — blocked for the `channel=phone` half of `POST /auth/send-otp`. The `OtpCode.channel` enum already accommodates `phone`. |
| **AS-61** | Transactional email vendor for marketing/broadcast at scale | **OPEN** — admin broadcast currently shares the transactional pool; a bulk sender should eventually be split out. |
| AS-62 | Bounce / complaint webhooks (SES, Mailgun, Postmark) | **OPEN** — would feed suppression lists into `users.notification_prefs`. |
| AS-63 | Scheduled email campaign surface in the admin panel | **OPEN** — not in MVP scope. |