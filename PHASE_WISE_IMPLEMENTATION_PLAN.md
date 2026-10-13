# SportX India — Phase-Wise Implementation List (Build Order)

> Generated from `docs/` on 2026-10-13. Synthesized from:
> `PRD.md` §8 · `Phased-Roadmap.md` (v3 delta) · `Backend-Feature-Delta.md` §9 build order + §11 endpoint catalog ·
> `Functional-Requirements.md` · `Database-Design.md` · `API-Specification.md` ·
> `Implementation-Execution-Plan.md` · `Development-Checklist.md` Phase 8 · `Jira-Tickets.md` ·
> `Talent-Scout-Implementation-Guide.md` · `UI-Completion-And-Backend-Wiring-Plan.md`
>
> **Canonical rules (v3):**
> - Roles = `athlete, coach, academy, organizer, scout, admin`. `sponsor` REMOVED (sponsorship = `opportunities.type`).
> - Auth = phone **OR** email + 6-digit OTP (P0, resend timer) + password login kept. Google = deferred (P1).
> - Guardian consent mandatory for <18 (P0). Verification request + admin queue + user mgmt = P0.
> - No in-app payments (parked P2). Map view parked. Multi-role accounts parked.
> - New P0 modules: opportunities, programs, facilities, social feed, follow/connect, 1-to-1 chat, blocks/reports, leaderboard, positions master, opportunity expiry.

**How to use:** build phases in order. Each phase lists Backend (Laravel `sportx-api`), Mobile (Flutter `sportx_app`), Admin, and ✅ Exit criteria (demo/test). Check boxes as you go.

---

## Phase 0 — Project Foundation (1 week)

**Goal:** monorepo runs, DB migrates, auth skeleton works.
**Docs:** `Phased-Roadmap.md` P0 · `Backend-Architecture.md` · `Mobile-Architecture.md` · `Jira P0-E1`

### Backend (`sportx-api`)
- [ ] Laravel 11 scaffold: `composer create-project`, `.env`, `config/sportx.php`, CORS (Flutter origin), Sanctum, `/api/v1` prefix
- [ ] Migrations (all tables per `Database-Design.md` order): users, all profile tables, sports/cities/age_groups/positions, trials/tournaments/categories/registrations/results, opportunities, programs/facilities, posts/likes/comments, follows/connection_requests, conversations/messages, blocks, saved, reports, verification_requests, guardian_consents, leaderboard, notifications/reminders, expiry rules, media
- [ ] Seeders: sports (5+), cities (10+, 3+ states), age_groups (6), positions, expiry rules, dev data (sample academies/coaches/trials/athletes)
- [ ] Middleware: `auth:sanctum`, `role:{athlete,coach,academy,organizer,scout,admin}`, `EnsureAdmin2FAVerified`
- [ ] CI skeleton: lint + test on push, staging deploy on merge
- [ ] Health endpoint `GET /system/health`

### Mobile (`sportx_app`)
- [ ] `flutter create`, feature-first folders, `Dio` + `AuthInterceptor` (`core/utils/api_client.dart`), Riverpod, `go_router` shell
- [ ] Theme tokens: Primary `#1677ff`, Surface `#f7f8fa`, Text `#111111`, Muted `#6b7280`, Inter, 8px grid
- [ ] Shared widgets: `async_state_view.dart` (loading Shimmer / error+retry / empty / data), `DirectoryListTemplate`, `DetailPageTemplate`, `FormPageTemplate`
- [ ] State pattern: `StateNotifier<XState>` + `copyWith`; list pagination `DirectoryNotifier` (`load/loadMore/refresh`)

✅ **Exit:** `php artisan migrate && db:seed` clean; Flutter boots; login token hits a test endpoint.

---

## Phase 1 — Roles, Auth, Guardian, Verification (P0 core trust)

**Goal:** any role can sign up → OTP → onboarding → token.
**Docs:** Delta `BE-M1.x` · FR-AUTH-1…16 · FR-GUARD-1…3 · FR-VERIF-1 · Screens `A.1–A.10`

### Backend
- [ ] `UserRole` enum: drop `sponsor`, add `scout`; update policies/seeders/admin filters; migrate any sponsor rows → opportunities (delta §4/§6)
- [ ] OTP stack: `otp_codes` (hash, expiry 5min, attempts≤5, channel), `POST /auth/send-otp`, `/auth/verify-otp`, `/auth/resend-otp` (60s cooldown), `RateLimitOtp`; support SMS **+** email (SMS vendor = blocking, AS-03)
- [ ] Keep password auth: `POST /auth/register`, `/auth/login` (password **or** OTP branch), `/auth/logout`, `GET /auth/me`, `POST /me/change-password`, `POST /me/delete-account` (soft, 90-day purge)
- [ ] Onboarding: `GET /onboarding/{role}`, `POST /onboarding/athlete|coach|academy|organizer|scout` (❌ no `/onboarding/sponsor`); 30 fields/role per Mandatory Fields
- [ ] Guardian: `guardian_consents` table, `POST /guardian/consent` (OTP to guardian), `POST /guardian/verify-otp`, `GET/PUT /me/guardian-controls`; gate: DOB<18 → `pending` until verified; restricted visibility/messaging defaults
- [ ] Verification: `verification_requests` (morph, ID+org proof via signed URLs, notes, status, reviewer, reason), `POST/GET /me/verification`, `GET /admin/verification` + approve/reject+reason, badge on profile/card/search, `VerificationDecided` notification
- [ ] Checklist: `GET /me/completion-checklist` (per-role missing items + deep links, %)

### Mobile
- [ ] Screens: S1 Splash (3-dot pulse) → S2 Role Selection (5 cards, no sponsor) → S3 Sign Up (name first, phone/email, T&C, Google button placeholder) → S4 OTP Verify (6-digit + timer) → S5 Login (password/OTP toggle, forgot link)
- [ ] Onboarding wizards: A1/A2 athlete, C1 coach, AC1 academy, O1 organizer (+docs upload), TS1/SC.1 scout (30 fields each)
- [ ] Guardian screens `A.9` + Parental Controls `AT.10`; Verification Request `A.10` (upload, status Pending/Verified/Rejected+reason)

✅ **Exit:** sign up as each of 5 roles via phone AND email OTP; minor signup blocked until guardian OTP; verification request → admin approve → blue check shows.

---

## Phase 2 — Profiles, Media, Achievements (30 fields)

**Goal:** complete rich profiles for all roles.
**Docs:** Delta `BE-M2.x` · FR-ATH-1/2 · FR-COACH-1 · FR-ACAD-1 · FR-PLAT-7

### Backend
- [ ] `talent_scout_profiles` (30 fields) + `talent_scout_sports` pivot; `GET/PUT /me/scout-profile`, `GET /scouts/{id}` (About+Activity only), `GET/PUT /me/organizer-profile`, `GET /organizers/{id}`, `GET /athletes/{id}` (minors restricted)
- [ ] `athlete_sports` pivot: `playing_role, level, experience_years, is_primary`
- [ ] `achievements` typed CRUD: `GET/POST /me/achievements`, `PUT/DELETE /me/achievements/{id}` (title/type/sport/level/year/certificate/desc, owner morph athlete/coach)
- [ ] Media: `POST /media/upload` (+caption+sport tag), `PUT /media/reorder`, `DELETE /media/{id}`, `GET /me/media`; private docs via signed URLs
- [ ] Privacy: `PUT /me/privacy` (`profile_visibility`, `who_can_message/connect`); `social_links` JSON; `GET/PUT /me/settings` (visibility/messaging/language/push toggles)

### Mobile
- [ ] Profile view/edit + Media Gallery (upload/delete/reorder) per role: A4/A5/A6, C2, AC2, O-profile, TS2/SC.3
- [ ] Completion checklist UI `AT.6` with deep links; photo/media viewer `S.28`

✅ **Exit:** each role profile saves all 30 fields; achievements + gallery persist; privacy settings enforced.

---

## Phase 3 — Discovery, Search, Filters, Saved

**Goal:** browse everything (LinkedIn-style Explore).
**Docs:** Delta `BE-M3.x` · FR-DISC-1…7 · FR-ATH-4/5/7/9/15 · Screens `S.2–S.8`, `D.1–D.5`

### Backend
- [ ] Directories (existing, extend): `GET /academies /coaches /trials /tournaments /sports-venues` + filters `position/level/facilities/price/rating`, distance sort (city-centroid MVP), registration-status on events
- [ ] `GET /me/home` (role-aware: greeting, completion %, leaderboard strip, counts, feed preview); `GET /explore` (grouped sections)
- [ ] `GET /search` (+ `athletes` group), `POST /me/recent-searches`; `GET /meta/positions`, `/meta/facilities` (sports/cities/age-groups exist)
- [ ] Saved: `GET/POST/DELETE /me/saved` — morphs `post, opportunity, event` (+ existing 6)

### Mobile
- [ ] Shell: bottom nav `Home / Explore / (+) Create / Community / More` (`S.1`, `S.15`), role Home dashboards (AT.1/CO.2/AC.2/OR.2/SC.2), Create launcher `S.8`
- [ ] Universal Search `S.5` + results tabs `S.6/S.7` + Filter Panel `S.4` (sport/city/age/position/level/facilities/price/date, sort relevance/distance/rating)
- [ ] Directory list `T1/S.3` + Detail `T2/D.1–D.5` for academy/coach/trial/tournament/venue; Save ♡ + overflow ⋮ + Report entry on every detail
- [ ] Saved screen `S.20` (tabs by type); Settings `S.22`, Help `S.24` (FAQ + contact)

✅ **Exit:** search "cricket ahmedabad" → tabbed results incl. athletes; filter → detail → save → appears in Saved; report works.

---

## Phase 4 — Opportunities + Applications (unified, replaces sponsor/scholarship)

**Goal:** providers post, athletes apply in-app, providers review.
**Docs:** Delta `BE-M5.x` · FR-OPP-1…5 · FR-ATH-11/13 · Screens `D.9/D.10`, `AT.8`, `AC.9`, `SC.11/12`

### Backend
- [ ] `opportunities` (provider morph academy/organizer/coach/scout, type scholarship/sponsorship/tryout/camp, eligibility, benefits/amount, deadline, docs, status) + `opportunity_applications` (pitch/docs/snapshot/status)
- [ ] Endpoints: `GET /opportunities` (type/sport/age/deadline filters), `GET /opportunities/{id}`, `POST /me/opportunities`, `PUT/PATCH /me/opportunities/{id}` (+publish/close), `POST /opportunities/{id}/apply` (409 duplicate), `GET /me/opportunities?type=applied|saved|created`
- [ ] Migrate `scholarships/sponsorships → opportunities` (`legacy_type`), `sponsorship_applications → opportunity_applications`; old endpoints → 410
- [ ] Applicant review (P1-ready, build API now): `GET /opportunities/{id}/applications`, `PATCH …/applications/{app}` (shortlist/decline+note)
- [ ] Expiry: add `opportunity` to `expiry_rules` + sweep; notifications for new application/decision

### Mobile
- [ ] Opportunity list/detail/apply form `D.9/D.10`; My Opportunities `AT.8` (Applied/Saved/Created + status chips); provider posting + management (reuse SP3/SP4 layouts); applications inbox `SP7/SP8` + shortlist `SP9`

✅ **Exit:** academy posts scholarship → athlete applies with pitch → provider shortlists → athlete sees status; expired-by-deadline auto-hides.

---

## Phase 5 — Programs, Facilities, Venues + Enquiries

**Goal:** training inventory live, enquiries open chat threads.
**Docs:** Delta `BE-M6.x` · FR-PROG-1…4 · FR-ENQ-1…4 · Screens `D.11–D.13`, `CO.4/5`, `AC.7/8`

### Backend
- [ ] `programs` (owner morph coach/academy; title/sport/age/duration/mode/price/schedule/about/status draft/active/past): `GET /me/programs`, `POST/PUT /me/programs…`, `GET /programs/{id}`, `POST /programs/{id}/enquire` (→ chat thread)
- [ ] `facilities` (academy_id, name/type/size/amenities/images): `GET /me/facilities`, `POST/PUT/DELETE …`, `GET /facilities/{id}`; migrate `academies.facilities` JSON → rows
- [ ] Enquiries: add `subject_type = program, opportunity`; `POST /enquiries`, `GET /me/enquiries` (Chats/Requests tabs), `GET/POST /enquiries/{id}(/messages/read)`; enquiry creation returns/opens thread

### Mobile
- [ ] Program list/form/detail + enquiry button; Facility list/form/detail (tabs All/Grounds/Indoor/Gym/Other); Coach/Academy program management (Active/Drafts/Past); Enquiry modal `T3/A11` + inbox `T4/C4/C5/AC8/AC9`

✅ **Exit:** coach creates program → athlete enquires → thread appears in both inboxes; facility CRUD reflects on academy detail.

---

## Phase 6 — Social, Network, Chat, Safety (verify-first)

**Goal:** LinkedIn core — feed, graph, messaging, blocks.
**Docs:** Delta `BE-M7.x` · FR-SOC-1…7 · FR-TRUST-1…4 · FR-ENQ-3 · Screens `S.9–S.14`, `S.17–S.19`, `S.23`, `S.26–S.28`

> ⚠️ `UI-Completion-And-Backend-Wiring-Plan.md` says `posts/conversations/connections` may already be partially built — **verify tables + `/posts` routes first**, then complete to v3 schema (`follows`, `connection_requests`, `conversation_participants`, `blocks`).

### Backend
- [ ] Posts/feed: `posts` (author morph, text/media/hashtags/sport/audience), `GET /feed` (For You/Following/Athletes/Coaches/Academies/Events), `POST /posts`, `GET/PATCH/DELETE /posts/{id}`, `POST/DELETE /posts/{id}/like`, `GET/POST /posts/{id}/comments`, `DELETE /comments/{id}`
- [ ] Network: `follows` + `connection_requests` — `POST/DELETE /follow/{type}/{id}`, `GET /me/followers|following`, `POST /connections` (with purpose), `GET /me/connections` (Connections/Requests/Sent), `PATCH /connections/{id}` (accept/decline → unlock chat + `ConnectionAccepted` notify), `DELETE /connections/{id}`
- [ ] Chat: `conversations` (+participants) + `messages` (text P0, media P1) — `GET/POST /conversations`, `GET /conversations/{id}`, `POST …/messages`, `PATCH …/read`; rules: accepted-connection OR enquiry thread only, no cold DMs; minors = guardian-allowed only; 90-day purge default
- [ ] Safety: `blocks` (`POST/GET/DELETE /blocks…`, hide both ways, disable chat/follow); reports extend morphs `user, post` (+opportunity/program/facility): `POST /reports`, `GET /me/reports`

### Mobile
- [ ] Feed + Create Post `S.9` + Post Detail `S.27` (like/comment/save); Community `S.12–S.14`; Follow buttons; Connections `S.19`; Chat inbox `S.17` (Chats/Requests, unread) + Thread `S.18` (report/block entry); Safety Centre `S.23`; Report sheet `S.26`; Media viewer `S.28`

✅ **Exit:** post → like/comment; follow + connect → accept → chat unlocks; block hides + disables chat; report lands in admin queue.

---

## Phase 7 — Leaderboard + Scout Extensions

**Goal:** credibility engine + full scout workflow.
**Docs:** Delta `BE-M8.x`, `BE-M10.x` · FR-LB-1…4 · FR-TS-1…13 · Screens `S.6`, `AT.1`, `SC.2–SC.13`

### Backend
- [ ] Leaderboard: `leaderboard_scores` (athlete/sport/points/season) + `leaderboard_seasons`; `RecalculateLeaderboardJob` (on verified achievement, completion milestones, participation + nightly rebuild), `ResetLeaderboardSeasonJob`; `GET /leaderboard` (sport/location/age, podium + ranks 4–10), `GET /leaderboard/strip` (top-5 home); minors anonymized (first name + initial); coach/academy/team/event tabs P1-ready
- [ ] Scout: `scout_shortlists` (status under_review/good/high/final + tags + private notes, unique scout+athlete): `GET/POST/DELETE /me/shortlist` (+PATCH status/tags/notes, pipeline tabs); `observations` (rating/note/media): `POST/GET /observations`; `POST /athletes/{id}/contact` (purpose; U-18 → guardian notify, consent before chat); dashboard aggregates (top-talents slice via leaderboard, upcoming trials, counts — or fold into `/me/home`)

### Mobile
- [ ] Leaderboard screen `S.6` + home strip `AT.1` (filters + podium + ranks 4–10)
- [ ] Scout: Dashboard `SC.2`, Discovery `SC.4` (sport/age/location/skill/position/achievements filters), Athlete View (history/achievements/media + Shortlist/Connect CTAs), Shortlist `SC.5/6` (pipeline tabs + edit status/tags/notes), Observations `SC.10`, Contact `SC.13` (purpose; guardian notice for U-18)

✅ **Exit:** verified achievement moves leaderboard rank; scout discovers → shortlists with status → observes → contacts (minor routes to guardian).

---

## Phase 8 — Events, Registrations, Supply-Side Management

**Goal:** trials/tournaments/camps end-to-end with registrant ops.
**Docs:** Delta `BE-M4.x` · FR-ATH-8/10/14 · FR-ACAD-2…10 · FR-ORG-1…10 · FR-COACH-8 · Screens `D.6–D.8`, `AT.9`, `AC.3–AC.6`, `OR.4–OR.8`

### Backend
- [ ] Unified create `POST /me/events?type=trial|tournament|camp` (map to `trials`/`tournaments` tables — keep tables, unify at API layer); `GET /me/events` (My Events, Upcoming/Past + counts), `GET /events/{id}`, `PUT/PATCH /me/events/{id}` (+publish/close)
- [ ] Register: `POST /trials/{id}/register`, `/tournaments/{id}/register` (duplicate guard + capacity); `GET /me/registrations` (AT.9 Upcoming/Past), `DELETE /me/registrations/{id}` (cancel); `RegistrationDecided` → notify athlete (push + in-app)
- [ ] Manage: `GET /events/{id}/registrations` (All/Approved/Pending + search + bulk), `GET /registrations/{id}` (+docs), `POST /registrations/{id}/approve|reject`, per-category capacity meters + manual `payment_status` flag (info only), waitlist toggle
- [ ] Export: `GET /events/{id}/registrations/export` (CSV/Excel, role-scoped); results: extend `tournament_results` pattern (publish per category + public bracket view)

### Mobile
- [ ] Athlete: Trial/Tournament detail → Registration form `A14/A18/T3` → Confirmation `A15` (reg ID + .ics + reminder toggle) → Activity Hub `AT.9/A24`
- [ ] Academy: Dashboard `AC.3`, Trial posting `AC.4`, My Trials `AC.5/AC.6`, Registrant list/detail `AC.6/OR.8` (verify/reject)
- [ ] Organizer: Dashboard `OR.2`, Event create `OR.5`, My Events `OR.4/AC.6`, Registration mgmt `OR.7/O7`, Capacity `O8`, Results publish/view `O9/O10`

✅ **Exit:** organizer creates tournament (3 categories + capacity) → athlete registers → organizer approves → athlete sees Confirmed + notification; CSV exports; results public.

---

## Phase 9 — Admin P0, Expiry, Notifications, Search Polish

**Goal:** moderated, self-cleaning, reminded platform.
**Docs:** Delta `BE-M11.x` · FR-ADMIN-1…13 · FR-NOTIF-1…5 · FR-DISC-6/7 · Screens `AD.1–AD.12`, `S.16`

### Backend
- [ ] Admin: `POST /admin/login`, `/admin/verify-2fa` (enforced); `GET /admin/dashboard` (listings/flags/expirations/signups/verifications/users-by-role); `GET /admin/users` (+role/status filters), detail, suspend/ban + audit; verification queue approve/reject; content CRUD `/admin/content/{type}` (+opportunities/programs/facilities/posts); moderation (`…/moderation/**` + suspend action, reporter+reported notify); masters (+`positions`); expiry (`/admin/expiry*` + opportunity type)
- [ ] Expiry engine: `expires_at` on publish, `SweepExpiredContentJob`, events, Override/Restore
- [ ] Notifications: enum extend (follow, connection, message, enquiry, registration decision, verification result, mention, broadcast); events/listeners (`RegistrationDecided`, `VerificationDecided`, `ConnectionAccepted`, `ContentReported`); reminder subs on save/confirm (T-2d/T-1d defaults) + `SendDueRemindersJob`; `GET /me/notifications?tab=` (All/People/Opps/Events/Mentions, Today/Yesterday/Week), read/read-all, `POST /me/device-tokens` (FCM)
- [ ] Analytics log `POST /analytics/events` (signup/registration/enquiry/shortlist funnel); search polish (trending, recents, relevance, enriched cards)

### Mobile
- [ ] Notifications Center `S.16` (tabs + grouping + unread + mark-all-read); reminder toggles; Admin web panel views (`admin/*.blade.php`: login/dashboard/content/moderation/expiry/categories/users/verification)

✅ **Exit:** report → admin queue → remove → both parties notified; expired trial auto-expires + restorable; saved-item reminder fires; admin adds sport/city → appears in filters.

---

## Phase 10 — Hardening & Polish (production-ready)

**Goal:** secure, fast, observable.
**Docs:** `Security-and-NonFunctional.md` · `Production-Backend-Plan.md` · `Phased-Roadmap.md` P4 · `Development-Checklist.md` P6–P7

- [ ] Auth hardening: rate limits + 429/Retry-After, OTP expiry/attempts, CORS review, audit log (moderation/status/override)
- [ ] Media: MIME validation, signed URLs (60-min), private docs access-controlled
- [ ] Queues: Horizon; email/media/push jobs queued; FCM (`FCMService`, `SendPushNotification`, device tokens)
- [ ] Observability: Sentry (Flutter + Laravel), APM, Telescope (dev), health check
- [ ] Perf: index review, N+1/eager-load pass, pagination everywhere, P95 <2.5s lists / <500ms admin
- [ ] Account: forgot-password (token-link exists; OTP variant P1), `POST /me/change-password`, language shell (English-only), ICS export (trials/tournaments) + `.ics` download, bracket viz polish
- [ ] QA: `flutter analyze` clean; load test 1000+ concurrent; manual smoke per role (athlete/coach/academy/organizer/scout/admin) on staging

✅ **Exit:** DoD — `grep dummyItems` = 0; ≥85 screens use `ref.watch/read/dioProvider`; every P0 feature has backend + wired screen + integration test; admin behind 2FA; media behind signed URLs.

---

## Phase 11 — P1 Wave (MVP+, right after launch — do NOT build in MVP)

**Docs:** Delta §2 `BE-P1.x` · FR asterisked `S` items

| # | Feature | Backend | Mobile |
|---|---|---|---|
| P1.1 | Ratings & reviews | `reviews` (rater→morph, stars/text; gated to verified interaction) + aggregates | `D.14/D.15` rate + display |
| P1.2 | Event schedule + gallery | `event_schedules` + media morph on event | `OR.9/10` timetable + gallery |
| P1.3 | Results for trials | generic `event_results` (extend tournament pattern) | publish + public view |
| P1.4 | Event analytics | `event_views` log + aggregates (views/regs/inquiries/timeline/sources) | `OR.12` dashboard |
| P1.5 | Announcements | reuse broadcast infra, event-audience targeting | `OR.14` compose |
| P1.6 | Talent reports + compare | `scout_reports` (5-dim + conclusion) + compare query | `SC.7/8/9` |
| P1.7 | Recommendations | rule-based (sport/age/location) | `AT.1` recs |
| P1.8 | Mentions/hashtags, chat media, suggestions | hashtag extraction + mention notify, attachments, suggest query | feed/chat |
| P1.9 | Admin broadcast | `broadcasts` + `BroadcastNotificationJob` + FCM fan-out | `AD.12` compose/target |
| P1.10 | Our Athletes | `academy_athlete_invites` + accept flow (sets `academy_id`) | `AC.5/AC.10` |
| P1.11 | Extra reminders | opportunity deadlines + nearby-trial detection | toggles |
| P1.12 | Forgot-password via OTP | OTP reset (alongside link) | `A.6` |
| P1.13 | Language infra | selection stored (content English-only) | `A.7` |
| P1.14 | Google sign-in | Socialite + `POST /auth/google` | `google_sign_in` on S3 |
| P1.15 | Waitlist auto-promote | `PromoteWaitlistedRegistrations` job + notify | status update |
| P1.16 | Share/deep links | `GET /share/{type}/{slug}` resolver | `S.30` share sheets |

**Parked (P2 — do not build):** online payments, map view, groups/polls, live/streaming, boosted placement, multi-role accounts, teams, staff recruiting, stories, group chat/cold DMs, email/SMS as notify channels.

---

## Quick trackers

### Endpoint count (Delta §11)
~70 new + ~25 changed + ~10 verify-first (social/chat/admin-users) in P0; ~30 new in P1; ~12 sponsor routes removed.

### Screen count (v3 `SCREEN_INVENTORY.md`)
**129 total (94 P0 / 25 P1 / 10 P2):** Auth 10 · Shared shell 30 · Shared detail/forms 17 · Athlete 10 · Coach 8 · Academy 12 · Organizer 17 · Scout 13 · Admin 12.

### Jira import
`docs/Jira-Tickets.md` has CSV-ready tables per Phase→Epic (83 tickets, story points 1/2/3/5/8) — copy each table to CSV for bulk import. Map new v3 work to epics P2-E8 (opportunities), P2-E9 (programs/facilities), P2-E10 (social/chat), P2-E11 (leaderboard), P3-E1 (verification queue + user mgmt).
