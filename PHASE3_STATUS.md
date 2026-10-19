# Phase 3 — Status & Handoff (resume here)

> `flutter analyze --no-fatal-infos` → **0 errors, 0 warnings**, 35 pre-existing info-level lints.
> Nothing is committed. All work is uncommitted in the working tree.

---

## 0. Most recent session — what was fixed

### Onboarding state management (was completely non-functional)
The screen compiled but could not be completed. Fixed:

| Bug | Fix |
|---|---|
| `TextEditingController()` created inside `build()` — every keystroke discarded typed text | `_CoreIdentityStep` → `StatefulWidget`, controllers created in `initState`, disposed in `dispose` |
| Fields lost when navigating back and forward | Step states seeded from `notifier.progress.formData` in `initState` |
| Date picker never displayed the chosen date | `_DatePickerField` → `StatefulWidget` with `_selectedDate` + `setState`; also handles external changes via `didUpdateWidget` |
| All 5 preference switches reset on rebuild and never reflected the stored value | `_PreferencesStep` → `StatefulWidget`, seeded from stored data, toggles now call `setState` |
| **Primary Sport + City dropdowns had `items: const []`** — unselectable, always submitted `null` | Wired to the existing `metaProvider` (`/meta/sports`, `/meta/cities`), with loading + empty states |
| Media/verification steps just wrote a string, no picker | Still not implemented — see Remaining Work |
| "Continue" advanced with empty fields | Added `validateCurrentStep()` in the notifier; required keys per step, role-specific keys for the profile step, error snackbar |
| Screen was unreachable | Registered at `/onboarding` in `router.dart` |

Also added `MultiStepOnboardingNotifier.progress` and `.fieldValue(key)` so widgets can read state without touching the protected `state` member.

### Leaderboard (was rendering hardcoded fakes)

| Bug | Fix |
|---|---|
| `height: height - 120` → **negative plinth height** for 3rd place (height=60) | Heights now passed directly (72/40/24) |
| Podium assigned `entries[0]` to **2nd place** and `entries[1]` to 1st | Corrected: index 0 = rank 1 |
| `"#${rank} of ${rank + 100}"` — invented participant count | Uses real `totalParticipants` from the API; degrades to `#rank` when 0 |
| `_categoryLabel()` returned literal `'XP'` regardless of filter (comment admitted it) | New `leaderboardCategoryUnit(category)` → XP / matches / wins / achievements / connections; threaded through rows and the rank card |
| Relied on API ordering | Explicit sort by `rank`, then `score` descending |
| `LeaderboardCategory.rank` — enum value that was not a real category | Removed |
| `leaderboardSportsProvider` duplicated `metaProvider` with a different endpoint | Deleted; screen now uses `metaProvider` |
| Dead `_categoryShortName` / `_formatScore` duplication | Removed |

**Still unverified:** the `/me/leaderboard` response contract remains an assumption (see below).

---

---

## 1. Where things stand

| Phase | Scope | Status |
|---|---|---|
| Phase 1 | Critical fixes (overflow, dedup, chat ordering, notifications, Google auth) | ✅ Complete |
| Phase 2 | Create bottom sheet, Community 4 tabs, groups, feed test data, role requirements, profile completion | ✅ Complete |
| Phase 3 | Leaderboard, chat real-time, notification deep-links, progressive onboarding | ⚠️ **Partially complete** |

### Phase 3 files created
| File | State |
|---|---|
| `sportx_app/lib/features/athlete/presentation/providers/leaderboard_provider.dart` | Created. Parses cleanly. |
| `sportx_app/lib/features/athlete/presentation/screens/athlete_leaderboard_screen.dart` | Created. Parses cleanly. |
| `sportx_app/lib/features/onboarding/presentation/providers/multi_step_onboarding_provider.dart` | Created + fixed. Parses cleanly. |
| `sportx_app/lib/features/onboarding/presentation/screens/multi_step_onboarding_screen.dart` | Created + syntax fixed. Parses cleanly. |

Wiring added: `/athlete-leaderboard` route in `router.dart`, "Leaderboard" entry in the athlete `moreRows` in `role_config.dart`.

---

## 2. Remaining work in Phase 3

### 2.1 Leaderboard (highest priority — UI exists, algorithm/UX unfinished)

**Backend contract is still an assumption.** Verify before shipping:
- Endpoint assumed: `GET /me/leaderboard?period=&category=&sport_id=`
- Assumed response shape: `{ data: { entries: [...], current_user: {...}, total_participants: n } }`
- Assumed sports endpoint: `GET /sports?limit=50`

**Known defects in the current implementation:**

1. `leaderboard_provider.dart`
   - `LeaderboardCategory` includes a `rank` enum value that is not a real category. Remove it.
   - `refreshLeaderboard()` helper is unused dead code.
   - `leaderboardSportsProvider` returns `({id, name})` records — confirm this matches existing sport provider conventions in the codebase, or reuse an existing `sportsProvider` instead of duplicating.

2. `athlete_leaderboard_screen.dart`
   - `_CurrentUserRankCard` shows `#${entry.rank} of ${entry.rank + 100}` — **hardcoded fake value**. Must come from a real `total_participants` field.
   - `_PodiumView` is unreachable: it indexes `entries[0..2]` and treats `entries[0]` as 2nd place, so the API must be guaranteed 0-indexed with index 0 = rank 1. Add explicit sorting, do not rely on API order.
   - `_PodiumPlace` uses `height - 120` for the plinth height, which produces a **negative height** for place 3 (height = 60). Fix the podium height math.
   - `_LeaderboardRow._categoryLabel` always returns `'XP'` regardless of the selected category. It needs the actual `LeaderboardCategory`.
   - `_LeaderboardRow` and `_CurrentUserRankCard` duplicate `_formatScore`. Extract to a shared helper.
   - Podium ordering/score display: currently shows podium only when `entries.length >= 3`; if the API returns fewer, there is a gap in the list indexing. Verify `entryIndex` math in `_buildLeaderboardContent`.

3. **Algorithm design is not done.** The planned intent (still to be agreed/implemented):
   - Period windows: weekly resets Monday, monthly, season, all-time.
   - Category scores: XP, matches played, wins, achievements, connections.
   - Need to decide: where scoring is computed (server vs client), tie-break rules, and how rank bands work for users outside the visible page (e.g. "you're #412 of 8,340").

**Recommendation:** confirm the backend contract first, then fix the client defects above. Do not build more UI until the response shape is fixed.

---

### 2.2 Chat (only message ordering was fixed in Phase 1)

`chat_provider.dart` currently has **only** the API response reversal. Still to do:

- Real-time updates (WebSocket / FCM data-message listener — no transport is wired yet).
- Optimistic send with rollback on failure.
- Read receipts.
- Typing indicators.
- Pagination / infinite scroll on older messages.
- Media support (image + video attachments in chat).
- A "requests" tab for pending message requests.

Design note: `PushNotificationService` already exists and has a background handler. Chat real-time should hook into that rather than creating a second transport.

---

### 2.3 Notifications

Already done in Phase 1:
- Guarded FCM token registration, auth lifecycle hooks.
- Pending-notification storage + processing while logged out.
- Normalized deep-link parsing.

Still to do:
- Complete the background-message handling path (background handler exists; the foreground routing into the router is incomplete).
- Verify deep-link handling for every notification type end-to-end.

---

### 2.4 Google Sign-In

Phase 1 fixed role handling (`isSignUp`), error normalization, cancellation handling.

Blocked on config:
- Full Google Sign-In **web** support and reliable native auth need `GOOGLE_SERVER_CLIENT_ID` wired into the build. This has **not** been done.
- Confirm `isSignUp: true` is passed on all signup screens, otherwise the role is not sent to the backend.

---

### 2.5 Progressive onboarding (screen exists, needs real validation)

`multi_step_onboarding_screen.dart` + `multi_step_onboarding_provider.dart` were built and then syntax-fixed this session.

**These are known-unfinished and must be addressed:**

1. `onboardingStepsForRole(role)` in the provider is the single source of truth now (the duplicated copy was removed). `MultiStepOnboardingNotifier.stepsForRole` delegates to it.

2. ~~`_CoreIdentityStep` state management~~ — **FIXED** (see §0).

3. ~~`_DatePickerField` never updates~~ — **FIXED** (see §0).

4. ~~`_PreferencesStep` local bools~~ — **FIXED** (see §0).

5. ~~Empty sport/city dropdowns~~ — **FIXED**, wired to `metaProvider` (see §0).

6. **Media and Verification steps are still non-functional.** Tapping "Profile Photo" / "Cover Photo" / "Government ID" only writes `{..._action: 'pick'}` into form data. No image picker, no upload. Either implement picking + upload (needs an upload endpoint) or hide these steps. Note validation does *not* require them, so they can be deferred safely.

7. ~~No step validation~~ — **FIXED** via `validateCurrentStep()` (see §0). Note it validates a curated per-step key list rather than reading `role_requirements.dart` directly; the two can drift and should be reconciled.

8. ~~Not routed~~ — **FIXED**, registered at `/onboarding`. Still decide whether it replaces the per-role onboarding screens or sits alongside them. `role_config.dart` still points athletes at `/onboarding-1`.

9. Endpoint assumption: `POST /onboarding/{role}` with a flat `{formData}` map. **Unverified** — confirm with backend. Per-role payload shapes will likely differ.

10. ~~Deprecated API usage~~ — **FIXED** (`initialValue`, `activeThumbColor`).

---

## 3. Known risks / things to verify

- **Profile Completion screen** uses dynamic profile-field access and `profileProvider`. The runtime shape has not been validated against the real profile model/API. Check this before demoing.
- **Community groups endpoints** are assumed: `GET /groups`, `GET /me/groups`, `POST /groups/:id/join`, `POST /groups/:id/leave`.
- **Combined posts** provider falls back to test data on API error or empty response — confirm this is acceptable for production or gate it behind a debug flag.
- `/create` route still exists but is no longer used by the FAB.

---

## 4. Suggested order to resume

1. Confirm the leaderboard backend contract (`/me/leaderboard`) — still an assumption.
2. Manually smoke-test `/onboarding`: type in every field, go back and forward, pick a date, toggle switches, select sport/city, confirm Continue is blocked until required fields are filled.
3. Decide media/verification steps: implement upload, or remove them from the step list.
4. Reconcile `validateCurrentStep()` with `role_requirements.dart` so they cannot drift.
5. Decide whether `/onboarding` replaces or accompanies the per-role onboarding screens; update `role_config.dart`.
6. Chat real-time — decide the transport first.
7. Google Sign-In — get `GOOGLE_SERVER_CLIENT_ID` into the build config.
8. Final pass: `flutter analyze`, smoke test feed, groups, create sheet, chat, notifications, Google auth.

> Nothing above has been run in a real app. All fixes are verified by static analysis and code reading only.

---

## 5. Commands

```bash
cd /home/rainstreamweb/Pictures/test/sportsx/sportx_app
flutter analyze --no-fatal-infos          # expect 0 errors
```

Repo root: `/home/rainstreamweb/Pictures/test/sportsx`
Full analysis of the original scope: `ATHLETE_SIDE_FIX_PLAN.md`