# 03b — M2 Profiles & Portfolio / M3 Discovery, Search & Saved — End-to-End Audit

Scope: trace M2.1–M2.12 and M3.1–M3.11 UI → state → API → route → controller → validation/auth → DB → response → UI.
Read-only audit, 2026-11-02. Paths relative to repo root. Backend = `sportx-api/`, app = `sportx_app/`.

---

## M2.1 Athlete profile — Status: DONE (minor gaps)

Evidence:
- Route: `sportx-api/routes/api.php:227-230` (`/me/profile` GET/PUT, `/me/profile/images` PUT) — `auth:sanctum`.
- Controller: `sportx-api/app/Http/Controllers/ProfileController.php:11-42` (show, role-matched with eager loads), `:44-126` (update, per-role validation), `:135-178` (updateImages, photo/cover slots), `:180-224` (updateSports).
- Public/self view: `AthleteDiscoveryController::show` (`api.php:273`) loads user, sports, city, ageGroup, photo, academy, coach, achievements, mediaItems (`AthleteDiscoveryController.php:60-81`).
- Flutter: `sportx_app/lib/features/athlete/presentation/screens/profile_screen.dart` (server data, completion % from `/me/home` at `:162-173`), shared viewer `sportx_app/lib/features/shared/presentation/screens/view_profile_screen.dart:148-173` (`/athletes/{id}`, `/coaches/{id}`).
- Social links attached to payload: `ProfileController.php:36` via `SocialLinksController::attach`.

Gaps:
1. **Athlete gallery key mismatch on public profile** — `AthleteDiscoveryController::show` sets the media attribute under `media` (`AthleteDiscoveryController.php:65-70`) while `ViewProfileScreen` reads `media_items` (`view_profile_screen.dart:90`). The other-viewer athlete profile renders an empty Media Gallery. MEDIUM.
2. `ViewProfileScreen` coach subtitle falls back to `₹0/hour` reading `hourly_rate` (`view_profile_screen.dart:589-596`) — no such column on coach_profiles; shows a fake ₹0 rate. LOW.
3. Hard-coded "Performance Stats" block (42 Matches / 1,250 Runs / 35.7 Avg / 12 Wickets) exists in `view_profile_screen.dart:931-952`. It is gated on `performance_stats` which no backend endpoint ever returns (grep of `sportx-api/app` = 0 hits), so it is dead-gated, but the mock values are in the production widget tree. LOW.
4. Empty/error: profile_screen shows snackbar on failure (`profile_screen.dart:151-156`) but no full error state with retry; loading skeleton present.

Severity: MEDIUM overall (gallery mismatch).

## M2.2 Multi-sport data — Status: DONE

Evidence:
- `PUT /me/profile/sports` (`api.php:229`), `ProfileController::updateSports` (`ProfileController.php:180-224`) — accepts rich objects `{sport_id, playing_role, level, experience_years, is_primary}` and syncs pivot.
- Pivot migration `sportx-api/database/migrations/2026_08_12_000002_create_athlete_sports_pivot.php` — `athlete_sports` with `unique(athlete_id, sport_id)`; extended columns in `2026_10_14_000001_phase2_privacy_pivots_achievements.php:17-38`.
- `AthleteProfile::sports` belongsToMany eager-loaded in discovery (`AthleteDiscoveryController.php:12`).
- Flutter: `sportx_app/lib/features/athlete/presentation/screens/manage_sports_screen.dart`.

Gaps: none material. Note `Schema::hasColumn('athlete_sports','playing_role')` feature-detection means pre-migration DBs silently drop rich fields (acceptable degradation). Severity: LOW.

## M2.3 Achievements & certificates (upload) — Status: PARTIAL

Evidence:
- Routes: `/me/achievements` CRUD (`api.php:441-444`). Controller `AchievementController.php` — typed CRUD, owner-scoped via `scope()` (`:160-175`), year/type/sport/level/certificate validation (`:41-49`), leaderboard recalc job dispatch (`:67-74`).
- Certificate columns: `2026_10_14_000001_...:57-88` (`certificate_media_id` FK to media_items, title/type/sport/level/year/description).
- Upload path: Flutter `add_achievement_screen.dart:59-80` uploads certificate via `POST /media/upload` (`media_type: 'document'`), then attaches `certificate_media_id`.
- Media upload validation: `MediaController::upload` (`MediaController.php:181-316`) — size `max_upload_mb=10` (`config/sportx.php:190`), content-SNIFFED MIME allow-list (`:224-238`; photo: jpeg/png/webp, document: pdf/jpeg/png), ownership check on client-supplied owner (`:244-251`), transactional quota counter (`:292-303`), `CompressPhoto` job (`:307`).

Gaps:
1. **Certificates stored on PUBLIC disk.** `MediaController.php:266` — `$file->store(..., 'public')`, `disk` column forced `'public'` (`:273`), `MediaItem::url()` (`app/Models/MediaItem.php:25-34`) returns `/storage/...`. Achievement certificates (PDFs/JPGs of identity-ish documents) are directly fetchable by anyone with the URL, no auth. A signed-URL flow exists (`signedUrl`, `MediaController.php:389-407`) but is pointless while files live on the public disk. HIGH.
2. **No ownership check on `certificate_media_id`** — `'certificate_media_id' => 'nullable|exists:media_items,id'` (`AchievementController.php:47,92`) allows attaching another user's media row id. LOW.
3. Certificate upload sends no `context` → defaults to `context='gallery'` (`MediaController.php:201`), so certificates can appear in gallery listings (client filters by media_type, server does not). LOW.
4. Quota: only `photo`+`context=gallery` counts (`MediaController.php:208-216`) — documented, per-role limits via `PlatformSettings::galleryPhotoLimit` (`app/Support/PlatformSettings.php:108-117`). Certificate uploads unlimited (no per-user cap on documents). LOW.

Severity: HIGH (public-disk certificates).

## M2.4 Media gallery — Status: DONE

Evidence:
- `GET /me/media`, `/me/media/quota`, `POST /media/upload`, `DELETE /media/{id}`, `PUT /media/reorder`, signed download (`api.php:210-216`); all owner-checked (`MediaController.php:57-69,318-377`).
- Gallery-only context filter server-side (`MediaController.php:139-147`); quota endpoint + drift repair (`:71-109,161-179`).
- Flutter: `media_gallery_screen.dart` — quota guard client-side with authoritative server re-check (`:35-55,247-257`), tabs photos/legacy-videos (`:170-171`), delete/reorder, viewer.
- Quota plan doc present (root `PHOTO_QUOTA_COMPRESSION_PLAN.md`).

Gaps: video grid tab is vestigial (uploads disabled server-side, `MediaController.php:184-188`); server gallery index is not media_type-filtered (documents with context=gallery appear in raw payload). LOW. Severity: LOW.

## M2.5 Coach profile — Status: DONE

Evidence:
- `/me/coach-profile` GET/PUT, `role:coach` (`api.php:233-234`); `CoachProfileController.php:9-62` — languages, certifications, availability, fee fields, achievements blob (`:24-48`).
- Public listing/detail: `DirectoryController::coaches/coach` (`api.php:183-184`), detail attaches social links and unsets user (`DirectoryController.php:55-62`).
- Programs tab: `/programs` public (`api.php:249-250`), morphs coach/academy; Flutter `_ProgramsTab` (`coach_profile_view_screen.dart:481-497`) links to managed programs; enrollment flow `/coaches/{coach}/enroll` (`api.php:339`).
- Completion checks for coaches server-side: `CompletionChecklistController.php:134-147`.

Gaps: `full_name` update in `CoachProfileController::update` writes all `$validated` straight into `$profile->update($validated)` (`:54`) — mass-assignment is fillable-guarded, OK; but `email` here writes to profile table not users table (potential divergence). LOW.

## M2.6 Academy profile — Status: DONE (Reviews tab missing)

Evidence:
- `/me/academy` GET/PUT `role:academy` (`api.php:235-236`), `AcademyController.php:12-65` (sports sync, academy_type, listing_status).
- Public: `DirectoryController::academies/academy` (`api.php:181-182`), `published()` scope + rich resource incl. head_coach, sports_offered, facilities (`DirectoryController.php:28-35,90-115`).
- Facilities CRUD `role:academy,organizer` (`api.php:259-262`); programs `/programs`.

Gaps: spec's Reviews tab — no rating data exists anywhere (see M2.12); Flutter `academy_detail_screen.dart:30-31` passes `rating: null, reviewsCount: null`. Staff count/facilities present via facilities + academy_coaches. Severity: LOW (blocked only by M2.12).

## M2.7 Organizer profile — Status: PARTIAL

Evidence:
- `/me/organizer` GET/PUT + team CRUD (`api.php:237-243`), `OrganizerProfileController.php:9-54` (event_types, org_type per spec §5, sports sync).
- Public card: `GET /organizers/{id}` (`api.php:246`) → `publicShow` (`OrganizerProfileController.php:59-70`).

Gaps:
1. `publicShow` returns the **raw `$profile->toArray()`** with no field allow-list — includes `registration_number`, `verification_doc_media_id`, `user_id` (`fillable` at `app/Models/OrganizerProfile.php:14-27`). `verification_doc_media_id` id can be fed to `/media/{id}/signed-url`? No — signed-url checks ownership, but the **public storage URL** of the verification document is fetchable directly if the media id is enumerated (`/storage/media/organizer_profile/{id}/...`). MEDIUM.
2. Public card has **no event stats, venues, team, media** (spec F-16) — it's the bare profile row. PARTIAL vs spec.
3. No listing/publish status gate on `publicShow` (unlike academies' `published()`); any draft organizer is publicly visible. LOW.

## M2.8 Scout profile (shortlist/reports private) — Status: DONE

Evidence:
- Scout self-service `role:talent_scout` group (`api.php:276-294`); shortlist + observations strictly scoped to caller's profile: `ScoutShortlistController.php:15,22,41,49,88,107,120` and `ObservationController.php:14-21` all filter `talent_scout_profile_id = $request->user()->talentScoutProfile->id`.
- Public scout profile `GET /scouts/{id}` (`api.php:298`, `role:athlete` only) → `TalentScoutController::publicShow` (`TalentScoutController.php:73-87`): returns profile row only, `unset($data['user'])`, verified flag. **No shortlist/report data is reachable from any public route** (verified: shortlist/observations routes all under auth + owner scope).
- Contact not exposed (profile has no phone/email columns — `2026_09_04_000001_create_talent_scout_profiles_table.php`).

Gaps: `publicShow` and scout index ignore `listing_status` (`TalentScoutController.php:15-52,73-87`) — scouts who set listing off are still listed/shown. LOW. Severity: LOW.

## M2.9 Privacy controls — Status: PARTIAL (athletes only, one policy never enforced)

Evidence (server-side enforcement IS real for athletes):
- Storage: `users.privacy_settings` JSON (`2026_10_14_000001_...:11-18`), cast `array` (`app/Models/User.php:34`).
- Minors default restricted: `PrivacyController::defaultsFor` (`PrivacyController.php:24-32`) — minor → `profile_visibility=followers`, `who_can_message=connections`, `who_can_connect=nobody`; `User::isMinor()` (`User.php:119-134`).
- Minors cannot loosen settings: `PrivacyController::update` (`:45-65`) restricts allowed values for minors.
- Enforcement, athlete visibility: `AthleteDiscoveryController::isVisibleTo` (`:86-103`, anything not `public` → self/admin only) applied on list (`:46-49`), detail (`:74-78`, 403) and universal search (`SearchController.php:216-222`). Detail endpoint is auth-required (`api.php:273`).
- Minor masking: `maskMinor` strips `date_of_birth` + `phone`, sets `is_minor` (`AthleteDiscoveryController.php:111-134`) — applied on list, detail and search.
- Messaging enforcement: `ConversationController.php:297-299` enforces target `who_can_message`.

Gaps:
1. **`who_can_connect` is never enforced anywhere.** Grep of `app/` shows it only in PrivacyController (storage) and the settings UI. `ConnectionController::request` and `ScoutConnectionController::store` never read it — for minors (default `nobody`) any user can still POST `/connections` or `/athletes/{athlete}/connect`. HIGH.
2. **Privacy applies to athletes only.** Coaches/academies/organizers/scouts expose `profile_visibility` in their settings UI (`settings_screen.dart:142-176` is role-generic), but `/coaches`, `/academies` are **public unauthenticated routes** (`api.php:181-184`) with zero visibility filtering, and `/organizers/{id}`, `/scouts/{id}` likewise. Setting "followers/private" for those roles does nothing. HIGH.
3. `profile_visibility=followers` is treated identically to `private` (`isVisibleTo:95-102`) — there is no follow-graph check, so the "followers can see" tier silently behaves as "nobody". MEDIUM.
4. `SavedItemController::enrich` for `athlete_profile` (`SavedItemController.php:149-157`) and `SearchController::athletesGroup` apply visibility, but a blocked-by-privacy athlete can still be reached via `/me/saved` enrich (title/photo of a private profile leak into saved list). LOW.

Severity: HIGH (2 gaps above).

## M2.10 View as Public / Share profile (P1) — Status: BROKEN (UI-only)

Evidence:
- Flutter screen exists: `sportx_app/lib/features/athlete/presentation/screens/view_as_public_screen.dart` (149 lines).
- **Entirely hard-coded**: stats `('12','48','2','5')` (`:78-83`), fake bio string (`:121-124`), tabs always show empty states. It does not render the user's real data at all and does not simulate any server-side privacy filtering.
- Share: `profile_screen.dart:459-462` shares `{ApiConfig.webBaseUrl}/profile/{userId}` (default `https://sportx.in`, `core/config/api_config.dart:11`); same hard-coded URL in `view_profile_screen.dart:506-510`.
- **No web route serves `/profile/{id}`**: `sportx-api/routes/web.php` contains only `/` and `/panel/*`; `sportx.in` is not even the API host. Every shared profile link 404s. There is no public profile web page and no "view as public" API (no unauthenticated athlete profile endpoint — `/athletes/{id}` requires auth, `api.php:273`).
Gaps: feature as specced (preview + deep-link share) does not function. Severity: HIGH (P1 feature, fully non-functional share path; hard-coded mock data in a production screen).

## M2.11 Social links (P1) — Status: DONE

Evidence:
- `GET/PUT /me/social-links` (`api.php:433-434`); `SocialLinksController.php` — platform whitelist (`:17`), URL normalization (`@handle` → https, `:111-121`), validation (`:47-65`).
- Surfaced on payloads: own profile `ProfileController.php:36`, coach detail `DirectoryController.php:58`, academy detail `:32`, scout self `TalentScoutController.php:62`.
- Flutter: `shared/presentation/widgets/social_links.dart`; `ViewProfileScreen._buildSocialLinksSection` renders real links, hidden when empty (`view_profile_screen.dart:1023-1026`).

Gaps: social links are attached to *own* athlete profile but not to the athlete public profile (`AthleteDiscoveryController::show` doesn't call `attach`) — viewers don't see an athlete's links. LOW.

## M2.12 Ratings & reviews (P1) — Status: NOT STARTED

Evidence:
- No `Review`/`Rating` model, table, migration, route or controller exists (grep `sportx-api` for review/rating models = none; only `leaderboard` `rating` column in `2026_10_18_...php:42` is unrelated).
- No `avg_rating` column on coach_profiles/academies (0 hits in migrations) — `DirectoryController::sortBy` rating branch is dead (`DirectoryController.php:77-79`), and the `rating` filter at `:48` is column-guarded so it no-ops.
- Flutter: `coach_directory_screen.dart:122` renders `c.avgRating ?? c.rating ?? 0` — always 0; `academy_detail_screen.dart:30-31` passes nulls.
Gaps: entire feature absent (spec allowed P0 read-only seeded display + P1 submit; neither exists). Severity: MEDIUM (P1).

---

## M3.1 Explore (All + tabs) — Status: DONE

Evidence:
- Backend: `GET /explore` grouped, capped sections (`api.php:207`, `HomeController::explore` `:57-70`) — **but the Flutter app never calls `/explore`** (grep: only router path strings). The screen composes its own sections from the paginated directory providers: `explore_screen.dart:180-182,391,410,451,472` (`trialsProvider`, `tournamentsProvider`, `sportsVenuesProvider`, `athletesProvider`, `coachesProvider`, `academiesProvider` in `shared/providers/directory_provider.dart:113-146`).
- Tabs Events/Venues/Athletes/Coaches/Academies (`explore_screen.dart:173`), "See All" routes (`:100-105,132-138`), empty/error states present (12 EmptyState/error refs).
Gaps: `GET /explore` is API-only dead weight; "All" tab of the spec is the Home screen instead. LOW. Note: rail sections use `athletesProvider` (first 20 only, no pagination). LOW.

## M3.2 Athlete discovery — Status: DONE (with auth caveat)

Evidence:
- `GET /athletes` (`api.php:272`) — `role:sponsor,talent_scout,athlete` (no guest discovery), filters q/sport_id(array)/city_id/age_group_id/skill_level/has_achievements, per_page cap 50 (`AthleteDiscoveryController.php:22-41`), privacy + minor masking (`:46-52`), self-exclusion (`:17-20`).
- Detail `GET /athletes/{id}` (`:58-81`) — auth, visibility 403, minor mask.
- Flutter: `athletesProvider`/`athleteDetailProvider` (`directory_provider.dart:141-154`); athlete directory screen `features/connections/presentation/screens/athlete_directory_screen.dart`; follow/connect actions in `view_profile_screen.dart`.

Gaps: achievements relation eager-loaded in full on the list (`:12`) purely for `has_achievements` — heavy payload (only `achievements_count` is needed). MEDIUM perf. Position/state filters absent (city only). LOW.

## M3.3 Coach discovery — Status: DONE

Evidence:
- `GET /coaches` public (`api.php:183`), filters sport_id/city_id/fee_min/max/age_group/level/experience/rating(col-guarded)/q/sort (`DirectoryController.php:37-53`), pagination cap 50 (`:83-88`), index `(listing_status, city_id)` on coach_profiles (`2026_01_01_000008_create_coach_academy_tables.php:65`).
- Flutter: `coach_directory_screen.dart` w/ retry + empty states, enroll action (`api.php:339`).

Gaps: `fee_min/fee_max` compared against `fee_structure` which is a **string** column (`'nullable|string|max:120'` validation in `CoachProfileController.php:39`) — numeric range comparison on a string like "₹500/session" is meaningless. Same for academy `fee_range` (`DirectoryController.php:17-18`). MEDIUM (filters silently misbehave). `rating` filter dead (no column). LOW.

## M3.4 Academy / training discovery — Status: DONE

Evidence:
- `GET /academies` public (`api.php:181`), `DirectoryController::academies:11-26` — sport/city/fee/age_group JSON/facility JSON/verified/q/sort; detail with head_coach, coaches, sports, social links (`:28-35`).
- Training segments via `/programs` (`api.php:249-250`) and Flutter academies/coaches/training segments in academy screens (`academy_directory_screen.dart`, retry/empty present).
- Index `(listing_status, city_id)` (`2026_01_01_000008...:38`).

Gaps: fee_range string-compare (as above); `whereJsonContains('age_groups', (int)...)` requires exact int match in JSON array — brittle if stored as strings. LOW.

## M3.5 Event / trial discovery — Status: DONE (covered by M5 auditors in depth)

Evidence: `/trials`, `/tournaments` public (`api.php:185-188`), published scopes + sport/city eager loads in Search/Explore; Flutter `trialsProvider`, `tournamentsProvider`, event cards with date badges; unified `/events` for owners (`api.php:367-373`).
Gaps: none in scope of this audit beyond what M5/M6 drafts cover.

## M3.6 Universal search — Status: PARTIAL (pagination broken; dead groups)

Evidence:
- `GET /search` public (`api.php:203`), `SearchController::search:18-150` — 8 groups (academies, coaches, trials, tournaments, scholarships, sponsorships, venues, athletes), validation of q/sport/city/age_group/date/gender/position/level/facilities/sort (`:20-32`), recent-search persistence (`:51-56,152-178`).
- Athletes group privacy-gated + minor-masked via delegation (`:186-223`).
- Flutter: `search_provider.dart:240-320` — debounce gen-guard (`:245-247,296`), grouped results, recent searches sync (`:322-373`), trending fallback chips (`:395-415`).

Gaps:
1. **Search pagination is broken end-to-end.** Server returns fixed `limit(N)->get()` collections with `meta = {query, filters}` only (`SearchController.php:146-149`) — no paginator, no current_page/last_page. Client sends `page`/`per_page=20` and reads `meta.current_page`/`meta.last_page` (`search_provider.dart:251,292-304`) → `hasMore` is always false; `loadMore()` (`:359-363`) is a no-op. Even if it fired, the server ignores `page` and would return duplicates. MEDIUM.
2. **Legacy groups still queried:** `scholarships`/`sponsorships` groups query `Scholarship`/`Sponsorship` models (`SearchController.php:121-130`) while the Phase-4 cutover 410'd their directories (`api.php:195-198`) — search results can return stale rows from tables the product no longer exposes. LOW.
3. Filters `fee_min/fee_max`, `facility` (client sends singular `facility`, server reads plural `facilities` for venues only, `search_provider.dart:125` vs `SearchController.php:44`) are silently ignored by `/search`. LOW-MEDIUM.
4. `sort=distance|rating` validated (`:31`) but never applied — only echoed in meta. See M3.7/M3.8.
5. Error state: `universal_search_screen.dart:154-167` — on error `results` stays null and `query` non-empty → falls into "No results found" branch; network errors are indistinguishable from empty results (error field never rendered). MEDIUM UX.

## M3.7 Filters & sort — Status: PARTIAL

Evidence:
- Per-entity supported params verified above (M3.2–M3.6, M3.10). Sort whitelist in `DirectoryController::sortBy` (`:65-81`) prevents injection; allowed: name/created_at/verification_badge/year_established (+experience/avg_rating when the column exists — it doesn't).
- Flutter `SearchFilters` (`search_provider.dart:21-137`) exposes sport/city/position/level/facility/sort/gender/fee/date.
Gaps:
- sort by **relevance** is not implemented (server sorts by column or latest, never by match relevance). MEDIUM.
- sort by **distance**/**rating** accepted but no-ops (server and client). MEDIUM.
- **state filter** absent (spec M3.7 state/city) — only city_id. LOW.
- athlete **position** filter absent on `/athletes` (only in `/search` coaches). LOW.
- fee sliders silently dead in universal search (above). MEDIUM when combined with 3.6.3.

## M3.8 Distance / "near me" — Status: NOT STARTED

Evidence:
- **No geolocation anywhere in the stack.** Zero `latitude`/`longitude`/`distance` columns in any migration (grep = 0 hits); no distance sort/filter logic in any controller (the only `distance` hits are the accepted-but-ignored `sort=distance` at `SearchController.php:31` and unrelated deadline logic in OrganizerAnalyticsController).
- Flutter: no `geolocator`/`location` package in `sportx_app/pubspec.yaml`; zero `km`/`Geolocator`/`LocationPermission` strings in `lib/` (grep = 0 hits). No "km on academy cards" exists — nothing hard-coded, nothing real.
Gaps: feature entirely absent despite P0. Severity: HIGH (P0 gap).

## M3.9 Saved / bookmarks — Status: PARTIAL (server-side solid; client truncates)

Evidence:
- `GET/POST/DELETE /me/saved` (`api.php:219-221`), all auth-scoped to `user_id` (`SavedItemController.php:22,42-49,61-64`).
- 10 server-validated item types incl. `athlete_profile`, `coach_profile`, `opportunity`, `post` (`:38`); dedupe `409` (`:47`); DB unique `(user_id, item_type, item_id)` (`2026_01_01_000015_create_interaction_tables.php:41`); enrichment per type (`:73-183`); pagination cap 50 (`:26`).
- Flutter: `saved_provider.dart` — toggle optimistic (`:97-131`), remove, server persistence.
Gaps:
1. **Client loads only page 1 (default 20) and has no loadMore** (`saved_provider.dart:68-94` — no per_page, no pagination) → saved items beyond the first 20 are invisible, and `isSaved()` (`:57-58`) returns false for them, so the heart icon on profile screens un-marks already-saved items. MEDIUM.
2. No `event` item_type (Phase 8 unified events can't be saved as `event`; trials/tournaments individually still can). LOW.
3. Enrich is N+1 (one `::find` per item, `:85-177`) — capped at 50/page, acceptable. LOW.
4. `saved_screen.dart` has empty state; error state present (`saved_provider.dart:85-93`).

## M3.10 Venue / facility discovery (P1) — Status: DONE

Evidence:
- `GET /sports-venues`, `/sports-venues/{id}` public (`api.php:199-200`); `SportsVenueController.php:10-29` — sport/city/booking/q filters, pagination cap 50, published scope.
- Search integration (`SearchController.php:131-142`), explore section (`HomeController.php:67`).
- Flutter: `sportsVenuesProvider` (`directory_provider.dart:137-139`), `sports_venue_list_screen.dart` (loading + empty states), `sports_venue_detail_screen.dart`, plus Venues tab in explore (`explore_screen.dart:391`).
Gaps: `facilities` filter in search does LIKE across name/address (loose). LOW.

## M3.11 Recommendations (P1) — Status: PARTIAL (fake)

Evidence:
- Home "Recommended Athletes for You" rail (`home_screen.dart:142-145,170-229`) — renders `athletesProvider.take(6)` (`:197`), i.e. simply the first 6 rows of `GET /athletes` (which is ordered by whatever `AthleteProfile` default order is, no scoring).
- No rule-based sport/age/location matching exists server-side; no recommendation endpoint.
Gaps: it is discovery-by-arbitrary-order wearing a "Recommended" label. Also subject to athlete privacy filtering (good) but not role-aware for coaches/organizers (rail is shown on the generic home). LOW-MEDIUM (P1; mislabeled feature rather than broken data).

---

## Cross-cutting verification answers (per brief)

1. **Privacy server-side?** Yes for athletes (list/detail/search all gate + mask, `AthleteDiscoveryController.php:46-52,72-78`); minors default restricted and cannot loosen (`PrivacyController.php:24-65`). BUT `who_can_connect` is stored and never enforced, and non-athlete profiles have no privacy enforcement on public directory routes (see M2.9 gaps 1-2).
2. **Media upload:** public disk for ALL content types including achievement certificates/documents (`MediaController.php:266,273`); MIME sniffed allow-list, 10 MB cap, per-role gallery-photo quota (photos only, `context=gallery`), quota maintained transactionally with drift repair. Certificates have no quota and no ownership binding on attach.
3. **Search/filter/pagination/indexes:** every list endpoint paginates except `GET /search` groups (fixed limit) — and the client wrongly expects paginator meta there. Indexes: `(listing_status, city_id)` on coach/academy, FK-backed indexes on athlete city/age_group/dob, `(owner_type, owner_id, sort_order)` on media_items, unique on saved_items — adequate; `%LIKE%` text search is unindexable but acceptable at this scale. N+1: athlete list over-loads full `achievements`; saved enrich N+1 (capped).
4. **Saved:** server-side, 10 types, dedup + unique index — solid; client truncates to 20.
5. **Scout:** shortlists/observations owner-scoped only, no public exposure (verified all routes).
6. **Completion meter:** computed server-side (`CompletionChecklistController`, `HomeController::completionFor` at `HomeController.php:45`), deep links provided per missing item (`CompletionChecklistController.php:108-116` deep_link keys), but the Flutter profile-completion screen mostly recomputes from profile data locally (`profile_completion_screen.dart:26-89`) and `/me/completion-checklist` is consumed only by the organizer provider (`organizer_provider.dart:161-163`); deep_link strings are spec names (`profile/edit`, `scout/sports`) that don't match the app's GoRouter paths — deep links are effectively decorative. MEDIUM.
7. **Hard-coded/mock data:** `view_as_public_screen.dart` fully mocked; `view_profile_screen.dart:931-952` mock performance stats (dead-gated); trending-search fallback chips (`search_provider.dart:405-414`, acceptable fallback); no TODO/FIXME debt in these features. Empty/loading/error states: good on directories/explore/saved (skeletons, retries); universal search lacks a distinct error state.
8. **Distance/near me:** nothing — no geo columns, no location permission, no km strings. Not implemented at all (not merely hard-coded).

## Top risks (ranked)

| # | Finding | Severity |
|---|---------|----------|
| 1 | Certificates/identity documents on public disk, unauthenticated URLs | HIGH |
| 2 | `who_can_connect` never enforced; minors' "nobody" connect policy is fiction | HIGH |
| 3 | Privacy settings do nothing for coach/academy/organizer/scout public profiles | HIGH |
| 4 | M3.8 near-me/distance P0: not implemented in any layer | HIGH |
| 5 | M2.10 share links 404 (no web route) + fully mocked "View as Public" | HIGH |
| 6 | Universal search pagination broken (no server paginator, client reads nonexistent meta) | MEDIUM |
| 7 | Saved list truncated to 20, breaks save-state beyond page 1 | MEDIUM |
| 8 | Fee range filters compare against string columns (coaches/academies) | MEDIUM |
| 9 | Organizer public card leaks registration_number/verification doc id, no stats | MEDIUM |
| 10 | Search error state indistinguishable from "No results" | MEDIUM |
