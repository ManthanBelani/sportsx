> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

# Notification System — SportX India (FCM Push + In-App + Email Fallback)

> **Status:** Implemented in `sportx-api` + `sportx_app`. Replaces the placeholder `NotificationProvider` abstraction in `Integration-Architecture.md` §6.3 with a concrete Firebase Cloud Messaging implementation, and closes **AS-03** for the push half.
>
> **Related docs:** `Email-Provider-Architecture.md` (the `email` channel) · `Integration-Architecture.md` §7 (superseded by this document) · `Security-and-NonFunctional.md` §3 (rate limiting) · `Mobile-Architecture.md` §4.

---

## 1. Summary

SportX delivers every user-facing event over up to three channels, driven by **one** notification record:

| Channel | Transport | Availability | Recorded as |
|---|---|---|---|
| **In-app** | `notifications` table, read by `GET /me/notifications` | Always | Source of truth |
| **Push** | Firebase Cloud Messaging HTTP v1 | When a device token is registered | `pushed_at` + `push_status` |
| **Email** | SMTP or Gmail API (`NotificationFallbackMail`) | When push could not be delivered | Separate mailable |

**The core design principle:** the database row is written **first** and is the single source of truth. Push and email are derived from that row. This is what prevents the notification centre and the push tray from ever disagreeing about what happened — a failure mode the previous implementation allowed, since push was dispatched directly with no record of whether it arrived.

```php
NotificationService::send($user, 'enquiry_reply', 'New reply from Kiran', '…');
   │
   ├─ 1. INSERT notifications row                    ← always, transactionally
   │      push_status = 'queued'
   │
   ├─ 2. dispatch NotificationCreated event
   │      └─► SendPushNotificationListener
   │            ├─ read user's notification_prefs    ← honour opt-outs
   │            ├─ load active device tokens
   │            └─ dispatch SendPushNotification job
   │                  ├─ FCM messages:send per token
   │                  ├─ update pushed_at / push_status
   │                  └─ no valid tokens → NotificationFallbackMail
   │
   └─ 3. return Notification
```

---

## 2. Notification types

The original `notifications.type` enum held only `reminder`, `enquiry_reply`, `status_update` — too narrow for the v3 vocabulary, and the MySQL enum made adding a type a migration every time. The column is now `VARCHAR(40)`.

| Type | Emitted when | Category (deep-link route) |
|---|---|---|
| `reminder` | T-2d / T-1d event reminder; expiry sweep | `reminder` |
| `enquiry_reply` | A reply lands on an enquiry thread | `enquiry` |
| `status_update` | Listing/trial/tournament published, closed, flagged | `status` |
| `registration_approved` | Athlete's trial/tournament registration approved | `registrations` |
| `registration_rejected` | Registration rejected | `registrations` |
| `trial_approved` / `trial_rejected` | Admin moderates a trial listing | `my-listings` |
| `tournament_approved` / `tournament_rejected` | Admin moderates a tournament | `my-listings` |
| `account_action` | Account approved, rejected, suspended | `settings` |
| `broadcast` | Admin broadcast / announcement | `announcements` |

Social types (`follow`, `connection_request`, `connection_accepted`, `message`, `mention`) from `Integration-Architecture.md` §7 are folded into the same table with a matching `category` value, so no additional types are needed when those modules ship.

---

## 3. Data model

### `notifications` (extended)

| Column | Type | Notes |
|---|---|---|
| `user_id` | FK → `users` | `cascadeOnDelete` |
| `type` | `varchar(40)` | **widened** from `enum(3)` — §2 |
| `channel` | `varchar(16)` default `in_app` | `in_app` \| `push` \| `email` \| `sms` |
| `title` | `varchar(190)` | |
| `body` | `string` | |
| `category` | `varchar(40)` nullable | client routing key (§2) |
| `image_url` | `varchar(500)` nullable | large image for rich push |
| `priority` | `enum('normal','high')` default `normal` | FCM `android.priority` / APNs push priority |
| `notifiable_type` / `notifiable_id` | morph pair | the triggering entity |
| `action_url` | `varchar(500)` nullable | deep link |
| `metadata` | `json` nullable | extra payload for deep linking |
| `read_at` | timestamp nullable | indexed |
| `pushed_at` | timestamp nullable | when FCM accepted the message |
| `push_status` | `varchar(16)` nullable | `queued` \| `sent` \| `partial` \| `failed` \| `no_devices` |
| `created_at` / `updated_at` | timestamp | |

**Indexes:** `(user_id, read_at, created_at)` (inbox + unread count) and `(type, created_at)` (reminder sweeper).

> **`push_status` is what makes the email fallback safe.** Without it, a retry or a failed send would silently send a duplicate fallback email to a user who already got the push.

### `user_device_tokens`

| Column | Type | Notes |
|---|---|---|
| `user_id` | FK → `users` | `cascadeOnDelete` |
| `token` | `string(500)` | **UNIQUE** — see below |
| `device_type` | `enum('ios','android','web')` | |
| `device_id` | `string` nullable | |
| `is_active` | boolean default true | |
| `last_seen_at` | timestamp nullable | TTL pruning |
| `failure_count` | `unsignedSmallInteger` default 0 | retires repeatedly-rejected tokens |

**Indexes:** `(user_id, is_active)`, **unique `token`**.

> **`token` must be unique.** FCM tokens identify exactly one app installation. With only a non-unique index, the same token could be attached to several users — after a reinstall, both the old user and the new one keep receiving every message. The migration collapses existing duplicates and then adds the constraint.

### `users.notification_prefs` (existing JSON column, now honoured)

```json
{
  "in_app":   { "default": true },
  "push":     { "default": true,  "trial_updates": true, "enquiries": true },
  "email":    { "default": false, "account": true, "announcements": true },
  "categories": { "broadcast": true, "reminder": true }
}
```

> **Previously dead data.** This column existed and was cast, but **no service or controller ever read it**. Every user was pushed unconditionally regardless of what they had set. It is now the gate that `NotificationService` consults before dispatching (§5).

### Legacy `device_tokens` table

A second, parallel table (`device_tokens`, with a `platform` column) exists alongside `user_device_tokens`. **Only `user_device_tokens` is used.** The duplicate is scheduled for removal — `DeviceToken` the model and its table have no readers and are a standing source of confusion about which table is authoritative.

---

## 4. FCM transport

`App\Services\FCMService` talks to the **FCM HTTP v1** API.

> **Correctness fix.** The previous implementation called `messages:sendMulticast` and then read `responses[0].successCount`. **That endpoint does not exist in FCM HTTP v1** — it was part of the retired legacy FCM v1 API and returns `404` against v1. `responses[0]` would then be `null`, and the method silently reported success. Push delivery was effectively a no-op that reported success. The rewrite sends `messages:send` per token, which is the documented v1 contract.

### 4.1 Authentication

| Aspect | Detail |
|---|---|
| Mechanism | OAuth2 service-account JWT → `firebase.messaging` scope |
| Library | `google/auth` (`ServiceAccountCredentials::fetchAccessTokenWithAssertion`) |
| Credentials | `FCM_CREDENTIALS_PATH` — a service-account JSON key |
| Cache key | `fcm_access_token` |
| Cache TTL | `expires_in − 60s` |

### 4.2 Send

```http
POST https://fcm.googleapis.com/v1/projects/{FCM_PROJECT_ID}/messages:send
Authorization: Bearer {access_token}

{
  "message": {
    "token": "{device_token}",
    "notification": { "title": "…", "body": "…", "image": "https://…" },
    "data": { "notification_id": "512", "type": "enquiry_reply", "category": "enquiry", "action_url": "/enquiries/9", "priority": "high" },
    "android": {
      "priority": "high",
      "notification": { "channel_id": "sportx_default", "click_action": "FLUTTER_NOTIFICATION_CLICK" }
    },
    "apns": {
      "headers": { "apns-priority": "10", "apns-push-type": "alert", "apns-sound": "default" },
      "payload": { "aps": { "alert": { "title": "…", "body": "…", "sound": "default" }, "category": "enquiry_reply", "mutable-content": 1 } }
    }
  }
}
```

**Per-message Android channel.** Each notification type maps to an Android channel so users can tune categories independently:

| Channel ID | Types |
|---|---|
| `sportx_default` | fallback |
| `sportx_enquiries` | `enquiry_reply` |
| `sportx_reminders` | `reminder` |
| `sportx_updates` | `status_update`, `*_approved`, `*_rejected` |
| `sportx_announcements` | `broadcast` |

> **Without an explicit `channel_id`, Android silently drops notifications** on API 26+ and logs `NotificationChannel is not set`. This is one of the most common causes of "FCM works but nothing appears".

### 4.3 Token lifecycle

| Event | Behaviour |
|---|---|
| App registers | `POST /me/device-tokens` → upsert on the unique `token`, `last_seen_at = now()`, `is_active = true` |
| Token refresh | `onTokenRefresh` → same endpoint (idempotent) |
| **UNREGISTERED / INVALID_ARGUMENT** | Token is permanently dead → `is_active = false` immediately, row kept for audit |
| **QUOTA_EXCEEDED / RESOURCE_EXHAUSTED** | Transient. `failure_count++`; retired at `FCM_MAX_RETRIES` (default 3). **Not** retired on the first failure |
| `SENDER_ID_MISMATCH` | Token belongs to a different Firebase project → retire; the client sent the wrong `google-services.json` |
| Logout | All of the user's tokens → `is_active = false` |
| No activity for `DEVICE_TOKEN_TTL_DAYS` (default 120) | `PruneStaleDeviceTokensJob` retires them |

> **The `failure_count` distinction matters.** A device in aeroplane mode produces a transient failure. Retiring its token on the first error would permanently destroy a valid registration, and the user would silently stop receiving pushes. Only FCM's explicit "this token will never work again" signals retire immediately.

### 4.4 Batching

FCM HTTP v1 has **no multicast endpoint** — one HTTP request per token. Tokens are chunked (`FCM_BATCH_SIZE`, default 500) and each chunk runs as one queued job with retries and backoff, keeping a 500-token fan-out off the request thread.

Throughput is bounded by Google quota (`messages.send` = 100 units; default 1,000,000 units/day → ~10,000 sends/day). A national broadcast to 50,000 users **requires a quota increase** before launch.

### 4.5 Topics

| Topic | Use |
|---|---|
| `sportx_broadcast` | Announcements — subscribe on login, unsubscribe on logout |
| `sportx_sport_{id}` | Sport-specific announcements (caches well, low cardinality) |

Topic messages cost 1,000 quota units each, so topics are for genuinely broadcast-shaped content, not per-user notifications.

---

## 5. Preference resolution

`NotificationService` evaluates preferences **before** dispatching push:

```
1. Load users.notification_prefs (JSON), merge over config('sportx.notifications')
2. Hard overrides (cannot be disabled by the user):
      account_action, registration_approved, registration_rejected  → in_app always
3. Per-type channel defaults:
      config('sportx.notifications.type_channels.{type}')
4. User overrides per channel / category
5. Dispatch only the channels that remain enabled
```

Hard overrides exist because transactional account and registration decisions must reach the user; a user who cannot see that their registration was rejected will simply never apply.

> **Email is opt-in by default** (`email.default = false`). Push and in-app default to `true`, matching platform norms and Android's post-Android 13 runtime-permission model.

---

## 6. Email fallback

When push cannot be delivered, `NotificationFallbackMail` is queued:

| Condition | `push_status` | Fallback email? |
|---|---|---|
| No active device tokens (never registered, or all pruned) | `no_devices` | **Yes** |
| All tokens rejected permanently | `failed` | **Yes** |
| Some tokens succeeded | `partial` | **No** |
| All tokens succeeded | `sent` | **No** |
| FCM not configured at all | `no_devices` | **Yes** |

Delivered via the active provider from `Email-Provider-Architecture.md` — SMTP or Gmail — and honours the user's `email` preference.

---

## 7. API contract

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/me/notifications` | Any | Inbox. `?unread_only=1`, paginated 20 |
| PATCH | `/me/notifications/{id}/read` | Any | Mark one read (403 if not owner) |
| POST | `/me/notifications/read-all` | Any | Mark all read |
| DELETE | `/me/notifications/{id}` | Any | Delete one |
| POST | `/me/device-tokens` | Any | Register an FCM token |
| DELETE | `/me/device-tokens` | Any | Unregister (logout) |
| POST | `/me/device-tokens/subscribe` | Any | Subscribe to an FCM topic |
| GET | `/me/notification-preferences` | Any | Read resolved preferences |
| PUT | `/me/notification-preferences` | Any | Update preferences |
| POST | `/me/device-tokens/test` | Any | Send a test push to the caller's devices |
| GET | `/admin/notifications/stats` | Admin | Delivery stats by type / status |
| POST | `/admin/notifications/broadcast` | Admin | Broadcast (in_app + push channels) |

**`POST /me/device-tokens`**

```json
{ "token": "fcm_registration_token", "device_type": "android", "device_id": "optional-installer-id" }
```

Upsert on `token`. `200` with `{ "message": "Device token registered" }`.

**`GET /me/notifications`** returns:

```json
{
  "data": [
    { "id": 512, "type": "enquiry_reply", "category": "enquiry", "title": "New reply from Kiran",
      "body": "Trial this Saturday at 6 PM.", "action_url": "/enquiries/9",
      "image_url": null, "is_read": false, "read_at": null, "created_at": "2026-10-04T09:12:00+00:00" }
  ],
  "meta": {
    "pagination": { "total": 34, "per_page": 20, "current_page": 1, "last_page": 2 },
    "unread_count": 6
  }
}
```

> **`unread_count` is returned on every page load** so the tab badge needs no extra request. The client treats it as eventually consistent.

---

## 8. Flutter implementation

### Packages

```yaml
firebase_core: ^3.8.1                 # already present
firebase_messaging: ^15.1.6           # already present
flutter_local_notifications: ^18.0.1  # ADD — system tray display
```

### Flow

| Scenario | Behaviour |
|---|---|
| Cold start | `getInitialMessage()` → deep link to the referenced screen |
| Foreground | `onMessage` → `flutter_local_notifications` + in-app provider refresh + SnackBar |
| Background | `@pragma('vm:entry-point')` handler → `LocalNotifications` in the system tray |
| Tap (background) | `getInitialMessage()` → deep link |
| Tap (foreground) | `onMessageOpenedApp` → deep link |
| Token refresh | `onTokenRefresh` → `POST /me/device-tokens` |

### Registration

`PushNotificationService.init(ref)` runs post-frame from `main.dart`, calls `FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true)`, then registers the token. `AuthNotifier` re-registers after login and unregisters on logout, so a token always belongs to the current session.

> **Android 13+ requires an explicit runtime permission.** `requestPermission()` without declaring `POST_NOTIFICATIONS` in `AndroidManifest.xml` returns a silent no-op on Android 13+. This is the single most common cause of "it works on Android 12 but not 13".

### Local notification setup

- Android channel IDs must match §4.2 exactly (`sportx_default`, `sportx_enquiries`, …). A mismatch means a silent drop.
- iOS: `DarwinInitializationSettings` with `.sound`, `.badge`, `.alert`; foreground presentation via `presentAlert: true`.
- Tap payload → `go_router` via the app's `navigatorKey`, using `action_url` and `category`.

### Background handler

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Show via flutter_local_notifications; do not touch providers — no app context.
}
```

> **Two real bugs to fix in the current app:**
> 1. `main.dart` calls `Firebase.initializeApp()` with **no `options:`**, so `DefaultFirebaseOptions` is never used and everything depends on native config. Web and tests will fail.
> 2. The foreground handler shows a SnackBar but **no system notification**, so a backgrounded-but-not-terminated app produces nothing visible.

---

## 9. Security

| Threat | Control |
|---|---|
| Push to the wrong user | Tokens are only read via `user_id`; never accepted as an addressable identifier in any endpoint |
| Token enumeration | Device-token endpoints require Sanctum auth and scope to the caller |
| Reading another user's notifications | `abort_unless($notification->user_id === $request->user()->id)` on every per-item route |
| Push-triggered privilege escalation | The payload carries **routing metadata only**. Every authorisation decision is re-evaluated server-side when the tapped screen loads |
| Payload injection | `toPushPayload()` coerces every value to a non-empty string; FCM rejects empty `data` values |
| Logout leaving a live channel | Logout sets `is_active = false` and unsubscribes from topics |
| Notification content leaking to a lock screen | Per-channel user control; `sportx_updates` can be tuned separately from `sportx_enquiries` |
| Broadcast abuse | Admin-only, `role:admin` + 2FA, audited |

> **A push payload is not an authorisation token.** `action_url: /registrations/9` in a push body does not grant access to registration 9. It is a routing hint; the API re-checks ownership. This is the most important rule in the design.

---

## 10. Reliability & monitoring

| Signal | Where | Action |
|---|---|---|
| `push_status = 'failed'` rate | `notifications` table | Investigate credential / quota / project mismatch |
| `push_status = 'no_devices'` rate | `notifications` table | A rising share means the Flutter token registration flow is broken |
| `failure_count` climbing | `user_device_tokens` | Systematic rejection — check `SENDER_ID_MISMATCH` |
| Queue depth on `push` | Horizon | Saturated workers, not a delivery failure |
| FCM quota headroom | Google Cloud console | **Pre-flight item before any large broadcast** |
| `NotificationFallbackMail` volume | Mail provider | High volume means push is silently failing |
| Token TTL prunes | `PruneStaleDeviceTokensJob` log | An unexpected spike means token refresh stopped |

### Scheduled jobs

```php
// routes/console.php
Schedule::job(new SendDueRemindersJob)->everyFifteenMinutes();  // existing
Schedule::job(new PruneStaleDeviceTokensJob)->daily();
Schedule::job(new PruneNotificationRowsJob)->daily();
Schedule::job(new PurgeExpiredOtpsJob)->dailyAt('02:00');         // existing
```

`NOTIFICATION_RETENTION_DAYS` (default 180) bounds inbox growth; `DEVICE_TOKEN_TTL_DAYS` (default 120) retires devices that have not checked in.

---

## 11. Testing

| Suite | Coverage |
|---|---|
| `FCMServiceTest` | `Http::fake()`; asserts endpoint, auth header, per-token payload, Android channel mapping, APNs headers; `UNREGISTERED` → token retired; `QUOTA_EXCEEDED` → `failure_count` incremented and **not** retired |
| `NotificationServiceTest` | Row always written; preferences honoured; hard overrides cannot be disabled; email fallback fires only on `no_devices`/`failed` |
| `NotificationPreferenceTest` | Merge order: hard overrides → type defaults → user prefs |
| `NotificationControllerTest` | Inbox, `unread_count`, cross-user access → 403, mark-read idempotency |
| `DeviceTokenTest` | Upsert on the unique token; token transfer between users; logout deactivates |
| `PruneStaleDeviceTokensJobTest` | TTL boundary respected |

Jobs use `Queue::fake()` or the `database` queue driver so no network is touched.

---

## 12. Gaps closed

| Gap (pre-existing) | Fix |
|---|---|
| `messages:sendMulticast` does not exist in FCM HTTP v1 — **every push silently reported success while doing nothing** | Per-token `messages:send`; failures surfaced via `push_status` |
| Android `channel_id` never set — Android 8+ silently drops every notification | Per-type channel mapping (§4.2) |
| `notification_prefs` was dead data — nobody read it | Preference gate in `NotificationService` (§5) |
| No APNs headers — iOS alerts arrived silently in the background | `apns` block with priority, push-type and sound |
| Tokens never retired — stale tokens accumulated forever | `UNREGISTERED` immediate retirement + TTL pruning + `failure_count` |
| `user_device_tokens.token` not unique — duplicate rows stole each other's notifications | Unique constraint after de-duplication |
| `NotificationController::sendPushNotification()` referenced `$notification->message`, a column that does not exist — **empty push bodies** | `toPushPayload()` reads `body` |
| Admin approve/reject produced no notification of any kind | Account/registration notification types (§2) + email |

---

## 13. Open items

| ID | Item | Status |
|---|---|---|
| **AS-03c** | Push provider | **CLOSED** — FCM HTTP v1 |
| AS-67 | FCM quota increase request | **OPEN — launch blocker for large broadcasts** |
| AS-68 | APNs key upload + p8 provisioning for iOS production pushes | **OPEN** — dev builds work; release builds need an APNs auth key uploaded to Firebase |
| AS-69 | Remove the legacy `device_tokens` table and `DeviceToken` model | **OPEN** — unused, causes confusion |
| AS-70 | Per-sport topics (`sportx_sport_{id}`) | **PARTIAL** — schema supports it; subscription UX not built |
| AS-71 | Notification digest ("3 new updates today") instead of per-event pushes | **OPEN** — reduces fatigue and quota on low-priority types |
| AS-72 | `flutter_local_notifications` system-tray display | **OPEN** — required for background delivery to be visible |