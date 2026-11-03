# 06 — Backend Review (API inventory, data model, jobs, ops)

Full security evidence: `_drafts/04b_backend_security.md`. Route source: `sportx-api/routes/api.php` (646 lines, 365 routes) + `routes/web.php` (Blade panel) + `routes/console.php` (jobs).

## 1. Endpoint inventory (by area → feature IDs)

| Area | Endpoints (method/path summary) | Auth / role | Features |
|---|---|---|---|
| Health | GET `/health`, `/system/health` | public | ops |
| Auth | POST register, verify-email, login, otp-login/request+verify (5-10/min), forgot/reset-password, google, resend-verification; POST send/resend/verify-otp (20/min + per-destination caps); POST logout (sanctum); GET /auth/me | public + sanctum | M1.1, M1.7 |
| Guardian | POST consent/resend/verify-otp (5-10/min); GET/PUT /me/guardian-controls; DELETE guardian-consent | sanctum | M1.4 ⚠️ PUT editable by minor |
| Verification | POST/GET /me/verification (5/min) | sanctum | M1.6 |
| Completion | GET /me/completion-checklist | sanctum | M1.5 |
| Meta | GET sports/cities/age-groups/positions/facilities/trending-searches | public | M11.7, M3.7 |
| Onboarding | POST onboarding/{athlete,coach,academy,organizer,sponsor,talent-scout,scout}; GET schema | sanctum | M1.3 (sponsor = legacy) |
| Directories | GET academies/coaches(+/{id}), trials, tournaments, sports-venues | **public** | M3.2–M3.5, M3.10 ⚠️ no visibility enforcement |
| Search | GET /search; GET/POST /me/recent-searches | public / sanctum | M3.6, M3.7 ⚠️ pagination broken |
| Home/Explore | GET /me/home, /explore | mixed | M3.1 (explore unused by app) |
| Media | GET /me/media(+quota); POST /media/upload; DELETE /media/{id}; PUT reorder; **GET /media/download/{id} (no auth)**; GET signed-url | sanctum (mostly) | M2.4, M2.3 ⚠️ public disk |
| Saved | GET/POST/DELETE /me/saved | sanctum | M3.9 |
| Reports | POST /reports (20/min); GET /me/reports | sanctum | M11.1 |
| Profiles | GET/PUT /me/profile(+sports,+images); coach/academy/organizer profile CRUD (role middleware); GET /organizers/{id} public | sanctum | M2.1–M2.7 ⚠️ public card leaks fields |
| Team | CRUD /me/organizer/team | role:organizer | M2.7 (P2-adjacent) |
| Programs | GET /programs(+{id}); GET/POST/PUT /me/programs; POST /programs/{id}/enquire (role:athlete) | mixed | M6.1, M6.2 |
| Facilities | CRUD /me/facilities (role:academy,organizer) | sanctum | M6.3 |
| Enquiries | POST /enquiries (role:athlete); GET inbox/{id}; POST messages; PUT read | sanctum | M6.2 ⚠️ no notification on create |
| Discovery | GET /athletes (role:sponsor,talent_scout,athlete), /athletes/{id} | sanctum | M3.2, M10.2 ⚠️ PII leak |
| Scout | scout-profile CRUD; scout-shortlist CRUD; scout-connections (accept/reject/incoming); POST athletes/{athlete}/connect; GET /scouts (role:athlete); athlete-side requests | role:talent_scout / athlete | M10.3–M10.5 |
| Registrations | POST trials/{t}/register, tournaments/{t}/register (role:athlete); GET registrations + pending-requests; approve/reject; capacity GET/PUT; my-registrations; ics; payment PATCH | sanctum | M4.3 ⚠️ capacity unenforced, payment_status client-settable |
| Coaching enrollments | POST coaches/{c}/enroll (role:athlete); coach approve/reject | sanctum | M6.2-adjacent |
| Results | GET/POST tournaments/{t}/results; publish/unpublish | mixed | M4.9 |
| Provider listings | /me/trials, /me/tournaments, /me/events CRUD + publish/close; EventRegistrationController index/bulk/export/approve/reject/cancel | sanctum | M4.1, M4.4, M4.5 ⚠️ bulk type-pin bug; draft leak |
| Analytics | GET /me/organizer/analytics | role:organizer,admin | M4.10 |
| Opportunities | GET /opportunities(+{id}); POST/PUT /me/opportunities + publish/close; POST apply (role:athlete); GET applications; PATCH review | mixed | M5.1–M5.5 ⚠️ no unique index |
| Legacy 410 | /scholarships, /sponsorships, sponsor shortlists, /me/applications | — | clean cutover |
| Notifications | GET /me/notifications; markRead/read-all; delete; prefs GET/PUT; POST analytics/events; device-tokens register/unregister/test; **POST notifications/{id}/send-push (authed user-triggered send?)** | sanctum | M9.1, M9.2 ⚠️ types bug |
| Social links / privacy / achievements / settings / activity | /me/social-links, /me/privacy, /me/achievements CRUD, /me/settings(+password), /me/change-password, DELETE /me/account | sanctum | M2.11, M2.9, M2.3, M12.1, M12.2 |
| Conversations | GET/POST /me/conversations **and** POST /conversations; GET {id}; POST messages (120/min); read ×3 verbs | sanctum | M7.6 ⚠️ cold-DM path |
| Connections | GET /me/connections(+requests,status,count); POST /connections + /me/connections/request; accept; PATCH; DELETE ×2 | sanctum | M7.5 |
| Follows | POST/DELETE /follow/{type}/{id}; following/followers/status | sanctum | M7.4 |
| Blocks | GET/POST /blocks; DELETE /blocks/{user} | sanctum | M11.2 ⚠️ not enforced in discovery |
| Leaderboard | GET /leaderboard, /leaderboard/strip, /me/leaderboard | sanctum | M8.1, M8.2 ⚠️ integrity |
| Scout extras | GET/POST /observations; POST /athletes/{id}/contact; GET /scout/dashboard | sanctum | M10.4, M10.5, M10.1 |
| Posts/groups | GET /feed,/posts; POST /posts (30/min); GET/PATCH/DELETE {id}; like/unlike; comments; groups index/join/leave | sanctum | M7.1–M7.3, M7.11(P2) |
| **Admin API** | prefix /admin (auth+role:admin+admin.2fa): dashboard; verification queue; content CRUD; moderation queue/actions; expiry-rules+monitor+override/restore; categories ×4; settings; email-settings; users (+approve/reject/suspend/destroy); opportunities approve/reject; broadcast + targeted; leaderboard-config; audit-logs; registration analytics + admin overrides | admin | M11.3–M11.9, M4.7 |
| **Admin auth** | POST /admin/login, /verify-2fa, /logout, GET /me | sanctum | M11.9 ⚠️ unthrottled |

**Flags:** endpoint-without-feature: `/media/download/{id}` unauthenticated · `POST /me/notifications/{id}/send-push` exposed to any authed user (verify intent) · `/explore` unused · `/onboarding/sponsor` + `role:sponsor` legacy · groups stack (P2 built). Feature-without-endpoint: announcements (OR.14), schedule editor (OR.9), talent reports (SC.8), ratings/reviews (D.14/15), achievements-verification (needed by rule 8).

## 2. Data model gaps

| Gap | Impact | Evidence |
|---|---|---|
| No `is_verified`/`verification_status` on `achievements` | Rule 8 unenforceable; leaderboard gameable | `2026_08_18_000001`, `2026_10_14_000001` |
| No unique index on `opportunity_applications` | duplicate applications under race | `OpportunityController.php:204-208` app-check only |
| No lat/lng columns anywhere (academies, venues, profiles) | M3.8 impossible | migrations sweep |
| No `reviews`/`ratings` tables | M2.12 dead; rating sorts dead code | — |
| `posts` has no `status` column (and not fillable) | moderation remove 500s | `2026_08_11_000001:55-70`, `Post.php:13` |
| `expiry_rules` column drift (`duration_days`/`action` vs real `days_after`/`trigger_field`/`is_active`) | admin API 500s | `AdminExpiryController.php:28-53` vs migration |
| No `banned` status in `users.status` enum | M11.5 no ban | `2026_09_13_000001` adds only `pending` |
| No guardian *account* — consent stores name/phone/email strings | guardian mediation impossible; M10.5 fictitious | `guardian_consents` migration |
| Sanctum `personal_access_tokens` polymorphic (no FK) → orphan tokens on delete; `expiration => null` | suspended/deleted users keep access | `2026_08_05_080023`, `config/sanctum.php:53` |
| Fee fields are strings (`fee_structure`, `fee_range`) compared numerically | broken filters, full scans | `DirectoryController.php:17-18,43-44` |
| No soft deletes on `users` (hard delete in admin + self-service) | unrecoverable; audit gaps | `AdminUserController::destroy` |
| Audit coverage holes: Post/Program/Facility/Opportunity lack `Auditable`; verification decisions + expiry overrides unaudited | compliance | `_drafts/03f` M11.6/M11.10 |

**Solid constraints found:** unique indexes on follows/connections/blocks/saved_items/trial_registrations/tournament_registrations/conversation_participants; FK cascades on guardian_consents and profile tables; master-data tables seeded (11 sports, cities, age groups, positions).

## 3. Jobs & schedulers (routes/console.php)

| Job | Schedule | Verdict |
|---|---|---|
| SweepExpiredContentJob | hourly | ✅ works, idempotent; ⚠️ no owner notification, no reschedule on edit |
| SendDueRemindersJob | 15 min | ❌ dead code — `ReminderService::arm()` never called, nothing ever subscribed |
| PurgeExpiredOtpsJob | daily 02:00 | ✅ |
| PruneOldMessagesJob (90-day chat purge) | daily 03:00 | ✅ exists (privacy-positive) |
| PruneStaleDeviceTokensJob / PruneNotificationRowsJob | daily | ✅ |
| RecalculateLeaderboardJob | nightly 04:00 | ✅ runs; rebuild itself inherits the no-verified-filter flaw; recalc never fires on registration approval |
| mail:probe, notifications:monitor | hourly | ✅ ops monitoring exists |

Queue: `database` driver; composer dev script runs `queue:listen` — **Horizon is installed but NOT mounted** (provider unregistered) so production worker supervision is undefined.

## 4. Ops & environments

- **Config reality:** `.env`: APP_ENV=local, APP_DEBUG=true, APP_URL=ngrok tunnel; MySQL `sportx_dev` on 127.0.0.1 root/password (documented in committed CREDENTIALS.md). No production environment exists in the repo.
- **No CI/CD** (no `.github/`, no pipeline files anywhere).
- **Backups:** none configured (no package, no cron, no docs).
- **Error monitoring:** Sentry SDK wired (`bootstrap/app.php:10`) but disabled in env; mobile crash reporting removed.
- **Health check:** GET /api/v1/health + /system/health (DB ping) — present.
- **Migrations/seeders:** 60+ migrations, comprehensive seeders incl. master data and test users (`AllSeeder`). ⚠️ `AdminProfileSeeder.php:19` seeds a committed TOTP secret with pre-verified 2FA — must never run outside dev.
- **Rate limiting:** only per-route throttles on auth/OTP/posts/chat; no global limiter, no `RateLimiter::for` definitions; no TrustProxies configured.
- **CORS:** defaults `*` when `CORS_ALLOWED_ORIGINS` unset (`config/cors.php:20`).
- **HTTPS:** no forceScheme/HSTS/secure-cookie hardening found; `usesCleartextTraffic="true"` on Android.

## 5. What could not be run
Backend tests (`php artisan test`) and live endpoint probing were **not executed — PHP is not installed on this audit machine**. PHPUnit suite exists; its pass state and real IDOR probing remain UNVERIFIED (see 08_NEEDS_HUMAN_CONFIRMATION).
