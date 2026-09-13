# Dynamic Theme Controlled by Admin Panel — Full Analysis & Implementation Approaches

> **Project:** SportX India — `sportx_app` (Flutter + Riverpod) + `sportx-api` (Laravel)  
> **Date:** 2026-09-12  
> **Author:** Automated Codebase Audit (OpenCode / Muse Spark)  
> **Scope:** Allow an **admin** to change the **entire app theme** (colors, typography, spacing/radius, component styles) **at runtime** without requiring an app-store release.

---

## Table of Contents

1. [Current State Audit](#1-current-state-audit)
2. [What “Dynamic Theme” Means Here](#2-what-dynamic-theme-means-here)
3. [Requirements & Non-Goals](#3-requirements--non-goals)
4. [Cross-Cutting Concerns (read first)](#4-cross-cutting-concerns)
5. [Approach 1 — Backend-Driven Theme Config via DB + REST API (RECOMMENDED)](#5-approach-1--backend-driven-theme-config-via-db--rest-api-recommended)
6. [Approach 2 — Preset / Palette Picker (Constrained Choice)](#6-approach-2--preset--palette-picker-constrained-choice)
7. [Approach 3 — Firebase Remote Config](#7-approach-3--firebase-remote-config)
8. [Approach 4 — CDN-Hosted Theme JSON (S3 / R2 / Cloud Storage)](#8-approach-4--cdn-hosted-theme-json-s3--r2--cloud-storage)
9. [Approach 5 — White-Label / Multi-Tenant + Scheduled Theming](#9-approach-5--white-label--multi-tenant--scheduled-theming)
10. [Approach 6 — Build-Time / Flavor + OTA (CodePush / Shorebird)](#10-approach-6--build-time--flavor--ota-codepush--shorebird)
11. [Comparison Matrix](#11-comparison-matrix)
12. [Recommended Phased Rollout](#12-recommended-phased-rollout)
13. [Shared Implementation Details (applies to A1, A2, A4, A5)](#13-shared-implementation-details)
14. [Testing & QA Checklist](#14-testing--qa-checklist)
15. [Operational Runbook](#15-operational-runbook)
16. [File Change Inventory](#16-file-change-inventory)
17. [Appendix A — Current Hardcoded Values to Replace](#appendix-a--current-hardcoded-values-to-replace)
18. [Appendix B — Example Theme JSON Schema](#appendix-b--example-theme-json-schema)
19. [Appendix C — Minimal Admin UI Wireframe](#appendix-c--minimal-admin-ui-wireframe)

---

## 1. Current State Audit

### 1.1 Flutter App — Theme Layer

| File | Line | Finding |
|------|------|---------|
| `sportx_app/lib/theme/colors.dart:3-34` | `class AppColors` | **All colors are `static const`** — `primary=0xFF1677ff`, `cta=0xFFF97316`, `background=0xFFffffff`, `surface=0xFFf7f8fa`, `textPrimary=0xFF111111`, `textSecondary=0xFF6b7280`, `border=0xFFd9dee7`, `success/warning/error/info`, `primaryLight/Dark/Darker`, `ctaLight/Dark`, `sportBadgeBg`, `verifiedBadge`, `mandatoryIndicator`. No runtime override possible. |
| `sportx_app/lib/theme/app_theme.dart:5-156` | `class AppTheme { static ThemeData get lightTheme }` | Single static getter returns `ThemeData(useMaterial3:true)` wired to `AppColors`. No `darkTheme`, no `ThemeMode`, no Riverpod watch. Every widget reads `AppColors.xxx` directly or `Theme.of(context)`. |
| `sportx_app/lib/theme/design_tokens.dart:1-13` | `class DesignTokens` | Only `spacingXs…3Xl` and `radius=8`. Card radius is hardcoded as `16` in `app_theme.dart:52`, button radius `12`, input radius `12`, chip radius `20` — **not** using tokens. Inconsistent. |
| `sportx_app/lib/main.dart:29-42` | `SportXApp extends ConsumerWidget` | `MaterialApp.router(theme: AppTheme.lightTheme)` — **hardcoded**, no provider. No `themeMode`, no `darkTheme`, no `builder` that watches a theme provider. |
| `sportx_app/lib/core/router.dart:423-506` | `MainShell` | Bottom nav uses `AppColors.primary` and `Color(0xFF6b7280)` directly, not `Theme`. 100+ grep hits for `AppColors` across `lib/features/**` — every screen imports `colors.dart`. |
| `sportx_app/lib/features/admin/presentation/screens/admin_dashboard_screen.dart:47-66` | Admin dashboard | Stat cards hardcode `Colors.blue/red/orange/green` instead of `AppColors` — drift from design system. |
| `sportx_app/lib/core/utils/storage_service.dart:10-49` | `StorageService` | Uses `flutter_secure_storage`. Keys: `sportx_auth_token`, `sportx_user_data`. **No theme key**. JSON encode/decode already used for `user_data` — reusable for theme caching. |
| `sportx_app/pubspec.yaml:9-32` | Dependencies | `flutter_riverpod ^2.5.1`, `dio ^5.7.0`, `flutter_secure_storage ^9.2.2`, `google_fonts ^6.2.1`, `firebase_core`, `firebase_messaging` already present. `shared_preferences` **not** present but `flutter_secure_storage` is fine for small JSON; or add `shared_preferences` for larger non-sensitive cache. No `flex_color_scheme` or `riverpod_generator` theme code yet. |
| `sportx_app/lib/core/config/api_config.dart:3-27` | `ApiConfig` | Base URL from `dotenv`. All API via `dioProvider` with `AuthInterceptor`. Ready to add `ThemeService`. |

**Impact:** Any color change today requires code edit → commit → build → Play Store / App Store review (1-3 days) → user update. No instant seasonal branding, no A/B, no white-label.

### 1.2 Backend — Admin & Config Surface

| Area | File | Finding |
|------|------|---------|
| Routes | `sportx-api/routes/api.php:278-344` | Admin group is `/api/v1/admin` with `auth:sanctum, role:admin, admin.2fa`. Existing controllers: `AdminDashboardController`, `AdminContentController`, `AdminModerationController`, `AdminExpiryController`, `AdminCategoryController`, `AdminUserController`, `AdminAuthController`. **No theme/settings controller.** |
| Auth | `sportx-api/app/Http/Middleware/*` | `EnsureRole`, `EnsureAdmin2FAVerified` + `role:admin` guard already enforced — reuse for theme endpoints. |
| Migrations | `sportx-api/database/migrations/*.php` | `users` table, `expiry_rules`, `sports`, `cities`, `age_groups`, `recent_searches`, etc. **No `settings` or `app_config` / `theme_configs` table**. No generic key-value store. |
| Settings endpoint | `sportx-api/app/Http/Controllers/SettingsController.php:10-98` | Per-user `notification_prefs` + `language` — pattern to copy, but user-scoped, not global. |
| Cache | `sportx-api/config/*.php`, `.env` | Standard Laravel `cache` (file/database/redis) available. No theme cache yet. |

### 1.3 Admin Panel

- Flutter admin screens exist in `lib/features/admin/presentation/screens/` (`admin_dashboard_screen.dart`, `admin_provider.dart:263-681`) and communicate via `Dio` to `/admin/*` endpoints.
- Separately, `docs/Admin-Panel-Implementation-Prompt.md` describes a **Blade/HTML** admin web panel (`resources/views/admin/*`, `public/admin/css/*`) — either or both can host the theme editor. The Flutter admin app is already authenticated and is the **fastest place to add theme controls** without Blade work.

### 1.4 Design System Drift

- `docs/Mobile-Architecture.md:18-50` documents design tokens as `primary #2563EB`, `cta #F97316`, `Poppins` font — but `colors.dart` uses `1677ff` (different blue) and `fontFamily: 'Inter'` + `GoogleFonts.inter`. Admin panel prompt uses `Poppins`. **Dynamic theming must reconcile this drift** and centralize source of truth.

---

## 2. What “Dynamic Theme” Means Here

**Dynamic** = admin changes values in a UI, presses Save/Publish, and **all installed apps** reflect the new theme **without an app update**:

- **Colors:** `primary`, `secondary/cta`, `background`, `surface`, `textPrimary/Secondary/Tertiary`, `border`, `success/error/warning/info`, `infoLight/successLight`, derivatives (`primaryLight/Dark`, `ctaLight/Dark`).
- **Typography:** font family (`Poppins` vs `Inter`), scale, weights.
- **Shape & Spacing:** card radius, button radius, input radius, chip radius, spacing scale.
- **Component overrides:** `AppBar`, `Card`, `ElevatedButton`, `InputDecoration`, `BottomNavigationBar`, `Chip`, `Divider`, `SnackBar`, `NavigationBar`.
- **Phase 2 (optional):** per-feature illustration, splash background, logo URL, empty-state Lottie, seasonal banner.

**Control plane:** Admin panel (Flutter admin screens +/or Blade web) → Backend persists → Apps fetch → Local cache → `ThemeData` rebuilt → `MaterialApp` re-renders.

---

## 3. Requirements & Non-Goals

### Must Have

- Single source of truth, versioned, auditable.
- Secure — only `role:admin` can write; public or `auth` read with aggressive caching.
- Offline-safe — app works with last cached theme if network fails; never crashes on corrupt JSON.
- Validated — hex colors validated, contrast warnings, required keys enforced.
- Instant-ish propagation — ≤5 min default, ≤30s if push-assisted.
- Backward compatible — old app versions that don’t know new keys must still render (fallback to `AppColors`).

### Non-Goals (initially)

- Per-user theming (user picks light/dark in settings) — can be added later as `ThemeMode` layer on top.
- Fully arbitrary CSS — start with tokens, not free-form style injection.

---

## 4. Cross-Cutting Concerns

### 4.1 Color Validation & Accessibility

- Accept only `^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$` (with optional alpha). Backend validates, Flutter double-validates before applying.
- Auto-derive `primaryLight/Dark` via HSL if admin only sets `primary` — or let admin override derivatives explicitly.
- Warn if `primary` vs `background` contrast < 4.5:1 (WCAG AA). Block publish if < 3:1 or show “low contrast” badge.

### 4.2 Dark Mode Strategy

- Ship **two palettes**: `light` and `dark`. If admin only edits light, auto-generate dark by inverting surface/background and adjusting text. Better: admin edits both side-by-side with preview.
- App stores `ThemeMode { system, light, dark }` in `StorageService` later; for now default `ThemeMode.light` and add toggle after dynamic colors land.

### 4.3 Caching & Propagation

- **Backend cache:** `Cache::remember('theme:active', 3600, fn() => ThemeConfig::active())` + bust on publish. Add `ETag`/`If-None-Match` and `Cache-Control: public, max-age=300`.
- **Client cache:** `flutter_secure_storage` key `sportx_theme_config_v1` + in-memory Riverpod state. Fetch on: app start (before `runApp`), `didChangeAppLifecycleState(resumed)`, pull-to-refresh on home, and FCM silent push `theme.updated`.
- **Polling fallback:** If not using FCM, poll every `15 min` while foregrounded, or use `If-Modified-Since` header with `updated_at`.

### 4.4 Versioning & Rollback

- Every publish inserts a new row (`version` auto-increment) or overwrites single row but writes `theme_config_histories`. Keep last 20 versions. “Restore v12” = one click.
- Include `version` + `updated_at` in API response; app sends `?since_version=12` to avoid re-download if unchanged.

### 4.5 Security

- Write: `auth:sanctum + role:admin + admin.2fa`. Validate JSON schema server-side (reject unknown keys in strict mode or allow `additionalProperties: false`).
- Read: `GET /api/v1/theme` is **public** (or `auth:sanctum` if you want to hide upcoming rebrand) — no PII, CDN-cacheable.
- Rate-limit public read (`throttle:60,1`), no rate-limit for version-check HEAD.

---

## 5. Approach 1 — Backend-Driven Theme Config via DB + REST API (RECOMMENDED)

> **Effort:** M (3-5 days) • **Flexibility:** High • **Risk:** Low • **No new vendor**

### 5.1 Architecture

```
[Admin Flutter/Blade] --POST /admin/theme--> [Laravel: AdminThemeController]
                                           -> validates -> writes `theme_configs` (is_active=1)
                                           -> Cache::forget('theme:active')
                                           -> fires ThemeUpdated event -> FCM broadcast (optional)
                                                        |
[Mobile App] --GET /api/v1/theme (cached)--> [ThemeController] --Cache::remember--> [DB]
         |--> ThemeProvider (Riverpod) caches to SecureStorage
         |--> AppTheme.fromConfig(config) builds ThemeData
         `--> MaterialApp(theme: provider.theme, darkTheme: provider.darkTheme)
```

### 5.2 Backend — DB

**New migration** `2026_09_12_000001_create_theme_configs_table.php`:

```php
Schema::create('theme_configs', function (Blueprint $table) {
    $table->id();
    $table->unsignedInteger('version')->unique();
    $table->string('name')->default('Default'); // "Diwali 2026", "IPL Season"
    $table->json('config');           // full JSON blob (see Appendix B)
    $table->boolean('is_active')->default(false)->index();
    $table->boolean('is_published')->default(false);
    $table->foreignId('created_by')->nullable()->constrained('users');
    $table->timestamp('published_at')->nullable();
    $table->timestamp('scheduled_at')->nullable(); // for Approach 5 extension
    $table->timestamps();
    $table->index(['is_active','is_published']);
});
Schema::create('theme_config_histories', function (Blueprint $table) {
    $table->id();
    $table->foreignId('theme_config_id')->constrained();
    $table->json('config');
    $table->foreignId('changed_by')->nullable()->constrained('users');
    $table->text('change_reason')->nullable();
    $table->timestamps();
});
```

Alternative single-row variant: `app_settings` key-value table (`key='theme'`, `value=json`, `updated_at`) — simpler but loses version history. Recommend dedicated table.

**Model** `app/Models/ThemeConfig.php`:

```php
class ThemeConfig extends Model {
    protected $casts = ['config'=>'array','is_active'=>'bool','is_published'=>'bool','scheduled_at'=>'datetime','published_at'=>'datetime'];
    public static function active(): ?self { return Cache::remember('theme:active', 3600, fn()=> self::where('is_active',true)->latest('version')->first()); }
    public static function nextVersion(): int { return (self::max('version') ?? 0) + 1; }
}
```

### 5.3 Backend — API

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/theme` | public (or `auth:sanctum` optional) | Returns active config. Headers: `ETag: "v{version}-{hash}"`, `Cache-Control: public, max-age=300` |
| `GET` | `/api/v1/theme/preview?version=12` | public | Preview any version (for admin preview without activating) |
| `GET` | `/api/v1/admin/theme` | `admin` | List all versions (paginated, with `is_active` flag) |
| `GET` | `/api/v1/admin/theme/{id}` | `admin` | Single version detail |
| `POST` | `/api/v1/admin/theme` | `admin` | Validate + create draft (`is_active=false`) |
| `PUT` | `/api/v1/admin/theme/{id}` | `admin` | Update draft (only if not active) |
| `POST` | `/api/v1/admin/theme/{id}/publish` | `admin` | Sets `is_active=true`, others false, bumps `version`, clears cache, optionally broadcasts FCM |
| `POST` | `/api/v1/admin/theme/{id}/rollback` | `admin` | Re-activate prior version (creates new version row as copy) |
| `POST` | `/api/v1/admin/theme/validate` | `admin` | Dry-run schema + contrast check, returns warnings/errors without persisting |

**Controller sketch** `app/Http/Controllers/Admin/AdminThemeController.php`:

```php
public function publicShow(Request $r) {
    $active = ThemeConfig::active() ?? ThemeConfig::fallbackDefault(); // fallback returns code default
    if ($r->header('If-None-Match') === '"v'.$active->version.'"') return response('', 304);
    return response()->json(['data'=>$active->config,'meta'=>['version'=>$active->version,'updated_at'=>$active->updated_at]])
        ->header('ETag', '"v'.$active->version.'"')
        ->header('Cache-Control','public, max-age=300');
}
public function store(Request $r) {
    $validated = $r->validate(['name'=>'required|string|max:80','config'=>'required|array','config.colors'=>'required|array' /* + strict hex rules */]);
    $this->validateHex($validated['config']);
    $row = ThemeConfig::create(['version'=>ThemeConfig::nextVersion(),'name'=>$validated['name'],'config'=>$validated['config'],'created_by'=>$r->user()->id]);
    return response()->json(['data'=>$row],201);
}
public function publish(Request $r, ThemeConfig $theme) {
    DB::transaction(function() use($theme){
        ThemeConfig::where('is_active',true)->update(['is_active'=>false]);
        $theme->update(['is_active'=>true,'is_published'=>true,'published_at'=>now()]);
        Cache::forget('theme:active');
        // optional: broadcast via FCM topic "theme"
        // event(new ThemeUpdated($theme));
    });
    return response()->json(['data'=>$theme->fresh()]);
}
```

**Validation helper:** regex `^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$`, require keys `colors.primary`, `colors.background`, `colors.textPrimary`; warn if `colors.primary` contrast with `background` < 4.5.

### 5.4 Flutter — Model & Service

**New file** `lib/theme/app_theme_config.dart`:

```dart
class AppThemeConfig {
  final int version;
  final String name;
  final ThemeColors colors;
  final ThemeTypography typography;
  final ThemeShape shape;
  final ThemeSpacing spacing;
  final DateTime? updatedAt;
  // fromJson / toJson / toThemeData()
  Color hex(String v) => Color(int.parse(v.replaceFirst('#','0xFF'))); // handle 8-digit alpha
  ThemeData toThemeData() => ThemeData(useMaterial3:true, colorScheme:..., appBarTheme:..., ...);
  static AppThemeConfig fallback() => AppThemeConfig(version:0, name:'fallback',
    colors: ThemeColors(primary:'#1677ff', cta:'#F97316', background:'#ffffff', ...),
    typography: ThemeTypography(fontFamily:'Inter'),
    shape: ThemeShape(cardRadius:16, buttonRadius:12),
    spacing: ThemeSpacing(xs:4, sm:8, md:12, lg:16, xl:20),
  );
}
```

**New file** `lib/core/services/theme_service.dart`:

```dart
class ThemeService {
  final Dio dio;
  ThemeService(this.dio);
  Future<AppThemeConfig?> fetchRemote({int? sinceVersion}) async {
    final res = await dio.get('/theme', queryParameters: {if(sinceVersion!=null)'since_version':sinceVersion});
    if(res.statusCode==304) return null;
    return AppThemeConfig.fromJson(res.data['data'], meta: res.data['meta']);
  }
}
```

### 5.5 Flutter — State & Wiring

**New provider** `lib/theme/theme_provider.dart`:

```dart
final themeServiceProvider = Provider((ref)=> ThemeService(ref.watch(dioProvider)));
final storageServiceProvider = Provider((ref)=> StorageService());

final themeConfigProvider = StateNotifierProvider<ThemeNotifier, AsyncValue<AppThemeConfig>>((ref){
  return ThemeNotifier(ref.watch(themeServiceProvider), ref.watch(storageServiceProvider));
});
class ThemeNotifier extends StateNotifier<AsyncValue<AppThemeConfig>> {
  ThemeNotifier(this.service, this.storage): super(const AsyncLoading()) { _init(); }
  Future<void> _init() async {
    // 1) load cached
    final cached = await storage.getThemeConfig();
    if(cached!=null) state = AsyncData(AppThemeConfig.fromJson(cached));
    // 2) fetch remote
    try { final remote = await service.fetchRemote(sinceVersion: cached?.version); if(remote!=null){ await storage.saveThemeConfig(remote.toJson()); state = AsyncData(remote);} }
    catch(_){ if(state is AsyncLoading) state = AsyncData(AppThemeConfig.fallback()); }
  }
  Future<void> refresh() async { /* force fetch + notify */ }
}
```

**Modify** `lib/core/utils/storage_service.dart` — add:

```dart
static const _themeKey = 'sportx_theme_config_v1';
Future<void> saveThemeConfig(Map<String,dynamic> json) => _storage.write(key:_themeKey, value:jsonEncode(json));
Future<Map<String,dynamic>?> getThemeConfig() async { final v=await _storage.read(key:_themeKey); return v==null?null:jsonDecode(v); }
```

**Modify** `lib/main.dart` — hydrate before first frame to avoid flash:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... dotenv, firebase
  final container = ProviderContainer();
  // optional: await container.read(themeConfigProvider.notifier).warmUp();
  runApp(UncontrolledProviderScope(container: container, child: const SportXApp()));
}
class SportXApp extends ConsumerWidget {
  @override Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeConfigProvider);
    final config = themeAsync.valueOrNull ?? AppThemeConfig.fallback();
    // show splash until first load? or fallback immediately
    return MaterialApp.router(
      title: 'SportX India',
      theme: config.toThemeData(),           // was AppTheme.lightTheme
      darkTheme: config.toDarkThemeData(),   // new
      themeMode: ThemeMode.light,             // later: ref.watch(themeModeProvider)
      routerConfig: ref.watch(routerProvider),
    );
  }
}
```

**Refactor** `lib/theme/colors.dart` + `app_theme.dart`:

- Keep `AppColors` as fallback constants but **deprecate direct use** in features. New canonical access: `Theme.of(context).colorScheme.primary`, `Theme.of(context).extension<…>()` or `ref.watch(themeConfigProvider).colors.primary`.
- Add `ThemeExtension` for custom tokens (`cta`, `successLight`) so `Theme.of(context).extension<SportXColors>()!.cta` works.
- Replace 100+ `AppColors.xxx` call sites incrementally (codemod) — not blocking for v1.

### 5.6 Admin Panel — Flutter

**New screen** `lib/features/admin/presentation/screens/theme_editor_screen.dart`:

- Left: color pickers (primary, cta, background, surface, textPrimary, border, success/warning/error/info). Use `flutter_colorpicker` or custom hex field + preview swatch.
- Middle: live preview card (button, input, card, chip, badge) that re-renders from draft `AppThemeConfig`.
- Right: JSON raw editor (collapsible) + validation errors/warnings.
- Actions: Save Draft → POST `/admin/theme`, Publish → POST `/{id}/publish`, Rollback, Preview on device (QR deep link with `?preview_theme_version=12`).

Add route `GoRoute(path:'/admin/theme', builder: (_) => ThemeEditorScreen())` and quick-action card on `AdminDashboardScreen:113` — `_buildActionCard('Theme', Icons.palette)`.

State lives in `admin_provider.dart` — add:

```dart
Future<void> loadThemeVersions() async { ... GET /admin/theme }
Future<bool> saveThemeDraft(Map<String,dynamic> config) async { ... }
Future<bool> publishTheme(int id) async { ... }
```

### 5.7 Pros / Cons

| Pros | Cons |
|------|------|
| Full control — any hex, any token | Must build validation + preview carefully |
| Works offline, no vendor lock-in | Requires backend work + cache invalidation |
| Versioned + rollback + audit | Client must handle corrupt/missing keys gracefully |
| Public endpoint CDN-cacheable | 5-min propagation unless FCM push added |

---

## 6. Approach 2 — Preset / Palette Picker (Constrained Choice)

### Idea

Admin does **not** type hex. Instead picks from 5-8 curated presets: `SportX Blue (default)`, `Energy Orange`, `Forest Green`, `Royal Purple`, `Sunset Red`, `Monsoon Teal`, plus optional `Custom` (unlocks hex fields).

Backend stores `preset_id` + optional overrides: `{"preset":"forest","overrides":{"primary":"#1B7A4D"}}`. App maps `preset_id` → hardcoded `AppColors` map shipped in binary, or to a small JSON whitelist.

### When to use

- Need to ship in **1-2 days** with zero risk of ugly colors.
- Design team wants brand guardrails.
- As **Phase 1** before full freeform editor (Approach 1).

### Minimal backend

```php
// theme_configs.preset enum: ['default','forest','purple','red','teal','custom']
// config json: {"preset":"forest","overrides":{"primary":"#1B7A4D"}}
```

Validation is trivial: `preset in:default,forest,...` + `overrides` values must be in allowed hex list or match brand palette.

### Flutter

```dart
final presetThemes = {
  'default': ThemeColors(primary:'#1677ff', ...),
  'forest':  ThemeColors(primary:'#1B7A4D', cta:'#F97316', ...),
};
AppThemeConfig resolve(String preset, Map overrides) => presetThemes[preset]!.copyWith(overrides);
```

### Pros / Cons

| Pros | Cons |
|------|------|
| Fastest, safest, no contrast bugs | Limited expressiveness |
| Zero new validation logic | Still needs same fetch/cache plumbing as A1 |
| Good for seasonal campaigns if presets cover them | Custom requests still need code change unless `custom` freed |

> **Recommendation:** Ship A2 as **A1’s subset** — store full config but admin UI initially only exposes preset radio group. Later ungate freeform picker behind `advanced_mode` toggle.

---

## 7. Approach 3 — Firebase Remote Config

### Idea

Store theme JSON as Remote Config parameters: `theme_primary`, `theme_cta`, `theme_background`, … or single `theme_json` string. Admin edits in Firebase Console (or via Admin SDK proxied through Laravel so admin never sees Firebase). App fetches via `firebase_remote_config` SDK; values auto-cache with `minimumFetchInterval`.

### Architecture

```
[Admin Blade/Flutter] --POST /admin/theme--> [Laravel] --Admin SDK--> [Firebase Remote Config]
[Mobile] --fetchAndActivate()--> [Firebase RC SDK] --> cache --> ThemeProvider
```

Laravel acts as proxy so admin auth (`role:admin`) is enforced; Firebase API key is server-side.

### Flutter wiring

```dart
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.setConfigSettings(RemoteConfigSettings(fetchTimeout:10s, minimumFetchInterval: Duration(minutes: 15)));
await remoteConfig.fetchAndActivate();
final primary = remoteConfig.getString('theme_primary'); // '#1677ff'
```

Wrap in `themeProvider` same as A1; RC becomes just another `ThemeService` implementation.

### When to use

- Team already on Firebase (you are — `firebase_core`, `firebase_messaging` present).
- Want **instant rollback** via Firebase Console without backend deploy.
- Want **A/B testing / percentage rollout / per-country** overrides out of the box.

### Pros / Cons

| Pros | Cons |
|------|------|
| Free, globally CDN’d, no backend table | Theme JSON size limit (RC param ≤ 1 KB each; use multiple keys or single JSON ≤ ~10 KB) |
| Built-in targeting, A/B, gradual rollout | Admin Console UX is key-value, not color picker — need custom UI anyway |
| SDK handles caching, throttling, offline | Vendor lock-in, extra SDK; publish latency 5-15 min (or force fetch) |
| No backend migration if proxied incorrectly | Must sync Laravel cache + RC — two sources of truth if not careful |

> **Practical take:** Use RC **as a kill-switch / override layer** on top of A1, not replacement. E.g., `GET /theme` returns DB config, but `Firebase RC` can force `primary` for 10% of users for an experiment. Not needed for MVP.

---

## 8. Approach 4 — CDN-Hosted Theme JSON (S3 / R2 / Cloud Storage)

### Idea

Theme is a **static JSON file** `https://cdn.sportx.in/theme/v{version}.json` (or `theme.json` with versioned `ETag`). Admin “publish” uploads JSON to S3/R2 via Laravel `Storage::disk('s3')->put('theme/theme.json', json)`. App fetches directly from CDN URL (no API hit), ideal for unauthenticated cold start.

### Flow

```
Admin -> POST /admin/theme/publish (JSON) -> Laravel -> Storage::put('theme/theme.json') -> invalidate CloudFront -> cdn.sportx.in/theme/theme.json
App -> GET https://cdn.sportx.in/theme/theme.json (If-None-Match) -> cache -> build ThemeData
```

Laravel still validates and can keep DB history; CDN is just delivery. Or skip DB entirely and treat S3 as source of truth (less auditable).

### Pros / Cons

| Pros | Cons |
|------|------|
| Fastest read (edge cached, no API load) | Extra infra (S3 + CDN + invalidation) |
| Works before auth (splash) | Must handle CORS, CDN cache purge latency |
| Cheap at scale | Two systems to invalidate (DB + CDN) if you keep both |
| Can version as `theme/v12.json` for atomic switch | App must know CDN URL (hardcoded or from `/meta` bootstrap) |

> **Use if:** you already serve assets from CDN and want zero backend read load. Otherwise A1’s `GET /api/v1/theme` with `Cache-Control` + Redis is simpler.

---

## 9. Approach 5 — White-Label / Multi-Tenant + Scheduled Theming

### Extends A1/A4

- Add columns: `tenant_id` (nullable → global), `scheduled_at` (publish at future time via scheduler), `applies_to` JSON (`{"roles":["athlete","sponsor"],"regions":["MH"]}`), `priority`.
- Scheduler job every minute: `ThemeConfig::where('scheduled_at','<=',now())->where('is_published',false)->each->publish()`.
- App sends `X-Tenant` / `region` header or query `?tenant=sportx_pune`; backend resolves `activeFor(tenant, role, region)`.
- Admin UI: calendar picker “Activate on 2026-10-26 00:00 (Diwali theme)”, auto-revert date, preview by tenant.

### Use cases

- “Pune franchise sees maroon theme, Mumbai sees blue.”
- Seasonal skin (IPL orange for 2 weeks, then auto-revert).
- Partner white-label (Decathlon co-brand).

### Complexity

- Medium-high. Start with global theme (A1), add `tenant_id` only when multi-tenant demand is confirmed. Design schema to be forward-compatible (nullable tenant, single active per scope).

---

## 10. Approach 6 — Build-Time / Flavor + OTA (CodePush / Shorebird)

### Idea

Theme baked at **build time** via `--dart-define=PRIMARY=#B91C1C` or flavor `lib/theme/flavors/`. To change without store update, use OTA patching (Shorebird / CodePush) that pushes new Dart code.

### Why not primary

- Not truly admin-controlled at runtime without OTA infra + review.
- Adds binary patching risk, store policy nuance, and still requires release pipeline.
- Useful only as **emergency fallback** if remote fetch is broken (ship a hard-patch via Shorebird).

### When it makes sense

- App must work fully offline, zero network on first launch, and theme must differ by build variant (Play Store vs Enterprise APK).
- Keep one `flavor` for screenshot tests.

---

## 11. Comparison Matrix

| Criterion | A1 DB+API ⭐ | A2 Preset | A3 Firebase RC | A4 CDN JSON | A5 White-Label | A6 OTA |
|-----------|-------------|-----------|----------------|-------------|----------------|--------|
| Admin UX (color picker) | ✅ Full | ⚠️ Limited | ⚠️ Via proxy | ✅ Full | ✅ Full + schedule | ❌ Dev-only |
| Time to MVP | 3-5d | 1-2d | 2-3d | 3-4d | 5-8d | 2d + OTA setup |
| Runtime without update | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ Needs patch |
| Offline support | ✅ Cached | ✅ Cached | ✅ Cached | ✅ Cached | ✅ Cached | ✅ Baked |
| Targeting / A/B | Add later | Add later | ✅ Built-in | Add later | ✅ Per-tenant | ❌ |
| Infra cost | Low | Low | Free (Firebase) | S3+CDN | Low | Shorebird cost |
| Vendor lock-in | None | None | Firebase | Cloud vendor | None | Shorebird |
| Rollback | ✅ Version table | ✅ Version | ✅ RC version | ✅ S3 version | ✅ + schedule | ❌ Patch revert |
| Security | `role:admin` | `role:admin` | Proxy + IAM | Signed URL option | Same | Code signing |
| Recommended for SportX | **YES — Phase 1** | **As Phase 0** | Add-on later | Alternative if CDN exists | Phase 2 | Fallback only |

---

## 12. Recommended Phased Rollout

### Phase 0 — Safety Net (1 day, before A1)

1. Create `AppThemeConfig.fallback()` that mirrors current `AppColors` + `AppTheme.lightTheme`.
2. Add `ThemeMode` + prepaid `ThemeExtension` so every `AppColors.xxx` has a `Theme.of(context)` equivalent.
3. Add `flutter_secure_storage` key `sportx_theme_config_v1` and `ThemeProvider` that today just returns fallback. Wire `MaterialApp(theme: ref.watch(themeProvider).theme)`. No backend yet — proves plumbing.

### Phase 1 — Preset + DB (2-3 days)

4. Backend: migration `theme_configs`, model, `AdminThemeController`, routes in `routes/api.php:278` group, cache.
5. Flutter: `ThemeService.fetchRemote`, `theme_provider.dart`, `main.dart` warm-up, admin `ThemeEditorScreen` with **preset radio + hex overrides for primary/cta only**.
6. QA + publish one preset to prod. Verify 304/ETag, offline cache, kill-switch (publish fallback).

### Phase 2 — Full Token Editor (2-3 days)

7. Expand JSON to full `DesignTokens` (see Appendix B): all colors, `typography.fontFamily`, `shape.*`, `spacing.*`.
8. Admin editor: full color grid + contrast badge + live preview cards (button, input, card, chip, nav).
9. Add dark palette side-by-side, `ThemeMode` toggle in app settings (`SettingsController` already supports `language`; add `theme_mode`).
10. Add audit history + rollback UI.

### Phase 3 — Power Features (when needed)

11. Scheduled activation (`scheduled_at` + scheduler job).
12. Per-tenant / per-region scoping.
13. FCM silent push `data: {type:"theme.updated", version:14}` → app `onMessage` triggers `ref.read(themeProvider.notifier).refresh()`.
14. Optional Firebase RC layer for A/B experiments.

---

## 13. Shared Implementation Details

### 13.1 Refactor Strategy for 100+ `AppColors` Usages

Do **not** bulk-replace all at once. Codemod approach:

1. Keep `AppColors` as `@deprecated` shim that delegates to `ThemeConfig` for backward compat during migration:
   ```dart
   class AppColors {
     static Color get primary => _config?.colors.primary ?? const Color(0xFF1677ff);
     static AppThemeConfig? _config; // set by ThemeProvider
   }
   ```
   Or better: leave `AppColors` untouched and migrate files opportunistically to `Theme.of(context).colorScheme.primary` / `Theme.of(context).extension<SportXColors>()!.cta`.

2. Add `SportXThemeExtension extends ThemeExtension<SportXThemeExtension>`:
   ```dart
   class SportXThemeExtension extends ThemeExtension<SportXThemeExtension> {
     final Color cta, ctaLight, ctaDark, sportBadgeBg, verifiedBadge, mandatoryIndicator;
     final Color successLight, infoLight;
     // lerp, copyWith
   }
   ```

3. Lint rule: `avoid_using_app_colors_directly` (custom_lint) to nudge new code toward `Theme.of`.

### 13.2 Splash / First-Frame Flash

Fetch theme **before** `runApp` to avoid white flash with wrong colors:

```dart
WidgetsFlutterBinding.ensureInitialized();
final container = ProviderContainer();
await container.read(themeConfigProvider.notifier).warmUp(); // reads SecureStorage in <50ms, then async refresh
runApp(UncontrolledProviderScope(container: container, child: const SportXApp()));
```

If warmUp is slow, show `SplashScreen` with fallback colors; swap when remote arrives via `ref.listen`.

### 13.3 Error Handling

```dart
try { remote = await service.fetchRemote(); }
on DioException catch(e) {
  if(e.response?.statusCode==304) return; // not modified
  // keep cached, log to Sentry
}
catch(e) { /* malformed JSON -> keep cached, report */ }
```

Backend must never return 500 for theme — return fallback default with `meta.fallback=true` if DB empty.

### 13.4 Testing

- Unit: `ThemeConfig.fromJson` rejects bad hex, `AppThemeConfig.fallback().toThemeData()` golden.
- Widget: pump with `ProviderScope(overrides:[themeConfigProvider.overrideWithValue(AsyncData(redConfig))])` assert button color.
- Integration: Laravel Pest test `GET /api/v1/theme returns 304 when If-None-Match matches`.
- Manual: change primary to `#B91C1C`, publish, kill app, relaunch, verify without reinstall.

---

## 14. Testing & QA Checklist

- [ ] Cold start with no cache → fallback renders, then remote overwrites without crash.
- [ ] Airplane mode → cached theme renders.
- [ ] Corrupt `SecureStorage` JSON → fallback + re-fetch on next online.
- [ ] Publish new primary → app reflects within 5 min (or on FCM / resume).
- [ ] 304 path → no overwrite, no flicker.
- [ ] Contrast warning shows when admin picks low-contrast pair.
- [ ] Old app version (before new `mandatoryIndicator` key) still renders — new keys optional with fallback.
- [ ] Admin RBAC: non-admin `POST /admin/theme` → 403.
- [ ] Rollback: publish v3, rollback to v1 → v4 created as copy of v1, active = v4.
- [ ] Dark mode: toggle `ThemeMode.dark` uses dark palette, not just `ColorScheme.dark()`.

---

## 15. Operational Runbook

1. **Change color:** Admin → `/admin/theme` → pick colors → Save Draft → Preview → Publish → verify on device (pull-to-refresh or wait 5 min).
2. **Emergency revert:** `/admin/theme` → History → Restore previous version → Publish (or `POST /admin/theme/{id}/rollback`).
3. **Scheduled campaign:** Set `scheduled_at` → cron publishes automatically; set revert date as second scheduled entry.
4. **Incident (bad theme breaks contrast):** Backend admin can `PUT /admin/theme/validate` dry-run; if already published, one-click rollback. If CDN variant, purge `theme.json`.
5. **Monitoring:** Alert if `GET /api/v1/theme` 5xx > 1% or p95 > 500ms; log `theme.version` distribution to know rollout %.

---

## 16. File Change Inventory

### New — Backend (`sportx-api/`)

```
database/migrations/2026_09_12_000001_create_theme_configs_table.php
app/Models/ThemeConfig.php
app/Models/ThemeConfigHistory.php
app/Http/Controllers/ThemeController.php              # public GET /theme
app/Http/Controllers/Admin/AdminThemeController.php   # admin CRUD + publish
app/Http/Requests/ThemeConfigRequest.php              # validation + hex + contrast
tests/Feature/ThemeConfigTest.php
routes/api.php                                         # add 8 routes (see §5.3)
config/cache.php                                       # ensure theme cache tag
```

### New — Flutter (`sportx_app/`)

```
lib/theme/app_theme_config.dart        # AppThemeConfig, ThemeColors, Typography, Shape
lib/theme/sportx_theme_extension.dart  # ThemeExtension for cta/successLight etc
lib/theme/theme_provider.dart          # StateNotifier<AsyncValue<AppThemeConfig>>
lib/core/services/theme_service.dart   # Dio wrapper for GET /theme
lib/features/admin/presentation/screens/theme_editor_screen.dart
lib/features/admin/presentation/widgets/color_picker_field.dart
lib/features/admin/presentation/widgets/theme_preview_card.dart
```

### Modified

```
lib/theme/colors.dart                  # keep as fallback, add @deprecated or delegate
lib/theme/app_theme.dart               # add ThemeData fromConfig(AppThemeConfig) factory
lib/theme/design_tokens.dart           # expand to mirror JSON tokens (or deprecate)
lib/core/utils/storage_service.dart    # add sportx_theme_config_v1 key
lib/main.dart                          # hydrate theme before runApp + watch provider
lib/features/admin/presentation/providers/admin_provider.dart  # theme CRUD methods
lib/features/admin/presentation/screens/admin_dashboard_screen.dart # add Theme quick-action
pubspec.yaml                           # optional: flutter_colorpicker, flex_color_scheme
```

---

## Appendix A — Current Hardcoded Values to Replace

From `sportx_app/lib/theme/colors.dart:4-34`:

```
primary        #1677ff
cta            #F97316
background     #ffffff
surface        #f7f8fa
cardBackground #f7f8fa (duplicate)
textPrimary    #111111
textSecondary  #6b7280
textTertiary   #9CA3AF
border         #d9dee7
success        #22C55E
successLight   #DCFCE7
error          #ef4444
warning        #f59e0b
info           #1677ff (same as primary)
infoLight      #EFF6FF
primaryLight   #93C5FD
primaryDark    #1D4ED8
primaryDarker  #1E40AF
ctaDark        #EA6C0A
ctaLight       #FED7AA
sportBadgeBg   #EFF6FF
verifiedBadge  #22C55E
mandatoryIndicator #EF4444
```

From `app_theme.dart` (hardcoded in ThemeData):
- `fontFamily: 'Inter'` + `GoogleFonts.inter`
- radii: `16` (Card), `12` (Button/Input), `20` (Chip), `10` (SnackBar)
- spacing in `MainShell` + screens: ad-hoc `16,12,8`
- `AppBar.backgroundColor = AppColors.background`, `NavigationBar.indicatorColor = primary.withAlpha(0.15)`

All of the above should become tokens in the remote JSON, with the current values as `fallback()`.

---

## Appendix B — Example Theme JSON Schema

```json
{
  "version": 14,
  "name": "Diwali 2026",
  "updated_at": "2026-09-12T10:30:00Z",
  "colors": {
    "primary": "#B91C1C",
    "primaryLight": "#FCA5A5",
    "primaryDark": "#7F1D1D",
    "primaryDarker": "#450A0A",
    "cta": "#F97316",
    "ctaLight": "#FED7AA",
    "ctaDark": "#EA6C0A",
    "background": "#ffffff",
    "surface": "#f7f8fa",
    "textPrimary": "#111111",
    "textSecondary": "#6b7280",
    "textTertiary": "#9CA3AF",
    "border": "#d9dee7",
    "success": "#22C55E",
    "successLight": "#DCFCE7",
    "error": "#ef4444",
    "warning": "#f59e0b",
    "info": "#1677ff",
    "infoLight": "#EFF6FF",
    "sportBadgeBg": "#EFF6FF",
    "verifiedBadge": "#22C55E",
    "mandatoryIndicator": "#EF4444"
  },
  "colors_dark": {
    "primary": "#60A5FA",
    "background": "#0F172A",
    "surface": "#1E293B",
    "textPrimary": "#F8FAFC",
    "textSecondary": "#94A3B8",
    "border": "#334155"
  },
  "typography": {
    "fontFamily": "Poppins",
    "scale": 1.0,
    "weights": { "regular": 400, "semiBold": 600, "bold": 700 }
  },
  "shape": {
    "cardRadius": 16,
    "buttonRadius": 12,
    "inputRadius": 12,
    "chipRadius": 20,
    "snackBarRadius": 10
  },
  "spacing": {
    "xs": 4, "sm": 8, "md": 12, "lg": 16, "xl": 20, "2xl": 24, "3xl": 32
  },
  "components": {
    "appBar": { "elevation": 0, "centerTitle": false },
    "navigationBar": { "indicatorAlpha": 0.15 }
  },
  "assets": {
    "logoUrl": "https://cdn.sportx.in/assets/logo-diwali.png",
    "splashBackground": "#FFF7ED"
  }
}
```

**JSON Schema (Laravel validation):**

```php
'colors' => 'required|array',
'colors.primary' => 'required|regex:/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/',
'colors.background' => 'required|regex:/^#...$/',
// ... same for each required key
'typography.fontFamily' => 'required|in:Poppins,Inter,Roboto',
'shape.cardRadius' => 'required|numeric|min:0|max:32',
```

Unknown keys: reject in strict mode or ignore with warning — decide and document.

---

## Appendix C — Minimal Admin UI Wireframe

```
┌─ Admin → Theme ────────────────────────────────────────────────┐
│  [Presets: ● Default ○ Forest ○ Purple ○ Red ○ Teal ○ Custom] │
│                                                                │
│  Colors                                    Live Preview        │
│  ┌─────────────────────┐   ┌──────────────────────────────┐   │
│  │ Primary   [#1677ff] │   │  [Card]  [Button Primary]   │   │
│  │ CTA       [#F97316] │   │  [Input] [Chip] [Badge ✓]   │   │
│  │ Background[#ffffff] │   │  Aa Poppins 16px TextPrimary│   │
│  │ Surface   [#f7f8fa] │   │  Nav: ○ Home ● Search      │   │
│  │ Text Prim [#111111] │   └──────────────────────────────┘   │
│  │ Border    [#d9dee7] │   Contrast: ✅ 8.2:1 (AA)         │
│  │ ... expand all      │                                    │
│  └─────────────────────┘                                    │
│  Shape  Card [16]  Button [12]  Input [12]                    │
│  Font   [Poppins ▼]                                           │
│                                                                │
│  [Save Draft]  [Publish]  History: v14 active · v13 · v12 …  │
│  Raw JSON ▸ { "colors": { ... } }                            │
└────────────────────────────────────────────────────────────────┘
```

Figma reference: mirror `AdminWebLayout` from `docs/Admin-Panel-Implementation-Prompt.md:51-72` (sidebar 256px, topbar 64px, content max-w-5xl).

---

## TL;DR Recommendation for SportX

1. **Do Approach 1** (DB + `GET /api/v1/theme` + Riverpod + SecureStorage). It is the simplest, cheapest, and fully admin-controlled.
2. **Start with Approach 2’s UI** (preset picker) on top of Approach 1’s plumbing — ship in 2 days, ungate freeform later.
3. Add **FCM push + ETag** for near-instant propagation.
4. Keep **Blade vs Flutter admin** interchangeable — same API serves both.
5. Version everything; never mutate active row in place — append new version and flip `is_active`.

> **Next step:** Create migration + `AdminThemeController` + `theme_provider.dart` as per §5, then replace `MaterialApp.router(theme: AppTheme.lightTheme)` with `theme: ref.watch(themeConfigProvider).valueOrNull?.toThemeData() ?? AppTheme.lightTheme` — you’ll have dynamic theming behind a feature flag in one PR.

---

*End of document — generated from full codebase audit of `sportx_app/lib/theme/*`, `lib/main.dart`, `lib/core/**`, `sportx-api/routes/api.php`, `app/Http/Controllers/Admin/*`, `database/migrations/*`, and `docs/Mobile-Architecture.md`.*
