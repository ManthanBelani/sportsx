# SportX — App & Backend Performance / Scalability Plan

**Date:** 2026-10-21
**Scope:** `sportx_app` (Flutter 3 + Riverpod + Dio) and `sportx-api` (Laravel 11 + MySQL + Sanctum)
**Goal:** Make the stack fast and reliable enough to serve **all users** at scale — reduce latency, bandwidth, server load, and rebuild costs.
*(Note: this complements the existing `PERFORMANCE_IMPROVEMENT_PLAN.md`, which focused on loading screens; this one covers full-stack scalability.)*

---

## 1. Executive Summary

The stack is pre-production (dev DB `sportx_db`, ngrok tunnel URL) but already has structural bottlenecks that would block scaling:

| # | Problem | Where | Impact at scale |
|---|---------|-------|-----------------|
| 1 | Original-size images stored & served, no thumbnails/WebP, no CDN | `MediaController.php:105`, 50 × `Image.network` in app | Biggest bandwidth multiplier |
| 2 | Zero response caching on hot endpoints | `HomeController::explore()` — 5 queries every hit | CPU crushed on traffic spikes |
| 3 | Runtime `Schema::hasColumn()` per request | `SearchController.php:87-105` + 8 controllers | information_schema hit per request |
| 4 | Search = 7 sequential `LIKE '%q%'` scans | `SearchController.php:66-150` | Slow, unindexable, unscalable |
| 5 | 24 controllers return full `get()` lists (no pagination) | Academy, Event, Facility, Results, etc. | Payload + memory grows with data |
| 6 | Conversation `show()` loads ALL messages | `ConversationController.php:28-31` | Chat will die at volume |
| 7 | No rate limiting on content endpoints | `routes/api.php` — throttle only on auth/OTP | Abuse / no load-shedding |
| 8 | Session, cache, queue all on `database` driver | `.env:23-38` | DB contention on every request |
| 9 | No provider caching in app; detail screens refetch on every visit | `directory_provider.dart` detail providers | Wasted requests + spinner everywhere |
| 10 | `Image.network` everywhere, `cached_network_image` installed but unused | `community_feed.dart:53,119`, `post_detail_screen.dart:110` … | Re-downloads every image |
| 11 | 28 non-builder `ListView` + 288 raw `ref.watch` (almost no `select`) | e.g. `community_screen.dart:81`, `home_kit.dart` (1,497 lines) | Full-screen rebuilds, jank |
| 12 | Router eagerly imports ~167 screens | `core/router.dart` (845 lines) | Large bundle, slower startup |

---

## 2. Backend (Laravel) Improvements

### P0 — Critical (do first)

1. **Image processing + server-side compression pipeline** (`sportx-api/app/Http/Controllers/MediaController.php:105`)
   - Install [Intervention Image] or use Spatie MediaLibrary: generate thumbnails (e.g. 320/800/1600px) + WebP on upload, via a **queued job** (`QUEUE_CONNECTION` must be Redis first, see P1-3).
   - Store sizes; API returns URL variants; app picks per context (avatar vs cover).
   - Serve media through CDN or `S3 + CloudFront/Cloudflare` instead of Laravel's `storage/` public disk.
   - *Impact: ~3–10× bandwidth reduction, faster app image loads.*

   **Server-side compression / storage savings** (compress what we keep on disk):
   - Re-encode every stored original to **WebP at quality ~80** (or AVIF where supported) — typically **60–80% smaller** than the uploaded JPEG/PNG with no visible quality loss.
   - Downscale any original above a max dimension (e.g. cap at 2048px long edge) before encoding — a 12MP phone photo at 10MB becomes ~200–400KB.
   - Strip EXIF/metadata (also removes GPS clutter), optimize PNG palette sizes, convert large PNGs to JPEG/WebP when no transparency is needed.
   - Store **only the compressed variants** on disk (thumb ~320px, medium ~800px, large ~1600px capped) — keep the untouched original only for the first 24–48h (for re-processing) then delete, so storage shrinks **~5–10×**.
   - Do the same for **backfill**: one-time artisan command (queued) that compresses all files already in `storage/app/public/media` and rewrites their URLs in the `media` table.
   - Optional hardening: reject uploads that stay >5MB *after* compression; surface estimated-savings metric in admin panel.
   - *Impact: less disk usage (smaller/faster backups, cheaper storage/CDN egress) AND less bandwidth for the app — one job fixes both.*

2. **Cache hot read endpoints**
   - `HomeController::explore()` (5 independent `latest()/limit()` queries per hit) → wrap in `Cache::remember('explore', 300, ...)`; invalidate on write events.
   - Cache directories (`/academies`, `/coaches`, `/trials`, `/venues` list pages) for 60–300s.
   - Move `CACHE_STORE` from `database` to **Redis**.

3. **Kill runtime schema sniffing**
   - `SearchController.php`, `AchievementController.php`, `DirectoryController.php:46-77`, `ProfileController.php:66`, `PrivacyController.php:44`, `MediaController.php:120-123` all call `\Schema::hasColumn()` **per request**.
   - Resolve the schema once (per model, cached, or just remove the dynamic branch — the columns exist in migrations).

4. **Global rate limiting + response compression**
   - In `bootstrap/app.php` add ` shines.`→ `throttle:api` middleware group (e.g. 60/min per user, 15/min for search & upload) and apply at the `/api/v1` group in `routes/api.php` — today only login/OTP (`throttle:10,1` etc., lines 109–140) are limited.
   - Enable gzip/brotli at the web server (nginx `gzip on; brotli on;`) or add a compression middleware; JSON compresses ~70–80%.

### P1 — High

5. **Pagination everywhere**
   - 24 controller files return unpaginated `get()`: `AcademyController`, `AchievementController`, `EventController`, `FacilityController`, `CoachProfileController`, `ResultsController`, `ProfileController`, `ScoutConnectionController`, `ScoutShortlistController`, `NotificationPreferenceController`, `SettingsController`, `SocialLinksController`, `OrganizerProfileController`, `OnboardingController`, `AdminExpiryController` (`ExpiryRule::all()` twice, lines 21, 50) etc.
   - Standard: `->paginate(min($perPage, 50))` with `Link` headers.

6. **Chat fixes** (`ConversationController.php`)
   - `show()`: paginate `messages` (e.g. `messages()->latest()->limit(50)` + load-older endpoint) — currently loads *every* message with sender.
   - `index()`: replace `whereHas('participants')` + nested latest-message subqueries with a single `join` on last-message; add composite index `(conversation_id, created_at DESC)` on `messages`.

7. **Search**
   - Replace 7 sequential `LIKE '%q%'` scans with **MySQL FULLTEXT** (`MATCH ... AGAINST`) or Laravel Scout + **Meilisearch/Typesense**.
   - `RecentSearch::updateOrCreate` (line 50) writes DB on every keystroke request → throttle to on-submit only, and debounce client-side.

8. **Feed eager-load trim** (`PostController.php:50-68`)
   - `with(['user','comments.user'])` loads *every* comment's user per post; instead load latest 2–3 comments per post (windowed subquery or `comments Earl`: `with(['comments' => fn($q) => $q->latest()->limit(3), 'comments.user'])`), plus `comments_count`.

9. **Add missing DB indexes**
   - Only 37/63 migrations contain any index. Sweep all filter/sort columns (`status`, `owner_type/owner_id` polymorphics, `user_id` FKs, `created_at` sort columns) and add indexes + composite indexes for hot filters.

### P2 — Structural

10. **Move session/cache/queue off `database` driver** → Redis (queue + horizon), eliminate DB contention; optionally serve via Octane (Swoole/RoadRunner) for 3–10× req/s.
11. **Realtime chat/push:** today only `BROADCAST_CONNECTION=log` and app-side chat is fetch-once. Add WebSockets (Laravel Reverb / Pusher) or at minimum polling-safe `message_id > :lastId` delta endpoint.
12. **Ops:** un-comment `PHP_CLI_SERVER_WORKERS=4` for dev; add APM (Sentry performance / Telescope in staging), slow-query log >200ms, and a load test (k6) to size for target concurrency.
13. **Remove dev URL dependency:** stop serving production app against ngrok (`APP_URL=https://movable-washstand-...ngrok-free.dev`) — a tunnel is a hard throughput ceiling.

---

## 3. Flutter App Improvements

### P0 — Critical

1. **Cached images everywhere** — replace ~50 `Image.network` / `NetworkImage` occurrences with `CachedNetworkImage` (already in `pubspec.yaml:39`, used 0 times). Key spots:
   - `lib/features/social/presentation/widgets/community_feed.dart:53,119`
   - `lib/features/social/presentation/screens/post_detail_screen.dart:110` (full-size original, `height:300`, no cache)
   - `lib/features/more/presentation/screens/more_screen.dart:262`
   - `lib/features/coach/presentation/screens/showcase_athletes_screen.dart:291,340`
   - Add `memCacheWidth/memCacheHeight` for covers/avatars; never decode orig-size into a 300px box.

2. **Provider caching (keepAlive):**
   - Detail providers in `lib/shared/providers/directory_provider.dart` (`academyDetailProvider`, `coachDetail`, etc. lines 140-173) are bare `FutureProvider.family` → add `.cacheFor(Duration(minutes: 10))` so revisits don't refetch + re-skeleton.
   - `refresh()` clears `items: []` before reload (lines ~55, 83-86) → keep stale data while refetching (no empty flash).
   - Stop fetching `{'page':1,'per_page':20}` when UI shows 3–5 items (lines ~45) — request only what's shown or accept partial response.

3. **Timeouts + retries** (`lib/core/config/api_config.dart`, `sportx_app/.env`)
   - 30s/30s → 10s connect / 15s receive; wire the unused `maxRetries` into a retry interceptor (idempotent GET only, exp backoff).

### P1 — High

4. **List rendering:**
   - Convert 28 children-style `ListView(...)` to `ListView.builder` / shrink-wrap alternatives: `community_screen.dart:81`, `chat_list_screen.dart:97`, `role_selection_screen.dart:55`, `more_screen.dart:33` …
   - Add keys (ValueKey on ids) on dynamic item lists for state retention.

5. **Rebuild control:**
   - 288 `ref.watch` calls with almost no `ref.watch(x.select(...))` → whole screens rebuild on any state slice change. Convert screens (esp. `home_kit.dart`, 1,497 lines) to select the minimal slice, split `home_kit` into per-section widgets with `const` constructors.

6. **Startup path:**
   - Split `lib/core/router.dart` (845 lines, ~167 eager screen imports): use `deferred as` imports where target builds allow, and route builder factories so screens compile lazily into separate bundles (esp. if web target ships).
   - Split other monoliths: `multi_step_onboarding_screen.dart` (1,098 lines), `athlete/profile_screen.dart` (873), `view_profile_screen.dart` (872), `sportx_cards.dart` (780).

7. **Pagination/load-more:** ensure lists with server pagination grow pages on scroll (search load-more was reported broken; add `PagedChildBuilderDelegate`-style infinite scroll).

### P2 — Polish

8. Replace remaining 40+ `CircularProgressIndicator` with the existing skeletons (`lib/shared/presentation/widgets/skeleton.dart`).
9. Drop dead `pretty_dio_logger` dep from release builds; keep full-body logging debug-only.
10. Persist cached list responses (e.g. `Hive`/`Isar` first-paint cache) for Home so cold start paints content instantly and revalidates in background.
11. Realtime chat strategy (WebSocket/Reverb) instead of fetch-once `FutureProvider` (`lib/features/chat/presentation/providers`, lines 95-102) — pairs with backend P2-11.

---

## 4. Rollout Order & Expected Win

| Phase | Items | Expected result |
|-------|-------|-----------------|
| **Phase 1 (week 1)** | B-2 image pipeline (thumbnails/WebP), A-1 CachedNetworkImage, A-2 keepAlive/cache, A-3 timeouts, B-4 throttle+gzip | ~60–80% bandwidth & perceived-latency reduction — single biggest win |
| **Phase 2 (week 2)** | B-2 explore/dir caching, B-3 remove `Schema::hasColumn`, B-5 paginate all `get()` lists, B-6 chat pagination, A-4/a-5 list + rebuild control | Handles 10× traffic; smooth scrolling |
| **Phase 3 (week 3-4)** | B-7 search (FULLTEXT/Scout), B-8 feed eager-load fix, B-9 indexes, A-6 router split, Redis for cache/queue/session | DB CPU down, bundle/startup down |
| **Phase 4** | Octane, WebSockets, CDN in front of storage + API, load-test to target concurrency, A-10 offline first-paint cache | Production-grade for all users |

**Measure continuously:** p95 latency per endpoint (Sentry/Telescope), image bytes per session (client), DB slow-query log, Flutter DevTools rebuild counts, and a k6 load test target (e.g. 5,000 concurrent users on `/explore`, `/search`, feed).

---

## 5. Quick-Win Checklist

- [ ] `Cache::remember` on `HomeController::explore()` (30 min)
- [ ] `CachedNetworkImage` sweep (50 files)
- [ ] Move `CACHE_STORE` to Redis
- [ ] Global `throttle:api` group
- [ ] Off-switch for `Schema::hasColumn` calls
- [ ] Cap `perPage` at 50 and paginate the 24 unpaginated controllers
- [ ] `cacheFor` on detail FutureProviders
- [ ] Timeouts 10s/15s + retry interceptor
- [ ] Add thumbnail generation + WebP compression queue job on `MediaController` (compress on upload, quota-friendly storage)
- [ ] Backfill: batch-compress all existing files in `storage/app/public/media`

- [ ] Re-point app `.env` from ngrok to real host when going live
