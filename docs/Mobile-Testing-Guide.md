# SportX India — Mobile App Testing Guide

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

A practical, role-by-role guide for running the SportX stack locally and testing the Flutter mobile app end-to-end against the Laravel backend.

> **⚠️ Historical / practice guide.** This guide reflects the pre-v3 wired behaviour. The v3 design (`sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md`, 129 screens / 6 roles) changes several things referenced below: **auth is now OTP** (not email+password only), the **Sponsor role is REMOVED** (sponsorship = Opportunity type), and new flows exist (guardian consent, verification, feed/posts, follow/connect, chat, leaderboard, opportunities, programs, facilities). Obsolete references are marked inline; see `Backend-Feature-Delta.md` for the authoritative delta.

---

## 1. Architecture at a glance

```
┌─────────────────────┐         HTTPS (Dio)          ┌──────────────────────────┐
│  Flutter App        │  ─────────────────────────▶  │  Laravel API (sportx-api)│
│  sportx_app         │  ◀─────────────────────────  │  /api/v1/*  (port 8002)  │
│  (Android/iOS/Web)  │         JSON + Bearer        │  MySQL DB `sportx`       │
└─────────────────────┘                              └──────────────────────────┘
```

- **Base URL is configurable** via `sportx_app/.env` → `API_BASE_URL`. Change it and do a **full app restart** (hot reload is not enough).
- All mobile data flows through real API calls (`dioProvider`) — there is no separate mock server.

---

## 2. Prerequisites

| Tool | Version / notes |
|------|-----------------|
| PHP | 8.2+ with `pdo_mysql`, `mbstring`, etc. |
| Composer | latest |
| MySQL | 8.x (a `sportx` database) |
| Flutter | 3.x (Dart SDK ^3.10) |
| A device | Android emulator, iOS simulator, or a physical phone |

---

## 3. Start the backend (`sportx-api`)

```bash
cd sportx-api
cp .env.example .env          # then edit DB_* and APP_URL (see below)
composer install
php artisan key:generate
```

Edit `sportx-api/.env` — the important lines:

```ini
APP_URL=http://127.0.0.1:8002
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=sportx
DB_USERNAME=root
DB_PASSWORD=password
MAIL_MAILER=log               # ⚠️ OTP/verification codes are written to the log, NOT emailed
```

Create the database, run migrations + seed master data, then start the server on **port 8002** (matches `APP_URL`):

```bash
mysql -u root -p -e "CREATE DATABASE sportx;"
php artisan migrate --seed    # runs MasterDataSeeder (sports/cities/age-groups) + ExpiryRuleSeeder
php artisan db:seed --class=DevDataSeeder   # optional: sample trial/tournament/scholarship + 2 users
php artisan serve --port=8002
```

**Smoke test** — open http://127.0.0.1:8002/api/v1/health → `{"status":"ok","db":"connected"}`.

---

## 4. Start the mobile app (`sportx_app`)

```bash
cd sportx_app
flutter pub get
```

### 4.1 Point the app at the backend (`.env`)

Edit `sportx_app/.env`:

```ini
API_BASE_URL=http://127.0.0.1:8002/api/v1
```

> ⚠️ **Pick the right host for your device:**
> | Test target | `API_BASE_URL` |
> |-------------|----------------|
> | **Android emulator** | `http://10.0.2.2:8002/api/v1` (emulator maps `10.0.2.2` → host `127.0.0.1`) |
> | **iOS simulator / Web** | `http://127.0.0.1:8002/api/v1` |
> | **Physical phone** | `http://<YOUR_LAN_IP>:8002/api/v1` (e.g. `192.168.1.10`) — PC & phone on same Wi-Fi |

After editing `.env`, **fully restart** the app (stop the `flutter run` process and re-run).

### 4.2 Run it

```bash
flutter run                      # picks the single connected device
# or choose a target:
flutter run -d chrome            # web (fastest for quick checks)
flutter run -d emulator-5554     # a specific Android emulator
flutter run -d <ios-device-id>   # iOS
```

---

## 5. Test accounts

### 5.1 Seeded users (from `DevDataSeeder`)

| Role | Email | Password |
|------|-------|----------|
| Organizer | `org1@sportx.test` | `password` |
| ~~Sponsor~~ | ~~`sponsor1@sportx.test`~~ | **[REMOVED — sponsor role dropped; sponsorship is now an Opportunity]** |

The seeder also creates sample content: a trial, a tournament (+ category), a **scholarship/opportunity**, and a sports venue. *(A legacy sponsorship row migrates to `opportunities` — see `Backend-Feature-Delta.md` §4/§6.)*

### 5.2 Create accounts for the other roles

**[v3]** Sign-up now uses **phone/email + OTP** (`A.3`–`A.5`); the old "email + password only, no OTP" path below is **superseded** (kept for history). You can still create accounts directly in the DB for speed (set `email_verified_at`):

```bash
php artisan tinker
```

```php
use App\Models\User;
use Illuminate\Support\Facades\Hash;

foreach ([
  ['athlete', 'athlete@test.com'],
  ['coach',   'coach@test.com'],
  ['academy', 'academy@test.com'],
] as [$role, $email]) {
    User::firstOrCreate(
        ['email' => $email],
        ['role' => $role, 'name' => ucfirst($role).' Test', 'password' => Hash::make('password'), 'status' => 'active', 'email_verified_at' => now()]
    );
}

// Admin (separate login portal at /admin/login)
User::firstOrCreate(
    ['email' => 'admin@test.com'],
    ['role' => 'admin', 'name' => 'Admin Test', 'password' => Hash::make('password'), 'status' => 'active', 'email_verified_at' => now()]
);
```

All accounts use password **`password`**.

> **[SUPERSEDED]** Auth was **email + password only** (no OTP/email verification), auto-verified and issued a token immediately. The v3 design makes **OTP P0** (`POST /auth/send-otp`, `/auth/verify-otp`, `/auth/resend-otp`) for phone **or** email, adds **guardian consent** for minors (`A.9`/`AT.10`) and **verification requests** (`A.10`), and keeps password login alongside. The name field is still optional at sign-up.

---

## 6. How each role works (and what to test)

All non-admin roles land on the **Home** tabbed shell (Home / Search / Saved / Activity / Profile) after login. Role-specific **dashboards and tools are reached from the Profile screen** (or automatically after completing onboarding). Admin is a separate portal.

> **[v3]** The new shell is `[Home][Explore][(+) Create][Community][More]` and role homes call `GET /me/home`. See `Mobile-App-Flow.md` §1/§4a.

### 🏃 Athlete  —  `athlete@test.com / password`
*The discovery & registration user.*

1. **Login** → Home (trending sports, featured listings).
2. **Onboarding** (if prompted): pick sport(s) → age group → skill level → city. *(Screens: Onboarding-1, Onboarding-2)*
3. **Discover** directories from Home or Search:
   - Academies → tap one → **Enquire** (opens Enquiry screen, sends to `/enquiries`).
   - Coaches, Trials, Tournaments, Scholarships, Sports Venues.
4. **Register** for a Trial or Tournament → Registration Confirmation.
5. **Profile** tab → Edit Profile, add achievements, media gallery, share profile.
6. **Saved** tab → save/unsave listings.
7. **Enquiries inbox** (`/enquiry-inbox`) → view replies, send messages.

### 🏏 Coach  —  `coach@test.com / password`
*Manages their coach profile & posts trials.*

1. **Login** → complete **Coach Onboarding** → lands on **Coach Dashboard** (`/coach-dashboard`).
2. **Edit Coach Profile** (`/edit-coach-profile`) → credentials, facilities, showcase athletes.
3. **[v3]** **My Training Programs** (`CO.4`/`CO.5`) → create/publish a program → athlete enquiry (`D.12`) → chat (`S.18`).
4. **Post a Trial** (`/post-trial`) → publish.
5. **My Trials** → open a trial → **Registrant list** → open a registrant → **Verify / Reject / Reminder**, download `.ics`.

### 🏫 Academy  —  `academy@test.com / password`
*Like Coach but academy-scoped.*

1. **Login** → **Academy Onboarding** → **Academy Dashboard** (`/academy-dashboard`).
2. **Edit Academy Profile** (`/edit-academy-profile`).
3. **[v3]** **Facilities** (`AC.7`/`AC.8`), **Programs** (`AC.4`), **Our Athletes** (`AC.5`/`AC.10`), **Opportunities** (`AC.9`).
4. **Post Trials** and **manage registrants** (same flows as Coach).

### 🏆 Organizer  —  `org1@sportx.test / password`  *(seeded)*
*Runs tournaments end-to-end.*

1. **Login** → **Organizer Onboarding** → **Organizer Dashboard** (`/organizer-dashboard`).
2. **Post a Tournament** (`/post-tournament`) with categories + capacities → publish.
3. **Registration Management** → view registrants per tournament.
4. **Capacity Management** (`/capacity-management`) → set/update seats & waitlist.
5. **Results Publishing** (`/results-publishing`) → add results → publish/unpublish.
6. **Results View** (`/results-view`) → public results.

### 💰 Sponsor / Brand — **[REMOVED — see Backend-Feature-Delta.md §4]**
~~`sponsor1@sportx.test / password`~~ — the `sponsor` role is gone. Sponsorship is now an **Opportunity type** (`D.9`/`D.10`/`AT.8`) posted by Academy/Organizer/Coach/Scout and browsed/applied by all. Test it from any provider account (e.g. `org1@sportx.test`) or an athlete account instead of a sponsor login.

### 🛡️ Admin  —  `admin@test.com / password`
*Platform control — reached via the **separate** `/admin/login` screen (not the normal login).*

1. From the app, navigate to **Admin → Login** (`/admin/login`).
2. Enter admin email + password + **any 6-digit 2FA code** (MVP accepts any code).
3. **Dashboard** (`/admin/dashboard`) → platform stats.
4. **Manage Users** (`AD.3` `/admin/users`) → search/verify / suspend / ban (delta §11.17).
5. **Verification Queue** (`AD.4` `/admin/verification`) → approve **blue check** / reject with reason.
6. **Moderation Queue** (`AD.7`/`AD.8`) → reports → approve / remove / warn / **suspend** (users + posts).
7. **Content Manager** (`AD.5`/`AD.6`) → manage academies, coaches, events, **opportunities**, **programs**, **facilities**, **posts**.
8. **Compose / Targeted Notifications** (`AD.12`, P1), **Expiry monitor** (+opportunity type), **Categories** (sports/cities/age-groups/**positions**), **Leaderboard config** (`AD.11`, P1).

> Admin uses its own auth (`/admin/login`, `/admin/verify-2fa`) and a separate `adminProvider`. Normal user login will **not** grant admin access.

---

## 7. Cross-role interaction checklist

Use two accounts to verify the loops that span roles:

| Flow | Actor A (do this) | Actor B (verify) |
|------|-------------------|------------------|
| Trial registration | **Athlete** registers for a trial | **Coach/Academy** sees the registrant & verifies |
| Tournament registration | **Athlete** registers for a tournament | **Organizer** sees it in Registration Mgmt |
| Enquiry / chat | **Athlete** enquires about an academy/coach/program | **Academy/Coach** replies (S.18 thread) |
| **[v3] Opportunity apply** | **Athlete** applies to an opportunity with a pitch (`D.10`) | **Provider** (Academy/Organizer/Coach/Scout) reviews applicants |
| **[v3] Social feed** | Any user creates a post (`S.9`) | Others like / comment (`S.27`) |
| **[v3] Follow / Connect** | **User A** follows (instant) or sends a connection request | **User B** sees it in Connections (`S.19`); accept unlocks chat |
| **[v3] Verification** | Any user requests blue check (`A.10`) | **Admin** approves/rejects in the verification queue (`AD.4`) |
| **[v3] Guardian consent** | Minor athlete signs up | Guardian receives OTP; controls apply (`A.9`/`AT.10`) |
| **[v3] Leaderboard** | Athlete earns points (verified achievements/activity) | Appears on `S.6` + home strip |
| Report → moderation | Any user reports user/post/listing | **Admin** sees it in Moderation Queue |

---

## 8. Verifying the API directly (debug aid)

When a screen shows an error, confirm the endpoint in isolation:

```bash
# Health
curl http://127.0.0.1:8002/api/v1/health

# Login as athlete → copy "token"
curl -X POST http://127.0.0.1:8002/api/v1/auth/login \
  -H "Accept: application/json" -H "Content-Type: application/json" \
  -d '{"email":"athlete@test.com","password":"password"}'

# Authenticated call
curl http://127.0.0.1:8002/api/v1/me/profile \
  -H "Accept: application/json" -H "Authorization: Bearer <token>"
```

The full route list is in `sportx-api/routes/api.php` and `docs/API-Specification.md`.

---

## 9. Troubleshooting

| Symptom | Likely cause / fix |
|--------|--------------------|
| App stuck on splash / "No internet connection" | Wrong `API_BASE_URL` host for the device (see §4.1), or backend not running on 8002. |
| Works on web but not on Android emulator | Use `10.0.2.2:8002`, not `127.0.0.1:8002`. |
| Works on emulator but not on physical phone | Use your PC's LAN IP; ensure same Wi-Fi and no firewall blocking port 8002. |
| Login fails with 401 | Wrong password, or user `status != active`. Recreate via tinker (§5.2). |
| Sign-up doesn't log me in | **[v3]** Sign-up now issues/verifies an OTP before returning a token (`/auth/send-otp` → `/auth/verify-otp`); check the OTP is written to the log (`MAIL_MAILER=log`) or the SMS stub. Restart `php artisan serve`. |
| Admin "Access denied" (403) | That account isn't `role = admin`. Use `admin@test.com`. |
| ` dio` 401 then kicked to login | Token expired/invalidated — log in again. |
| Changes to `.env` not taking effect | Hot reload won't reload `.env`. Fully restart `flutter run`. |
| 419 / "419 Page Expired" | Hitting a web route, not an API route. API paths start with `/api/v1`. |
| Seed error "No such db" | Create the `sportx` DB first (§3). |

---

## 10. Quick smoke test (5 minutes)

1. `php artisan serve --port=8002` → `/api/v1/health` returns `ok`.
2. Set `sportx_app/.env` → `API_BASE_URL=http://10.0.2.2:8002/api/v1` (emulator) and `flutter run`.
3. **Login** as `athlete@test.com / password` → Home loads listings.
4. Search → open a Tournament → Register → see confirmation.
5. In another login (or tinker) as the **organizer**, confirm the registration appears.

If all five pass, the full mobile ↔ backend wiring is healthy.
