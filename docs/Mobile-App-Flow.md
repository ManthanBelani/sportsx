# SportX India — Mobile App Flow (per role)

The authoritative end-to-end flow for the Flutter app, covering auth, role onboarding, the persistent bottom-nav shell, and the role-specific tools each user type reaches. This reflects the **wired** behaviour after the flow fixes.

---

## 1. The shell: one persistent bottom nav for every role

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

```
 App start
   │
   ▼
 Splash ──► Role Selection ──┬──► Sign Up (email + password) ──┐
                             │                                  │
                             └──► Login (email + password) ─────┤
                                                                ▼
                                                   AuthProvider.register / login
                                                   (backend issues token)
                                                                │
                                              ┌─────────────────┴──────────────────┐
                                              ▼                                    ▼
                                  needs_onboarding == true            needs_onboarding == false
                                              │                                    │
                                              ▼                                    ▼
                                   <role> onboarding screen                   /home (shell)
                                              │
                                              ▼
                                   markOnboardingComplete() → role landing
```

- Auth is **email + password only** (no OTP). Registration auto-verifies and returns a token immediately.
- The router **redirects automatically** based on `AuthState`:
  - `authenticated + needs_onboarding` → forced to that role's onboarding screen.
  - `authenticated + onboarding done` → `/home` (auth/onboarding screens are blocked).
  - `unauthenticated` → `/role-selection`.

---

## 3. Role onboarding screens (the "info-taking" forms)

Each role collects its profile info right after signup. On success the screen calls `markOnboardingComplete()` and routes to the role landing.

| Role | Onboarding route(s) | Collects | After submit → |
|------|---------------------|----------|----------------|
| **Athlete** | `/onboarding-1` → `/onboarding-2` | Sport(s) + age group → skill level + city | `/home` |
| **Coach** | `/coach-onboarding` | sport coached, experience | `/coach-dashboard` |
| **Academy** | `/academy-onboarding` | academy name, sport, city | `/academy-dashboard` |
| **Organizer** | `/organizer-onboarding` | organization name, type | `/organizer-dashboard` |
| **Sponsor** | `/sponsor-onboarding` | brand name, category | `/sponsor-dashboard` |
| Admin | — (no onboarding) | separate portal at `/admin/login` | `/admin/dashboard` |

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
 Activity tab ──► My registrations & applications (trials/tournaments/sponsorships)
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

### 💰 Sponsor / Brand
**Landing:** `/sponsor-dashboard`.

```
 Onboarding done ──► /sponsor-dashboard
 Profile tab Quick Links:
   ├─ Dashboard (/sponsor-dashboard)
   ├─ Post Sponsor (/sponsor-posting)      → publish
   ├─ Discover (/athlete-discovery)        → shortlist athletes (/shortlist)
   ├─ Applications (/applications-inbox)   → /application-detail (accept/reject)
   └─ My Listings (/my-sponsorships)
 Athletes apply via /sponsor-pitch/:id (athlete side) → appear in Applications.
```

### 🛡️ Admin (separate portal)
**Entry:** `/admin/login` (email + password + any 6-digit 2FA).

```
 /admin/login ──► /admin/dashboard
                  ├─ Users (/admin/users) → verify/suspend/delete
                  ├─ Approvals (/admin/approvals)
                  ├─ Moderation (/admin/moderation) → report actions
                  ├─ Opportunities (/admin/opportunities) → approve/reject sponsorships
                  ├─ Notifications (compose / targeted)
                  └─ Expiry monitor · Categories (sports/cities/age-groups)
 Admin is NOT part of the user bottom-nav shell — it has its own navigation.
```

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
| sponsor | `/sponsor-onboarding` |
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
| Role onboarding (coach/academy/organizer/sponsor) | `lib/features/<role>/presentation/screens/<role>_onboarding_screen.dart` |
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
