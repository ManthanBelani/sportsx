# 01 — Feature Traceability Matrix (M1–M12)

Every feature ID from `sportsx-design-v3/new_design_docs/MVP_FEATURE_LIST.md`, with the traced status. Evidence is `file:line` in the repo; full traces live in `audit_report/_drafts/03a…03f`. Machine-readable version: `01_FEATURE_TRACEABILITY.csv`.

**Status vocabulary:** DONE · PARTIAL · UI-ONLY · API-ONLY · NOT STARTED · BROKEN · UNVERIFIED · OUT OF SCOPE
**Severity:** BLOCKER · HIGH · MEDIUM · LOW · —

### Summary counts

| Priority | Total | DONE | PARTIAL | BROKEN | NOT STARTED | UI-ONLY | DONE % |
|---|---|---|---|---|---|---|---|
| **P0** | 69 | 35 | 31 | 1 | 2 | 0 | **51%** |
| **P1** | 27 | 3 | 7 | 2 | 5 | 7 | **11%** |
| **P2** | 10 | 0 (groups stack fully built = scope creep) | — | — | — | — | — |

**P0 features NOT done (34):** M1.1, M1.4, M2.3, M2.7, M2.9, M3.6, M3.7, M3.8, M3.9, M4.3, M4.4, M4.5, M5.3, M5.6, M6.2, M7.1, M7.3, M7.6, M8.1, M9.2, M10.1, M10.2, M10.5, M11.1, M11.2, M11.3, M11.5, M11.6, M11.8, M11.9, M12.2, M12.4, M12.5, M12.6 — of which M11.3 is BROKEN and M3.8/M12.6 are NOT STARTED.

---

## M1 — Accounts, onboarding & trust

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence (key) | Gaps / required change | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M1.1 | Sign up / login (OTP, consent, session) | P0 | A.3–A.5 | `sign_up_screen.dart`, `otp_screen.dart`, `auth_provider.dart`, `storage_service.dart:14-31` | `AuthController.php`, `OtpController.php`, `OtpService.php`; routes api.php:113-136 | `users`, `otp_codes` | PARTIAL | OTP pipeline strong (`OtpService.php:47-113`: bcrypt, expiry, attempts, throttles) | T&C/privacy consent never captured (checkbox UI-only, no API field, no migration); password signup auto-verifies email (`AuthController.php:62`); phone/SMS OTP unavailable — email only; login OTP bypassable via `require_otp=false` (`AuthController.php:194-196`); Sanctum `expiration => null` | **HIGH** |
| M1.2 | Role selection, one role per account | P0 | A.2 | `role_selection_screen.dart`, `role_config.dart` | `AuthController.php:42-56`, `OnboardingController.php:20,58,86,130`, `role:` middleware | `users.role` | DONE | Role set only at creation; no endpoint mutates role; onboarding aborts on mismatch | — | — |
| M1.3 | Role onboarding wizards | P0 | AT.2, CO.1, AC.1, OR.1, SC.1 | `multi_step_onboarding_screen.dart` (1,207 lines) | `OnboardingController.php`, `GET /onboarding/{role}` schema | role profile tables | DONE | All 5 wizards wired to POST endpoints | File size/quality only (mobile review §3) | — |
| M1.4 | Guardian consent for minors | P0 | A.9, AT.10 | `guardian_consent_screen.dart`, `guardian_controls_screen.dart` | `GuardianController.php`, `GuardianConsentService.php:57-64` | `guardian_consents` | PARTIAL | Consent row persisted w/ FK; OTP to guardian email; minor chat gate enforced (`ConversationController.php:239-264`) | **Minor can edit own guardian controls** (`PUT /me/guardian-controls`, `GuardianController.php:184-207`) — unlocks own DMs/public profile; guardian contact for scout outreach routes to the minor, not a guardian (`AthleteContactController.php:39-49`); consent checkbox not captured in signup | **HIGH** |
| M1.5 | Profile completion meter | P0 | AT.6, S.1 | `home_screen.dart:75,86`, `profile_screen.dart:372-383`, `more_screen.dart:211` | `CompletionChecklistController.php:108-116`, `HomeController.php:45` | — | DONE | Server-computed, deep-link fields, shown on Home/Profile/More | Flutter deep-link paths don't match GoRouter routes (LOW) | LOW |
| M1.6 | Verification request & blue check | P0 | A.10, AD.4 | `verification_screen.dart` | `VerificationController.php`, admin routes api.php:541-544 | `verification_requests` | DONE | Admin-only approve under `auth+role:admin+admin.2fa`; ownership check `VerificationController.php:57-61`; docs via signed URLs (but see B-6 public disk); hard-override notification on result | Proof docs stored on public disk (B-6) | LOW* |
| M1.7 | Forgot password | P1 | A.6 | `forgot_password_screen.dart:29,57-60` | `AuthController.php:339-375`, `PasswordResetMail.php:20-30` | `users` | BROKEN | Backend emails 64-char token link to `/reset-password?token=…` | No `/reset-password` route in Flutter router; screen asks for a short code never sent; deep link resolves to app.url = ngrok | HIGH |
| M1.8 | Language selection | P1 | A.7 | `language_screen.dart` | `SettingsController.php:49` | `users.settings` | UI-ONLY | Auth-flow selection never saved; backend validates only `en,hi` (Gujarati → 422); no l10n framework in app | MEDIUM |
| M1.9 | Permissions primer | P1 | A.8 | `permissions_screen.dart` | — | — | UI-ONLY | Rationale cards only; no permission_handler wired | LOW |
| M1.10 | Role switching | P2 | — | — | — | — | OUT OF SCOPE | — | — |

## M2 — Profiles & portfolio

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M2.1 | Athlete profile | P0 | D.1, AT.3 | `view_profile_screen.dart`, `edit_profile_screen.dart` | `ProfileController.php`, `AthleteDiscoveryController.php:46-78` | `athlete_profiles`, `athlete_sports` | DONE | Full tabs, visibility enforced server-side in list/detail/search | Public gallery key mismatch (server `media`, client reads `media_items`, `view_profile_screen.dart:90`) → visitor gallery empty | LOW |
| M2.2 | Multi-sport data | P0 | AT.4 | `manage_sports_screen.dart` | `ProfileController::updateSports` | `athlete_sports` | DONE | Primary sport + per-sport fields persisted | — | — |
| M2.3 | Achievements & certificates | P0 | S.11, AT.5 | `add_achievement_screen.dart:59-68`, `achievements_screen.dart` | `AchievementController.php`, `MediaController.php:266-273` | `achievements`, `media_items` | PARTIAL | CRUD wired; certificate upload works | **Certificates stored on public disk** — unauthenticated `/storage/...` fetch; no admin verification of achievements (feeds M8.1 failure) | HIGH |
| M2.4 | Media gallery | P0 | S.10, S.28 | `media_gallery`, `media_viewer` | `MediaController.php` (quota, signed-url) | `media_items` | DONE | Content-sniffed MIME allowlist, 10MB cap, quota in-transaction | All media on public disk (B-6); no upload progress/cancel/retry | MEDIUM |
| M2.5 | Coach profile | P0 | D.2, CO.3 | `coach_profile_edit_screen.dart` | `CoachProfileController.php` (role:coach) | `coach_profiles` | DONE | Fields + programs tab wired | — | — |
| M2.6 | Academy profile | P0 | D.3, AC.3 | `edit_academy_profile_screen.dart` | `AcademyController.php` (role:academy) | `academies`, `academy_sports` | DONE | Tabs + facilities wired | Reviews tab impossible — no rating data exists (M2.12) | LOW |
| M2.7 | Organizer profile | P0 | D.4, OR.3 | `organizer_profile_edit_screen.dart` | `OrganizerProfileController.php`, publicShow :59-70 | `organizer_profiles` | PARTIAL | Public card + edit work | Public card returns raw `toArray()` incl. `registration_number`, `verification_doc_media_id` (PII leak) | MEDIUM |
| M2.8 | Scout profile | P0 | D.5, SC.3 | `scout_profile_screen.dart` | `TalentScoutController.php` | `talent_scout_profiles`, `scout_shortlists`, `observations` | DONE | Shortlists/observations strictly owner-scoped (03e verified, no IDOR) | Shortlist-add notification leaks scout identity to athlete incl. minors (`ScoutShortlistController.php:73-81`); scout dashboard leaks minors' full names (`ScoutDashboardController.php:28-31`) | MEDIUM |
| M2.9 | Privacy controls | P0 | S.22, AT.10 | `privacy settings in settings_screen` | `PrivacyController.php:24-65` | `users.settings` | PARTIAL | Minor visibility floor enforced (`PrivacyController.php:48-65`); athlete visibility enforced in discovery (`AthleteDiscoveryController.php:46-52,72-78`) | **`who_can_connect` never enforced** (zero refs in ConnectionController/ScoutConnectionController); coach/academy/organizer/scout detail endpoints have no visibility enforcement; `/coaches`,`/academies` public unauthenticated | HIGH |
| M2.10 | View as Public / Share | P1 | AT.7, S.30 | `view_as_public_screen.dart` (hard-coded stats :78-83) | none public | — | BROKEN | Fully mocked; share URL `sportx.in/profile/{id}` 404s (routes/web.php serves `/` and `/panel/*` only) | HIGH |
| M2.11 | Social links | P1 | AT.3 | social links editor | `SocialLinksController.php` | `users.social_links` | DONE | — | — |
| M2.12 | Ratings & reviews | P1 | D.14, D.15 | `reviews` screens (mock `average: 4.6`, router.dart:364) | none | none | NOT STARTED | No Review model/table/route anywhere; rating sort dead code | — |
| M2.13 | Team pages | P2 | D.17 | — | — | — | OUT OF SCOPE | — | — |

## M3 — Discovery, search & saved

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M3.1 | Explore (All + tabs) | P0 | S.2, S.3 | `explore_screen.dart` | `HomeController::explore`, `DirectoryController` | various | DONE | Category tabs + rails live | Backend `/explore` endpoint unused by app (dead API) | LOW |
| M3.2 | Athlete discovery | P0 | S.3, SC.4 | `athlete discovery rails` | `AthleteDiscoveryController.php` | `athlete_profiles` | DONE | Filters + minor masking (see gaps) | Nested `user` email/phone leak incl. minors (`:60,132`); eager-loads unused achievement rows | HIGH |
| M3.3 | Coach discovery | P0 | S.3 | coach directory | `DirectoryController::coaches` | `coach_profiles` | DONE | Pagination + filters | `avgRating ?? 0` render — no rating source | LOW |
| M3.4 | Academy discovery | P0 | S.3, D.3 | academy directory | `DirectoryController::academies` | `academies` | DONE | Photos/chips/facilities | Fee filters compare numerics against string columns (`:17-18,43-44`) | MEDIUM |
| M3.5 | Event/trial discovery | P0 | S.3, D.6 | trials/tournaments lists | `TrialController`, `TournamentController` | `trials`, `tournaments` | DONE | Published-only filters, date badges | — | — |
| M3.6 | Universal search | P0 | S.5 | `universal_search_screen.dart:154-167`, `search_provider.dart:251,292-304` | `SearchController.php:146-149` | various | PARTIAL | Cross-entity groups + recent searches | **Pagination broken end-to-end** (fixed `limit()->get()`, client reads non-existent `meta.current_page` → loadMore dead); errors render as "No results"; legacy 410'd tables still queried; `facility` param ignored | MEDIUM |
| M3.7 | Filters & sort | P0 | S.4 | `search_filter_sheet` | `SearchController.php:31`, `DirectoryController::sortBy:77-79` | — | PARTIAL | Sport/state/city/age/level/filters work | `sort=relevance/distance/rating` accepted then silently ignored (no-ops) | MEDIUM |
| M3.8 | Distance / near me | P0 | S.3 | none | none | no lat/lng columns | NOT STARTED | No geo anywhere (no geolocator dep, no columns, no logic) | Feature absent; `sort=distance` silent no-op | HIGH |
| M3.9 | Saved / bookmarks | P0 | S.20 | `saved_provider.dart:57-94` | `SavedItemController.php` | `saved_items` (unique idx) | PARTIAL | Server solid: 10 types, dedupe 409, unique index | Client loads page 1 only → items beyond 20 invisible; `isSaved()` wrong beyond 20 | MEDIUM |
| M3.10 | Venue discovery | P1 | D.13 | venue screens | `SportsVenueController.php` | `sports_venues` | DONE | — | — | — |
| M3.11 | Recommendations | P1 | AT.1 | home rails | `HomeController` | — | PARTIAL | "first 6 athletes" wearing a Recommended label — not rule-based | LOW |
| M3.12 | Map view | P2 | D.16 | — | — | — | OUT OF SCOPE | — | — |

## M4 — Events, trials & registrations

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M4.1 | Create/edit event or trial | P0 | OR.5 | `post_trial_screen.dart`, `post_tournament_screen.dart`, drafts saved | `ProviderTrialController.php:64`, `ProviderTournamentController.php:56`, `EventController.php` | `trials`, `tournaments` | DONE | Role-gated, draft/publish, expiry armed on publish | Tournaments have no `required_documents`; editing event date doesn't reschedule pending expiry event | MEDIUM |
| M4.2 | Event detail | P0 | D.6 | `trial_detail`, `tournament_detail` | `TrialController::show` (published filter), `Tournament.php:103-144` | — | DONE | Slot math consistent (filled = approved; spots = Σ category capacity) | **Draft leak**: unified `EventController::show()` L93-106 has no status filter — any authed user can read draft trials | MEDIUM |
| M4.3 | Event registration | P0 | D.7, D.8 | `trial_registration_screen.dart`, `tournament_registration_screen.dart` | `RegistrationController::storeTrial L21-94`, `storeTournament L298-370` | `trial_registrations`, `tournament_registrations` | PARTIAL | Duplicate guard via DB unique indexes; consent shown | **CAPACITY NEVER ENFORCED** — no vacancy check, no lockForUpdate, no category-capacity check anywhere in the store paths (BLOCKER); trial form DOB collected but never sent; required docs not enforced client-side; team fields silently dropped by validation; `payment_status` client-supplied (self-declare "paid"); race on duplicate yields 500 not 409 | **BLOCKER** |
| M4.4 | Manage registrations | P0 | OR.7, OR.8 | `registration_management_screen.dart:715-743,868-960` | `EventRegistrationController::bulk L190-234`, approve/reject | registration tables | PARTIAL | Per-row approve/reject wired w/ ownership checks + notifications | **Bulk actions API-only** (checkboxes feed nothing in UI); API bulk type-pinning broken (Symfony QUERY_STRING overwrite); bulk reject w/o reason fails all rows | HIGH |
| M4.5 | Export registrant list | P0 | OR.7 | `registration_management_screen.dart:170-197` (share sheet) | `EventRegistrationController::export L237-265` | — | PARTIAL | Ownership-checked, real CSV | Columns thin (id/athlete/status/payment/created_at); no docs/category/contact; selection ignored (exports all) | MEDIUM |
| M4.6 | Registration status notifications | P0 | AT.9, S.16 | `push_notification_service.dart:69-158` | `RegistrationController` notify calls, `NotificationService.php:14-19` | `notifications` | DONE | In-app + FCM + action_url deep links end-to-end | Typed `status_update` misses HARD_OVERRIDE_TYPES → suppressible by prefs; deep-link targets `/registrations/{trials\|tournaments}/{id}` not routed in app → 404 on tap | MEDIUM |
| M4.7 | Auto-expiry | P0 | AD.10 | (admin Blade `expiry.blade.php`) | `SweepExpiredContentJob` hourly (`routes/console.php:19`), `ExpiryService` | `expiry_rules`, `expiry_events` | DONE | Rule-driven, idempotent, admin override/restore | Owners never notified on expiry | LOW |
| M4.8 | Event schedule & gallery | P1 | OR.9, OR.10 | `/event-gallery` exists; **no OR.9 route at all** | none for schedule | — | PARTIAL | Gallery works | Schedule editor not started | — |
| M4.9 | Results publishing | P1 | OR.11 | `results_publishing_screen.dart` | `ResultsController.php` (store/publish/unpublish) | `tournament_results` | PARTIAL | API + screen exist | Thin validation; low usage evidence | — |
| M4.10 | Event analytics | P1 | OR.12 | `organizer_analytics_screen` | `OrganizerAnalyticsController.php` (role:organizer,admin) | `analytics_events` | PARTIAL | API + screen exist | — | — |
| M4.11 | Announcements | P1 | OR.14 | `/post-announcement` route exists | **no backend endpoint** | — | UI-ONLY | — | — |
| M4.12 | Calendar view | P1 | S.3 | `table_calendar` dep present | — | — | UNVERIFIED | dep exists; no traced integration | — |
| M4.13/14 | Payments / promote | P2 | — | — | — | — | OUT OF SCOPE | — | — |

## M5 — Opportunities

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M5.1 | Opportunity listing & detail | P0 | D.9 | `opportunity_list_screen.dart` | `OpportunityController::index/show` | `opportunities` | DONE | Unified type model (scholarship/sponsorship/tryout/camp); legacy 410 routes clean | No pagination server-side (caps 50) | LOW |
| M5.2 | Create opportunity | P0 | AC.9, SC.12 | `post_opportunity_screen.dart` | `OpportunityController::store`, `resolveProvider() :340-351` | `opportunities` | DONE | Role-gated (academy/organizer/coach/scout); Flutter excludes organizer deliberately | Deadline field is free text (no date picker); missing sport/age_group/docs fields | MEDIUM |
| M5.3 | Apply / submit pitch | P0 | D.10 | apply screen (no doc upload UI) | `OpportunityController::apply :204-208,373-385` | `opportunity_applications` | PARTIAL | Pitch + profile snapshot auto-attached; owner notified; dup 409 | **Document upload not wired in UI** (API accepts `document_media_ids`); **no unique index** on applications (race dup) | HIGH |
| M5.4 | My Opportunities | P0 | AT.8 | `my_opportunities_screen.dart` | `OpportunityController::mine` | — | DONE | Applied/Saved/Created tabs live | Saved tab filters through `Opportunity::open()` → saved-but-closed items vanish | LOW |
| M5.5 | Applicant review | P1 | AC.9 | (no dedicated screen traced) | `applications` + `review :355-358` (ownership-checked) | `opportunity_applications` | PARTIAL | API complete | No provider review UI found | — |
| M5.6 | Scouting opportunities hub | P0 | SC.11 | `/opportunities` w/ type filter chips | same as M5.1 | — | PARTIAL | Reachable and functional | Chip-filter approximation of the Trials/Scholarships/Camps tabs shape | LOW |

## M6 — Programs, facilities & academy operations

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M6.1 | Training programs | P0 | CO.4, CO.5, D.11 | `my_programs_screen.dart`, `post_program_screen.dart` | `ProgramController.php` (owner morph coach/academy) | `programs` | DONE | CRUD + Active/Drafts/Past tabs + draft saving | — | — |
| M6.2 | Program/listing enquiry | P0 | D.12 | `enquire_screen.dart` | `EnquiryController::store :12-48` (+ `ProgramController::enquire`) | `enquiries`, `enquiry_messages` | PARTIAL | Enquiry creates thread + messages; reply flow both ways | **Owner never notified of a new enquiry** (`store` sends nothing; only `reply` notifies, and only the athlete `:103-135`) → P0 flow stalls silently | HIGH |
| M6.3 | Facilities | P0 | AC.7, AC.8, D.13 | `facilities` screens | `FacilityController.php` (role:academy,organizer) | `facilities` | DONE | Tenant-scoped CRUD | Type enum missing classroom/changing-rooms | LOW |
| M6.4 | Our Athletes | P1 | AC.5, AC.10 | `invite_athlete_screen.dart:19-33` | none | none | UI-ONLY | Hard-coded candidate list, zero API calls, no backend table/routes | — |
| M6.5/6 | Staff / collaborations | P2 | — | — | — | — | OUT OF SCOPE | — | — |

## M7 — Social: feed, follow, connections & messaging

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M7.1 | Create post | P0 | S.9 | `create_post_screen.dart` | `PostController::store :156-158` | `posts` | PARTIAL | Text/photo + hashtags + audience work | **Video rejected server-side** ("Video posts are no longer supported" 422) vs spec text/photo/video; edit/delete own post API-only — `updatePost`/`deletePost` (`posts_provider.dart:256-276`) called by zero screens; no edit/delete menu in post detail | HIGH |
| M7.2 | Feed | P0 | S.1 | `community_feed` / home feed | `PostController::index :23-25,59,111` | `posts` | DONE | Tabs, pagination + dedup, blocked-user filtering, batched likes/media maps (no N+1) | — | — |
| M7.3 | Post interactions | P0 | S.27 | `post_detail_screen.dart`, `PostCardV3` | like/comment endpoints | `post_likes`, `post_comments` | PARTIAL | Like + comment wired with counts | **Save never wired** (bookmark icon just navigates, `home_kit.dart:788,1391`; no save in post detail) | MEDIUM |
| M7.4 | Follow / unfollow | P0 | S.3, D.x | follow buttons | `FollowController.php` | `follows` (unique) | DONE | Unique constraint, status endpoint, FCM on follow | — | — |
| M7.5 | Connect (mutual) | P0 | S.19 | `my_connections_screen.dart`, `connection_requests` | `ConnectionController.php:45-148,217-249` | `connections` (unique) | DONE | pending→accepted state machine; 3-req/day anti-harassment cap; mutual auto-accept; accept creates conversation under cache lock | `who_can_connect` setting unenforced (see M2.9) | — |
| M7.6 | 1-to-1 messaging | P0 | S.17, S.18 | `chat_list_screen.dart`, `chat_screen.dart`, `chat_provider.dart` | `ConversationController.php` (peerChatGate :277-319, minorChatGate :239-264) | `conversations`, `conversation_participants`, `messages` | PARTIAL | Threads, unread counts, mark-read, block+minor gates at create | **Cold DMs allowed by default** — `who_can_message=everyone` (adult default) passes with no relationship check (`:318`), violating §6 rule 3; no block/report in chat UI; minor gate not re-checked at send; message icon no unread badge; list stale unless open; 4s polling only in-thread | HIGH |
| M7.7 | Share post | P1 | S.30 | share_plus | — | — | PARTIAL | OS share sheet exists | Link targets 404 (no web routes / deep links) | — |
| M7.8 | Mentions & hashtags | P1 | S.16 | — | hashtags stored only | — | NOT STARTED | No mention parsing/notifications | — |
| M7.9 | Chat media attachments | P1 | S.18 | — | — | — | NOT STARTED | — | — |
| M7.10 | Community: Network & Events | P1 | S.12 | `community_screen.dart` (4 tabs) | `/groups`, suggestions | `groups`, `group_members` | DONE | Real tabs w/ working follow + states | — | — |
| M7.11–13 | Groups full / polls / live | P2 | S.13/14, S.8, CO.8 | groups screens exist (P2 scope) | GroupController + tables exist | `groups` | OUT OF SCOPE | **Scope creep note:** P2 groups endpoints/tables/screens are built while P0 M12.6/M3.8 are not | — |

## M8 — Leaderboard

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M8.1 | Athlete leaderboard | P0 | S.6, AT.1 | `leaderboard_screen.dart` | `LeaderboardController.php:19-56`, `LeaderboardService.php:81-90`, `AthleteLeaderboardController.php` | `leaderboard_scores`, `leaderboard_seasons` | PARTIAL | Podium + ranks 4-10 + filters + correct minor masking (`:74-110`) | **"Verified achievements only" is dead code** — `achievements` table has no verified column (`2026_08_18_000001`, `2026_10_14_000001`); self-declared points uncapped (+50/POST, trivial inflation); `/me/leaderboard` has no filter at all + matches winners by free-text name + loads whole table per request; recalc never on registration approval | HIGH |
| M8.2 | Leaderboard strip on Home | P0 | S.1 | `home_kit.dart:413` | `LeaderboardController::strip :59-68` | — | DONE | Top-5 strip on athlete/coach/academy homes | Sport chips decorative (all push same route) | LOW |
| M8.3 | Other leaderboards | P1 | S.6 | — | explicit P1 comment `LeaderboardController.php:17` | — | NOT STARTED | — | — |
| M8.4 | Points rules & admin config | P1 | S.7, AD.11 | `leaderboard_info_screen.dart:55` (static text), admin Blade `leaderboard.blade.php` + API | `AdminLeaderboardConfigController.php` (weights 0-500, season reset, rebuild) | `platform_settings` | PARTIAL | Admin API + Blade done | Mobile rules page hard-coded, ignores tuned weights | — |

## M9 — Notifications

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M9.1 | In-app notification feed | P0 | S.16 | `notifications_screen.dart`, `notifications_provider.dart:108-142` | `NotificationController.php:16-74` (ownership checks :62,:78) | `notifications` | DONE | Tabs, unread, mark-one/all, delete; model list implementation | Tabs fixed, not role-adapted | LOW |
| M9.2 | Push notifications | P0 | S.16 | `push_notification_service.dart:139-158,262-284` (all 3 app states) | `NotificationService.php` (category prefs gate, chunked queue, FCM v1, push_status) | `device_tokens`, `user_device_tokens` | PARTIAL | Full FCM lifecycle incl. foreground banner, token register/refresh/remove, deep-link action_url plumbing | **6 registration notifications typed `status_update` → filed under People + suppressible (hard-override types `registration_approved/rejected` never used anywhere)**; **enquiry creation sends nothing to owner**; several action_urls 404 in-app (`/account-status`, `/my-reports`, `/registrations/{type}/{id}`) | HIGH |
| M9.3 | Deadline / nearby reminders | P1 | S.16 | — | `ReminderService`, `SendDueRemindersJob` (15-min) | `reminder_subscriptions` | BROKEN | Job + service correct in isolation | **`ReminderService::arm()` has zero call sites repo-wide** — no subscription ever created, job returns 0 forever; no "trial near you" | MEDIUM |
| M9.4 | Admin broadcast | P1 | AD.12 | admin Blade `notifications.blade.php` + Flutter admin | `AdminUserController::broadcast/broadcastTargeted`, `BroadcastTargeting.php` | `notifications` | PARTIAL | Broadcast + targeted + delivery stats exist | — | — |
| M9.5 | Email/SMS | P2 | — | — | email fallback exists in NotificationService | — | OUT OF SCOPE | — | — |

## M10 — Talent scouting

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M10.1 | Scout dashboard | P0 | SC.2 | `talent_scout_dashboard_screen.dart:172` | `ScoutDashboardController.php:28-35` | — | PARTIAL | Endpoint + screen live | `top_talents` uses raw `user->name` — **no minor anonymization**; `upcomingTrials` has no date/status filter (past trials shown as upcoming) | MEDIUM |
| M10.2 | Discover talents | P0 | SC.4 | scout discovery screen | `AthleteDiscoveryController.php` | `athlete_profiles` | PARTIAL | sport(multi)/age/city/level/achievements filters | Spec's "position" filter missing; PII leak (M3.2) | MEDIUM |
| M10.3 | Shortlist | P0 | SC.5, SC.6 | `scout_shortlist` screens | `ScoutShortlistController.php` (L15/41/86/105 owner-scoped) | `scout_shortlists` | DONE | Statuses/notes/tags validated; **no IDOR** | Athlete notified w/ scout's real name on shortlist-add (rule-10 tension) | LOW |
| M10.4 | Add observation | P0 | SC.10 | observation screen | `ObservationController.php` (owner-scoped) | `observations` | DONE | Rating/note validation, throttled | `media_id` not ownership-checked | LOW |
| M10.5 | Contact athlete / parent | P0 | SC.13 | `scout_connect` screens | `AthleteContactController.php:39-49`, `ScoutConnectionController::store :34-77` | `scout_connections` | PARTIAL | Two-way connect flow + chat gate post-acceptance | **Guardian-routing is fictitious** — "guardian review" notification goes to the *minor's own user_id* (no guardian account exists; consent stores name/phone/email strings only); ScoutConnection store has no minor handling at all | HIGH |
| M10.6 | Talent report | P1 | SC.8, SC.9 | `talent_report` screen | none | none | UI-ONLY | Local-state form, zero API calls | — |
| M10.7 | Compare talents | P1 | SC.7 | compare screen | — | — | UI-ONLY | Router-extra objects, falls back to `_sample` demo data | — |
| M10.8 | Top performers shortcut | P1 | S.6 | dashboard card | — | — | PARTIAL | Links to leaderboard | Labeled "This Week", board is season; no prefilter | — |

## M11 — Safety, moderation & admin

| ID | Feature | Pri | Screens | Mobile/Admin | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M11.1 | Report user/post/listing | P0 | S.26 | report sheet only in `detail_page_template.dart:363` (4 listing types) | `ReportController.php:22` (13 types incl. user/post) | `listing_reports` | PARTIAL | API accepts all types; admin queue shows reports | **No report button on any post or any profile** (rule 9 unmet from app); `reportable_id` no exists-validation; no dedupe/rate limit | HIGH |
| M11.2 | Block user | P0 | S.23 | `blockUser()` (`follow_block_provider.dart:57`) **zero callers**; Safety Centre = unblock only | `BlockController.php` (removes follows+connections; enforced chat :77-79/:146-150, feed :23,111, follow) | `blocks` (unique) | PARTIAL | API complete | **No block button anywhere in the app UI** → manage-list can only ever be empty; **no Block checks in discovery/profile/search** → blocked users fully visible | HIGH |
| M11.3 | Moderation queue & actions | P0 | AD.7, AD.8 | Blade `moderation.blade.php` (approve/remove only) + Flutter admin | `AdminModerationController.php:141` | `listing_reports`, content tables | BROKEN | Approve/warn/suspend work on listings/users w/ notifications + audit logs; reporter outcomes on all 4 API actions (:283-297) | **`remove` on post/facility reports 500s** (sets nonexistent `status` column; not fillable) → report stuck, content stays live; Blade remove = hard delete, **no notifications**; Blade "resolve" closes report leaving content live; no Warn/Suspend buttons in Blade detail; no repeat-offender tracking | HIGH |
| M11.4 | Verification queue | P0 | AD.4 | Blade + Flutter admin | `VerificationController::queue/approve/reject` | `verification_requests` | DONE | Badge column per type, reject requires reason, hard-override notifications, double-review guard | — | — |
| M11.5 | User management | P0 | AD.3 | Blade + Flutter admin | `AdminUserController.php:72-79`, `AuthController.php:169-171` | `users` | PARTIAL | Search/suspend/approve/reject; suspended blocked at login | **No ban** (wireframe wants Suspend+Ban); **suspend doesn't delete tokens, no status middleware → suspended users keep live sessions**; hard delete only; **`/admin/users` serializes full User model — `google2fa_secret` leaks** (`User.php:20` hidden only password/remember_token) | HIGH |
| M11.6 | Content manager | P0 | AD.5, AD.6 | Blade (7 types), API (11 types) | `AdminContentController.php` (+ `$request->all()` fallback :183-186) | content tables | PARTIAL | Full CRUD incl. posts/programs/facilities/opportunities | Post/Program/Facility/Opportunity lack `Auditable` trait → those admin edits unaudited | MEDIUM |
| M11.7 | Master data | P0 | AD.9 | Blade + Flutter admin | `AdminCategoryController.php` | `sports`, `cities`, `age_groups`, `positions` | DONE | Full CRUD both surfaces; seeders registered (`MasterDataSeeder`, `PositionSeeder` via `AllSeeder.php:31-32`) | Positions API-only in panel (no tab) | LOW |
| M11.8 | Expiry rules | P0 | AD.10 | Blade `expiry.blade.php:47-63` real; **Flutter `admin_expiry_rules_screen.dart:34-39` hard-coded mock** | `AdminExpiryController.php:28-53`, `ExpiryService` | `expiry_rules` | PARTIAL | Blade UI ↔ ExpiryRule ↔ hourly sweep chain works | **API `updateRules` writes nonexistent columns (`duration_days`/`action`) → 500**; API override/restore set `status` instead of `listing_status`; rule scope covers only trial/tournament/sponsorship/scholarship | MEDIUM |
| M11.9 | Admin dashboard + 2FA | P0 | AD.1, AD.2 | Blade login (`@csrf`, throttled 10/min, session regen), Flutter admin | `AdminAuthController.php`, `AuthenticateAdminPanel.php:29`, `EnsureAdmin2FAVerified.php:16` | `admin_profiles`, `users.google2fa_*` | PARTIAL | 2FA flow verified end-to-end: API token can't hit `/admin/*` until TOTP (12h window); KPI tiles + 7-day chart | **Admin API login+verify-2fa unthrottled** (`routes/api.php:640-645`); TOTP secret plaintext + duplicated; **seeded TOTP secret `JBSWY3DPEHPK3PXP` committed** (`AdminProfileSeeder.php:19`); `ADMIN_2FA_ENFORCE=false` accepts any 6 digits on both surfaces; dashboard lacks pending-verifications tile + by-role breakdown (wireframe AD.2) | HIGH |

## M12 — Account, settings & platform

| ID | Feature | Pri | Screens | Mobile | Backend | DB | Status | Evidence | Gaps | Sev |
|---|---|---|---|---|---|---|---|---|---|---|
| M12.1 | Settings & privacy | P0 | S.22 | `settings_screen.dart` | `SettingsController.php`, `PrivacyController.php` | `users.settings` | DONE | Visibility, messaging perms, notification toggles, password change | Password change doesn't invalidate other sessions; `who_can_connect` unenforced (M2.9) | LOW |
| M12.2 | Delete account | P0 | S.22 | `settings_screen.dart:509-541` | `SettingsController::destroy` (FK cascades) | `users` | PARTIAL | In-app with confirm; hard delete cascades profiles/social/consents/tokens | **Fails for Google-only accounts** (password Hash::check on null → permanent 401); media files not purged from disk; Sanctum token rows orphan | HIGH |
| M12.3 | Help, About, legal | P0 | S.24, S.25 | `help_support_screen`, `legal_screen` | static content | — | DONE | Screens + routes live; PRIVACY_POLICY.md exists in repo | — | — |
| M12.4 | Logout | P0 | S.29 | `more_screen.dart:60,71-81` | `AuthController.php:325` (token revoke) | — | PARTIAL | Confirmation dialog + server revoke + FCM unregister + storage clear | Settings-screen logout skips confirmation dialog | MEDIUM |
| M12.5 | Empty/loading/error/offline states | P0 | all | `sportx_cards.dart:693` EmptyState, `skeleton.dart` (20+ variants), retry buttons | — | — | PARTIAL | Empty/loading/error broadly present and used | **No offline detection anywhere** (no connectivity_plus); search errors render as "No results" | MEDIUM |
| M12.6 | Product analytics & crash reporting | P0 | — | `logAnalyticsEvent()` (`notification_prefs_provider.dart:46-57`) — **zero call sites**; Sentry removed (`pubspec.yaml:36`) | `AnalyticsController.php:14-32` (FUNNEL endpoint live) | `analytics_events` | NOT STARTED | Backend funnel endpoint exists and is unused; no crash reporting at all | HIGH |
| M12.7 | Deep links | P1 | S.30 | share_plus URLs | — | — | UI-ONLY | Share sheet emits URLs | No app-links/scheme in AndroidManifest (:26-29) or iOS (CHANGE_ME placeholder); URLs 404 (no web routes) | MEDIUM |

## Cross-cutting scope-creep note (P2 built while P0 missing)

Groups (P2): `GroupController.php`, `groups`/`group_members` tables, `/groups` routes, and Flutter `community_screen.dart` Groups tab are all built and functional, while P0 features M12.6 (analytics), M3.8 (near-me), M11.3 (working moderation) are not. Sponsor legacy role: `/onboarding/sponsor` route, `role:sponsor` middleware references and a `SponsorProfile` model still exist despite the role being removed from MVP (kept working via 410 Gone controllers).
