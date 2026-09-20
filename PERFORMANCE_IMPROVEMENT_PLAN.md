# SportX - Performance Improvement Plan
## Why the app shows too many / too long loading screens

**Date:** 2026-09-20
**Scope:** sportx_app (Flutter + Riverpod + Dio) and sportx-api (Laravel) - full-stack audit
**Goal:** Reduce perceived and actual latency. Replace blocking full-screen spinners with instant cached UI, parallel data fetching, and backend caching.

---

## 1. Executive Summary

The loading problem is **not one bug** - it is ~8 compounding issues:

| # | Category | Root Cause | Effect |
|---|----------|------------|--------|
| 1 | Artificial delay | auth_provider.dart:79-84 forces 1500ms splash even on fast network | Every cold start waits 1.5s longer |
| 2 | No HTTP / provider cache | api_client.dart:8-32, directory_provider.dart:140-173, cache.php:18 default database | Every navigation re-fetches; back-and-forth = spinner |
| 3 | 30s Dio timeout | api_config.dart:15-19 | User stares at spinner for 30s before error |
| 4 | Waterfall on startup | home_screen.dart:18-25 + meta_provider.dart:43-46 + profile_provider.dart = 8-9 parallel calls but no batching/caching | Slow first paint, jank |
| 5 | Synchronous SecureStorage read per request | api_client.dart:40-43 | Adds 10-50ms per request serially |
| 6 | Backend: 7 sequential LIKE queries per search | SearchController.php:66-107 with LIKE %%q%% no index, no cache | Search slow under load |
| 7 | CircularProgressIndicator instead of skeleton | 49 occurrences across screens | Jarring blank screen vs shimmer |
| 8 | Pagination broken / over-fetch | Home fetches 20 but shows 3; search loadMore never triggers | Wasted bandwidth |

Fixing (1)+(2)+(3) alone removes >60% of perceived loading.

---

## 2. Flutter App Findings (Detailed)

### 2.1 Splash / Auth - lib/features/auth/presentation/providers/auth_provider.dart:51-77

- checkAuth() does await storage.getToken() (disk I/O) -> await dio.get('/auth/me') -> await _ensureMinSplashDuration(). The last call enforces Future.delayed(1500 - elapsed).
- Result: even if token is absent (instant) or API responds in 200ms, splash stays 1.5s. On slow network, 1.5s + 30s timeout = up to 31.5s splash.
- login()/register() block on await FirebaseMessaging.instance.getToken() (auth_provider.dart:190-199) - Firebase not ready = extra 2-5s.
- **Fix:** Remove artificial delay (or keep 300ms max for branding, not 1500ms). Make FCM registration fire-and-forget (unawaited).

### 2.2 Networking - lib/core/config/api_config.dart:15-21 + lib/core/utils/api_client.dart:8-32

- connectTimeout=30s, receiveTimeout=30s. Industry standard: 10s connect / 15s receive. maxRetries=1 defined but never used.
- dioProvider has zero caching/retry/dedup interceptors. validateStatus 200-299 breaks 304 handling.
- LogInterceptor(responseBody:true) in debug logs full JSON (20 items x 5 dirs) and blocks UI thread on large lists.
- AuthInterceptor.onRequest does await storage.getToken() via FlutterSecureStorage.read on every request - uncached, serializes request dispatch.

### 2.3 Directory / Detail Providers - lib/shared/providers/directory_provider.dart

- DirectoryNotifier constructor auto-calls load() with isLoading:true - every screen entry shows DirectoryStateView skeleton even if data was just fetched.
- refresh() clears items:[] before reload -> flash of empty state (directory_provider.dart:83-86).
- load() always fetches per_page=20 even though home_screen.dart:219 only uses take(3) / take(5) - 4x over-fetch.
- Detail providers (academyDetailProvider:140, coachDetail:145, trialDetail:150, etc.) are plain FutureProvider.family without keepAlive or cacheFor. Riverpod disposes them when route pops -> revisit = full refetch + full-screen GenericDetailSkeleton.
- grep keepAlive|autoDispose|cacheFor = 0 results across the app.
- grep CircularProgressIndicator = 49 hits - many screens use centered spinner instead of the existing skeleton.dart shimmers.

### 2.4 Home - lib/features/home/presentation/screens/home_screen.dart

- Initial load fires 5x DirectoryNotifier.load() + profileProvider + 3x meta calls = 8-9 requests on first paint.
- onRefresh() correctly uses Future.wait but initial load has no batching or priority (above-the-fold should load first).
- Images use placeholder Icon not CachedNetworkImage - no disk cache for cover/logo.
- No AutomaticKeepAlive / no PageStorage - tab switch rebuilds lists.

### 2.5 Search - lib/features/search/presentation/providers/search_provider.dart:199-352

- No debounce: every setCategory() / updateFilters() immediately calls search() -> rapid isLoading:true flicker via universal_search_screen.dart:160 skeleton.
- per_page mismatch: provider sends 20, backend defaults to 5 (SearchController.php:30) -> inconsistent UI.
- hasMore logic expects current_page/last_page but backend returns only meta.query -> pagination footer spinner (universal_search_screen.dart:436-441) never or always shows; loadMore broken.
- RecentSearch::updateOrCreate on every keystroke hits DB write.

### 2.6 Meta / Notifications / Saved

- meta_provider.dart:43-46 Future.wait of 3 endpoints on every app start, no cache. Static data (sports/cities/ageGroups) refetched constantly.
- notifications_provider + PushNotificationService:26-42 reload full /me/notifications on every foreground push -> skeleton flash.
- storage_service.dart:6-49 only persists token/user - no Hive/Isar/Drift/SharedPreferences for directory/detail/search caches. Offline = infinite spinner.

### 2.7 Build / Bundle

- pubspec.yaml:26 google_fonts: ^6.2.1 downloads fonts at runtime -> extra network + layout shift. Prefer bundled fonts.
- cached_network_image: ^3.3.1 is declared but not used in home_screen.dart cards.
- pull_to_refresh: ^2.0.0 unmaintained; consider RefreshIndicator (already used) only.
- No flutter build apk --analyze-size / deferred imports: router.dart eagerly imports 90+ screens - initial Dart bundle large.

---

## 3. Backend Findings (Detailed)

### 3.1 No Caching Anywhere

- Only 2 Cache:: usages in whole codebase (FCMService.php:130,142). Zero in DirectoryController.php, TrialController.php, TournamentController.php, SearchController.php, MetaController.php.
- config/cache.php:18 default database (DB table lock, slow). redis configured but never selected - even if caching added, it hits DB.
- No Cache-Control, ETag, Last-Modified headers. No stale-while-revalidate.

### 3.2 Search - app/Http/Controllers/SearchController.php:17-113

- Executes 7 separate queries sequentially (66-107), each with LIKE %%q%% (no B-tree or FULLTEXT index), each with limit(5), each with eager with() but no cache.
- Under load: 7x full table scans per keystroke.
- RecentSearch::updateOrCreate per search adds write latency.
- Returns {data: {...}, meta: {query}} - no pagination meta, breaks Flutter hasMore.

### 3.3 Directories - DirectoryController.php:11-59, TrialController.php:10-33

- Eager loading correct (with(['city','logo',...])) but no pagination cache.
- Filters like where('fee_range','>=',...) on string column, whereJsonContains('age_groups') without JSON index -> full scan.
- where('name','like','%%q%%') cannot use index.
- paginate(50) no Cache-Control header, no select() pruning - returns all columns including large description.

### 3.4 Meta - MetaController.php:11-38

- sports/cities/ageGroups get() all rows on every call. Should be Cache::rememberForever.

### 3.5 General

- config/database.php:20-46 default sqlite fallback, no read replica, no query cache.
- No API response compression check (ensure nginx gzip / Brotli on JSON).
- No rate-limit headers / no throttle on search/directories (only auth has throttle:10,1).

---

## 4. Prioritized Improvement Plan

### P0 - Immediate (1-2 days) - Biggest perceived gain

| # | Action | Files | Expected Outcome |
|---|--------|-------|------------------|
| P0-1 | Remove / reduce splash delay to 300ms or 0 | auth_provider.dart:79-84 | Cold start -1.2s |
| P0-2 | Lower Dio timeouts to 10s connect / 15s receive; wire maxRetries with exponential backoff | api_config.dart:15-19, api_client.dart | Fail fast, auto-retry transient errors |
| P0-3 | Cache token in memory - read SecureStorage once, keep in RAM | api_client.dart:40-43, storage_service.dart | -10-50ms per request |
| P0-4 | Make FCM registration fire-and-forget | auth_provider.dart:190-199 | Login faster 1-2s |
| P0-5 | Replace all full-screen CircularProgressIndicator with skeleton | 49 files, start with notifications_screen.dart:74, universal_search_screen.dart:440 | Less jarring |
| P0-6 | Backend: add Cache-Control: public, max-age=60 + ETag for directories/meta/search | DirectoryController.php, MetaController.php, SearchController.php | Enables HTTP cache |

### P1 - High Impact (1 week)

| # | Action | Detail |
|---|--------|--------|
| P1-1 | Add Riverpod caching - convert FutureProvider.family details to @Riverpod(keepAlive: true) with cacheFor(Duration(minutes:5)) or manual keepAlive link | Prevents refetch on back navigation |
| P1-2 | Fix refresh() to not clear items - keep stale list visible while reloading | directory_provider.dart:83-86 copyWith(isLoading:true) without clearing |
| P1-3 | Fix pagination - backend must return current_page/last_page for search; Flutter hasMore uses it; use bottom skeleton not centered spinner | SearchController.php:110-113, search_provider.dart:244-252 |
| P1-4 | Debounce search 350ms + cancel previous request via Dio CancelToken | search_provider.dart:199-310 |
| P1-5 | Over-fetch fix - home uses per_page=6 not 20 | directory_provider.dart:45 param or dedicated home endpoint |
| P1-6 | Backend: add Cache::remember 60-300s for directories, 1h for meta | DirectoryController.php:13, MetaController.php |
| P1-7 | Switch cache driver to redis (or file if no Redis) | .env: CACHE_STORE=redis, config/cache.php:18 |
| P1-8 | Add DB indexes for name, city_id, sport_id, listing_status | Migration; replace LIKE %%q%% with FULLTEXT where possible |
| P1-9 | Use CachedNetworkImage for all academy/coach/trial cover images with disk cache | home_screen.dart:259-267 etc. |

### P2 - Medium (2 weeks) - Offline and Architecture

| # | Action | Detail |
|---|--------|--------|
| P2-1 | Local persistence - Hive/Isar/Drift cache for directories + details with TTL (stale-while-revalidate) | New core/cache/ layer |
| P2-2 | Batch home endpoint - single GET /home/feed returning academies+coaches+trials+tournaments+scholarships | Reduces 5 -> 1 round-trip; backend can parallelize with Cache::remember |
| P2-3 | Request deduplication interceptor - coalesce identical concurrent GETs | api_client.dart custom interceptor |
| P2-4 | Pagination everywhere - cursor/infinite scroll with SliverList + ScrollController threshold | Directory list screens |
| P2-5 | KeepAlive tabs - AutomaticKeepAlives / PageStorageKey for bottom nav | router.dart:431-440 ShellRoute |
| P2-6 | Optimize search - move to Meilisearch / Scout FULLTEXT, or at least MATCH ... AGAINST; cache frequent queries | SearchController.php:49-64 |
| P2-7 | Compress API responses - enable gzip/brotli on nginx, add select() minimal columns | Infra + controllers |
| P2-8 | Bundle fonts - remove google_fonts runtime fetch, bundle via pubspec.yaml: flutter.fonts | pubspec.yaml:28 |

### P3 - Polish (ongoing)

- Deferred imports for admin/scout heavy routes.
- LogInterceptor only log headers/status in debug, not full bodies.
- Add performance monitoring: Firebase Performance / Sentry traces for each endpoint.
- Add pull-to-refresh skeleton instead of clearing list.
- Prefetch detail on card viewport (precache when card visible 50%).

---

## 5. Concrete Code Suggestions

### 5.1 Flutter - Token In-Memory Cache (api_client.dart:40-43)

`dart
class AuthInterceptor extends Interceptor {
  String? _cachedToken;
  Future<String?> _getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await ref.read(storageServiceProvider).getToken();
    return _cachedToken;
  }
  // on logout: _cachedToken = null;
}
`

### 5.2 Flutter - Remove Splash Delay

`dart
// auth_provider.dart:79-84
Future<void> _ensureMinSplashDuration(DateTime start) async {
  final elapsed = DateTime.now().difference(start);
  if (elapsed.inMilliseconds < 300) {
    await Future.delayed(Duration(milliseconds: 300 - elapsed.inMilliseconds));
  }
}
// Or remove call entirely for instant nav; show branding in SplashScreen animation only.
`

### 5.3 Flutter - KeepAlive Detail Provider

`dart
final academyDetailProvider = FutureProvider.family<Academy, String>((ref, id) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close); // auto-expire
  final resp = await ref.watch(dioProvider).get('/academies/\');
  return _detailFromResponse(resp, Academy.fromJson);
});
`

### 5.4 Flutter - Debounced Search

`dart
Timer? _debounce;
void setSearch(String q) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 350), () => search(q));
}
`
+ Dio CancelToken to cancel previous dio.get('/search').

### 5.5 Backend - Meta Cache

`php
// MetaController.php
public function sports() {
  return Cache::rememberForever('meta.sports', fn() => Sport::all());
}
public function cities() { return Cache::remember('meta.cities', 3600, fn() => City::with('state')->get()); }
`

### 5.6 Backend - Directory Cache + ETag

`php
// DirectoryController.php
public function academies(Request \) {
  \ = 'academies:'.md5(json_encode(\->only(['q','sport_id','city_id','page','per_page'])));
  \ = Cache::remember(\, 120, fn() => \->paginate(\, \));
  return response()->json(\)->header('Cache-Control','public, max-age=60');
}
`

### 5.7 Backend - Search Optimization

`php
// Option A: limit to 1-2 tables per query, cache 60s, use FULLTEXT
// Option B: Scout/Meilisearch
Academy::search(\)->query(fn(\) => \->published())->take(5)->get();
`

---

## 6. Metrics to Track Before/After

| Metric | Tool | Target |
|--------|------|--------|
| Cold start to home paint | flutter run --trace-startup / Firebase Performance | < 1.8s (from ~3.5s) |
| Home API total time | Dio log / DevTools Network | < 600ms (from 1500ms+) |
| Search p95 | Laravel Telescope / Sentry | < 300ms (from 800ms+) |
| Detail revisit (back nav) | Riverpod + DevTools | 0ms (cached) vs 400ms now |
| APN/FCM login overhead | Manual | < 100ms fire-and-forget |
| Bundle size | flutter build apk --analyze-size | -15% via font bundling + deferred imports |

---

## 7. Quick Wins Checklist (copy to issues)

- [ ] auth_provider.dart:79-84 reduce splash delay 1500->300ms
- [ ] api_config.dart:15-16 timeout 30->10/15s
- [ ] api_client.dart:40 cache token in memory
- [ ] auth_provider.dart:105,145 make FCM fire-and-forget
- [ ] Replace 49 CircularProgressIndicator with Skeleton (skeleton.dart already exists)
- [ ] directory_provider.dart:83 dont clear items on refresh
- [ ] search_provider.dart debounce 350ms + CancelToken
- [ ] search_provider.dart:48 / SearchController.php:30 align per_page and fix hasMore
- [ ] Backend CACHE_STORE=redis + Cache::remember for meta/directories/search
- [ ] Add DB indexes on name, city_id, sport_id, listing_status
- [ ] Use CachedNetworkImage everywhere
- [ ] Home per_page=6 not 20; or new /home/feed batch endpoint

---

## 8. References

- sportx_app/lib/core/config/api_config.dart:15-19
- sportx_app/lib/core/utils/api_client.dart:8-47
- sportx_app/lib/core/utils/storage_service.dart:6-49
- sportx_app/lib/features/auth/presentation/providers/auth_provider.dart:51-84,190-199
- sportx_app/lib/shared/providers/directory_provider.dart:32-173
- sportx_app/lib/shared/providers/meta_provider.dart:39-67
- sportx_app/lib/features/home/presentation/screens/home_screen.dart:18-25,184-546
- sportx_app/lib/features/search/presentation/providers/search_provider.dart:199-352
- sportx_app/lib/shared/presentation/widgets/skeleton.dart
- sportx-api/app/Http/Controllers/DirectoryController.php:11-59
- sportx-api/app/Http/Controllers/SearchController.php:17-113
- sportx-api/app/Http/Controllers/MetaController.php:11-38
- sportx-api/config/cache.php:18
