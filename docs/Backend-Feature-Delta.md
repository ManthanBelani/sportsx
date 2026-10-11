# Backend Feature Delta — New Design (v2) vs Old Spec

> **Purpose:** list every feature that is **new, changed, or removed** in the new design (`sportsx-design-v3/new_design_docs/`: `MVP_FEATURE_LIST.md` v2 + `SCREEN_INVENTORY.md` v2 + wireframes 01–06) compared with the old backend spec (`docs/`: PRD, Functional-Requirements, API-Specification, Database-Design, Backend-Architecture + role guides), so the team knows **exactly what to implement now** in `sportx-api`.
>
> **Baseline assumed:** old backend is ~130/141 endpoints implemented to the OLD spec (see `Production-Backend-Plan.md` §1, `Development-Checklist.md`). This doc only lists the **delta** — already-built old-spec work is not repeated unless it must change.
>
> **Priority legend (from new docs):** `P0` = must ship in MVP · `P1` = MVP+ (right after) · `P2` = parked.

---

## 0. TL;DR — decisions that changed (read first)

| # | Old decision (docs/) | New design (v2) | Backend impact |
|---|---|---|---|
| D1 | **No OTP** — backend redesigned to email/password, `otp_codes` dropped (`Production-Backend-Plan.md` §2). Flutter `verifyOtp()` calls dead endpoints (`integration-audit.md`). | **OTP signup/login is P0** — phone **or** email + 6-digit OTP, resend timer (A.3/A.4/A.5). | **Re-introduce OTP stack**: `otp_codes` table, issue/verify/resend endpoints, rate limits, phone + email channels. |
| D2 | **Sponsor/Brand is a full role** (enum, onboarding, `sponsor_profiles`, sponsorship CRUD, inbox, shortlist). | **Sponsor role REMOVED.** Sponsorship = an *Opportunity type* posted by Academy/Organizer/Coach/Scout (Athlete P1). | Remove `sponsor` from `UserRole`; drop sponsor onboarding; migrate `sponsorships` → unified opportunities; re-point shortlists/applications. See §6. |
| D3 | Scholarships are **admin-curated only** (FR-ADMIN-11). Athletes apply via **external link**, state not tracked. | Providers (Academy/Organizer/Coach/Scout) **post** scholarships/opportunities; athletes **apply in-app with pitch**, track status (AT.8), providers **review applicants** (P1). | Opportunity posting endpoints for 4 roles; in-app applications with status machine; applicant-review endpoints. |
| D4 | Minors handling **open** (AS-34, legal review pending). | **Decided:** guardian consent mandatory <18 (A.9/AT.10), restricted defaults, leaderboard anonymization, scout contact via guardian. | New guardian-consent flow + enforcement policies. AS-34 can be closed. |
| D5 | Phone verification **deferred**; email-OTP first (PRD A1). | Phone **or** email OTP at signup, P0 (M1.1). | OTP must support SMS channel at MVP, not just email. Vendor selection (AS-03) becomes blocking. |
| D6 | Admin console **fully documented, built later** (PRD A4). | Verification queue (AD.4) + user management (AD.3) are **P0**. | Build admin users + verification-review endpoints in MVP, not later. |
| D7 | Social feed/posts/chat **explicitly excluded**; enquiry threads only. | Lightweight feed + posts + likes/comments + follow/connect + 1-to-1 chat are **P0**. | New social + messaging backend (partly stubbed — verify, see §2 G). |
| D8 | Ratings/reviews, analytics dashboards **non-goals**. | Reviews P1, event analytics P1, leaderboard P0, broadcast P1. | New points engine (P0) + reviews/analytics/broadcast (P1). |
| D9 | Google sign-in deferred (Could/Phase 4). | Shown on Sign Up (A.3). | **Confirm:** keep deferred, or promote to P0 per wireframe. |

---

## 1. New P0 backend work (must ship)

### M1 — Auth, onboarding & trust

| ID | Feature (new screens) | Old state | Build now |
|---|---|---|---|
| BE-M1.1 | OTP issue / verify / resend, phone + email (A.3, A.4, A.5) | `otp_codes` dropped; no OTP endpoints | Re-create `otp_codes` (hash, expiry, attempts, channel), `POST /auth/send-otp`, `POST /auth/verify-otp`, resend cooldown, `RateLimitOtp`. Keep email/password login alongside. |
| BE-M1.2 | Role model = athlete, coach, academy, organizer, **scout**, admin (A.2) | Enum has `sponsor`, no `scout`; scout only in side-guide | `UserRole`: **remove `sponsor`, add `scout`**; update `role:*` middleware, policies, seeders, admin filters. Data migration for any sponsor rows (see §6). |
| BE-M1.3 | Scout onboarding (SC.1) + scout profile (D.5, SC.3) | No scout onboarding endpoint; no `scout_profiles` in main schema | Extend canonical `talent_scout_profiles` table to the 30 scout fields (see `SportX_Mandatory_Fields.md`), `POST /onboarding/scout`, `GET/PUT /me/scout-profile`. |
| BE-M1.4 | Guardian consent for minors (A.9) + parent controls (AT.10) | Nothing (AS-34 open) | `guardian_consents` (athlete_id, name, phone, relationship, consent OTP, verified_at, status); gate: DOB<18 → require verified consent before profile activation; store messaging/visibility prefs; enforce in chat/discovery/leaderboard policies. |
| BE-M1.5 | Verification request + blue check + admin queue (A.10, AD.4) | `verification_status` cols only, "no approval screen" | `verification_requests` (requester morph, ID proof + org proof media, notes, status, reviewer, reason); `GET/POST /admin/verification` (approve/reject+reason); badge flag surfaced on profile/card/search resources; result notification. Private doc storage (signed URLs). |
| BE-M1.6 | Profile completion checklist API (AT.6) | Only `profile_completeness` integer returned | Per-role checklist endpoint (missing items + deep-link keys) for athlete/coach/academy/organizer/scout; completion % on Home/More/Profile resources. |

### M3/M8 — Discovery + Leaderboard

| ID | Feature | Old state | Build now |
|---|---|---|---|
| BE-M3.1 | Athletes in universal search (S.5) | `/search` has no athletes group | Add `athletes` (+ keep coaches) to grouped search response. |
| BE-M3.2 | Card enrichment + "near me" (S.2, S.3) | Basic cards | Achievements/media counts, rating, registration-status on event cards; distance sort (city-centroid or geocode — needs decision §7); `position`, `level`, `facilities`, `price`, `rating` filters. |
| BE-M3.3 | Saved for posts / opportunities / events (S.20) | Morphs cover 6 listing types only | Extend `saved_items` morph set: `post`, `opportunity`, `event`. |
| BE-M8.1 | **Leaderboard points engine (P0)** — S.6, AT.1 strip | Absent (one stray checkbox) | `leaderboard_scores` (athlete_id, sport_id, points, season_id) + recalculation on: verified achievement, profile completion milestones, post/event participation; `GET /leaderboard` (sport/location/age filters, podium + ranks 4–10); `leaderboard_seasons` + reset job; minors anonymized (first name + initial); coaches/academies/teams/events tabs P1-ready schema. |
| BE-M8.2 | Points config (AD.11, P1) | — | Admin weights + season-length endpoints (build with engine, expose in P1). |

### M4 — Events, trials & registrations

| ID | Feature | Old state | Build now |
|---|---|---|---|
| BE-M4.1 | Unified event/trial/camp create flow (OR.5) | Separate `trials` + `tournaments` tables | **Decision §7:** keep two tables (map `type` at API layer) vs new unified `events` table. Either way expose `POST /me/events?type=` for Organizer/Academy (Coach/Athlete P1 via policy flag). |
| BE-M4.2 | Registration decision notifications (AT.9, S.16) | Status cols exist; notify missing | Fire notification + push on approve/reject (trial + tournament). |
| BE-M4.3 | Export registrant list CSV (OR.7) | Only activity-log export exists | `GET /events/{id}/registrations/export` (CSV/Excel, role-scoped). |
| BE-M4.4 | Expiry for opportunities (AD.10) | Rule types: trial/tournament/sponsorship/scholarship | Add `opportunity` content type to `expiry_rules` + sweep. |

### M5 — Opportunities (biggest structural change)

| ID | Feature | Old state | Build now |
|---|---|---|---|
| BE-M5.1 | **Unified `opportunities`** — types scholarship/sponsorship/tryout/camp; posted by Academy/Organizer/Coach/Scout (Athlete P1); browsed by all (D.9, SC.11, AC.9) | Split `scholarships` (admin-only) + `sponsorships` (sponsor-owned) | New `opportunities` table (provider morph, type enum, eligibility, benefits/amount, deadline, docs, status) + CRUD per role + public list/detail + `opportunity_applications` (pitch, docs, profile snapshot, status) + `GET /me/opportunities` (Applied/Saved/Created). Migrate old rows (see §6). |
| BE-M5.2 | Applicant review P1 (shortlist/decline) | Sponsor inbox existed; generic review absent | `GET /opportunities/{id}/applications`, `PATCH …/applications/{app}` (shortlist/decline + note). |

### M6 — Programs, facilities, academy ops

| ID | Feature | Old state | Build now |
|---|---|---|---|
| BE-M6.1 | **Training programs** (CO.4/CO.5/D.11) | Absent | `programs` table (owner morph coach/academy, title, sport, age, duration, mode, price, schedule, about, status draft/active/past) + CRUD + public detail + Explore surfacing. |
| BE-M6.2 | Program/listing enquiry → chat thread (D.12) | Enquiry morphs: coach_profile/academy/sponsorship_application | Add `program` (+ `opportunity`) to enquiry `subject_type`; enquiry creation returns/opens thread (S.18). |
| BE-M6.3 | **Facilities CRUD** (AC.7/AC.8/D.13) | `academies.facilities` JSON only | `facilities` table (academy_id, name, type, size/lanes, amenities JSON, images) + CRUD + public detail; link on D.3 tab. |
| BE-M6.4 | Venues owner CRUD for organizers (OR.13, P1) | `sports_venues` discovery-only, ownerless | Add owner (`owner_user_id`) + provider CRUD; keep public browse. |

### M7 — Social & messaging (verify partial builds first!)

> `UI-Completion-And-Backend-Wiring-Plan.md` + `integration-audit.md` indicate `conversations/messages/participants/connections/posts/post_likes/post_comments` migrations and `/posts` endpoints may be **partially implemented**. Start each item with a verify-then-complete pass.

| ID | Feature | Old state | Build now |
|---|---|---|---|
| BE-M7.1 | **Posts + feed** (S.9, feed tabs) | Spec-excluded; partial impl suspected | `posts` (author morph, text, media, hashtags, sport tag, audience) + `GET /feed` (For You/Following/Athletes/Coaches/Academies/Events tabs) + edit/delete own. |
| BE-M7.2 | **Likes / comments / counts** (S.27) | Same as above | `post_likes`, `post_comments` + count aggregates on detail/feed resources. |
| BE-M7.3 | **Follow (one-way) + Connect (mutual request)** (S.3, S.19) | Screens existed, **no tables/endpoints** in main spec | `follows` + `connection_requests` (request/accept/decline/cancel/remove) + counts; gate chat visibility. |
| BE-M7.4 | **1-to-1 chat for connections + enquiry threads** (S.17/S.18) | Enquiry threads only; "no separate chat" | `conversations` + `messages` (+ text; media P1); open rules: accepted connection OR enquiry thread; Chats/Requests tabs; unread badges; minors rule (guardian-allowed only); report/block entry points. |
| BE-M7.5 | Privacy enforcement (S.22, AT.10) | Settings shell exists | `profile_visibility`, `who_can_message/connect` columns + policy enforcement in chat/discovery/contact endpoints. |

### M10 — Scouting (extends side-guide)

| ID | Feature | Old state | Build now |
|---|---|---|---|
| BE-M10.1 | Shortlist **status + tags + private notes**, tabs All/Under Review/Final (SC.5/SC.6) | Guide's `scout_shortlists` has notes only | Extend to `status` enum (under_review/good/high/final), `tags` JSON; filtered list + compare input. |
| BE-M10.2 | **Observations** (SC.10) | Absent | `observations` (scout, athlete, rating, note, media). |
| BE-M10.3 | Contact athlete/parent via guardian (SC.13) | Guide's `scout_connections` only | Reuse connection-request flow + guardian routing for U-18 (notify guardian, consent required before chat). |
| BE-M10.4 | Scout dashboard aggregates (SC.2) | Absent | Top-talents-this-week (leaderboard slice), upcoming trials, counts endpoints. |

### M11 — Safety, moderation & admin (P0 slice)

| ID | Feature | Old state | Build now |
|---|---|---|---|
| BE-M11.1 | Report **users + posts** (S.26) | `listing_reports` covers 6–7 listing types | Extend reportable morphs: `user`, `post` (+ opportunity/program/facility). |
| BE-M11.2 | **Block user** (S.23) | Screen existed, no backend | `blocks` (blocker/blocked) + hide content both ways + block chat + list/unblock endpoints. |
| BE-M11.3 | **User management** (AD.3) | Not in API spec (Flutter references `/admin/users`) | `GET /admin/users` (search, role/status filters), detail, suspend/ban (uses `users.status`), audit columns. Verify-then-complete. |
| BE-M11.4 | Moderation for users/posts + outcomes notify | Listings only | Extend moderate actions (remove/warn/**suspend**) + reporter/reported notifications. |
| BE-M11.5 | Content-manager types (AD.5/AD.6) | 7 types | Add `opportunities`, `programs`, `facilities`, `posts`, `sports_venues`(exists?) to `{type}` enum. |
| BE-M11.6 | **Positions master** (S.4 filter) | Masters: sports/cities/age groups | `positions` master + admin CRUD (sport-scoped optional). |

### M2/M12 — Profiles & platform

| ID | Feature | Old state | Build now |
|---|---|---|---|
| BE-M2.1 | Per-sport role/level/experience, primary sport (AT.4) | `athlete_sports` pivot is bare | Add `playing_role`, `level`, `experience_years`, `is_primary` to pivot. |
| BE-M2.2 | Rich achievements (type/sport/level/year/certificate) + coach achievements (S.11) | `achievements.text` only | Extend columns + `owner` morph (athlete/coach). |
| BE-M2.3 | Social links P1 (AT.3) | Academy `website` only | `social_links` JSON on profiles. |
| BE-M2.4 | Share / deep links P1 (S.30) | Notification payloads link back (no public resolve) | Public `GET /share/{type}/{slug}` resolver for profile/event/opportunity/post. |
| BE-M12.1 | Product analytics events (funnel: signup, registration, enquiry, shortlist) | Registration activity-log export only | `analytics_events` log endpoint (batch write) — also feeds OR.12. |
| BE-M12.2 | Registrant export (see BE-M4.3) | — | — |

---

## 2. P1 backend work (MVP+, build right after)

| ID | Feature | Notes |
|---|---|---|
| BE-P1.1 | Ratings & reviews (D.14/D.15) | New `reviews` (rater → rateable morph, stars, text); gate: only after verified interaction (enquiry/registration); aggregates on cards. |
| BE-P1.2 | Event schedule + gallery (OR.9/OR.10) | New `event_schedules` (day/slots); gallery via `media_items` morph on event. |
| BE-P1.3 | Results for events/trials (OR.11) | Extend `tournament_results` pattern to trials (or generic `event_results`). |
| BE-P1.4 | Event analytics basic (OR.12) | `event_views` log + aggregates (views/regs/inquiries, timeline, top sources). RegistrationAnalyticsController may cover parts — verify. |
| BE-P1.5 | Announcements to registrants/followers (OR.14) | Reuse broadcast/notification infra targeted by event audience. |
| BE-P1.6 | Talent reports + compare (SC.7/SC.8/SC.9) | New `scout_reports` (5-dimension scores, conclusion, notes) + filtered list. |
| BE-P1.7 | Recommendations (AT.1) | Rule-based service (sport/age/location) for athletes + events endpoints. |
| BE-P1.8 | Mentions/hashtags, chat media, network suggestions (M7.8–M7.10) | `hashtags` extraction + mention notifications; message attachments; suggestion query. |
| BE-P1.9 | Admin broadcast (AD.12) | `broadcasts` (audience filter, title/body, schedule) + FCM fan-out job. Compose/targeting screens exist in design-v2 — verify backend. |
| BE-P1.10 | Our Athletes invite/accept (AC.5/AC.10) | `academy_athlete_invites` (or direct `academy_id` link + notification accept flow). |
| BE-P1.11 | Deadline/nearby reminders (S.16) | Extend `ReminderService`: opportunity deadlines + nearby-trial detection. |
| BE-P1.12 | Forgot-password via OTP (A.6) | Replace token-link reset with OTP flow (or support both). |
| BE-P1.13 | Language infra (A.7) | Selection stored; content stays English-only (no backend strings work). |

---

## 3. Changed (not new) — modify existing backend

| Area | Old | New | Action |
|---|---|---|---|
| Auth | email/password + token verify-link; phone optional/unverified | OTP for phone **and** email; keep password login | Keep both; do NOT drop password auth. |
| Search response | 7 groups, no athletes | Add `athletes` group (+ coaches confirmed) | Extend `SearchService`. |
| Enquiry morphs | coach_profile/academy/sponsorship_application | + `program`, `opportunity` | Extend + policies. |
| Trial create policy | academy/organizer only | + coach (P1), + athlete (P1) | Policy flags per phase. |
| Scholarship posting | admin-only | providers post (AC.9 etc.) | Open endpoints + ownership policies. |
| Notification types | reminder/enquiry_reply/status_update | + follow, connection, message, enquiry, registration decision, verification result, mention, broadcast | Extend enum + events/listeners. |
| Report reasons | fake/outdated/inappropriate/other | + misleading/stale/suspicious wording mapped to same enum | No schema change; confirm mapping. |
| Registration decisions | verify/reject actions exist | Must notify athlete (push + in-app) | Add listeners. |
| Expiry sweep | 4 content types | + opportunities (+ programs/facilities never expire — confirm) | Extend rule set. |
| Admin content `{type}` | 7 types | + opportunities/programs/facilities/posts | Extend enum + resources. |
| Saved morphs | 6 listing types | + post/opportunity/event | Extend. |
| User detail | none | suspend/ban/verify from AD.3 | Verify-then-complete. |
| `profile_completeness` | integer only | Itemized checklist per role | Extend `ProfileService`. |
| Achievements | text line | typed records + certificates | Migrate text → rows. |
| Athlete sports pivot | bare | role/level/experience/primary | Migrate. |
| Academy facilities | JSON | dedicated table (list/detail) | Migrate JSON → rows. |

---

## 4. Removed / deprecated

| Item | Old backend touchpoints | Action |
|---|---|---|
| `sponsor` role | `UserRole` enum, `role:sponsor` middleware group, `SponsorOnboardingRequest`, `/onboarding/sponsor`, `sponsor_profiles`, `sponsorships.sponsor_id`, `shortlist_entries.sponsor_id`, `SponsorEngagementController`, sponsor policies, seeders, admin content type `sponsorships` (re-mapped) | 1) Add `opportunities` + migrate `sponsorships` rows (provider = legacy sponsor org as plain org name; status preserved). 2) Migrate `sponsorship_applications` → `opportunity_applications`. 3) Migrate `shortlist_entries` → scout/owner-keyed shortlist or drop if unused. 4) Remove enum value + onboarding + role routes (keep 410/404, never 500). 5) Update admin content types + seeders + tests. |
| Token-link-only auth assumption | `verification_token`, reset tokens | Keep (password flows stay); OTP added alongside. |
| "No chat system" (AS-04) | Enquiry-only assumption | Superseded: conversations + messages introduced; enquiries interoperate. |
| AS-34 open item (minors) | Legal review pending | Closed by guardian-consent design; keep DPDP purge (AS-35) + retention rules. |

---

## 5. New/changed schema checklist (migrations)

**New tables (P0):** `otp_codes` (re-add) · `guardian_consents` · `verification_requests` · `talent_scout_profiles` (extend existing) · `opportunities` · `opportunity_applications` · `programs` · `facilities` · `leaderboard_scores` · `leaderboard_seasons` · `posts` · `post_likes` · `post_comments` · `follows` · `connection_requests` · `conversations` · `messages` (+ `conversation_participants` if group-ready) · `blocks` · `observations` · `analytics_events`.
**New tables (P1):** `reviews` · `event_schedules` · `event_views` · `broadcasts` · `scout_reports` · `positions` · `academy_athlete_invites`.
**Extend:** `users.role` enum (drop sponsor, add scout) · `athlete_sports` (+role/level/exp/primary) · `achievements` (+type/sport/level/year/cert/owner) · enquiry/saved/report morph sets · `notifications.type` enum · `expiry_rules` types · admin content types · profiles (+visibility/messaging prefs, social links) · `sports_venues.owner_user_id`.
**Drop/merge (with migration):** `sponsor_profiles` · `sponsorships` → `opportunities` · `sponsorship_applications` → `opportunity_applications` · `shortlist_entries` → generalized shortlist.

---

## 6. New/changed endpoints checklist (illustrative paths)

**Auth:** `POST /auth/send-otp` · `POST /auth/verify-otp` · `POST /auth/resend-otp` · `POST /guardian/consent` · `POST /guardian/verify-otp` · `GET /me/completion-checklist`.
**Verification:** `POST /me/verification` · `GET /me/verification` · `GET /admin/verification` · `POST /admin/verification/{id}/approve|reject`.
**Scout:** `POST /onboarding/scout` · `GET/PUT /me/scout-profile` · `GET/POST/DELETE /me/shortlist` (+status/tags/notes) · `POST /observations` · `GET /scout-reports` · `POST /scout-reports` · contact via connections.
**Opportunities:** `GET /opportunities` · `GET /opportunities/{id}` · `POST /me/opportunities` (academy/organizer/coach/scout) · `PUT/PATCH /me/opportunities/{id}` · `POST /opportunities/{id}/apply` · `GET /me/opportunities?type=applied|saved|created` · `GET /opportunities/{id}/applications` (P1) · `PATCH …/applications/{app}` (P1).
**Programs/facilities:** `GET /me/programs` · `POST /me/programs` · `PUT /me/programs/{id}` · `GET /programs/{id}` · `POST /programs/{id}/enquire` · `GET /me/facilities` · `POST /me/facilities` · `GET /facilities/{id}`.
**Social:** `GET /feed` · `POST /posts` · `GET /posts/{id}` · `PATCH/DELETE /posts/{id}` · `POST /posts/{id}/like` · `GET/POST /posts/{id}/comments` · `POST /follow/{type}/{id}` · `DELETE /follow/{type}/{id}` · connection-request CRUD · `GET /conversations` · `GET /conversations/{id}` · `POST /conversations/{id}/messages` · `POST /blocks` · `GET/DELETE /blocks`.
**Leaderboard:** `GET /leaderboard` · `GET /leaderboard/strip` (home) · (P1) `GET/PUT /admin/leaderboard-config` · `POST /admin/leaderboard/reset-season`.
**Admin (P0 additions):** `GET /admin/users` · `GET /admin/users/{id}` · `POST /admin/users/{id}/suspend|ban` · verification endpoints above · `GET /registrations/export` (provider-scoped CSV).
**Platform:** `GET /share/{type}/{slug}` (P1) · `POST /analytics/events` · (P1) `POST /admin/broadcasts` · (P1) `GET/POST /reviews`.

---

## 7. Jobs, events, policies

- **Jobs (new):** `RecalculateLeaderboardJob` (on triggers + nightly full rebuild) · `ResetLeaderboardSeasonJob` · `BroadcastNotificationJob` (P1) · `CleanupUnverifiedAccountsJob` (optional, if OTP-gated).
- **Events/listeners (new):** `RegistrationDecided` → athlete notify · `VerificationDecided` → requester notify · `ConnectionAccepted` → chat unlock notify · `MentionCreated` (P1) · `ContentReported(user/post)` → moderation routing.
- **Policies (new/changed):** minors (chat/discovery/visibility) · scout-data privacy (shortlists/notes/reports owner-only) · provider posting matrix (who can post what per phase) · review gating (verified interaction only) · no cold DMs.

---

## 8. Decisions to confirm (backend-blocking)

| # | Question | Recommendation |
|---|---|---|
| 1 | OTP: rebuild SMS channel now (vendor), or email-OTP first + phone second? | New design says phone-or-email P0 → select SMS vendor now (AS-03 becomes blocking). |
| 2 | Events data model: unify `trials`+`tournaments` into `events`, or map at API layer? | Keep tables (data exists), unify at API/resource layer with `type` — least migration risk. |
| 3 | Sponsorship/scholarship migration strategy + downtime window? | Migrate rows to `opportunities` with `legacy_type`; keep old endpoints 410 with message for one release. |
| 4 | Google sign-in: P0 per wireframe or stay deferred? | Keep deferred unless stakeholder overrides (was Could/Phase 4). |
| 5 | Distance/near-me: city-centroid math vs geocoding (AS-31/32 open)? | City-centroid for MVP (no new vendor); precise location only if maps SDK chosen. |
| 6 | Scholarships: keep any admin-exclusive types (govt schemes) alongside provider-posted? | Yes — `posted_by=admin` type stays; providers post the rest. |
| 7 | Chat storage/retention + media scanning policy? | Text P0 with 90-day purge default (align AS-35); media P1 with MIME validation. |
| 8 | Leaderboard anti-gaming (verified-only achievements count — already specced?) | Confirm formula: verified achievements + completion + activity;.constants in admin config. |

---

## 9. Suggested backend build order (P0)

1. Roles & auth: enum change, OTP stack, scout onboarding, guardian consent.
2. Verification requests + admin queue + badge surfacing.
3. Opportunities (+ migrate sponsorships/scholarships) + applications + My lists.
4. Programs + facilities + program enquiry.
5. Social core: posts/feed/likes/comments (verify partial first), follows, connections, 1:1 chat, blocks.
6. Leaderboard engine + API.
7. Scout extensions (shortlist status, observations, guardian contact, dashboard).
8. Admin P0: users, verification queue, content-type extensions, export CSV.
9. Notifications matrix + reminders extension + policies + audit.
10. Search/discovery enrichment, saved morphs, completion checklist, share resolver.

P1 wave follows §2 in priority order (reviews → schedule/gallery → analytics → announcements → reports → broadcast).

---

## 10. Explicitly parked (do NOT build)

Online payments · promoted/boosted placement · groups · polls · live/webinar/streaming · map view · multi-role accounts · team pages · staff recruiting · collaborations · email/SMS notifications (as channels beyond OTP/push) · stories · sponsor-as-role (removed).

---

## Appendix A — New-screen → backend trace (P0, selected)

| Screens | Backend |
|---|---|
| A.3/A.4/A.5/A.6 | OTP stack + session/token issue |
| A.9/AT.10 | guardian_consents + enforcement |
| A.10/AD.4 | verification_requests + review actions |
| AT.1 (+strip) | leaderboard strip + feed + recommendations(P1) |
| AT.6 | completion-checklist service |
| S.2/S.3/S.5/S.6 | enriched directories + search + leaderboard APIs |
| S.8/S.15 | role-aware create tiles / more rows (config + existing CRUD) |
| S.9/S.27/S.10/S.28 | posts + media + likes/comments |
| S.12/S.19/S.17/S.18 | follows + connections + conversations |
| S.16 | extended notification types + read-all |
| S.20/S.21 | saved morphs + activity aggregation (+opportunities) |
| D.1–D.5 | profile resources + privacy + scout shortlist CTA |
| D.6/D.7/D.8/AT.9 | registrations + decision notifications + export |
| D.9/D.10/AT.8/SC.11 | opportunities + applications |
| D.11/D.12/CO.4/CO.5 | programs + program enquiry thread |
| AC.7/AC.8/D.13 | facilities CRUD |
| OR.5/OR.6/OR.7/OR.8 | event module + registrant mgmt + export |
| SC.4/SC.5/SC.6/SC.10/SC.13 | athlete search + shortlist + observations + guardian contact |
| AD.2/AD.3/AD.5–AD.10 | dashboard + users + content + moderation + master + expiry |
| S.22–S.26/S.29/S.30 | settings/privacy + report (extended morphs) + blocks + logout + share |

## Appendix B — Coverage notes

- Fully read: PRD, Functional-Requirements, API-Specification, Database-Design, Backend-Architecture, Screen-Inventory (old), Talent-Scout-Guide, Mobile-App-Flow, Glossary-and-Assumptions.
- Spot-checked via search: Approval-Based-Registration-System, Admin-Panel-Implementation-Prompt, Production-Backend-Plan, Development-Checklist, integration-audit, Integration-Test-Report, Phased-Roadmap, Jira-Tickets, UI-Completion-And-Backend-Wiring-Plan, Implementation-Execution-Plan, User-Journey-and-API-Alignment, Security-and-NonFunctional, Mobile-Architecture, ER/Class diagrams, System-Flow, Use-Cases, Personas, DYNAMIC_THEME.
- Not re-read (no backend impact expected): `SportX_India_Updated_MVP_Feature_List_with_talent_scout.pdf` (covered via FR traceability table), Mobile-Testing-Guide, Design-to-Flutter-Mapping, Design-Implementation-Plan.
- New docs fully read: `00_README`, wireframes 01–06, `MVP_FEATURE_LIST.md` v2, `SCREEN_INVENTORY.md` v2.

---

## 11. Complete endpoint catalog for the new design (LinkedIn-type app)

> Every endpoint the Flutter app needs to make the new design work end-to-end, grouped the way the product is organized: **Profiles → Feed → Network → Messaging → Opportunities → Notifications** (the LinkedIn shape: identity, content, graph, chat, jobs, alerts).
>
> Conventions: base `/api/v1` (unchanged); auth `Bearer` Sanctum (unchanged); list envelope `{data, meta}` + error envelope (unchanged, API-Spec §1).
> Status tags: ✅ EXISTS (old backend, keep) · 🆕 NEW (build) · 🔁 CHANGED (modify) · ❓ VERIFY (partially built per overlay docs — check `sportx-api` first) · 🅿️ P1 (MVP+ wave) · ⏸️ P2 (parked) · ❌ REMOVED.

### 11.1 Auth, OTP, guardian (screens A.1–A.10)

| Method | Path | Who | Screens | Status | Notes |
|---|---|---|---|---|---|
| POST | `/auth/register` | public | A.3 | 🔁 | Add `role=scout`, drop `sponsor`; phone **or** email; triggers OTP instead of instant token |
| POST | `/auth/send-otp` | public | A.3/A.4 | 🆕 | channel=email\|phone, cooldown 60s, max 5 attempts |
| POST | `/auth/verify-otp` | public | A.4 | 🆕 | Returns token + `needs_onboarding`; sets `email/phone_verified_at` |
| POST | `/auth/resend-otp` | public | A.4 | 🆕 | Rate-limited (Flutter already calls this — currently 404) |
| POST | `/auth/login` | public | A.5 | 🔁 | Keep email+password; **add** phone/email+OTP branch |
| POST | `/auth/logout` | any | S.29 | ✅ | — |
| GET | `/auth/me` | any | shell | ✅ | Session check (already used by app) |
| POST | `/auth/forgot-password` | public | A.6 | 🔁 | Token-link exists; add OTP variant (P1 per wireframe) |
| POST | `/auth/reset-password` | public | A.6 | 🔁 | Same as above |
| POST | `/auth/google` | public | A.3 | ❓ | Wireframe shows Google P0; old spec defers — confirm per §8 D9 |
| POST | `/guardian/consent` | public | A.9 | 🆕 | Guardian name/phone/relationship → OTP to guardian |
| POST | `/guardian/verify-otp` | public | A.9 | 🆕 | Verifies consent; unlocks minor's profile |
| GET/PUT | `/me/guardian-controls` | athlete | AT.10 | 🆕 | Consent status, message/visibility prefs, leaderboard name mode |
| GET | `/me/completion-checklist` | any | AT.6, homes | 🆕 | % + missing items with deep-link keys, per role |
| POST | `/me/change-password` | any | S.22 | 🆕 | Logged-in password change (only forgot/reset existed) |
| POST | `/me/delete-account` | any | S.22 | ✅ | Soft-delete (keep 90-day purge) |

### 11.2 Onboarding (AT.2, CO.1, AC.1, OR.1, SC.1)

| Method | Path | Who | Status | Notes |
|---|---|---|---|---|
| GET | `/onboarding/{role}` | any | ✅ | Add `scout` schema; drop `sponsor` |
| POST | `/onboarding/athlete` | athlete | ✅ | + guardian gate if DOB < 18 |
| POST | `/onboarding/coach` | coach | ✅ | 4-step wizard (profile → credentials → sports/fees → review) |
| POST | `/onboarding/academy` | academy | ✅ | 5-step (basic → sports/age → facilities → fees/photos → review) |
| POST | `/onboarding/organizer` | organizer | ✅ | — |
| POST | `/onboarding/scout` | scout | 🆕 | Org type, sports focus, experience, availability, languages, location |
| — | `/onboarding/sponsor` | — | ❌ | Removed with sponsor role |

### 11.3 Profiles — own + public (D.1–D.5, AT.3, CO.3, AC.3, OR.3, SC.3, A.10)

| Method | Path | Who | Status | Notes |
|---|---|---|---|---|
| GET/PUT | `/me/profile` (athlete) | athlete | ✅/🔁 | + privacy fields, social links, cover; achievements via dedicated CRUD |
| PUT | `/me/profile/sports` | athlete | 🔁 | Add per-sport `playing_role, level, experience_years, is_primary` (AT.4) |
| GET/PUT | `/me/coach-profile` | coach | ✅ | + programs tab data, rating aggregate (P1) |
| GET/PUT | `/me/academy` | academy | ✅ | + programs/facilities/events/reviews tab data |
| GET/PUT | `/me/organizer-profile` | organizer | 🆕 | No endpoint in old spec (table exists) |
| GET/PUT | `/me/scout-profile` | scout | 🆕 | Org, focus, exp, availability, languages |
| GET | `/athletes/{id}` | any | 🔁 | Open to all roles (was sponsor-scoped); minors restricted (AT.10 policy) |
| GET | `/coaches/{id}`, `/academies/{id}` | any | ✅ | + rating, distance, counts |
| GET | `/organizers/{id}` (D.4) | any | 🆕 | No public endpoint in old spec |
| GET | `/scouts/{id}` (D.5) | any | 🆕 | Public view: About + Activity only (shortlist/reports owner-only) |
| POST/GET | `/me/verification` (A.10) | any | 🆕 | ID + org proof upload, status (pending/verified/rejected+reason) |
| PUT | `/me/privacy` | any | 🆕 | `profile_visibility`, `who_can_message`, `who_can_connect` (or fold into settings) |
| GET | `/share/{type}/{slug}` | public | 🅿️ | Deep-link resolver for profile/event/opportunity/post (S.30) |

### 11.4 Sports, achievements, media (AT.4, AT.5, S.10, S.11, S.28)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET/POST | `/me/achievements` | 🆕 | Dedicated CRUD (was diff-via-profile): title, type, sport, level, year, certificate upload, description |
| PUT/DELETE | `/me/achievements/{id}` | 🆕 | Owner (athlete/coach) only |
| POST | `/media/upload` | ✅ | + caption + sport tag fields |
| PUT | `/media/reorder` | ✅ | — |
| DELETE | `/media/{id}` | ✅ | — |
| GET | `/me/media` | 🆕 | Gallery grid feed for profile Media tab + viewer (S.28) |

### 11.5 Discovery — home, explore, search, filter, leaderboard, saved (AT.1, CO.2, AC.2, OR.2, SC.2, S.2–S.7, S.20)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET | `/me/home` | 🆕 | **One role-aware dashboard** for all 5 homes: greeting, completion %, leaderboard strip/top-talents, shortcut counts (enquiries/registrations), feed preview |
| GET | `/explore` | 🆕 | Grouped sections (athletes/coaches/academies/events/opportunities) for S.2; cheaper than 5 calls |
| GET | `/academies`, `/coaches`, `/trials`, `/tournaments`, `/sports-venues` (+lists) | ✅ | + `position/level/facilities/price/rating` filters, distance sort, registration-status on events |
| GET | `/opportunities`, `/programs` | 🆕 | New listing types in Explore (see §11.7/11.8) |
| GET | `/search` | 🔁 | **Add `athletes` group**; recent searches |
| POST | `/me/recent-searches` | 🆕 | Persist recent (old spec has GET only) |
| GET | `/leaderboard` | 🆕 | Tabs (athletes/coaches/academies/teams/events), sport/location/age filters, podium + ranks |
| GET | `/leaderboard/strip` | 🆕 | Top-5 for home (AT.1/CO.2/AC.2) |
| GET/POST/DELETE | `/me/saved` | 🔁 | Extend morphs: `post, opportunity, event` |
| GET | `/meta/positions`, `/meta/facilities` | 🆕 | New filter metadata (sports/cities/age-groups exist) |

### 11.6 Events, trials & registrations (D.6–D.8, AT.9, AC.6, OR.4–OR.8)

| Method | Path | Status | Notes |
|---|---|---|---|
| POST | `/me/events?type=trial\|tournament\|camp` | 🆕/🔁 | Unified create (OR.5 5-step); maps to trials/tournaments tables per §8 D2 |
| GET | `/me/events` | 🆕 | My Events (OR.4/AC.6/CO.6-P1) with registered counts, Upcoming/Past |
| GET | `/events/{id}` | 🆕 | Or keep `/trials/{id}` + `/tournaments/{id}` (decision §8 D2); must include slots bar, fee, organizer, status |
| PUT/PATCH | `/me/events/{id}` (+publish/close) | 🔁 | Existing trial/tournament mutation endpoints |
| GET | `/events/{id}/registrations` | ✅ | Tabs All/Approved/Pending, search/filter, bulk approve/reject |
| GET | `/registrations/{id}` | ✅ | Registrant detail + documents (OR.8) |
| POST | `/registrations/{id}/approve`, `/reject` | ✅ | + **decision notification** (new listener) |
| GET | `/events/{id}/registrations/export` | 🆕 | CSV/Excel export (OR.7) |
| POST | `/trials/{id}/register`, `/tournaments/{id}/register` | ✅ | Duplicate guard + capacity rules stay |
| GET | `/me/registrations` | 🆕 | Unified My Registrations AT.9 (Upcoming/Past) across trials+tournaments |
| DELETE | `/me/registrations/{id}` | 🆕 | Athlete cancel registration |
| GET/POST | `/events/{id}/schedule` | 🅿️ | Timetable slots (OR.9) |
| GET | `/events/{id}/gallery` | 🅿️ | Via media morph (OR.10) |
| POST | `/events/{id}/results` | 🅿️ | Extend tournament-results pattern to trials (OR.11) |
| GET | `/events/{id}/analytics` | 🅿️ | Views/regs/inquiries, timeline, sources (OR.12; verify RegistrationAnalyticsController first) |
| POST | `/events/{id}/announce` | 🅿️ | Message to registrants/followers (OR.14) |

### 11.7 Opportunities & applications (D.9, D.10, AT.8, AC.9, SC.11, SC.12)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET | `/opportunities` | 🆕 | Filters: type (scholarship/sponsorship/tryout/camp), sport, age, deadline; SC.11 hub tabs use this |
| GET | `/opportunities/{id}` | 🆕 | Provider, eligibility, benefits/amount, deadline |
| POST | `/me/opportunities` | 🆕 | Academy/organizer/coach/scout (athlete P1); type-specific validation |
| PUT/PATCH | `/me/opportunities/{id}` (+publish/close) | 🆕 | Owner-only |
| POST | `/opportunities/{id}/apply` | 🆕 | Pitch + docs; profile auto-attached; 409 on duplicate |
| GET | `/me/opportunities?type=applied\|saved\|created` | 🆕 | My Opportunities AT.8 |
| GET | `/opportunities/{id}/applications` | 🅿️ | Provider applicant review |
| PATCH | `/opportunities/{id}/applications/{app}` | 🅿️ | Shortlist/decline + note |

### 11.8 Programs, facilities, enquiries (D.11–D.13, CO.4, CO.5, AC.4, AC.7, AC.8)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET | `/me/programs` | 🆕 | Tabs Active/Drafts/Past (CO.4/AC.4) |
| POST/PUT | `/me/programs`, `/me/programs/{id}` | 🆕 | Full program form (CO.5); publish/draft |
| GET | `/programs/{id}` | 🆕 | Public program detail (D.11) |
| POST | `/programs/{id}/enquire` | 🆕 | Preferred batch + message → creates chat thread (D.12 → S.18) |
| GET | `/me/facilities` | 🆕 | Tabs All/Grounds/Indoor/Gym/Other (AC.7) |
| POST/PUT/DELETE | `/me/facilities`, `/me/facilities/{id}` | 🆕 | Facility form (AC.8) |
| GET | `/facilities/{id}` | 🆕 | Public facility detail (D.13) |
| POST | `/enquiries` | 🔁 | Add `subject_type` = `program`, `opportunity` |
| GET | `/me/enquiries` | 🔁 | Widen role scope (organizer/scout where relevant), tabs Chats/Requests |
| GET/POST | `/enquiries/{id}`, `/enquiries/{id}/messages`, `/enquiries/{id}/read` | ✅ | Thread + reply + read receipts |

### 11.9 Social — posts, feed, likes, comments (S.8, S.9, S.27, S.10)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET | `/feed` | ❓/🆕 | Tabs For You/Following/Athletes/Coaches/Academies/Events; chronological + simple relevance |
| POST | `/posts` | ❓/🆕 | Text + media + hashtags + sport tag + audience (S.9) |
| GET/PATCH/DELETE | `/posts/{id}` | ❓/🆕 | Detail (S.27); edit/delete own |
| POST/DELETE | `/posts/{id}/like` | ❓/🆕 | Toggle + counts |
| GET/POST | `/posts/{id}/comments` | ❓/🆕 | Comment list + add (S.27) |
| DELETE | `/comments/{id}` | 🆕 | Own comment |
| GET | `/hashtags/trending` | 🅿️ | Hashtag + mention notifications (M7.8) |

### 11.10 Network — follow, connect, community (S.3, S.12–S.14, S.19)

| Method | Path | Status | Notes |
|---|---|---|---|
| POST/DELETE | `/follow/{type}/{id}` | 🆕 | One-way follow (athlete/coach/academy/event) |
| GET | `/me/followers`, `/me/following` | 🆕 | S.19 tabs |
| POST | `/connections` | 🆕 | Request (athlete↔athlete, scout→athlete with purpose) |
| GET | `/me/connections` | 🆕 | Tabs Connections/Requests/Sent |
| PATCH | `/connections/{id}` | 🆕 | Accept/decline → unlocks chat |
| DELETE | `/connections/{id}` | 🆕 | Cancel sent / remove connection |
| GET | `/me/suggestions` | 🅿️ | Suggested-for-you (S.12) |
| Groups (S.13/S.14) | — | ⏸️ | P2 parked — no endpoints |

### 11.11 Messaging — inbox, thread (S.17, S.18)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET | `/conversations` | ❓/🆕 | Tabs Chats/Requests, search, unread badges |
| POST | `/conversations` | 🆕 | Start from accepted connection (or auto-create on accept) |
| GET | `/conversations/{id}` | ❓/🆕 | Thread (S.18); report/block entry |
| POST | `/conversations/{id}/messages` | ❓/🆕 | Text P0; attachments P1 |
| PATCH | `/conversations/{id}/read` | 🆕 | Read receipts |
| Rules enforced | — | 🆕 | No cold DMs; minors = guardian-allowed connections only |

### 11.12 Scouting — shortlist, observations, reports, contact (SC.2–SC.13)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET | `/me/scout-dashboard` | 🆕 | Or fold into `GET /me/home` (recommended §11.5) |
| GET | `/athletes` (discover SC.4) | 🔁 | Open to scout; add `position, level, achievements` filters |
| GET/POST/DELETE | `/me/shortlist` | 🔁 | Extend guide's draft: `status` (under_review/good/high/final), `tags`, private notes, pipeline tabs |
| POST/GET | `/observations` | 🆕 | Quick note + rating + optional media (SC.10) |
| POST | `/athletes/{id}/contact` | 🆕 | Purpose (trial invite/enquiry); U-18 routes to guardian (SC.13) |
| POST/GET | `/scout-reports` | 🅿️ | 5-dimension assessment + conclusion (SC.8/SC.9) |
| GET | `/scout/compare?ids=` | 🅿️ | Side-by-side scores (SC.7) |

### 11.13 Academy ops — athletes & venues (AC.5, AC.10, OR.13)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET | `/me/academy/athletes` | 🅿️ | Age-chip filters, ratings (AC.5) |
| POST | `/me/academy/invites` | 🅿️ | Invite by name/phone (AC.10) |
| PATCH | `/me/academy-invites/{id}` | 🅿️ | Athlete accept/decline → sets `academy_id` |
| GET/POST/PUT | `/me/venues` | 🅿️ | Organizer-owned venues (OR.13); public browse exists |
| Staff / collabs | — | ⏸️ | P2 parked |

### 11.14 Notifications + broadcast (S.16, AD.12)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET | `/me/notifications?tab=` | 🔁 | Tabs All/People/Opps/Events/Mentions; Today/Yesterday/Week grouping |
| PATCH / POST | `…/read`, `…/read-all` | ✅ | — |
| POST | `/me/device-tokens` | ✅ | Exists per wiring plan (verify) |
| Notification types | enum extend | 🔁 | follow, connection, message, enquiry, registration decision, verification result, mention, broadcast |
| POST/GET | `/admin/broadcasts` | 🅿️ | Audience filter + schedule + FCM fan-out job (AD.12) |

### 11.15 Trust & safety (S.23, S.26)

| Method | Path | Status | Notes |
|---|---|---|---|
| POST | `/reports` | 🔁 | Extend morphs: `user`, `post` (+ opportunity/program/facility) |
| GET | `/me/reports` | 🆕 | My report statuses (S.23 safety centre) |
| POST/GET/DELETE | `/blocks`, `/blocks/{id}` | 🆕 | Block/unblock + blocked list (S.23) |

### 11.16 Settings, help, account (S.22, S.24, S.25)

| Method | Path | Status | Notes |
|---|---|---|---|
| GET/PUT | `/me/settings` | 🔁 | + visibility/messaging prefs, language, push toggles |
| GET | `/meta/faqs` | 🆕 | FAQ list (S.24 P0) |
| POST | `/support/contact` | 🆕 | Report-a-problem + contact (S.24 P0) |
| About/legal | client static | — | No endpoints (version string only) |

### 11.17 Admin console (AD.1–AD.12)

| Method | Path | Status | Notes |
|---|---|---|---|
| POST | `/admin/login`, `/admin/verify-2fa` | ✅ | + enforce 2FA middleware (was HIGH missing) |
| GET | `/admin/dashboard` | ✅ | Extend counters: verifications pending, reports open, users by role |
| GET | `/admin/users` (+filters) | 🆕 | Search, role/status filters (AD.3) |
| GET/POST | `/admin/users/{id}`, `…/suspend`, `…/ban` | 🆕 | Detail + Verify/Suspend/Ban |
| GET/POST | `/admin/verification`, `…/{id}/approve`, `…/reject` | 🆕 | Queue + reason-required reject (AD.4) |
| Content CRUD | `/admin/content/{type}` | 🔁 | Add types: opportunities, programs, facilities, posts |
| Moderation | `/admin/moderation/**` | 🔁 | Add user/post targets + suspend action |
| Master data | `/admin/categories/**` | ✅/🆕 | + `positions` |
| Expiry | `/admin/expiry*` | 🔁 | + opportunity type |
| Leaderboard config | `/admin/leaderboard-config`, `/reset-season` | 🅿️ | Weights + season controls (AD.11) |

### 11.18 Meta, media, system, analytics

| Method | Path | Status | Notes |
|---|---|---|---|
| GET | `/meta/sports\|cities\|age-groups\|trending-searches` | ✅ | — |
| POST | `/media/upload`, reorder, delete | ✅ | + signed URLs (planned MEDIUM) |
| POST | `/analytics/events` | 🆕 | Funnel logging (signup, registration, enquiry, shortlist) → feeds OR.12 |
| GET | `/system/health` | ❓ | Was MEDIUM missing in old plan — verify |
| Reviews D.14/D.15 | `/reviews` CRUD | 🅿️ | Gated to post-verified-interaction |

### Endpoint count roll-up (new design)

| Wave | New endpoints | Changed | Verify-first | Removed |
|---|---|---|---|---|
| P0 | ~70 | ~25 | ~10 (social/chat/admin-users) | sponsor role routes (~12) |
| P1 | ~30 | ~8 | ~5 (analytics/broadcast/faq) | — |
| P2 | 0 (parked) | — | — | — |

