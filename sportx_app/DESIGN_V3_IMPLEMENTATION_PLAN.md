# SportX Flutter — v3.2 Unified-Shell Implementation Plan

> Source of truth for the new design: `sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md`
> (129 screens, 6 roles + retained Sponsor). This document tracks the Flutter
> migration to that information architecture.

## 1. Objective

Rebuild the SportX app screens on a **shared component kit** with a **unified
shell**, so every role reuses the same chrome/navigation and only *content*
differs. This gives consistent UX, smaller bundle, easier maintenance, and
robust state management (no error states hand-rolled per screen).

## 2. Locked decisions

| Decision | Choice |
|---|---|
| Build approach | **Rebuild features on shared commons** (keep routing/data layer) |
| Sponsor role | **Keep both** — retain Sponsor *and* add Talent Scout |
| Router | Keep `go_router` |
| State | Keep **Riverpod 2** (+ codegen), add role/session layer |
| Networking | Keep `Dio` repositories |

## 3. Architecture

```text
lib/
├── core/
│   ├── role_config.dart        # NEW — role model, create tiles, more rows, accents
│   ├── router.dart             # shell + role guards (updated to consume role config)
│   └── session_scope.dart      # resetUserScopedProviders(ref) on login/logout/switch
├── shared/
│   ├── providers/
│   │   ├── role_config_provider.dart   # NEW — activeRoleProvider, roleConfigProvider
│   │   └── ...                          # existing shared providers
│   └── presentation/widgets/            # the component kit (commons)
│       ├── sportx_ui.dart               # buttons, top bar, chips, pills, cards (v2)
│       ├── async_state_view.dart        # AsyncDetailBuilder / DirectoryStateView
│       ├── directory_list_template.dart # reusable list screen
│       ├── detail_page_template.dart
│       ├── form_page_template.dart
│       └── skeleton.dart
└── features/<role>/presentation/screens/  # thin screens composed of commons
```

### 3.1 Unified shell (all roles)

Bottom nav, identical for every role:

```text
[Home] [Explore] [(+) Create] [Community] [More]
```

- **Home** → role dashboard: `/home`, `/coach-dashboard`, `/academy-dashboard`,
  `/organizer-dashboard`, `/scout-dashboard`, `/admin/dashboard`.
- **Explore** → `/universal-search` (alias `/explore`).
- **Create** → role-specific launcher sheet S.8 (`roleConfigProvider.createTiles`).
- **Community** → `/network` (alias `/community`).
- **More** → `/more` (**new** S.15 account hub; rows per role).

### 3.2 Role configuration (`core/role_config.dart`)

Single source of truth for per-role behaviour:

- `SportXRole` enum: `athlete, coach, academy, organizer, scout, sponsor, admin`.
- `roleConfigFor(role)` → `RoleConfig` with:
  - `label`, `accent` (role colour), `homeRoute`, `onboardingRoute`, `profileRoute`
  - `createTiles`: `CreateTile(id, label, subtitle, icon, tintBg, tintFg, route, priority)`
  - `moreRows`: `MoreRow(label, icon, route)`

Screens stay dumb: they read `roleConfigProvider` and render. Adding a role =
editing one file.

### 3.3 State management

- Root providers: `authProvider` (existing), `activeRoleProvider`,
  `roleConfigProvider` (new).
- Feature layer per module: `data/` (Dio repo) → `application/`
  (`AsyncNotifier` controllers) → `presentation/` (widgets).
- All async UI goes through `AsyncValue` + `AsyncDetailBuilder`/`DirectoryStateView`
  so loading/error/empty are consistent and never crash.
- Session scoping: `resetUserScopedProviders(ref)` on logout / account switch
  (already wired in `RouterNotifier`); new role-scoped providers must be added
  there.

## 4. Screen map (129)

| Section | IDs | Count | Flutter home |
|---|---|---|---|
| Auth & Onboarding | A.1–A.10 | 10 | `features/auth`, `features/onboarding` |
| Shared shell | S.1–S.30 | 30 | `features/*` + `shared/presentation/screens` |
| Shared detail/forms | D.1–D.17 | 17 | `features/*/…/detail` |
| Athlete | AT.1–AT.10 | 10 | `features/athlete`, `features/home` |
| Coach | CO.1–CO.8 | 8 | `features/coach` |
| Academy | AC.1–AC.12 | 12 | `features/academy` |
| Organizer | OR.1–OR.17 | 17 | `features/organizer`, `features/tournament` |
| Talent Scout | SC.1–SC.13 | 13 | `features/talent_scout` |
| Admin | AD.1–AD.12 | 12 | `features/admin` (web-style shell) |

Priorities: 94 P0 / 25 P1 / 10 P2. Build order: Foundation → Auth → Shared shell
→ Detail/forms → Athlete → Coach/Academy → Organizer → Scout → Admin.

## 5. Progress log

### Done
- **Role foundation**
  - `lib/core/role_config.dart` — roles, accents, home/onboarding/profile
    routes, per-role create tiles, per-role More rows.
  - `lib/shared/providers/role_config_provider.dart` — `activeRoleProvider`,
    `roleConfigProvider` (athlete fallback during auth transitions).
- **S.8 Create launcher** — `features/social/presentation/screens/create_sheet.dart`
  rewritten as `ConsumerWidget` driven by `roleConfigProvider.createTiles`
  (was a hard-coded universal list).
- **S.15 More / account hub** — `features/more/presentation/screens/more_screen.dart`
  new: profile summary card + role-driven rows + logout confirm.
- **Router wiring** — `/more` renders `MoreScreen`; shell "More" tab → `/more`
  for every role; onboarding redirect now allows any onboarding step
  (incl. `/guardian-consent`).
- **Shared component kit**
  - `shared/presentation/widgets/sportx_cards.dart` — `SportXCard`, `StatTile`,
    `CompletionCard`, `ProfileHeader`, `FeedPostCard`, `OpportunityCard`,
    `LeaderboardStrip`, `EmptyState`, `SegmentTabs`.
  - `shared/presentation/widgets/sportx_sheets.dart` — `showFilterSheet` (S.4),
    `showReportSheet` (S.26), `MediaUploadTile` (S.10).
- **Auth & Onboarding (A.6, A.7, A.8, A.9, A.10)**
  - `forgot_password_screen.dart` (A.6), `language_screen.dart` (A.7),
    `permissions_primer_screen.dart` (A.8), `guardian_consent_screen.dart` (A.9),
    `verification_screen.dart` (A.10). Routes: `/forgot-password`, `/language`,
    `/permissions`, `/guardian-consent`, `/verification`.
  - A.2 role selection already lists the 5 new-design roles incl. Scout.

### In progress
- **All role sections audited & completed on the shared kit:**
  - **Athlete (AT.1–AT.10):** new AT.4/AT.5/AT.6/AT.7/AT.10; rest existed.
  - **Coach (CO.1–CO.8):** only CO.8 missing → `coach_go_live_screen.dart`
    (`/coach-go-live`, P2). CO.4 `MyProgramsScreen` already has Active/Drafts/Past.
  - **Academy (AC.1–AC.12):** new AC.10 `invite_athlete_screen.dart`,
    AC.11 `academy_staff_screen.dart`, AC.12 `academy_collaborations_screen.dart`;
    AC.5 reuses `/showcase-athletes`, AC.7/AC.8 reuse facility screens.
  - **Organizer (OR.1–OR.17):** new OR.9 `schedule_editor_screen.dart`,
    OR.14 `post_announcement_screen.dart`, OR.15 `promote_event_screen.dart` (P2),
    OR.16 `organizer_team_screen.dart` (P2). OR.10 gallery aliases
    `/event-gallery`, OR.17 aliases `/my-collaborations`.
  - **Scout (SC.1–SC.13):** new SC.7 `compare_talents_screen.dart`,
    SC.8 `talent_report_screen.dart`; rest existed.
  - **Admin (AD.1–AD.12):** new AD.6 `admin_record_edit_screen.dart`,
    AD.9 `admin_master_data_screen.dart`, AD.10 `admin_expiry_rules_screen.dart`,
    AD.11 `admin_leaderboard_config_screen.dart`; also routed existing
    `AdminContentListScreen` (`/admin/content`) and picker.
- `roleConfigFor(...)` moreRows updated for athlete / coach / academy / organizer /
  admin to surface every new screen.

### Done (session: unified shell + kit migration)
- **Unified MainShell migration (all non-admin roles)**
  - `/coach-dashboard`, `/academy-dashboard`, `/organizer-dashboard` and
    `/scout-dashboard` now render **inside** the shared `MainShell`; each screen
    dropped its private `NavigationBar` / tab `IndexedStack` and became the role
    Home tab only (Events/Enquiries/Profile entry points moved to push routes +
    More rows).
  - `ScoutShell` deleted; scout sub-screens (`/scout-discovery`,
    `/scout-shortlist`, `/scout-connections`, `/scout-profile`) are plain pushed
    routes reachable from the dashboard quick actions + More rows.
  - Router: removed the "non-athlete roles bounce off shell screens" redirect
    (roles share the shell now; only athlete-only `/profile` still redirects).
  - `MainShell._onItemTapped` Home tab is role aware → `roleConfigProvider.homeRoute`.
- **Dashboard reskin onto the shared kit**
  - Coach dashboard: `StatTile` stats row, `CompletionCard` profile progress,
    weekly-availability card kept, quick actions push routes, recent enquiries
    jump to `/coach-enquiry-detail`.
  - Academy dashboard: `StatTile` row + registrations summary card; logout
    button removed (S.15 More is the single logout surface).
  - Organizer dashboard: home analytics content only; hand-rolled stat cards
    kept where live analytics feeds them; dead Events/Analytics/Profile tabs and
    their helpers removed.
  - Athlete HomeScreen already fully v2-kit (GreetCard/QuickTile); Scout
    dashboard likewise (GreetCard/QuickTile/AthleteAvatar) — verified, no drift.
- **S.28 Media Viewer wired**
  - `media_gallery_screen` tiles now push `/media-viewer` with
    `extra: {'media': [...resolved urls...], 'index', 'title'}` (matches the
    `/event-gallery` alias automatically).
  - Achievement certificate cards (AT.5) also open the shared viewer.
- **Achievements (AT.5) wired to the backend**
  - New `features/athlete/presentation/providers/achievements_provider.dart`
    → typed Phase-2 CRUD over `/me/achievements` (GET list, DELETE by id).
  - `AchievementsScreen` rebuilt as a `ConsumerWidget`: loading skeleton,
    error + retry, pull-to-refresh, empty state, delete confirm, edit push,
    certificate → S.28 viewer.
- **Session scoping audit**
  - Verified every user-scoped provider in `lib/` is invalidated by
    `resetUserScopedProviders(ref)`; added `achievementsProvider`.
- Admin keeps its web-style standalone shell by design (S inventory AD.*) —
  no bottom nav migration.

### Next
- Wire presentation-first screens to providers/APIs (manage-sports, staff,
  collaborations, master data, expiry rules, leaderboard config) — **blocked on
  backend endpoints**; achievements (AT.5) is done (`/me/achievements`).

## 6. Verification

- `flutter analyze <changed files>` after each increment.
- `flutter build apk --debug` per phase (do **not** re-add `sentry_flutter`; it
  breaks the Android debug build on AGP 8.11).
