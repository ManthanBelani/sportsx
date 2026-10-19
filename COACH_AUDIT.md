# Coach Role — Audit & Fix Log

> `flutter analyze --no-fatal-infos` → **0 errors, 0 warnings**.
> Coach screens are all registered in `router.dart` (14/14) — nothing was actually *missing*;
> the failures were behavioural. Nothing committed.

---

## 1. Fixed this session

### 1.1 Athlete search swallowed every error — looked like "no results"

`CoachNotifier.searchAthletes()` caught `DioException` and returned `[]` with the comment
*"Propagate search errors as empty list"* — the `catch` block in the screen was dead code,
because the exception could never escape.

**Effect:** if the search endpoint failed (401, 500, offline), the user saw "no athletes found"
and had no idea anything had failed. Silently indistinguishable from a genuine empty result.

**Fix:** returns a record `({rows, error})` instead of throwing or silently emptying. The screen
renders an explicit error state with the message.

### 1.2 Search fired an API request on every keystroke

`TextField.onChanged: _searchAthletes` — one `GET /athletes` per character typed. No debounce,
no cancellation.

**Fix:** 350 ms debounce (`_debounce`), plus a `_searchSeq` monotonic counter so a slow response
that arrives after the user has typed more is discarded. Prevents both request flooding and
results flashing back to stale queries.

### 1.3 Selection was snapshotted before the profile had loaded

`_loadSelectedAthletes()` was called from `initState()` and read `ref.read(coachProvider)`.
On first entry the provider has not fetched yet, so `showcaseAthletes` was empty — the screen
rendered an empty selection even for a coach who already had showcase athletes, and saving
immediately would have **wiped their existing list**.

**Fix:** `_syncSelectedFromProvider()` is invoked via post-frame callback once `isLoading` is
false, so the selection tracks the server. Guarded against clobbering in-progress edits via
`if (!_isSaving)`.

### 1.4 Partial PUTs could wipe unrelated profile fields  ← highest severity

`addCredential` / `removeCredential` / `updateFacilities` / `updateShowcaseAthletes` each sent a
body containing **only** the one changed key to `PUT /me/coach-profile`.

But `coach_profile_edit_screen.dart` writes to that **same endpoint with a full payload**
(~20 fields). So the endpoint is used both ways.

**If the backend treats PUT as a full replace** (standard REST), then adding a single credential
silently wipes the coach's bio, fees, experience, availability, and everything else — with no
error, because the request succeeds.

**Fix:** new `buildCoachProfilePayload(changed, current)` merges the current profile underneath
the changed field (stripping read-only `id`/`user_id`/`status`/`rating`/`avg_rating`/
`profile_photo_url`). Safe whether the backend merges or replaces. Applied to all four provider
methods and to the photo-upload PUT in the edit screen, which had the same hazard.

**This is the one to test manually first** — if the backend does full-replace, this bug was
actively destroying coach profiles.

### 1.5 `setState` after `await` with no `mounted` guard (×2)

- `add_credential_screen.dart` — image picker callback
- `coach_profile_edit_screen.dart` — photo upload callback

Both could touch a disposed `State`. Added guards.

### 1.6 Removed redundant `as DioException` casts (2×)

`ApiException.fromDio(e as DioException)` where `e` is already promoted to `DioException`.

---

## 2. Confirmed OK — no action needed

- **All 14 coach screens are routed.** Checked every screen filename against `router.dart`.
- **Enrollment flow is sound.** Pending/Active/Rejected tabs, approve/reject via PATCH with
  proper invalidation, correct error surfacing.
- **No empty dropdowns or TODO/FIXME/placeholder markers** anywhere under `features/coach/`
  (unlike the athlete onboarding screen, which had both).
- Most async/context handling is correct — the two bugs in §1.5 were the outliers.

---

## 3. NOT fixed — needs a decision

### 3.1 Go Live screen is entirely fake  ← largest gap

`coach_go_live_screen.dart` (189 lines) has **no provider, no API calls, no persistence**:

- `_scheduled` is a hardcoded `const` list of two fake sessions ("Batting Fundamentals — Live Q&A").
- "Start live now" just does `setState(() => _live = true)` — toggles a local `StatusPill`.
- "End session" likewise.
- Nothing is saved; leaving the screen discards everything.

It renders convincingly but does nothing. Either implement it (needs endpoints for create/list/
end session) or hide the route until then. **Currently a user can schedule what looks like a
webinar and lose it on exit.**

### 3.2 Partial-update safety net depends on backend behaviour

The merge in §1.4 protects the client, but the root question is still unanswered: does
`PUT /me/coach-profile` merge or replace? If it replaces, the two remaining full-payload writers
(`coach_profile_edit_screen` main save, `coach_profile_posting_screen`) are also at risk of
dropping `facilities` / `showcase_athletes`, which are **not** part of `Coach.toJson()`.
Recommend confirming against the backend and, ideally, moving to PATCH for partial updates.

---

## 4. Suggested next steps

1. **Manually test §1.4** — add a credential, then check bio/fees survived. This is the fix most
   likely to have been causing user-reported data loss.
2. Manually test §1.3 — open Showcase Athletes on a profile that already has athletes; confirm
   they load (previously they would appear empty, and Save would wipe them).
3. Decide on Go Live (§3.1): implement or hide.
4. Confirm PUT vs PATCH semantics with the backend.
5. Consider adding `facilities` / `showcase_athletes` to the edit screen's full payload if the
   backend does full-replace.

> All fixes verified by static analysis and code reading. **Nothing has been run against a live
> backend or in a running app.**