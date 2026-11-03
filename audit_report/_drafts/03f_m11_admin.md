# 03f — M11 Safety, Moderation & Admin (end-to-end trace)

Scope: MVP_FEATURE_LIST.md M11.1–M11.9 (lines 210–222), section 6 rules 4 & 9, SCREEN_INVENTORY.md §10 AD.1–AD.12 (lines 230–241), 06_admin_wireframes.md (all screens).
Two admin surfaces exist and were both traced:
- **Blade panel** (`/panel/*`, session auth): `routes/web.php:10-103`, `AdminPanelController` (1,403 lines).
- **JSON API** (`/api/v1/admin/*`, Sanctum token auth): `routes/api.php:533-646`, consumed by the in-app Flutter admin screens (`sportx_app/lib/features/admin/**`).

---

## M11.1 — Report user / post / listing — **PARTIAL**

**Evidence**
- API: `sportx-api/app/Http/Controllers/ReportController.php:19-34` — `POST /reports` validates `reportable_type in:academy,coach_profile,trial,tournament,scholarship,sponsorship,sports_venue,athlete_profile,user,post,opportunity,program,facility` (line 22) + `reason in:fake,outdated,inappropriate,other` (line 24). Creates `ListingReport`. Route: `routes/api.php` (user section). My-reports list: `ReportController::index` lines 10-17.
- Queue: every pending report reaches both admin queues regardless of type — Blade `AdminPanelController::moderation()` (`AdminPanelController.php:290-319`, `ListingReport::query()`), API `AdminModerationController::queue` (`AdminModerationController.php:45-73`).
- Morph map covers all 13 types: `app/Providers/AppServiceProvider.php:54-80`.
- Mobile: report UI exists in exactly ONE place — `sportx_app/lib/shared/presentation/widgets/detail_page_template.dart:363-373` ("Report this listing"), which pushes `/report` (`core/router.dart:600-608`) → `report_screen.dart:51-56` POSTs `/reports`.
- Only 4 detail screens pass a `savedType` and therefore get the report button: `academy_detail_screen.dart:72` ('academy'), `sports_venue_detail_screen.dart:50` ('sports_venue'), `tournament_detail_screen.dart:137` ('tournament'), `trial_detail_screen.dart:53` ('trial').
- `sportx_app/lib/shared/providers/report_provider.dart:9-18` (a second report client) has **zero callers** except provider-reset in `core/session_scope.dart:134`.

**Gaps**
- Rule 9 says "every post, listing and profile can be reported". Mobile reality: **no report button on posts** (zero occurrences of "report" in `community_screen.dart`, `post_detail_screen.dart`), **no report on any user/coach/athlete/sponsor profile** (zero in `view_profile_screen.dart`), no report on opportunities/scholarships/programs/facilities. Posts and users are reportable at the API but unreachable from the app.
- `reportable_id` is `required|integer` with no `exists` validation — reports for deleted/nonexistent ids are accepted silently.
- No dedupe: the same user can spam the same target with unlimited pending reports (queue groups them for display, `AdminModerationController.php:59-62`, but nothing caps creation).

**Severity: HIGH** (P0 feature; the two highest-risk targets — posts and users — cannot be reported from the app).

## M11.2 — Block user — **PARTIAL** (backend DONE, mobile UI broken)

**Evidence (confirms prior trace)**
- API complete: `BlockController.php` — `store` (lines 21-45: firstOrCreate Block, deletes Follows both ways, deletes Connections both ways = kills the chat-unlock path), `destroy` (unblock), `index` (manage list).
- Server-side enforcement: feed + post detail + comments `PostController.php:23-24,111,290,338,352,379,396,417`; chat `ConversationController.php:77,106,147,182`; follow `FollowController.php:40`; connections `ConnectionController.php:39`.
- **NOT enforced** in discovery/search/directory: zero `Block::` references in `AthleteDiscoveryController.php`, `DirectoryController.php`, `ProfileController.php`, or any listing controller. A blocked user still appears in search/discovery and their listings are fully visible.
- Mobile: `blockUser()` at `sportx_app/lib/features/connections/presentation/providers/follow_block_provider.dart:57-67` has **zero callers** (verified by repo-wide grep: only `unblockUser` is called, in `safety_centre_screen.dart:59`). There is no Block button on any profile, post, or chat screen.
- The manage list exists: Safety Centre (`safety_centre_screen.dart:16-75`) lists blocked users + unblock — but can only ever be empty because nothing can create a block.
- Safety Centre text at line 40 even promises "Blocking hides content both ways and disables chat" — a promise the user can never exercise.

**Severity: HIGH** (P0 safety feature; the write path is dead code).

## M11.3 — Moderation queue & actions — **BROKEN** (partial per action, per surface)

**Evidence**

API surface (`AdminModerationController.php`, mounted under `auth:sanctum + role:admin + admin.2fa`, `routes/api.php:535`):

| Action | What it does | Works? |
|---|---|---|
| approve (93-121) | marks all pending reports for target `approved`; notifies reporter only | Yes |
| remove (123-160) | line 141: `$item->update(['status' => 'removed'])` | **BROKEN for posts and facilities** — `posts` table has no `status` column (`migrations/2026_08_11_000001_create_social_tables.php:55-70`) and `status` is not in `Post::$fillable` (`app/Models/Post.php:13`); same for facilities (`AdminContentController.php:39` comment: "facilities + posts have no status column"). The update throws a QueryException → HTTP 500, and the code after it (marking reports resolved, notifying reporter, audit) never runs. Works for listings/users that do have `status`. |
| warn (162-202) | fires `ListingWarned` event → `NotifyOwnerOnListingWarned` (registered `AppServiceProvider.php:83`); marks reports `warned`; notifies reporter | Yes |
| suspend (208-240) | sets owner `status='suspended'` (line 219), notifies owner (`account_action` hard override, lines 221-230) + reporter (line 231), audits (line 232). Best-effort owner resolution `ownerUserId()` (243-281) | Yes — **but does not revoke Sanctum tokens** and nothing checks `status` on authenticated requests, so a suspended user with a live token keeps full API access until token expiry/re-login (`AuthController.php:169-171` only blocks at login). |

- Reporter outcome notifications: yes for approve/remove/warn/suspend via `notifyReporter()` (283-297, `action_url => '/my-reports'`). Reported user is notified on remove/warn (events) and suspend; **not** on approve.
- Audit: every API moderation action writes `AuditLog` (`AdminModerationController.php:299-316`).
- **No repeat-offender tracking anywhere** (grep for strike/offense/violation finds nothing user-facing; the FCM "3-strike" is device tokens only).

Blade panel surface (`AdminPanelController.php`):
- `moderationAction` (321-340): `remove` **hard-deletes** the reportable (`$reportable->delete()`, line 329) — works for every type but is far more destructive than the API's soft status change, and the two surfaces disagree on semantics.
- `warn` is accepted by validation (line 323) but **no Warn button exists** in `moderation.blade.php` (only Approve + "Reject & Remove", lines 140-141); warn is reachable only from the separate Flags page (`flags.blade.php`, `flagAction` 466-482).
- Panel actions notify **nobody** — no reporter, no owner (contrast API). No suspend from the report view (wireframe AD.8 requires "[ Suspend user ]"). Suspend only via user detail (`user_detail.blade.php` status form).
- `reportAction` (436-454) "resolve" marks the report `approved` **without touching the content** — a cosmetic button that can close a report leaving the violating content live.

**Severity: HIGH** (remove on post reports 500s; panel/API semantics diverge; no suspend from moderation detail; no offender history).

## M11.4 — Verification queue — **DONE**

**Evidence**
- API: `VerificationController.php` — queue (112-134), approve (144-163: `approve($admin)` → sets badge column per entity type via `VerificationRequest::BADGE_COLUMNS` (`academies.verification_badge`, `coach_profiles.verification_badge`, organizer/sponsor `verification_status`), hard-override notification "Your verification was approved"), reject (169-190: `reason required|string|max:1000`, notification body = reason).
- Model: `VerificationRequest.php:29-35` badge columns; `setBadge()` line 129-143 forceFills the flag.
- Blade panel: `AdminPanelController::verificationQueue` (506-528) resolves proof documents (`proof_media_ids` → MediaItem) for review; `verificationApprove` (530-550) and `verificationReject` (552-575) mirror the API exactly including the same notifications; double-review guarded by `isPending()`.
- Mobile admin: `verification_queue_screen.dart` + `verification_request_docs_screen.dart` wired to `GET /admin/verification` (`admin_provider.dart:129`).
- Badge surfaces in profile/cards/search were verified under M2/M3 (rule 4 satisfied there).

**Gaps (minor)**: no audit-log entry for approve/reject (relies on the `VerificationRequest` model not using the `Auditable` trait — it is not in the trait-user list). Reject requires a reason (good, matches wireframe).

**Severity: LOW**

## M11.5 — User management — **PARTIAL**

**Evidence**
- API: `AdminUserController.php` (routes `api.php:613-618`) — index with role/status/q filters (17-44), show, `approve` (sets email_verified_at + active + notification, 56-62), `reject` (status='deleted', 65-71), `suspend` (74-79: status='suspended' + `account_action` notification), `destroy` (117-120: `User::findOrFail($id)->delete()` — **hard delete**, User model has no `SoftDeletes`, `app/Models/User.php:7-13`).
- Blade: `AdminPanelController::users` (170-189, search + role/status filters), `updateUserStatus` (198-218: activate/suspend/reject→deleted; admin accounts protected line 205-207), `destroyUser` (220-229: hard delete, admin-protected).
- Login as suspended user is blocked: `AuthController.php:169-171` ("Account is suspended. Contact support.", 403).
- Mobile admin: `manage_users_screen.dart` + `admin_provider.dart:875-877` suspend.

**Gaps**
- **No "ban" distinct from suspend/reject** — wireframe AD.3 wants Suspend **and** Ban. Closest is reject→`status='deleted'`, which is not a ban (no block on re-registration by email; nothing stops re-signup).
- `suspend()` does **not** delete/revoke Sanctum tokens (`AdminUserController.php:74-79`) and no middleware rejects `status != active` for already-authenticated requests → suspended users keep a working session until their token dies. Same gap in the panel path and in `AdminModerationController::suspend`.
- `destroy` = hard delete with cascading FK damage and no audit log entry of its own (User uses `Auditable`, so `delete` IS captured via the trait — see M11.10 — but the destroy endpoints have no confirm of consequences).
- `AdminUserController::show/index` return the full User model; `$hidden` is only `['password','remember_token']` (`User.php:20`) → **`google2fa_secret` and `admin_2fa_verified_at` are serialized to any 2FA-verified admin** (and `google2fa_secret` is also present on `UserSeeder`-created rows). Secret leak via API.

**Severity: HIGH** (suspended users keep access; no ban; TOTP secrets leakable through user list endpoints).

## M11.6 — Content manager — **PARTIAL**

**Evidence**
- API `AdminContentController.php:11-41`: picker supports **11 types** — academies, coaches, trials, tournaments, scholarships, sponsorships, sports_venues, opportunities, programs, facilities, posts — matching AD.5's list (posts included, line 22). Full CRUD (store 169-201, update 203-243, destroy 317-343) with owner-on-behalf injection (282-315) incl. auto-creating OrganizerProfile/SponsorProfile. Validation: uses `$model::rules()` when defined, otherwise **`$request->all()` accepted wholesale** (lines 183-186, 227-229 — "admin is trusted").
- Blade panel `AdminPanelController::contentModels()` (1153-1164): only **7 types** — academies, coaches, trials, tournaments, scholarships, sponsorships, sports-venues. **No posts, opportunities, programs, facilities** in the web panel. Full create/edit forms (`content_form.blade.php` via `contentCreate/Store/Edit/Update` 1020-1062), delete (`contentDestroy` 265-273), publish toggle (275-286).
- Mobile admin: `admin_content_picker_screen.dart`, `admin_content_list_screen.dart`, `admin_record_edit_screen.dart` on the API.

**Gaps**
- **No `AuditLog` write in `AdminContentController` at all** — but content models (Academy, CoachProfile, Trial, Tournament, Scholarship, Sponsorship, SportsVenue, User, Sport, City, AgeGroup, AthleteProfile…) use the `Auditable` trait (`app/Traits/Auditable.php:11-28` boots on created/updated/deleted), so CRUD on those IS auto-logged with who/old/new. **Post, Program, Facility, Opportunity models do not use the trait** (absent from the model list) → admin edits of posts/programs/facilities/opportunities are unaudited.
- Wireframe AD.5 status column mismatch is handled (`statusColumn` map, lines 29-41).
- `$request->all()` fallback + Eloquent fillable is mass-assignment-safe-ish but silent-drops unknown fields; combined with no per-field validation for 4 of 11 types.

**Severity: MEDIUM**

## M11.7 — Master data — **DONE**

**Evidence**
- API `AdminCategoryController.php`: full CRUD for sports (18-77), cities (79-…), age-groups, positions (`routes/api.php:573-592`). Destroy = soft (sets `is_active=false`, line 74) — sensible.
- Blade: `AdminPanelController::categories` (344-351) + store/update/toggle/destroy (353-417, 1123-1149) with unique/duplicate handling (`categoryStore` 366-375 composite city check; friendly SQL error translation 1362-1385). Note: panel has **no positions tab** (categoryModel 1179-1187: sports/cities/age-groups only) — positions API-only.
- Seeders: `MasterDataSeeder.php` (11 sports lines 15-35, cities, age_groups line 62), `PositionSeeder.php` (sport-scoped positions), registered via `AllSeeder.php:31-32` ← `DatabaseSeeder.php:29`.
- Models Sport/City/AgeGroup use `Auditable` → all master-data mutations logged.

**Gaps**: none material. (Panel positions editing missing — LOW.)

**Severity: LOW**

## M11.8 — Expiry rules — **PARTIAL** (panel path works; API/mobile path broken; scope narrower than wireframe)

**Evidence**
- Chain: `ExpiryService::onPublish` (`app/Services/ExpiryService.php:33-66`) reads `ExpiryRule` (`days_after`, `is_active`), computes `expires_at`, registers `ExpiryEvent`; `SweepExpiredContentJob` (hourly, `routes/console.php:19`) → `ExpiryService::sweep()` (72-89) sets listing `status='expired'`.
- Blade UI works: `expiry.blade.php:47-63` form posts `rules[*][id|days_after|trigger_field|is_active]` → `AdminPanelController::expiryRulesUpdate` (1100-1119) updates the real columns. Monitor + override/restore (1066-1098) with correct per-model status-column map in `republishContent` (1325-1346).
- Defaults seeded: `ExpiryRuleSeeder.php` (trial/tournament/sponsorship/scholarship).
- **API path broken**: `AdminExpiryController::updateRules` (`AdminExpiryController.php:28-53`) validates `rules.*.duration_days` and `rules.*.action` and calls `ExpiryRule::updateOrCreate([…], ['duration_days'=>…, 'action'=>…])` — **neither column exists** (`expiry_rules` schema: `content_type, trigger_field, days_after, is_active`, `migrations/2026_01_01_000016_create_expiry_reminder_tables.php:11-18`). Any PUT `/admin/expiry-rules` → QueryException 500. Also `override()`/`restore()` (88-142) do `$event->content->update(['status' => 'published'])` — wrong column for academies/coaches/sports_venues (`listing_status`) → same class of silent/500 failure the panel version explicitly fixes with a column map.
- **Mobile expiry screen is a mock**: `admin_expiry_rules_screen.dart:34-39` renders four hardcoded `_ExpiryRule` rows ("Events / Trials 90", "Opportunities 60"…) with no dio import and no API call — never persisted, values don't match the seeded rules.

**Gaps**: rule scope is only trial/tournament/sponsorship/scholarship (+opportunity in MAP) — no academy/coach/venue/program/facility expiry; wireframe AD.10's "Events: close 1 day after end date" matches trial/tournament defaults.

**Severity: MEDIUM** (admin-configurable expiry works from the web panel; the mobile/API config surface is broken or fake).

## M11.9 — Admin dashboard KPIs + 2FA login — **DONE (surface) / PARTIAL (KPI completeness)** with security holes

**Evidence — auth flow end-to-end**

Blade panel (session):
1. `login.blade.php:13-15` — POST form with `@csrf` → `AdminPanelController::login` (42-64), throttled `throttle:10,1` (`web.php:15`), checks `role==='admin'`, `Auth::login` + `session()->regenerate()` (60), always redirects to TOTP challenge (63).
2. `show2fa` (66-97): enrolls secret on first login (87-89), returns `twofa.blade.php`. `verify2fa` (99-118): `TotpService::verify` (window ±1, `TotpService.php:17`), regenerates session (113), sets `session('admin_2fa_ok')` (114) and `admin_2fa_verified_at` (115).
3. Gate: `AuthenticateAdminPanel` (`app/Http/Middleware/AuthenticateAdminPanel.php:29-32`) — requires `session('admin_2fa_ok')` unless `ADMIN_2FA_ENFORCE=false`; plus role check (23-27). Logout invalidates session (120-127).

JSON API (token):
1. `AdminAuthController::login` (`AdminAuthController.php:17-60`) issues a Sanctum token and **force-nulls `admin_2fa_verified_at`** (line 46) so a fresh token cannot touch admin APIs. **No throttle middleware on this route** (`routes/api.php:640-645` — the group at line 76 has no throttle and there is no global API limiter in `bootstrap/app.php`).
2. `verify2fa` (62-112): TOTP verify → sets `admin_2fa_verified_at=now()`.
3. Gate: `EnsureAdmin2FAVerified` (`app/Http/Middleware/EnsureAdmin2FAVerified.php:14-19`) — admin APIs pass only if `admin_2fa_verified_at` is < 12h old, else 403 `2FA_REQUIRED`. So a stolen password alone cannot reach admin APIs (token is issued but every `/admin/*` call 403s) — good. **However**: any Blade-panel 2FA success also unlocks the API for that user for 12h and vice-versa (shared column), and `ADMIN_2FA_ENFORCE=false` bypasses BOTH surfaces accepting any 6-digit code (`AdminAuthController.php:70-80`, `AuthenticateAdminPanel.php:29-30`). `.env` currently has `APP_ENV=local` and the flag is only `true` in `.env.example:85` — nothing pins it true in prod.

Security findings (build on prior trace):
- **BLOCKER/HIGH — seeded admin TOTP secret committed**: `AdminProfileSeeder.php:19` `const TOTP_SECRET = 'JBSWY3DPEHPK3PXP'` (stored on `google2fa_secret` line 40 and `admin_profiles.two_factor_secret`), documented in `TEST_CREDENTIALS.md:62` together with `admin@sportx.test`/`password`. If seeders ever run outside dev, 2FA is theater. Seeder also pre-sets `admin_2fa_verified_at = now()` (line 41-44) — 12h API access immediately after seeding.
- **HIGH — admin API login + verify-2fa unthrottled** (`routes/api.php:640-645`): online password brute-force and TOTP brute-force (6 digits, ±1 window ⇒ 3 valid codes per 30s) are not rate-limited. Panel equivalents are throttled 10/min.
- MEDIUM — TOTP secret stored **plaintext** in `users.google2fa_secret` (`migrations/2026_10_20_000002_add_admin_totp_secret.php:13`) AND duplicated plaintext in `admin_profiles.two_factor_secret`.
- MEDIUM — `google2fa_secret` not in `User::$hidden` → leaked in every `/admin/users` index/show response (see M11.5).

**KPIs**
- Blade dashboard (`AdminPanelController::dashboard` 131-166): active listings (published academies+coaches+trials+tournaments+sponsorships), flagged items (pending reports), new signups 30d, total users, sports/cities counts, pending users/trials/tournaments, 7-day signup chart, recent users, pending reports. **No "pending verifications" tile** (wireframe AD.2 top bar shows "Verif 38") and no "new users **by role**" breakdown on the dashboard (role distribution lives on the separate Analytics page, 588-589).
- API dashboard (`AdminDashboardController.php:22-67`): active_listings, flagged_items, pending_expirations, new_signups_30d, total_users, pending_approvals (verification + pending users), tournament registration stats. **No open-reports-by-reason, no active events KPI, no per-role signup tiles.**
- Audit trail viewer exists on both surfaces (`AdminAuditController::index/show`, `apiIndex/apiShow`; views `audit_logs.blade.php` — GET-only forms, no CSRF issue).

**Severity: HIGH** (aggregated across the auth holes above; functionality itself DONE).

## M11.10 — Audit trail completeness (cross-cutting)

- `Auditable` trait (`app/Traits/Auditable.php`) auto-logs create/update/delete with user id/name/role, old/new values, ip, user-agent, route — applied to User, Academy, CoachProfile, Trial, Tournament, Scholarship, Sponsorship, SportsVenue, AthleteProfile, Sport, City, AgeGroup, OrganizerProfile, SponsorProfile, TalentScoutProfile (grep of `use Auditable`).
- Explicit `AuditLog::create` in: `AdminModerationController::audit` (302), `AdminSettingsController` (43), `EmailSettingsController` (60).
- **Not audited**: `AdminContentController` mutations on Post/Program/Facility/Opportunity; verification approve/reject; category actions via panel (covered by trait for the 3 models) ; panel `expiryOverride`/`expiryRestore`/`expiryRulesUpdate` (ExpiryRule/ExpiryEvent don't use the trait); broadcast notifications; panel user status change IS covered (User uses trait). `audit_log_enabled` setting can silently disable the whole trail (`Auditable.php:36-39`) — a foot-gun for a compliance log.

---

## Summary table

| ID | Feature | Status | Severity |
|---|---|---|---|
| M11.1 | Report user/post/listing | PARTIAL (mobile UI covers only 4 listing types; no post/user report entry) | HIGH |
| M11.2 | Block user | PARTIAL (API done; `blockUser()` has zero callers; not enforced in discovery/search) | HIGH |
| M11.3 | Moderation queue & actions | BROKEN (remove() 500s on posts/facilities; panel hard-deletes; no panel warn/suspend; no owner notification from panel) | HIGH |
| M11.4 | Verification queue | DONE | LOW |
| M11.5 | User management | PARTIAL (no ban; suspend doesn't revoke tokens; google2fa_secret leaks in user list) | HIGH |
| M11.6 | Content manager | PARTIAL (API 11 types, panel 7; unaudited for 4 types; `$request->all()` fallback) | MEDIUM |
| M11.7 | Master data | DONE (panel lacks positions tab) | LOW |
| M11.8 | Expiry rules | PARTIAL (panel works; API updateRules/override broken — wrong columns; mobile screen is a hardcoded mock) | MEDIUM |
| M11.9 | Dashboard + 2FA | DONE surface / PARTIAL KPIs; auth holes HIGH (unthrottled API login, plaintext/committed TOTP secret, env escape hatch) | HIGH |
| M11.10 | Audit trail | PARTIAL (strong trait coverage; gaps for 4 content types, verification decisions, expiry admin actions; kill-switch setting) | MEDIUM |
