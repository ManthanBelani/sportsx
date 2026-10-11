# SportX India — Mobile App Flow (per role)

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

The authoritative end-to-end flow for the Flutter app, covering auth, role onboarding, the persistent bottom-nav shell, and the role-specific tools each user type reaches. This reflects the **wired** behaviour after the flow fixes.

> **⚠️ Partly [SUPERSEDED — see Backend-Feature-Delta.md].** The v3 design (`sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md`, 129 screens / 6 roles) changes several things described below: the bottom nav is `[Home][Explore][(+) Create][Community][More]`, auth is **OTP** (not email/password-only), the **Sponsor/Brand role is REMOVED**, and new modules ship (feed/posts, follow/connect, chat, leaderboard, opportunities, programs, facilities). New v3 sections are marked **[v3]** below; stale sections are kept for history.

---

## 1. The shell: one persistent bottom nav for every role

> **[v3]** The new design uses a 5-tab shell: **`[Home] [Explore] [(+) Create] [Community] [More]`**. `Home` is the role-aware dashboard (`AT.1`/`CO.2`/`AC.2`/`OR.2`/`SC.2`); `Explore` is `S.2`; `Create` is the `S.8` launcher; `Community` hosts Network `S.12` (P1) / Groups (P2) / Events (P1); `More` is the `S.15` account hub. Header icons reach Search `S.5`, Notifications `S.16` and own profile. Messages are reached from More and profile "Message" buttons (`S.17`).

### [SUPERSEDED] old shell

All signed-in users (any role) live inside a single **`MainShell`** (`lib/core/router.dart`) with 5 tabs that **never disappear** while navigating between them:

```
 [Home]  [Search]  [Saved]  [Activity]  [Profile]
   0        1        2          3           4
 /home  /universal  /saved  /activity-hub  /profile
        -search
```

- The shell is a `ShellRoute`, so switching tabs uses `context.go(...)` (replaces, doesn't stack).
- `HomeScreen` no longer renders its own nav bar — the shell owns it.
- Role-specific **dashboards and tools are launched from the Profile tab** via a role-aware “Quick Links” grid.

---

## 2. Entry & authentication flow (shared)

> **[v3] OTP is now P0** (`A.3` Sign Up, `A.4` OTP, `A.5` Login, `A.6` Forgot/Reset). Sign up uses **phone _or_ email + 6-digit OTP** (`POST /auth/send-otp`, `/auth/verify-otp`, `/auth/resend-otp`, delta §11.1); password login is retained. After OTP, an athlete with DOB < 18 is routed to **Guardian Consent** (`A.9`) before onboarding. Google sign-in remains deferred unless overridden (delta §8 D9).

```
 App start
   │
   ▼
 Splash (A.1) ──► Role Selection (A.2) ──┬──► Sign Up (A.3) ──► OTP (A.4) ──┐
                                         │                                   │
                                         └──► Login (A.5) ───────────────────┤
                                                                             ▼
                                                        AuthProvider (send/verify OTP, token)
                                                                             │
                                          ┌──────────────────────────────────┴─────────────┐
                                          ▼                                                 ▼
                              DOB < 18 → Guardian Consent (A.9)                adult/other roles
                                          │                                                 │
                                          └──────────────► <role> onboarding ◄──────────────┘
                                          (AT.2 / CO.1 / AC.1 / OR.1 / SC.1)
                                                                             │
                                                                             ▼
                                                        markOnboardingComplete() → role landing
```

- **v3 auth:** phone **or** email + OTP (`A.3`–`A.6`); password login kept alongside. OTP sets `email_verified_at` / `phone_verified_at` and returns a token + `needs_onboarding`.
- The router **redirects automatically** based on `AuthState`:
  - `authenticated + needs_onboarding` → forced to that role's onboarding screen.
  - `authenticated + onboarding done` → `/home` (auth/onboarding screens are blocked).
  - `unauthenticated` → `/role-selection`.

> **[SUPERSEDED] old auth (email + password only, no OTP).** Registration auto-verified and returned a token immediately. Shown here for history only:
>
> ```
>  Splash ──► Role Selection ──┬──► Sign Up (email + password) ──┐
>                              └──► Login (email + password) ─────┤
>                                                                 ▼
>                                                    AuthProvider.register / login → token
> ```
> This flow lost the OTP stack (`otp_codes` dropped) and left Flutter `verifyOtp()` calls pointing at dead endpoints (delta D1). **Do not build against it.**

---

## 3. Role onboarding screens (the "info-taking" forms)

Each role collects its profile info right after signup. On success the screen calls `markOnboardingComplete()` and routes to the role landing.

| Role | Onboarding route(s) | Collects | After submit → |
|------|---------------------|----------|----------------|
| **Athlete** | `/onboarding-1` → `/onboarding-2` (`AT.2`) | Sport(s) + age group → skill level + city; **guardian consent first if < 18 (`A.9`/`AT.10`)** | `/home` |
| **Coach** | `/coach-onboarding` (`CO.1`) | 4-step: profile → credentials → sports/fees → review | `/coach-dashboard` |
| **Academy** | `/academy-onboarding` (`AC.1`) | 5-step: basic → sports/age → facilities → fees/photos → review | `/academy-dashboard` |
| **Organizer** | `/organizer-onboarding` (`OR.1`) | organization name, type | `/organizer-dashboard` |
| ~~**Sponsor**~~ | ~~`/sponsor-onboarding`~~ | **[REMOVED — see Backend-Feature-Delta.md]** sponsorships are now Opportunity type (`D.9`/`D.10`) | — |
| **Talent Scout** | `/scout-onboarding` (`SC.1`) | organization, sports specialization, experience, availability region, languages, location | `/scout-dashboard` |
| Admin | — (no onboarding) | separate portal at `/admin/login` | `/admin/dashboard` |

> Onboarding now captures the role's **30 profile fields** (`SportX_Mandatory_Fields.md`, 8–9 mandatory) with a completion checklist (`AT.6`, `GET /me/completion-checklist`). The old `/sponsor-onboarding` route is retired (should 404/410, never 500).

---

## 4. Per-role flows (what each user does after onboarding)

### 🏃 Athlete / Parent
**Landing:** `/home` (shell).

```
 Home ──► browse Academies / Coaches / Trials / Tournaments / Scholarships / Venues
   │           │
   │           ├─► Detail page ──► Enquire (coach/academy)  → /enquiry-inbox
   │           ├─► Trial detail ──► /trial-registration/:id ──► confirmation
   │           └─► Tournament detail ──► /tournament-registration/:id
   │
 Profile tab ──► Quick Links: Edit Profile · Media · Activity · Scholarships · Venues · Connections
                  └─ Settings / Log out
 Activity tab ──► My registrations & applications (trials/tournaments/**opportunities**)
```

### 🏏 Coach
**Landing:** `/coach-dashboard`.

```
 Onboarding done ──► /coach-dashboard
                         │
 Profile tab Quick Links:
   ├─ Dashboard (/coach-dashboard)
   ├─ Edit Profile (/edit-coach-profile)  → credentials, facilities, showcase athletes
   ├─ Post Trial (/post-trial)            → publish
   ├─ My Trials (/my-trials)              → /registrant-list → /registrant-detail (verify/reject)
   ├─ Enquiries (/enquiry-inbox)          → /enquiry-detail (reply)
   └─ Activity (/activity-hub)
 Browse tabs (Home/Search/Saved) reuse the same public directories as athletes.
```

### 🏫 Academy
**Landing:** `/academy-dashboard`. Same shape as Coach, academy-scoped.

```
 Profile tab Quick Links:
   ├─ Dashboard (/academy-dashboard)
   ├─ Edit Profile (/edit-academy-profile)
   ├─ Post Trial (/post-trial) → publish
   ├─ My Trials (/my-trials) → registrant management
   └─ Enquiries (/enquiry-inbox)
```

### 🏆 Organizer
**Landing:** `/organizer-dashboard`.

```
 Onboarding done ──► /organizer-dashboard
 Profile tab Quick Links:
   ├─ Dashboard (/organizer-dashboard)
   ├─ Post Event (/post-tournament)       → categories + capacity → publish
   ├─ My Events (/my-tournaments)
   │      └─ Registration Mgmt (/registration-management)
   │      └─ Capacity Mgmt (/capacity-management)
   │      └─ Results (/results-publishing) → public /results-view
   └─ Activity (/activity-hub)
```

### 💰 Sponsor / Brand — **[REMOVED — see Backend-Feature-Delta.md]**
**Landing:** ~~`/sponsor-dashboard`~~ — the `sponsor` role is **removed** (delta §0 D2 / §4). Sponsorship is now an **Opportunity type** (`D.9`/`D.10`/`AT.8`) posted by Academy/Organizer/Coach/Scout. Old flow kept for history:
```
 Onboarding done ──► /sponsor-dashboard
   ├─ Post Sponsor (/sponsor-posting)      → publish
   ├─ Discover (/athlete-discovery)        → shortlist athletes (/shortlist)
   └─ Applications (/applications-inbox)   → /application-detail (accept/reject)
```

### 🔍 Talent Scout
**Landing:** `/scout-dashboard`.

```
 Onboarding done ──► /scout-dashboard
 Profile tab Quick Links:
   ├─ Dashboard (/scout-dashboard)        → search shortcut, saved athletes, activity
   ├─ Discover Athletes (/scout-discovery) → filterable athlete cards
   ├─ Shortlist (/scout-shortlist)         → saved athletes with remove option
   └─ My Profile (/scout-profile-edit)
 Discover flow:
   Athlete cards ──► Athlete Profile View ──► Shortlist / Connect
   └─► Shortlist ──► Athlete Profile View ──► Remove
   └─► Connect ──► Connection/Enquiry Form ──► Confirmation
 Browse tabs (Home/Search/Saved) reuse the same public directories as athletes.
```

### 🛡️ Admin (separate portal)
**Entry:** `/admin/login` (email + password + any 6-digit 2FA).

```
 /admin/login ──► /admin/dashboard
                  ├─ Users (/admin/users) → verify/suspend/delete
                  ├─ Approvals (/admin/approvals)
                  ├─ Moderation (/admin/moderation) → report actions
                  ├─ Content / Opportunities (AD.5) → manage opportunities/programs/facilities/posts
   ├─ Verification Queue (AD.4) → approve/reject blue-check requests
                  ├─ Notifications (compose / targeted)
                  └─ Expiry monitor · Categories (sports/cities/age-groups)
 Admin is NOT part of the user bottom-nav shell — it has its own navigation.
```

---

## 4a. [v3] New shared modules (all roles)

These screens/modules are **new in v3** (`SCREEN_INVENTORY.md` v2) and are reached from the shell, profile or detail screens:

| Module | Screens | Entry / flow | Backend (delta §11) |
|---|---|---|---|
| **Social feed & posts** | `S.8` Create Launcher, `S.9` Create Post, `S.27` Post Detail, `S.28` Media Viewer | Home feed tabs (For You/Following/…) → create/like/comment/save | `GET /feed`, `/posts/**` (§11.9) |
| **Network (follow/connect)** | `S.12` Network, `S.19` Connections, `S.13`/`S.14` Groups (P2) | Explore/profile → Follow (instant) or Connect (request) → accept | `/follow/**`, `/connections/**` (§11.10) |
| **Messaging** | `S.17` Inbox, `S.18` Chat Thread | More / profile Message → accepted connection or enquiry thread | `/conversations/**`, `/enquiries/**` (§11.11/§11.8) |
| **Opportunities** | `D.9` Detail, `D.10` Apply, `AT.8` My Opportunities, `AC.9`/`SC.11`/`SC.12` posting | Explore/Home → detail → apply with pitch → track status | `/opportunities/**` (§11.7) |
| **Programs** | `CO.4`/`CO.5` Coach, `AC.4`, `D.11` Detail, `D.12` Enquiry | Coach/Academy → create → Explore → athlete enquires → chat | `/me/programs`, `/programs/**` (§11.8) |
| **Facilities** | `AC.7`/`AC.8`, `D.13` Detail, `OR.13` venues | Academy/Organizer → create → D.3 tab / Explore | `/me/facilities`, `/facilities/**` (§11.8) |
| **Leaderboard** | `S.6` Leaderboard, `S.7` Info, `AT.1` strip | Home strip / Explore → ranked tabs (athletes P0; others P1) | `GET /leaderboard`, `/leaderboard/strip` (§11.5) |
| **Guardian / minors** | `A.9`, `AT.10` | Minor signup → guardian consent → restricted defaults | `/guardian/**`, `/me/guardian-controls` (§11.1) |
| **Verification** | `A.10`, `AD.4` | Profile → request blue check → admin queue | `/me/verification`, `/admin/verification/**` (§11.1/§11.17) |
| **Settings / safety** | `S.22`–`S.26`, `S.29`, `S.30` | More → settings/privacy, blocks, report, logout, share | `/me/settings`, `/blocks`, `/reports` (§11.15/§11.16) |
| **Unified dashboards** | `AT.1`/`CO.2`/`AC.2`/`OR.2`/`SC.2`, `S.2` Explore | One role-aware home + grouped explore | `GET /me/home`, `GET /explore` (§11.5) |

---

## 5. How routing enforces the flow (router.dart)

```
redirect(context, state):
  if authenticated:
      onboardingRoute = _onboardingRouteFor(user.role)
      if needsOnboarding && onboardingRoute: → force onboardingRoute
      if on auth/onboarding screen:           → /home
  if unauthenticated:
      if on auth screen: stay
      else: → /role-selection
```

`_onboardingRouteFor(role)`:

| role | route |
|------|-------|
| athlete | `/onboarding-1` |
| coach | `/coach-onboarding` |
| academy | `/academy-onboarding` |
| organizer | `/organizer-onboarding` |
| ~~sponsor~~ | **[REMOVED — no route]** |
| talent_scout | `/scout-onboarding` |
| (other) | `null` |

Each onboarding screen calls `authProvider.notifier.markOnboardingComplete()` on success so the redirect releases the user to their landing screen.

---

## 6. Where things live (file map)

| Concern | File |
|---------|------|
| All routes + shell + redirect | `lib/core/router.dart` |
| Auth state, `markOnboardingComplete` | `lib/features/auth/presentation/providers/auth_provider.dart` |
| Sign up (email + password) | `lib/features/auth/presentation/screens/sign_up_screen.dart` |
| Login (email + password) | `lib/features/auth/presentation/screens/login_screen.dart` |
| Role selection | `lib/features/auth/presentation/screens/role_selection_screen.dart` |
| Athlete onboarding (2 steps) | `lib/features/onboarding/presentation/screens/onboarding_*.dart` |
| Role onboarding (coach/academy/organizer/scout) | `lib/features/<role>/presentation/screens/<role>_onboarding_screen.dart` |
| v3 modules (feed/social, network, messaging, opportunities, programs, leaderboard) | new `lib/features/{feed,network,messaging,opportunities,programs,leaderboard}/` — see `Mobile-Architecture.md` |
| Home shell content | `lib/features/home/presentation/screens/home_screen.dart` |
| Role-aware Profile + Quick Links | `lib/features/athlete/presentation/screens/profile_screen.dart` |

---

## 7. Testing the flow quickly

1. Start backend on `:8002` (see `docs/Mobile-Testing-Guide.md`).
2. `flutter run`.
3. **Sign Up** as each role → confirm you land on the correct onboarding screen → complete it → confirm you reach the right landing (athlete→Home, others→their dashboard).
4. Use the **Profile** tab → “Quick Links” to reach each role's tools.
5. Confirm the bottom nav **stays visible** when switching Home/Search/Saved/Activity/Profile.
6. **Login** with an existing account (e.g. `org1@sportx.test`) → if onboarding is already done, go straight to Home; the role's tools are still on the Profile tab.
