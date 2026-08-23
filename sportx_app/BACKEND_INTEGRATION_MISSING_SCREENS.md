# SportX Backend Integration - Missing Screens

This document specifies backend API endpoints needed for screens that are missing or incomplete in the Flutter app.

---

## MISSING SCREENS - API REQUIREMENTS

### 1. ATHLETE: Sponsorship List (`athlete/sponsorship-list.html`)

**Purpose:** Athlete views their sponsorship applications and statuses

**Missing Endpoint:** `GET /api/v1/me/applications`

**Status:** EXISTS in `SponsorEngagementController::myApplications()` (line 147-166)

**Current Implementation:** `shortlist_screen.dart` shows sponsor's shortlist, NOT athlete's applications

**Fix Required:** Create `athlete_sponsorships_screen.dart` that calls `GET /api/v1/me/applications`

**Response Model:**
```json
{
  "data": [
    {
      "id": 1,
      "sponsorship_id": 1,
      "athlete_id": 1,
      "pitch_note": "I am a promising athlete...",
      "status": "pending|reviewed|shortlisted|rejected",
      "replied_at": "2026-08-20T10:00:00Z",
      "created_at": "2026-08-15T10:00:00Z",
      "sponsorship": {
        "id": 1,
        "title": "XYZ Sports Scholarship",
        "sport": { "id": 1, "name": "Football" },
        "logo_url": "https://...",
        "deadline": "2026-09-01T00:00:00Z",
        "status": "published"
      }
    }
  ],
  "meta": {
    "pagination": {
      "total": 5,
      "per_page": 20,
      "current_page": 1,
      "last_page": 1
    }
  }
}
```

---

### 2. ATHLETE: Sponsorship Detail (`athlete/sponsorship-detail.html`)

**Purpose:** Athlete views details of a specific sponsorship application

**Missing Endpoint:** `GET /api/v1/me/applications/{id}`

**Implementation Required:**
```php
// Add to SponsorEngagementController
public function showApplication(Request $request, SponsorshipApplication $application)
{
    $athlete = $request->user()->athleteProfile;
    abort_unless($athlete && $application->athlete_id === $athlete->id, 403);

    return response()->json([
        'data' => $application->load(['sponsorship.sport', 'sponsorship.logo'])
    ]);
}
```

**Route Addition:**
```php
Route::get('/me/applications/{application}', [SponsorEngagementController::class, 'showApplication'])
    ->middleware(['auth:sanctum', 'role:athlete']);
```

**Response Model:**
```json
{
  "data": {
    "id": 1,
    "sponsorship_id": 1,
    "athlete_id": 1,
    "pitch_note": "I am a promising athlete...",
    "status": "shortlisted",
    "replied_at": "2026-08-20T10:00:00Z",
    "created_at": "2026-08-15T10:00:00Z",
    "sponsorship": {
      "id": 1,
      "title": "XYZ Sports Scholarship",
      "description": "...",
      "sport": { "id": 1, "name": "Football" },
      "logo_url": "https://...",
      "deadline": "2026-09-01T00:00:00Z",
      "eligibility": "Age 15-20, State level",
      "benefits": "Financial support up to 50,000",
      "amount": 50000,
      "status": "published"
    }
  }
}
```

---

### 3. ORGANIZER: Tournament Calendar (`tournament-calendar.html`)

**Purpose:** Calendar view of tournaments with date-based filtering

**Missing Endpoint:** `GET /api/v1/tournaments/calendar`

**Implementation Required:** New controller method

```php
// Add to TournamentController
public function calendar(Request $request)
{
    $validated = $request->validate([
        'year' => 'nullable|integer|min:2020|max:2100',
        'month' => 'nullable|integer|min:1|max:12',
        'sport_id' => 'nullable|integer|exists:sports,id',
        'city_id' => 'nullable|integer|exists:cities,id',
    ]);

    $year = $validated['year'] ?? now()->year;
    $month = $validated['month'] ?? now()->month;

    $startDate = Carbon::create($year, $month, 1)->startOfMonth();
    $endDate = $startDate->copy()->endOfMonth();

    $query = Tournament::where('start_date', '>=', $startDate)
        ->where('end_date', '<=', $endDate)
        ->where('status', 'published');

    if (!empty($validated['sport_id'])) {
        $query->where('sport_id', $validated['sport_id']);
    }
    if (!empty($validated['city_id'])) {
        $query->where('city_id', $validated['city_id']);
    }

    $tournaments = $query->with(['sport', 'city'])
        ->orderBy('start_date')
        ->get();

    // Group by date
    $grouped = $tournaments->groupBy(function($t) {
        return $t->start_date->format('Y-m-d');
    });

    return response()->json([
        'data' => $grouped,
        'meta' => [
            'year' => $year,
            'month' => $month,
            'tournament_count' => $tournaments->count()
        ]
    ]);
}
```

**Route Addition:**
```php
Route::get('/tournaments/calendar', [TournamentController::class, 'calendar']);
```

**Response Model:**
```json
{
  "data": {
    "2026-08-15": [
      {
        "id": 1,
        "title": "State Championship",
        "sport": { "id": 1, "name": "Football" },
        "city": { "id": 1, "name": "Mumbai" },
        "start_date": "2026-08-15",
        "end_date": "2026-08-20",
        "registration_deadline": "2026-08-10"
      }
    ]
  },
  "meta": {
    "year": 2026,
    "month": 8,
    "tournament_count": 12
  }
}
```

---

### 4. ADMIN: Analytics Dashboard (`admin/admin-analytics.html`)

**Purpose:** Admin views platform analytics and statistics

**Missing Endpoint:** `GET /api/v1/admin/analytics`

**Implementation Required:** New controller `AdminAnalyticsController`

```php
<?php

namespace App\Http\Controllers\Admin;

use App\Models\User;
use App\Models\Tournament;
use App\Models\Trial;
use App\Models\Sponsorship;
use App\Models\Registration;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminAnalyticsController extends Controller
{
    public function index(Request $request)
    {
        $validated = $request->validate([
            'period' => 'nullable|in:7d,30d,90d,365d',
        ]);

        $period = $validated['period'] ?? '30d';
        $days = match($period) {
            '7d' => 7,
            '30d' => 30,
            '90d' => 90,
            '365d' => 365,
        };

        $startDate = now()->subDays($days);

        // User growth
        $userGrowth = User::selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->where('created_at', '>=', $startDate)
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Users by role
        $usersByRole = User::selectRaw('role, COUNT(*) as count')
            ->where('created_at', '>=', $startDate)
            ->groupBy('role')
            ->get();

        // Listings by type
        $listings = [
            'tournaments' => Tournament::where('created_at', '>=', $startDate)->count(),
            'trials' => Trial::where('created_at', '>=', $startDate)->count(),
            'sponsorships' => Sponsorship::where('created_at', '>=', $startDate)->count(),
        ];

        // Registrations
        $registrations = Registration::where('created_at', '>=', $startDate)->count();

        // Active listings (published status)
        $activeListings = [
            'tournaments' => Tournament::where('status', 'published')->count(),
            'trials' => Trial::where('status', 'published')->count(),
            'sponsorships' => Sponsorship::where('status', 'published')->count(),
        ];

        // Top sports
        $topSports = DB::table('tournaments')
            ->join('sports', 'tournaments.sport_id', '=', 'sports.id')
            ->selectRaw('sports.name, COUNT(*) as tournament_count')
            ->where('tournaments.created_at', '>=', $startDate)
            ->groupBy('sports.name')
            ->orderByDesc('tournament_count')
            ->limit(5)
            ->get();

        // Top cities
        $topCities = DB::table('tournaments')
            ->join('cities', 'tournaments.city_id', '=', 'cities.id')
            ->selectRaw('cities.name, COUNT(*) as tournament_count')
            ->where('tournaments.created_at', '>=', $startDate)
            ->groupBy('cities.name')
            ->orderByDesc('tournament_count')
            ->limit(5)
            ->get();

        // Engagement metrics
        $engagement = [
            'total_registrations' => Registration::count(),
            'registrations_this_period' => Registration::where('created_at', '>=', $startDate)->count(),
            'total_saved_items' => DB::table('saved_items')->count(),
            'total_enquiries' => DB::table('enquiries')->count(),
        ];

        return response()->json([
            'data' => [
                'user_growth' => $userGrowth,
                'users_by_role' => $usersByRole,
                'listings' => $listings,
                'active_listings' => $activeListings,
                'registrations' => $registrations,
                'top_sports' => $topSports,
                'top_cities' => $topCities,
                'engagement' => $engagement,
            ],
            'meta' => [
                'period' => $period,
                'days' => $days,
                'start_date' => $startDate->toDateString(),
                'end_date' => now()->toDateString(),
            ]
        ]);
    }

    public function userAnalytics(Request $request)
    {
        $validated = $request->validate([
            'role' => 'nullable|in:athlete,coach,academy,organizer,sponsor',
        ]);

        $query = User::query();

        if (!empty($validated['role'])) {
            $query->where('role', $validated['role']);
        }

        $users = $query->selectRaw('
            COUNT(*) as total,
            SUM(CASE WHEN created_at >= ? THEN 1 ELSE 0 END) as new_this_month,
            SUM(CASE WHEN status = "suspended" THEN 1 ELSE 0 END) as suspended
        ', [now()->startOfMonth()])->first();

        return response()->json(['data' => $users]);
    }

    public function contentAnalytics(Request $request)
    {
        $startDate = now()->subDays(30);

        return response()->json([
            'data' => [
                'posts' => [
                    'total' => DB::table('posts')->count(),
                    'this_month' => DB::table('posts')->where('created_at', '>=', $startDate)->count(),
                ],
                'comments' => [
                    'total' => DB::table('comments')->count(),
                    'this_month' => DB::table('comments')->where('created_at', '>=', $startDate)->count(),
                ],
                'reports' => [
                    'total' => DB::table('reports')->count(),
                    'pending' => DB::table('reports')->where('status', 'pending')->count(),
                    'this_month' => DB::table('reports')->where('created_at', '>=', $startDate)->count(),
                ],
            ]
        ]);
    }
}
```

**Route Addition:**
```php
Route::get('/analytics', [AdminAnalyticsController::class, 'index']);
Route::get('/analytics/users', [AdminAnalyticsController::class, 'userAnalytics']);
Route::get('/analytics/content', [AdminAnalyticsController::class, 'contentAnalytics']);
```

**Response Model:**
```json
{
  "data": {
    "user_growth": [
      { "date": "2026-08-01", "count": 45 },
      { "date": "2026-08-02", "count": 52 }
    ],
    "users_by_role": [
      { "role": "athlete", "count": 1200 },
      { "role": "coach", "count": 340 }
    ],
    "listings": {
      "tournaments": 45,
      "trials": 32,
      "sponsorships": 18
    },
    "active_listings": {
      "tournaments": 120,
      "trials": 85,
      "sponsorships": 42
    },
    "registrations": 1560,
    "top_sports": [
      { "name": "Football", "tournament_count": 45 },
      { "name": "Cricket", "tournament_count": 38 }
    ],
    "top_cities": [
      { "name": "Mumbai", "tournament_count": 52 },
      { "name": "Delhi", "tournament_count": 48 }
    ],
    "engagement": {
      "total_registrations": 15600,
      "registrations_this_period": 1560,
      "total_saved_items": 8900,
      "total_enquiries": 2340
    }
  },
  "meta": {
    "period": "30d",
    "days": 30,
    "start_date": "2026-07-23",
    "end_date": "2026-08-22"
  }
}
```

---

### 5. ADMIN: System Settings (`admin/admin-system-settings.html`)

**Purpose:** Admin configures platform-wide settings

**Missing Endpoints:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/settings` | Get all settings |
| PUT | `/api/v1/admin/settings` | Update settings |
| GET | `/api/v1/admin/settings/maintenance` | Get maintenance mode |
| PUT | `/api/v1/admin/settings/maintenance` | Toggle maintenance mode |

**Implementation Required:** New controller `AdminSettingsController`

```php
<?php

namespace App\Http\Controllers\Admin;

use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class AdminSettingsController extends Controller
{
    public function index()
    {
        $settings = Setting::all()->groupBy('group');

        return response()->json([
            'data' => $settings,
        ]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'settings' => 'required|array',
            'settings.*' => 'nullable|string',
        ]);

        foreach ($validated['settings'] as $key => $value) {
            Setting::updateOrCreate(
                ['key' => $key],
                ['value' => $value, 'group' => $this->detectGroup($key)]
            );
        }

        // Clear cache
        Cache::forget('app_settings');

        return response()->json(['message' => 'Settings updated']);
    }

    public function getMaintenanceMode()
    {
        $enabled = Cache::get('maintenance_mode', false);
        $message = Setting::where('key', 'maintenance_message')->value('value') ?? 'System under maintenance';

        return response()->json([
            'data' => [
                'enabled' => $enabled,
                'message' => $message,
            ]
        ]);
    }

    public function toggleMaintenanceMode(Request $request)
    {
        $validated = $request->validate([
            'enabled' => 'required|boolean',
            'message' => 'nullable|string|max:500',
        ]);

        Cache::put('maintenance_mode', $validated['enabled'], now()->addDays(30));

        if (!empty($validated['message'])) {
            Setting::updateOrCreate(
                ['key' => 'maintenance_message'],
                ['value' => $validated['message'], 'group' => 'system']
            );
        }

        return response()->json([
            'data' => [
                'enabled' => $validated['enabled'],
                'message' => $validated['message'] ?? null,
            ]
        ]);
    }

    private function detectGroup(string $key): string
    {
        $groups = [
            'general' => ['app_name', 'app_url', 'support_email', 'support_phone'],
            'registration' => ['allow_registration', 'require_email_verification', 'require_admin_approval'],
            'listing' => ['auto_approve_listings', 'listing_expiry_days', 'max_listing_per_user'],
            'notification' => ['email_notifications', 'push_notifications'],
            'security' => ['max_login_attempts', 'session_timeout', '2fa_required'],
        ];

        foreach ($groups as $group => $keys) {
            if (in_array($key, $keys)) return $group;
        }
        return 'general';
    }
}
```

**Database Migration:**
```php
Schema::create('settings', function (Blueprint $table) {
    $table->id();
    $table->string('key')->unique();
    $table->text('value')->nullable();
    $table->string('group')->default('general');
    $table->timestamps();
});
```

**Routes:**
```php
Route::get('/settings', [AdminSettingsController::class, 'index']);
Route::put('/settings', [AdminSettingsController::class, 'update']);
Route::get('/settings/maintenance', [AdminSettingsController::class, 'getMaintenanceMode']);
Route::put('/settings/maintenance', [AdminSettingsController::class, 'toggleMaintenanceMode']);
```

---

### 6. ADMIN: Content Flagging (`admin/admin-content-flagging.html`)

**Purpose:** Admin moderates flagged content

**Status:** Partially implemented in `ModerationQueueScreen`, needs proper API

**Missing Endpoints:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/moderation/flags` | Get all flagged content |
| GET | `/api/v1/admin/moderation/flags/{id}` | Get flag details |
| POST | `/api/v1/admin/moderation/flags/{id}/dismiss` | Dismiss flag |
| POST | `/api/v1/admin/moderation/flags/{id}/content-remove` | Remove content |

**Implementation Required:**

```php
// Add to AdminModerationController
public function flags(Request $request)
{
    $validated = $request->validate([
        'status' => 'nullable|in:pending,reviewed,dismissed',
        'type' => 'nullable|in:post,comment,profile,listing',
    ]);

    $query = DB::table('content_flags')
        ->join('users as reporter', 'content_flags.user_id', '=', 'reporter.id')
        ->select('content_flags.*', 'reporter.name as reporter_name');

    if (!empty($validated['status'])) {
        $query->where('content_flags.status', $validated['status']);
    }
    if (!empty($validated['type'])) {
        $query->where('content_flags.content_type', $validated['type']);
    }

    $flags = $query->orderByDesc('created_at')->paginate(20);

    return response()->json(['data' => $flags->items(), 'meta' => ['pagination' => $flags]]);
}

public function showFlag(ContentFlag $flag)
{
    $flag->load(['reporter', 'content', 'content.author']);
    return response()->json(['data' => $flag]);
}

public function dismissFlag(Request $request, ContentFlag $flag)
{
    $flag->update(['status' => 'dismissed']);

    return response()->json(['data' => $flag]);
}

public function removeContent(Request $request, ContentFlag $flag)
{
    $flag->update(['status' => 'content_removed']);

    // Remove the actual content
    match($flag->content_type) {
        'post' => Post::destroy($flag->content_id),
        'comment' => Comment::destroy($flag->content_id),
        default => null,
    };

    return response()->json(['data' => $flag]);
}
```

---

### 7. ADMIN: Listing Moderation (`admin/admin-listing-moderation.html`)

**Purpose:** Admin approves/rejects listings (trials, tournaments, sponsorships)

**Status:** Partially covered by `pending_approvals_screen.dart`

**Missing Endpoints:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/listings/pending` | Get pending listings |
| GET | `/api/v1/admin/listings/{type}/{id}` | Get listing details |
| POST | `/api/v1/admin/listings/{type}/{id}/approve` | Approve listing |
| POST | `/api/v1/admin/listings/{type}/{id}/reject` | Reject listing |

**Implementation Required:**

```php
// Add to AdminModerationController
public function pendingListings(Request $request)
{
    $validated = $request->validate([
        'type' => 'nullable|in:trial,tournament,sponsorship',
        'status' => 'nullable|in:pending,approved,rejected',
    ]);

    $results = [];

    // Get trials
    if (empty($validated['type']) || $validated['type'] === 'trial') {
        $trials = Trial::with(['sport', 'provider'])
            ->where('status', $validated['status'] ?? 'pending')
            ->get()
            ->map(fn($t) => array_merge($t->toArray(), ['listing_type' => 'trial']));
        $results = array_merge($results, $trials->toArray());
    }

    // Get tournaments
    if (empty($validated['type']) || $validated['type'] === 'tournament') {
        $tournaments = Tournament::with(['sport', 'organizer'])
            ->where('status', $validated['status'] ?? 'pending')
            ->get()
            ->map(fn($t) => array_merge($t->toArray(), ['listing_type' => 'tournament']));
        $results = array_merge($results, $tournaments->toArray());
    }

    // Get sponsorships
    if (empty($validated['type']) || $validated['type'] === 'sponsorship') {
        $sponsorships = Sponsorship::with(['sport', 'sponsor'])
            ->where('status', $validated['status'] ?? 'pending')
            ->get()
            ->map(fn($s) => array_merge($s->toArray(), ['listing_type' => 'sponsorship']));
        $results = array_merge($results, $sponsorships->toArray());
    }

    return response()->json(['data' => $results]);
}

public function approveListing(Request $request, string $type, int $id)
{
    match($type) {
        'trial' => Trial::findOrFail($id)->update(['status' => 'published']),
        'tournament' => Tournament::findOrFail($id)->update(['status' => 'published']),
        'sponsorship' => Sponsorship::findOrFail($id)->update(['status' => 'published']),
    };

    return response()->json(['message' => 'Listing approved']);
}

public function rejectListing(Request $request, string $type, int $id)
{
    $validated = $request->validate(['reason' => 'nullable|string']);

    match($type) {
        'trial' => Trial::findOrFail($id)->update(['status' => 'rejected', 'rejection_reason' => $validated['reason']]),
        'tournament' => Tournament::findOrFail($id)->update(['status' => 'rejected', 'rejection_reason' => $validated['reason']]),
        'sponsorship' => Sponsorship::findOrFail($id)->update(['status' => 'rejected', 'rejection_reason' => $validated['reason']]),
    };

    return response()->json(['message' => 'Listing rejected']);
}
```

---

### 8. ADMIN: Notification Templates (`admin/admin-notification-templates.html`)

**Purpose:** Admin manages notification templates

**Missing Endpoints:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/notifications/templates` | List templates |
| GET | `/api/v1/admin/notifications/templates/{id}` | Get template |
| POST | `/api/v1/admin/notifications/templates` | Create template |
| PUT | `/api/v1/admin/notifications/templates/{id}` | Update template |
| DELETE | `/api/v1/admin/notifications/templates/{id}` | Delete template |
| POST | `/api/v1/admin/notifications/templates/{id}/send` | Send test notification |

**Implementation Required:** New controller `AdminNotificationTemplateController`

---

### 9. ADMIN: Sport Category Management (`admin/admin-sport-category-management.html`)

**Purpose:** Admin manages sports categories

**Status:** Partially covered by existing category endpoints

**Missing Enhancement:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/categories/sports/with-counts` | Get sports with listing counts |
| PUT | `/api/v1/admin/categories/sports/reorder` | Reorder sports |

---

## SUMMARY TABLE

| Screen | Missing Endpoints | Priority | Effort |
|--------|------------------|----------|--------|
| Athlete Sponsorship List | `GET /me/applications` | HIGH | 1 hr |
| Athlete Sponsorship Detail | `GET /me/applications/{id}` | HIGH | 1 hr |
| Tournament Calendar | `GET /tournaments/calendar` | MEDIUM | 2 hrs |
| Admin Analytics | `GET /admin/analytics` | HIGH | 4 hrs |
| Admin System Settings | CRUD `/admin/settings` | MEDIUM | 3 hrs |
| Admin Content Flagging | CRUD `/admin/moderation/flags` | MEDIUM | 3 hrs |
| Admin Listing Moderation | CRUD `/admin/listings` | MEDIUM | 3 hrs |
| Admin Notification Templates | CRUD `/admin/notifications/templates` | LOW | 2 hrs |
| Admin Sport Categories | Enhanced `/admin/categories` | LOW | 1 hr |

---

## FLUTTER SIDE IMPLEMENTATION

### New Providers Needed

```dart
// athlete_sponsorships_provider.dart
final athleteSponsorshipsProvider = StateNotifierProvider<AthleteSponsorshipsNotifier, AthleteSponsorshipsState>

class AthleteSponsorshipsState {
  final List<SponsorshipApplication> applications;
  final bool isLoading;
  final String? error;
}

class AthleteSponsorshipsNotifier {
  Future<void> loadApplications();
  Future<SponsorshipApplication?> getApplication(String id);
}
```

### New Screens Needed

| Screen | File | Provider |
|--------|------|----------|
| Athlete Sponsorship List | `athlete_sponsorships_screen.dart` | `athleteSponsorshipsProvider` |
| Athlete Sponsorship Detail | `athlete_sponsorship_detail_screen.dart` | `athleteSponsorshipsProvider` |
| Tournament Calendar | `tournament_calendar_screen.dart` | `tournamentProvider` |
| Admin Analytics | `admin_analytics_screen.dart` | `adminAnalyticsProvider` |
| Admin System Settings | `admin_system_settings_screen.dart` | `adminSettingsProvider` |
| Admin Content Flags | `admin_content_flags_screen.dart` | `adminModerationProvider` |
| Admin Listing Moderation | `admin_listing_moderation_screen.dart` | `adminModerationProvider` |
| Admin Notification Templates | `admin_notification_templates_screen.dart` | `adminNotificationProvider` |
| Admin Sport Categories | `admin_sport_categories_screen.dart` | `adminCategoryProvider` |

---

## API CLIENT ADDITIONS

```dart
// Add to api_client.dart

// Athlete Sponsorships
Future<ApiResponse<List<SponsorshipApplication>>> getMyApplications()
Future<ApiResponse<SponsorshipApplication>> getApplication(String id)

// Tournament Calendar
Future<ApiResponse<Map<String, List<Tournament>>>> getTournamentCalendar({
  int? year, int? month, int? sportId, int? cityId
})

// Admin Analytics
Future<ApiResponse<AdminAnalytics>> getAdminAnalytics({String period = '30d'})
Future<ApiResponse<UserAnalytics>> getUserAnalytics({String? role})
Future<ApiResponse<ContentAnalytics>> getContentAnalytics()

// Admin Settings
Future<ApiResponse<Map<String, Setting>>> getAdminSettings()
Future<ApiResponse<void>> updateAdminSettings(Map<String, String> settings)
Future<ApiResponse<MaintenanceMode>> getMaintenanceMode()
Future<ApiResponse<void>> toggleMaintenanceMode(bool enabled, String? message)

// Admin Moderation
Future<ApiResponse<List<ContentFlag>>> getFlaggedContent({String? status, String? type})
Future<ApiResponse<void>> dismissFlag(String id)
Future<ApiResponse<void>> removeFlaggedContent(String id)
```
