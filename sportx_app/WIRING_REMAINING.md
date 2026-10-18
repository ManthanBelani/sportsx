# SportX — Remaining Screen Wiring

> Companion to `DESIGN_V3_IMPLEMENTATION_PLAN.md`. Lists every screen that still
> reads **local state only** and needs backend wiring before it is production
> data. Generated from a full audit of `lib/**/*_screen.dart` (174 screens).
>
> Wired today: **~141 screens** via Riverpod providers + Dio. The rest are below.

## 1. Blocked on new backend endpoints (highest priority)

These screens need **new API surface** — the endpoint or the model does not
exist server-side yet. UI + local interaction are complete.

| # | Screen | Route (S/D id) | Needed API | Notes |
|---|--------|----------------|-----------|-------|
| 1 | Academy Staff | `/academy-staff` (AC.11) | `GET/POST/PATCH/DELETE /me/academy/staff` | Roles list (head coach, physio, admin…), status toggle. Staff owner = academy profile. |
| 2 | Academy Collaborations | `/academy-collaborations` (AC.12) | `GET/POST /me/academy/collaborations` | Partner academies/brands; also aliased at `/my-collaborations` for organizers. |
| 3 | Invite Athlete | `/academy-invite-athlete` (AC.10) | `POST /me/academy/invitations` | Needs athlete lookup by email/phone + invitation status tracking. |
| 4 | Organizer Team | `/organizer-team` (OR.16) | `GET/POST/DELETE /me/organizer/team` | Co-organizer roles & permissions. |
| 5 | Post Announcement | `/post-announcement` (OR.14) | `POST /tournaments/:id/announcements` or `/organization/announcements` | Target: followers or tournament registrants. Feed renders via `postsProvider`. |
| 6 | Promote Event | `/promote-event` (OR.15, P2) | Promotion/promo-pack endpoint or integration stub | Low priority (P2); can stay mock until launch week. |
| 7 | Schedule Editor | `/schedule-editor` (OR.9) | `PATCH /tournaments/:id/schedule` | Fixtures/match slots; also used for trials day plan. Receives `extra: {'title'}` today. |
| 8 | Coach Go Live | `/coach-go-live` (CO.8, P2) | Live-session endpoint (or third-party RTM) | P2 — booking a webinar slot is the minimum viable wiring. |
| 9 | Admin Master Data | `/admin/master-data` (AD.9) | `GET/PUT /admin/master-data?group=sports|cities|categories` | Replaces admin manual DB edits; powers all directory filters. |
| 10 | Admin Expiry Rules | `/admin/expiry-rules` (AD.10) | `GET/PUT /admin/content-expiry-rules` | Per-content-type TTL + auto-expire flag. |
| 11 | Admin Leaderboard Config | `/admin/leaderboard-config` (AD.11) | `GET/PUT /admin/leaderboard-config` | Weights per sport/activity; feeds `leaderboardProvider`. |
| 12 | Admin Record Edit | `/admin/records/edit` (AD.6) | `PATCH /admin/records/:id` (generic) | Receives `extra: {'type','initial'}` — needs a generic admin CRUD API. |
| 13 | Admin Notification Targeting | `/admin/notifications/targeting` (S.7 flow) | `POST /admin/notifications/targeted` | Role/city/sport segment send. `ComposeNotificationScreen` already posts; this is its wizard variant. |
| 14 | Groups | `/groups`, `/group-detail` (S.21) | `GET/POST /groups`, `GET /groups/:id` | Currently seeded sample data. |
| 15 | Reviews | `/reviews` (S.24) | `GET /:subjectType/:subjectId/reviews`, `POST …/reviews` | List receives `{title, average}` via `extra`; needs real review rows. `/write-review` must post to it. |
| 16 | Verification (A.10) | `/verification` | `POST /me/verification-requests`, `GET /me/verification-status` | Blue-check apply + status (none→pending→verified/rejected). |
| 17 | Guardian Controls | `/guardian-controls` (A.9 related) | `GET/PUT /me/guardian-settings` | Content filter, spend limit, blocked contacts for minors. |

## 2. Endpoints exist, screen needs re-pointing (medium effort)

| # | Screen | Route | Gap |
|---|--------|-------|-----|
| 18 | Manage Sports | `/manage-sports` (AT.4) | Schema is local `SportEntry` list; needs a multi-sport athlete profile model (`GET/PUT /me/sports`) — backend currently stores a single sport on the profile. |
| 19 | Profile Completion | `/profile-completion` (AT.6) | Checklist is hard-coded; compute from `profileProvider` field coverage (photo, bio, sport, contact, achievements…) instead. |

## 3. Intentionally unwired (no action)

Static/UX screens — no data ever expected:

- Splash, Landing, Role Selection, Language, Permissions primer (auth flow is
  handled by `authProvider` on the login OTP screens).
- Legal (`/legal`), Help & Support (`/help-support`).
- Map view launcher (works with query passed via `extra`).

## 4. Retired sponsor-era screens (deleting later is optional)

Unreachable by design — routes redirect to `/opportunities` (backend returns
410 SPONSOR_REMOVED). Never instantiated. Safe to delete files in a cleanup PR:

- `features/sponsor/**` (8 screens), `features/scholarship/**` (2),
- `features/sponsorship/**` (2), `sponsor_pitch_screen.dart`,
- legacy `home/opportunities_screen.dart`, `home/search_screen.dart`
  (superseded by `/universal-search` + `/opportunities`).

## 5. Acceptance checklist (per wired screen)

1. I/O through a `FutureProvider`/`StateNotifierProvider` — no `setState` data.
2. Accepts auth failure: `resetUserScopedProviders(ref)` includes its provider.
3. Renders through `AsyncValue.when` / `AsyncDetailBuilder` (loading/error/empty).
4. Mutations invalidate the owning provider and show API errors via `SnackBarUtils`.
5. All `context.push/go` targets exist in `router.dart` (audited — currently clean).

## Verification state

- `flutter analyze` — clean on all touched files (remaining infos pre-existing).
- `flutter build apk --debug` — builds.
- Live API smoke test pending (needs running backend).
