# SportX India — Remaining Work: Execution Plan

**Created:** 2026-08-11
**Goal:** Move from "UI + API exist but disconnected" (≈36% of screens wired) to production-ready.
**Companion doc:** `docs/UI-Completion-And-Backend-Wiring-Plan.md` (current status / evidence)

---

## How to read this plan

- Work is split into **6 phases (0–5)**. Phases 0 and 1 unblock everything; 2–4 are largely **independent and parallelizable** per module.
- Each task names the **exact file** and the endpoint/provider it consumes. The API endpoints already exist unless marked **[NEW BACKEND]**.
- Established patterns to reuse (do **not** invent new ones):
  - HTTP: `dioProvider` (`core/utils/api_client.dart`) — `AuthInterceptor` already injects the bearer token.
  - List + pagination: `DirectoryNotifier` (`shared/providers/directory_provider.dart`) — already has `load / loadMore / refresh` and loading/error/empty handling.
  - State shape: `StateNotifier<XState>` + `copyWith` (see `coach_provider.dart`, `auth_provider.dart`).
  - Screen shape: `ConsumerWidget` / `ConsumerStatefulWidget` → `ref.watch(provider)` → map states → feed `DirectoryListTemplate` / `DetailPageTemplate` / `FormPageTemplate` (these are pure presentation; keep them unchanged).

---

## Phase 0 — Foundation  *(≈0.5–1 day, sequential, do first)*

Unblocks Phases 1–2. No screens touched by the user yet.

- [ ] **0.1 Add detail (single-record) providers** in `shared/providers/directory_provider.dart`:
  - `academyDetailProvider = FutureProvider.family<Academy, String>((ref, id) => ...)`
  - Same for `coach`, `trial`, `tournament`, `scholarship`, `sponsorship`, `sportsVenue` — each `GET /{type}/{id}`.
- [ ] **0.2 Create the missing module providers** (one file each, mirror `coach_provider.dart`):
  - `features/saved/presentation/providers/saved_provider.dart` → `/me/saved` (list + save + unsave)
  - `features/trial/presentation/providers/trial_provider.dart` → trial register + provider trials (`/me/trials`)
  - `features/tournament/presentation/providers/tournament_provider.dart` → register + `/me/tournaments` + capacity + results
  - `features/organizer/presentation/providers/organizer_provider.dart` → re-exports tournament provider for organizer shell
  - `features/sponsor/presentation/providers/sponsor_provider.dart` → `/me/sponsorships`, `/athletes`, applications, shortlist
  - `features/shared/presentation/providers/enquiry_provider.dart` → `/me/enquiries`, `/enquiries/{id}`, reply
  - `features/shared/presentation/providers/activity_provider.dart` → `/me/activity`, `/me/registrations`, `/me/applications`
  - `features/academy/presentation/providers/academy_provider.dart` → `/me/academy` + `/me/trials` (academy shell)
  - `features/athlete/presentation/providers/media_provider.dart` → `/media/upload|reorder|{id}`
- [ ] **0.3 Add shared state widgets** in `shared/presentation/widgets/` (so screens stay small):
  - `async_state_view.dart` — maps `AsyncValue`/provider states → `loading` (Shimmer), `error` (retry), `empty`, `data`.
  - Keep `DirectoryListTemplate` calling `widget.onLoadMore()` → wire to `provider.loadMore()`.

---

## Phase 1 — Wire directories + detail screens to existing providers  *(≈1–1.5 days)*

Highest ROI: providers already exist, screens only switch from `dummyItems` to `ref.watch`.

- [ ] **1.1 Directory screens** → convert each to `ConsumerWidget`, watch its provider, feed `DirectoryListTemplate`, wire `onLoadMore`:
  - `academy/presentation/screens/academy_directory_screen.dart` → `academiesProvider`
  - `coach/presentation/screens/coach_directory_screen.dart` → `coachesProvider`
  - `trial/presentation/screens/trial_directory_screen.dart` → `trialsProvider`
  - `tournament/presentation/screens/tournament_directory_screen.dart` → `tournamentsProvider`
  - (scholarship + sports-venue list already wired — verify only)
- [ ] **1.2 Detail screens** → `ConsumerWidget` + `FutureBuilder`/`ref.watch(xDetailProvider(id))` → real params into `DetailPageTemplate`:
  - `academy_detail_screen.dart`, `coach_detail_screen.dart`, `trial_detail_screen.dart`, `tournament_detail_screen.dart`
  - scholarship/sponsorship/sports-venue detail routes (Phase 0.1 providers)
- [ ] **1.3 Saved** — `saved_screen.dart` → `savedProvider` (5 tabs filter by type), wire save/unsave toggle on directory cards.
- [ ] **1.4 Home `search_screen.dart`** (bottom-nav tab) → reuse `searchProvider` (currently separate from `universal_search_screen`).

**Exit criteria:** the four directory screens + four detail screens + saved load live paginated data; `grep dummyItems` returns 0 hits.

---

## Phase 2 — Wire provider self-service suites  *(≈3–4 days, parallelizable per module)*

Each sub-phase is independent — can be assigned to separate Agent Manager worktrees.

### 2A Academy *(≈0.5 day)*
- [ ] `academy_dashboard_screen.dart` → `/me/academy` + stats
- [ ] `academy_onboarding_screen.dart` → `POST /onboarding/academy`
- [ ] `academy_profile_posting_screen.dart` → `PUT /me/academy` (FormPageTemplate `onSubmit`)
- [ ] `trial_posting_screen.dart` → `POST /me/trials`
- [ ] `shared/.../my_trials_management_screen.dart` → `/me/trials` (list + publish/close)
- [ ] `shared/.../registrant_list_screen.dart` → `/trials/{id}/registrations`
- [ ] `shared/.../registrant_detail_screen.dart` → verify/reject/reminder endpoints

### 2B Coach *(≈0.5 day)*
- [ ] `coach_onboarding_screen.dart` → `POST /onboarding/coach`
- [ ] `coach_profile_posting_screen.dart` → `PUT /me/coach-profile`
- [ ] `coach_directory_screen.dart` (sponsor-directory) → `/coaches` with sponsor filter
- [ ] `shared/.../enquiry_inbox_screen.dart` → `/me/enquiries`
- [ ] `shared/.../enquiry_detail_screen.dart` → `/enquiries/{id}` + reply + markRead

### 2C Organizer *(≈1 day)*
- [ ] `organizer_dashboard_screen.dart`, `organizer_onboarding_screen.dart` → `/onboarding/organizer`
- [ ] `tournament_posting_screen.dart` → `POST /me/tournaments` + categories + publish
- [ ] `shared/.../my_tournaments_management_screen.dart` → `/me/tournaments`
- [ ] `registration_management_screen.dart` → `/tournaments/{id}/registrations`
- [ ] `capacity_management_screen.dart` → capacity GET/PUT + payment PATCH
- [ ] `results_publishing_screen.dart` / `results_view_screen.dart` → Results store/publish/index

### 2D Sponsor *(≈1 day)*
- [ ] `sponsor_onboarding_screen.dart` → `/onboarding/sponsor`
- [ ] `sponsorship_posting_screen.dart`, `my_sponsorships_management_screen.dart` → `/me/sponsorships`
- [ ] `athlete_discovery_screen.dart` → `/athletes`; `athlete_profile_view_screen.dart` → `/athletes/{id}`
- [ ] `applications_inbox_screen.dart` / `application_detail_screen.dart` → applications list + update
- [ ] `shortlist_screen.dart` → `/me/shortlist`
- [ ] `sponsor_dashboard_screen.dart` → `/me/activity` + sponsor metrics
- [ ] `shared/.../sponsor_pitch_screen.dart` → `POST /sponsorships/{id}/apply`

### 2E Athlete / shared remainder *(≈0.5 day)*
- [ ] `trial_registration_screen.dart` → `POST /trials/{id}/register`; `tournament_registration_screen.dart` → tournaments equivalent
- [ ] `registration_confirmation_screen.dart` → `GET /registrations/trials|tournaments/{id}` + `.ics` download
- [ ] `activity_hub_screen.dart` → `/me/activity` (+ registrations/applications tabs)
- [ ] `athlete/.../media_gallery_screen.dart` → `mediaProvider`

**Exit criteria:** all provider-suite screens show live data; `grep ref.watch|ref.read` count ≥ 80.

---

## Phase 3 — Finish admin wiring  *(≈0.5 day)*

(9 of 13 admin screens already wired.)

- [ ] `admin_login_screen.dart` → `POST /admin/login` + `/verify-2fa`
- [ ] `admin_dashboard_screen.dart` → `GET /admin/dashboard`
- [ ] `admin_content_list_screen.dart` / `admin_content_picker_screen.dart` → `/admin/content*`
- [ ] `notification_targeting_screen.dart` → notification template endpoints

---

## Phase 4 — New backends, then wire  *(≈3–4 days, sequential within each feature)*

These design features have **no API yet**.

### 4A Chat  *[NEW BACKEND]*
- [ ] Migrations: `conversations`, `conversation_participants`, `messages`
- [ ] `ConversationController` + `MessageController`: list, show, send, mark-read
- [ ] Routes under `/me/conversations`
- [ ] Wire `chat_list_screen.dart` + `chat_screen.dart`

### 4B Connections  *[NEW BACKEND]*
- [ ] Migrations: `connections` (follower/followee, status)
- [ ] `ConnectionController`: request, accept, list, requests
- [ ] Wire `my_connections_screen.dart` + `connection_requests_screen.dart`

### 4C Social feed  *[NEW BACKEND]* *(scope decision needed)*
- [ ] Posts + likes/comments models + `PostController`
- [ ] Wire `create_post_screen.dart` (already wired to something — confirm) + `post_detail_screen.dart`
- [ ] Home feed tab integration

**Exit criteria:** chat + connections + social end-to-end with seeded data.

---

## Phase 5 — Production hardening  *(≈2–3 days)*

Carry-over from the wiring plan; do in parallel with Phase 4.

- [ ] `EnsureAdmin2FAVerified` middleware + register; gate admin routes
- [ ] Signed URLs for private media (`media.download`) via `URL::temporarySignedRoute`
- [ ] FCM push for notifications (NotificationController already stores rows — add dispatch)
- [ ] Sentry exception tracking (Flutter + Laravel)
- [ ] Laravel Horizon for queues; move email/media jobs to queue
- [ ] Load test (1000 concurrent); Forge/Envoyer deploy config

---

## Timeline & milestones

| Milestone | Phases | Effort | Cumulative |
|-----------|--------|--------|------------|
| M1 — Foundation + directories wired | 0 + 1 | 2–2.5 d | 2–2.5 d |
| M2 — Provider suites wired | 2 | 3–4 d | 5–6.5 d |
| M3 — Admin complete | 3 | 0.5 d | 5.5–7 d |
| M4 — Chat/Connections/Social live | 4 | 3–4 d | 8.5–11 d |
| M5 — Production ready | 5 | 2–3 d | 10.5–14 d |

A single dev: ~2–2.5 weeks. **Parallelized (Agent Manager, one worktree per module for Phase 2): ~1–1.5 weeks.**

---

## Parallelization strategy (Agent Manager)

Phase 2 sub-phases (2A Academy, 2B Coach, 2C Organizer, 2D Sponsor, 2E Athlete/shared) touch **disjoint file sets** and all depend only on Phase 0. Run them as 5 parallel worktree sessions, each with:
- The provider file from Phase 0.x as a dependency (merge Phase 0 to base branch first),
- Module-specific screen list,
- Exit grep check + `flutter analyze` on the module.

Phases 4A/4B/4C are also mutually independent once their migrations land.

---

## Definition of Done (whole project)

1. `grep -rliE "dummyItems|List.generate\(" sportx_app/lib/features --include="*_screen.dart"` → **0 hits**.
2. `grep -rl "ref.watch\|ref.read\|dioProvider" sportx_app/lib/features --include="*_screen.dart" | wc -l` → **≥ 85**.
3. Every Phase-4 feature has a backend + wired screen + a passing integration test.
4. `flutter analyze` clean; admin routes behind 2FA; media behind signed URLs.
5. Manual smoke per role: athlete, coach, academy, organizer, sponsor, admin — full happy path against staging API.
