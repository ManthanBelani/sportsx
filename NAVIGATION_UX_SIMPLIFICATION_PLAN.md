# SportX — Navigation & UX Simplification Plan

**Date:** 2025-09-25  
**Scope:** `sportx_app/lib` — router, shells, dashboards, profile, discovery  
**Goal:** Make the app usable on first open without tutorials. 4 taps to any core task, no dead tabs, one consistent bottom bar.

---

## 1. Executive Summary

Current build has **~123 routes + 2 shells** in `lib/core/router.dart:252-484` but only 2 real `ShellRoute`s. The other 4 roles (coach / academy / organizer / sponsor) fake a shell with a local `NavigationBar` + `_currentTabIndex` inside the dashboard `Scaffold` (`lib/features/*/presentation/screens/*_dashboard_screen.dart`). Result: 3 different bottom-bar visuals, `Under Construction` placeholders for 60% of tabs, and `context.push` that kills tab state and hides the bar.

Plan: **One adaptive shell, 4 tabs + centered create action, role-aware content.** Cut management routes, tab-ify the 791-line `ProfileScreen`, and unify FAB/create flow. Deliver in 3 phases; Phase 1 (navigation bugs + button anti-pattern) already landed in this branch.

---

## 2. Problems Found (Evidence)

| Area | File | Symptom |
|------|------|---------|
| Route sprawl | `lib/core/router.dart:252-484` (611 lines, 125 route objects) | Flat list, `GoRoute(path: '/network')` outside shell until recent fix — tapping Network hid the bar. Non-athlete forced redirect via `shellRouteScreens.contains(loc)` breaks deep links. |
| Fake shells | `organizer_dashboard_screen.dart:57-84`, `coach_dashboard_screen.dart`, `academy_dashboard_screen.dart:317`, `sponsor_dashboard_screen.dart:302` | Each embeds `Scaffold + NavigationBar + switch(_currentTabIndex)`. Tabs 1-3 push new screens instead of switching content → back stack depth 5+. Academy/Sponsor: `body: _currentTabIndex==0 ? _buildHomeTab() : Center(Text('Under Construction'))` |
| Mega-scroll profile | `lib/features/athlete/presentation/screens/profile_screen.dart:132-771` | 12 vertical sections + 8px dividers, mixes identity + role `QuickLinks` grid (6 items, `lib/features/athlete/presentation/screens/profile_screen.dart:688-736`). Empty “Tournament History / Performance Stats” repeat placeholder. No anchors. |
| Dashboard bloat | `organizer_dashboard_screen.dart:88-401` | Home tab packs stats (6 cards), capacity bar, pending banner, deadline alert, 8 quick actions (2 rows), category breakdown, My Trials, My Tournaments — duplicates Events & Analytics tabs. |
| Duplicate concepts | router | `Saved / Shortlist / /shortlist`, `Enquiry Inbox x3` (`/enquiry-inbox`, `/coach-enquiry-inbox`, `/applications-inbox`), `My Trials / My Tournaments / My Sponsorships / My Registrations` as 4 top-level routes. |
| Inconsistent chrome | `lib/core/router.dart:492-528` vs `scout_shell.dart:72` | `MainShell` = custom `Container(white 94% + shadow) + FAB via Matrix4.translation(-18)` + `_buildNavItem`; `ScoutShell` = `Material3 NavigationBar`; dashboards = another `NavigationBar`. 3 languages. |
| Deep push hell | `lib/core/router.dart:338-365` | Management: `/registration-management`, `/capacity-management`, `/results-publishing`, `/registrant-list`, `/registrant-detail` with `extra:{id,title}` — no breadcrumb, no "back to tab". |

---

## 3. Design Principles

1. **4 tabs max + 1 create** — Miller's law. Athlete: `Home | Discover | [Create] | Network | Me`. Other roles: `Dashboard | Manage | Inbox | Me` (same slots, same order).
2. **One shell, not five** — Single `AdaptiveShell` `ShellRoute` with role-aware tab config. Preserve tab state via `StatefulShellRoute` (`go_router` indexed stack) so back doesn't drop state.
3. **Tab does not push** — Tab tap = `go` + index change. Push only for detail/management. Never `context.push` from `onDestinationSelected`.
4. **Cards, not walls** — Buttons `ConstrainedBox(maxWidth:480)` centered (fix already applied `sportx_ui.dart:27-67`). Content `ConstrainedBox(maxWidth:640)` centered on tablet/web.
5. **Progressive disclosure** — Dashboard shows 1 stat row + 2 actions + recent list. Full analytics lives in one dedicated screen, not repeated.
6. **Profile → Tabs** — Split 12-section scroll into `About | Media | Activity | Links` internal `TabBar`.

---

## 4. Proposed Information Architecture

### 4.1 Sitemap (Before → After)

```
Before (125 routes)                      After (~65 routes, grouped)
├─ /home (MainShell)                     ├─ /home         ─┐
├─ /universal-search (shell)             ├─ /discover      │ AdaptiveShell (5 tabs, indexed)
├─ /saved (shell/FAB)                    ├─ /bookmarks     │
├─ /network (now shell)                  ├─ /network       │
├─ /profile (shell, mega-scroll)         ├─ /me  (tabs)   ─┘
├─ /activity-hub (separate)              ├─ /activity  (push, merged trials/tournaments/sponsorships + tab filter, replaces ActivityHubScreen:73)
├─ /coach-dashboard (+3 fake tabs)        ├─ /dashboard (role-aware screen, replaces 4 dashboards × 4 tabs = 16 pseudo-routes)
├─ /academy-dashboard                    ├─ /manage  (Unified Manage: MyTrials/MyTournaments/MySponsorships by role, replaces 3)
├─ /organizer-dashboard                  ├─ /inbox  (Unified Inbox: enquiries + applications + connections by role, replaces 3)
├─ /sponsor-dashboard                    ├─ /post/* (create, single grouped route with ?type=trial|tournament|sponsorship)
├─ /scout-* (separate ScoutShell)        └─ Scout stays as ScoutShell (already clean) BUT unify colors/shadow with MainShell
... + 80 detail/management routes        + detail stays, but group under /manage/:id/* (registration/capacity/results)
```

**Delete / merge:** duplicate `/my-registrations` dup already removed, Academy/Sponsor dead `Under Construction` routes, redundant `/discover` vs `/universal-search` → keep one `/discover`.

### 4.2 Bottom Navigation (AdaptiveShell)

Single `lib/core/shell/adaptive_shell.dart:1-120`:

```dart
StatefulShellRoute.indexedStack(
  builder: (ctx, state, shell) => AdaptiveShell(shell: shell, role: role),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/home', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/discover', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/bookmarks', ...)]), // FAB target or bookmarks
    StatefulShellBranch(routes: [GoRoute(path: '/network', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/me', ... )]), // internal TabBar for profile
  ],
)
```

Tab config by role (same slot order, different labels/icons/utils):

| Slot | Athlete | Coach/Academy/Organizer/Sponsor | Scout (keep own) |
|------|---------|----------------------------------|------------------|
| 0 | House · Home | LayoutDashboard · Dashboard | ScoutDashboard |
| 1 | Compass · Discover | List · Manage | Compass · Discovery |
| 2 | **FAB** `+` → CreateSheet (`lib/features/social/presentation/screens/create_sheet.dart:1-80`) | same FAB | same |
| 3 | Users · Network | Inbox · Inbox (badge) | Users · Connections |
| 4 | User · Me | User · Me | User · Me |

`MainShell._buildNavItem` (`lib/core/router.dart:558-584`) replaced with standard `NavigationBar` + custom FAB overlay to match `ScoutShell`. One shadow token `SportXShadows.e1` (`lib/theme`).

### 4.3 Create Flow (FAB)

Current `showCreateSheet` branches by role but visuals diverge. New: single `CreateSheet` with 2-3 primary actions per role:

- Athlete: Post Achievement, Join Trial/Tournament
- Coach/Academy: Create Trial, Edit Profile
- Organizer: Create Tournament, Publish Results
- Sponsor/Scout: Post Opportunity, Discover Athletes

Close sheet → `go('/post/...')` not `push`.

### 4.4 Profile Simplification (`profile_screen.dart:132-771`)

```
Before: SingleChildScrollView 12 sections
After:  Scaffold(AppBar + TabBar(About/Media/Activity/Links), TabBarView)

About     → header + bio + quick stats (3)
Media     → Media Gallery grid (was :502-564)
Activity  → Tournament History + Performance Stats (was :368-499) lazy-load, empty CTAs go to /discover
Links     → SocialLinks + Share Profile + Quick Links (now 3-col grid paginated, not 6 at once)
Settings/Logout → AppBar overflow menu, not giant footer cards
```

Cuts 771 → ~350 lines, removes duplicate empty placeholders.

### 4.5 Dashboard Simplification (All Roles)

`_buildHomeTab` rule: **1 stat row (3 cards max) + 2 primary actions + 1 recent list (3 items) + See all**.

- Organizer: drop 2nd stat row, capacity card moves into Analytics tab; Quick Actions 8→4; My Trials/My Tournaments each collapsed to `See all`.
- Coach: keep 3 stats, 4 actions, recent enquiries 3 (not 5).
- Academy/Sponsor: implement real Manage/Inbox branches instead of `Under Construction` + `push`.

---

## 5. Route Hygiene

- Group management under `/manage/tournaments/:id/{registrations,capacity,results}` — enables breadcrumb `Manage → Tournament → Registrations`.
- `extra:{id,title}` → typed `state.pathParameters` (`:id`) + lookup; no stringly-typed `extra`.
- Keep `redirect` simple: athletes access AdaptiveShell 0-4; other roles access same shell 0-4 with role-mapped screens; remove `shellRouteScreens.contains` force-redirect aside from `needsOnboarding` gate.

---

## 6. Interaction Details

- **Back & Android:** `PopScope(canPop: false, onPopInvoked: double-tap exit on slot 0, else go slot 0)` inside `AdaptiveShell`. Prevents pop to `/splash`.
- **Deep link:** `initialLocation` stays `/splash`; role check after load `go(_dashboardRouteFor)` replaced by shell branches (no redirect loop).
- **Empty states:** One component `EmptyState(icon, title, action)` instead of 4 duplicated copies.
- **Search:** Merge `/universal-search` + `/discover` + `/search-filter` + `/opportunities` into `/discover?tab=athletes|trials|tournaments` with single `SearchBar`.
- **Notifications:** Bell badge via `SportXIconButton(badge:3)` (`home_screen.dart:92`) wired to one `notifications` provider, not hard-coded 3.

---

## 7. Implementation Phases

### Phase 1 — Shipped (this PR)
- `lib/core/router.dart` fixes: admin login whitelist, onboarding role guard, `RouterNotifier` role listen, `/network` inside shell, duplicate route delete, FAB keep bar.
- Button anti-pattern: `ConstrainedBox(maxWidth:480)` centering for `admin_login`, `enquire`, `form_page_template`, `coach_profile_edit`, `profile`, `tournament_edit`, `organizer_dashboard`, `role_selection` (`pub` pass `dart analyze` 24 infos, 0 errors).

### Phase 2 — One Shell (1-2 sprints)
1. Create `lib/core/shell/adaptive_shell.dart` with `StatefulShellRoute.indexedStack` + unified `NavigationBar`.
2. Extract current dashboard `_buildHomeTab` bodies into branch screens (`dashboard/`, `manage/`, `inbox/`), delete local `NavigationBar` from 4 dashboards.
3. Move `/activity-hub` content into `/activity` tabbed push screen, update Home QuickTiles to go `/discover?tab=`.
4. Visual QA on mobile 360dp, 768dp tablet, web `ConstrainedBox(640)`.

### Phase 3 — Profile & IA Cut (next sprint)
1. Refactor `ProfileScreen` → `MeScreen` with internal `TabBar` (4 tabs) + pull content.
2. Merge `MyTrials/MyTournaments/MySponsorships` into `/manage` with role filter; merge 3 inboxes into `/inbox`.
3. Group management routes under `/manage/:id/*`; add breadcrumb AppBar.
4. Delete dead routes, target `~65` routes, re-run `router.dart` coverage test.

---

## 8. Success Metrics

- **Task time:** 4 taps to: Discover trial → detail → register → confirmation (currently 5-6 due to extra pushes).
- **Dead ends:** 0 `Under Construction` tabs (currently 6).
- **Back behavior:** 1 press from any detail returns to its tab, not exit.
- **Build health:** `flutter analyze` 0 errors, `flutter test widget` for shell tab persistence.

---

## 9. File Checklist for Reviewer

- `lib/core/router.dart` — shells, redirect, branch order
- `lib/theme/design_tokens.dart` — add `contentMaxWidth=640`, `actionMaxWidth=480`, `fabSize=58`
- `lib/shared/presentation/widgets/sportx_ui.dart` — `PrimaryButton` already `MainAxisSize.min` correct
- `lib/shared/presentation/widgets/form_page_template.dart` — bottom sheet constrained example
- `lib/shared/presentation/widgets/detail_page_template.dart:122-414` — sticky bar correct pattern
- `lib/features/athlete/presentation/screens/profile_screen.dart` — split candidate
- `lib/features/*/presentation/screens/*_dashboard_screen.dart` — fake shells to delete

---

## 10. Open Questions

- Keep `/bookmarks` as FAB destination or make FAB exclusive to Create? Current FAB `showCreateSheet` toggles bookmark vs plus based on `selected==2` (`lib/core/router.dart:549`) — confusing. Propose fixed `+` always.
- Do sponsors need bottom bar at all or separate web layout? `admin_web_layout.dart` suggests web uses side nav — unify later.
- Should `ScoutShell` merge into `AdaptiveShell` with scout theme token or stay isolated? Keep isolated short term to limit risk.
