# Talent Scout Feature — AI Implementation Guide

This document provides step-by-step instructions for implementing the **Talent Scout** role in SportX India. It covers all changes required across Flutter frontend, Laravel backend, database, and API.

---

## Overview

Talent Scout is the **6th role** in the platform (alongside Athlete/Parent, Coach, Academy, Organizer, Sponsor/Brand). Talent Scouts discover athletes, shortlist promising profiles, and send connection requests.

### Feature Summary

| Capability | Description |
|-----------|-------------|
| Scout Profile | Professional profile with organization, sports specialization, experience, location |
| Athlete Discovery | Search athletes with advanced filters (sport, age, location, skill, achievements) |
| Athlete Profile View | View sports history, achievements, media gallery |
| Shortlist | Save promising athletes for later review |
| Connection Request | Contact athlete/parent through the platform |

---

## 1. Database Changes

### 1.1 New Tables Required

Create the following tables in Laravel:

```php
// database/migrations/xxxx_create_talent_scout_profiles_table.php
Schema::create('talent_scout_profiles', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->string('organization')->nullable();
    $table->string('affiliation')->nullable();
    $table->json('sports_specialization'); // array of sport_ids
    $table->integer('experience_years')->nullable();
    $table->foreignId('city_id')->nullable()->constrained();
    $table->text('bio')->nullable();
    $table->string('photo_media_id')->nullable();
    $table->boolean('listing_status')->default(true);
    $table->timestamps();
    $table->softDeletes();
});
```

```php
// database/migrations/xxxx_create_scout_shortlists_table.php
Schema::create('scout_shortlists', function (Blueprint $table) {
    $table->id();
    $table->foreignId('talent_scout_profile_id')->constrained()->cascadeOnDelete();
    $table->foreignId('athlete_profile_id')->constrained()->cascadeOnDelete();
    $table->text('notes')->nullable();
    $table->timestamps();
    
    $table->unique(['talent_scout_profile_id', 'athlete_profile_id']);
});
```

```php
// database/migrations/xxxx_create_scout_connections_table.php
Schema::create('scout_connections', function (Blueprint $table) {
    $table->id();
    $table->foreignId('talent_scout_profile_id')->constrained()->cascadeOnDelete();
    $table->foreignId('athlete_profile_id')->constrained()->cascadeOnDelete();
    $table->enum('status', ['pending', 'accepted', 'rejected'])->default('pending');
    $table->text('message')->nullable();
    $table->timestamps();
    
    $table->unique(['talent_scout_profile_id', 'athlete_profile_id']);
});
```

### 1.2 User Role Update

Update the `users` table role enum:

```php
// In existing users table migration
$table->enum('role', ['athlete', 'coach', 'academy', 'organizer', 'sponsor', 'talent_scout']);
```

---

## 2. Backend API Endpoints

### 2.1 Auth & Onboarding

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/onboarding/talent-scout` | Create talent scout profile |
| GET | `/api/v1/me/scout-profile` | Get current scout's profile |
| PUT | `/api/v1/me/scout-profile` | Update scout profile |

### 2.2 Athlete Discovery

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/athletes` | List athletes with filters |
| GET | `/api/v1/athletes/{id}` | Get athlete public profile |

**Query Parameters for `/api/v1/athletes`:**
- `sport_id` - Filter by sport
- `age_group_id` - Filter by age group
- `city_id` - Filter by city
- `skill_level` - Filter by skill level
- `has_achievements` - Boolean
- `search` - Text search on name
- `page`, `per_page` - Pagination

### 2.3 Shortlist

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/me/shortlist` | Get scout's shortlist |
| POST | `/api/v1/me/shortlist/{athlete_id}` | Add athlete to shortlist |
| DELETE | `/api/v1/me/shortlist/{athlete_id}` | Remove from shortlist |
| PATCH | `/api/v1/me/shortlist/{athlete_id}` | Update notes |

### 2.4 Connections

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/me/connections` | List scout's connections |
| POST | `/api/v1/athletes/{id}/connect` | Send connection request |
| PATCH | `/api/v1/me/connections/{id}` | Accept/reject connection |

---

## 3. Laravel Backend Implementation

### 3.1 Create Controllers

```bash
# Create TalentScoutController
php artisan make:controller Api/V1/TalentScoutController
php artisan make:controller Api/V1/ScoutShortlistController
php artisan make:controller Api/V1/ScoutConnectionController
php artisan make:controller Api/V1/AthleteDiscoveryController
```

### 3.2 Routes (routes/api/v1.php)

```php
// Talent Scout routes
Route::middleware(['auth:sanctum', 'role:talent_scout'])->group(function () {
    // Scout Profile
    Route::get('/me/scout-profile', [TalentScoutController::class, 'show']);
    Route::put('/me/scout-profile', [TalentScoutController::class, 'update']);
    
    // Shortlist
    Route::get('/me/shortlist', [ScoutShortlistController::class, 'index']);
    Route::post('/me/shortlist/{athlete}', [ScoutShortlistController::class, 'store']);
    Route::delete('/me/shortlist/{athlete}', [ScoutShortlistController::class, 'destroy']);
    Route::patch('/me/shortlist/{athlete}', [ScoutShortlistController::class, 'update']);
    
    // Connections
    Route::get('/me/connections', [ScoutConnectionController::class, 'index']);
    Route::patch('/me/connections/{connection}', [ScoutConnectionController::class, 'update']);
});

// Public athlete discovery (authenticated users)
Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/athletes', [AthleteDiscoveryController::class, 'index']);
    Route::get('/athletes/{athlete}', [AthleteDiscoveryController::class, 'show']);
    Route::post('/athletes/{athlete}/connect', [ScoutConnectionController::class, 'store']);
});
```

### 3.3 Models

```php
// app/Models/TalentScoutProfile.php
class TalentScoutProfile extends Model
{
    use HasFactory, SoftDeletes;
    
    protected $fillable = [
        'user_id', 'organization', 'affiliation', 
        'sports_specialization', 'experience_years', 
        'city_id', 'bio', 'photo_media_id', 'listing_status'
    ];
    
    protected $casts = [
        'sports_specialization' => 'array',
    ];
    
    public function user(): BelongsTo { ... }
    public function shortlists(): HasMany { ... }
    public function connections(): HasMany { ... }
}

// app/Models/AthleteProfile.php - Add relationships
public function scoutShortlists(): HasMany
{
    return $this->hasMany(ScoutShortlist::class, 'athlete_profile_id');
}

public function scoutConnections(): HasMany
{
    return $this->hasMany(ScoutConnection::class, 'athlete_profile_id');
}
```

### 3.4 Middleware

```php
// app/Http/Middleware/CheckRole.php
case 'talent_scout':
    return $user->role === 'talent_scout';
```

---

## 4. Flutter Frontend Implementation

### 4.1 Project Structure

Create the following directory structure:

```
sportx_app/lib/features/talent_scout/
├── data/
│   ├── models/
│   │   ├── talent_scout_profile.dart
│   │   ├── athlete_discovery_model.dart
│   │   └── scout_shortlist_model.dart
│   └── repositories/
│       └── talent_scout_repository.dart
├── presentation/
│   ├── providers/
│   │   ├── talent_scout_provider.dart
│   │   ├── athlete_discovery_provider.dart
│   │   └── scout_shortlist_provider.dart
│   └── screens/
│       ├── talent_scout_onboarding_screen.dart
│       ├── talent_scout_dashboard_screen.dart
│       ├── talent_scout_athlete_discovery_screen.dart
│       ├── talent_scout_athlete_profile_view_screen.dart
│       ├── talent_scout_shortlist_screen.dart
│       └── talent_scout_connection_screen.dart
```

### 4.2 Models

```dart
// talent_scout_profile.dart
class TalentScoutProfile {
  final String id;
  final String? organization;
  final String? affiliation;
  final List<int> sportsSpecialization;
  final int? experienceYears;
  final int? cityId;
  final String? bio;
  final String? photoMediaId;
}

// athlete_discovery_model.dart
class AthleteDiscovery {
  final String id;
  final String fullName;
  final String? photoUrl;
  final List<Sport> sports;
  final int? ageGroupId;
  final String? cityName;
  final String? skillLevel;
  final int achievementsCount;
}

// scout_shortlist_model.dart
class ScoutShortlistItem {
  final String id;
  final AthleteDiscovery athlete;
  final String? notes;
}
```

### 4.3 Providers

```dart
// talent_scout_provider.dart
class TalentScoutNotifier extends StateNotifier<AsyncValue<TalentScoutProfile>> {
  final TalentScoutRepository _repository;
  
  Future<void> createProfile(TalentScoutProfile profile) async { ... }
  Future<void> updateProfile(TalentScoutProfile profile) async { ... }
}

// athlete_discovery_provider.dart
class AthleteDiscoveryNotifier extends StateNotifier<AsyncValue<PaginatedResult<AthleteDiscovery>>> {
  final Dio _dio;
  
  Future<void> searchAthletes(AthleteFilters filters) async { ... }
  Future<void> loadMore() async { ... }
}

// scout_shortlist_provider.dart
class ScoutShortlistNotifier extends StateNotifier<AsyncValue<List<ScoutShortlistItem>>> {
  final Dio _dio;
  
  Future<void> addToShortlist(String athleteId) async { ... }
  Future<void> removeFromShortlist(String athleteId) async { ... }
  Future<void> updateNotes(String athleteId, String notes) async { ... }
}
```

### 4.4 Screens

#### 4.4.1 Onboarding Screen (`/scout-onboarding`)

Fields:
- Organization name (text)
- Affiliation (text, optional)
- Sports specialization (multi-select chips)
- Years of experience (dropdown)
- City (autocomplete)
- Bio (text area, optional)

Flow:
1. User fills form
2. POST to `/api/v1/onboarding/talent-scout`
3. On success: mark onboarding complete, navigate to `/scout-dashboard`

#### 4.4.2 Dashboard Screen (`/scout-dashboard`)

Layout:
- Welcome header with scout name
- Quick action tiles:
  - "Discover Athletes" → navigates to discovery
  - "My Shortlist" → navigates to shortlist
  - "My Profile" → navigates to profile edit
- Stats summary:
  - Shortlisted athletes count
  - Connection requests sent
  - Profile completeness meter

#### 4.4.3 Athlete Discovery Screen (`/scout-discovery`)

Features:
- Search bar at top
- Filter chips (sport, age, city)
- "Advanced Filters" button → opens filter panel
- Athlete cards in list/grid
- Each card shows: photo, name, sport, age group, city, achievements count
- Tap card → Athlete Profile View

Advanced Filters Panel:
- Sport multi-select
- Age group dropdown
- City dropdown
- Skill level dropdown
- Achievements toggle

#### 4.4.4 Athlete Profile View (`/scout-athlete/{id}`)

Sections:
- Hero: photo, name, sport badges
- Info: age group, city, skill level
- Sports History: timeline of sports participation
- Achievements: list with medals/certifications
- Media Gallery: photos/videos grid
- Actions (floating buttons):
  - "Shortlist" (heart icon)
  - "Connect" (message icon)

#### 4.4.5 Shortlist Screen (`/scout-shortlist`)

Features:
- List of shortlisted athlete cards
- Each card: photo, name, sport, city, remove button
- Tap card → Athlete Profile View
- Edit notes via long-press or swipe

#### 4.4.6 Connection Screen (`/scout-connect/{athleteId}`)

Form:
- Athlete name (display only)
- Message text area
- Submit button

Flow:
1. User fills message
2. POST to `/api/v1/athletes/{id}/connect`
3. On success: show confirmation, navigate back

### 4.5 Navigation Routes

Add to `lib/core/router.dart`:

```dart
'/scout-onboarding': (context) => const TalentScoutOnboardingScreen(),
'/scout-dashboard': (context) => const TalentScoutDashboardScreen(),
'/scout-discovery': (context) => const TalentScoutAthleteDiscoveryScreen(),
'/scout-athlete/:id': (context) => TalentScoutAthleteProfileViewScreen(athleteId: id),
'/scout-shortlist': (context) => const TalentScoutShortlistScreen(),
'/scout-connect/:athleteId': (context) => TalentScoutConnectionScreen(athleteId: athleteId),
```

### 4.6 Role Selection Update

In `role_selection_screen.dart`, add 6th role card:

```dart
RoleCard(
  title: 'Talent Scout',
  icon: Icons.person_search,
  description: 'Discover and shortlist promising athletes',
  onTap: () => context.go('/scout-onboarding'),
),
```

---

## 5. Shared Components

### 5.1 Profile Quick Links (Profile Screen)

Add Talent Scout quick links:

```dart
if (user.role == 'talent_scout') ...[
  QuickLinkTile(
    icon: Icons.dashboard,
    title: 'Scout Dashboard',
    onTap: () => context.go('/scout-dashboard'),
  ),
  QuickLinkTile(
    icon: Icons.people,
    title: 'Discover Athletes',
    onTap: () => context.go('/scout-discovery'),
  ),
  QuickLinkTile(
    icon: Icons.favorite,
    title: 'My Shortlist',
    onTap: () => context.go('/scout-shortlist'),
  ),
]
```

### 5.2 Athlete Card Widget

Create reusable `AthleteDiscoveryCard` widget:

```dart
class AthleteDiscoveryCard extends StatelessWidget {
  final AthleteDiscovery athlete;
  final VoidCallback? onTap;
  final VoidCallback? onShortlist;
  final VoidCallback? onConnect;
}
```

---

## 6. Seeding Data

### 6.1 Test Data Seeder

```php
// database/seeders/TalentScoutSeeder.php
public function run()
{
    $user = User::create([
        'name' => 'Kiran Patel',
        'email' => 'kiran@scout.test',
        'password' => Hash::make('password'),
        'role' => 'talent_scout',
        'email_verified_at' => now(),
    ]);
    
    TalentScoutProfile::create([
        'user_id' => $user->id,
        'organization' => 'Elite Talent Agency',
        'affiliation' => 'Gujarat Cricket Association',
        'sports_specialization' => [1, 3], // cricket, kabaddi
        'experience_years' => 12,
        'city_id' => 1,
    ]);
}
```

---

## 7. Screen-to-Screen Navigation Map

```
Scout Onboarding (TS1)
    ↓
Scout Dashboard (TS2)
    ├── Discover Athletes (TS3)
    │       ↓
    │   Athlete Profile View (TS4)
    │       ├── Shortlist (TS5) → confirmation
    │       └── Connect (TS6) → confirmation
    │
    └── My Shortlist (TS5)
            ↓
        Athlete Profile View (TS4)
                ↓
            Remove / Update Notes
```

---

## 8. Files to Create

### Flutter

| File | Purpose |
|------|---------|
| `lib/features/talent_scout/data/models/talent_scout_profile.dart` | Scout profile model |
| `lib/features/talent_scout/data/models/athlete_discovery_model.dart` | Athlete discovery model |
| `lib/features/talent_scout/data/models/scout_shortlist_model.dart` | Shortlist model |
| `lib/features/talent_scout/data/repositories/talent_scout_repository.dart` | API repository |
| `lib/features/talent_scout/presentation/providers/talent_scout_provider.dart` | State management |
| `lib/features/talent_scout/presentation/providers/athlete_discovery_provider.dart` | Discovery state |
| `lib/features/talent_scout/presentation/providers/scout_shortlist_provider.dart` | Shortlist state |
| `lib/features/talent_scout/presentation/screens/talent_scout_onboarding_screen.dart` | Onboarding |
| `lib/features/talent_scout/presentation/screens/talent_scout_dashboard_screen.dart` | Dashboard |
| `lib/features/talent_scout/presentation/screens/talent_scout_athlete_discovery_screen.dart` | Discovery |
| `lib/features/talent_scout/presentation/screens/talent_scout_athlete_profile_view_screen.dart` | Profile view |
| `lib/features/talent_scout/presentation/screens/talent_scout_shortlist_screen.dart` | Shortlist |
| `lib/features/talent_scout/presentation/screens/talent_scout_connection_screen.dart` | Connection form |

### Laravel

| File | Purpose |
|------|---------|
| `app/Http/Controllers/Api/V1/TalentScoutController.php` | Scout profile CRUD |
| `app/Http/Controllers/Api/V1/ScoutShortlistController.php` | Shortlist management |
| `app/Http/Controllers/Api/V1/ScoutConnectionController.php` | Connection requests |
| `app/Http/Controllers/Api/V1/AthleteDiscoveryController.php` | Athlete search |
| `app/Models/TalentScoutProfile.php` | Scout profile model |
| `app/Models/ScoutShortlist.php` | Shortlist model |
| `app/Models/ScoutConnection.php` | Connection model |
| `database/migrations/xxxx_create_talent_scout_profiles_table.php` | Migration |
| `database/migrations/xxxx_create_scout_shortlists_table.php` | Migration |
| `database/migrations/xxxx_create_scout_connections_table.php` | Migration |
| `database/seeders/TalentScoutSeeder.php` | Test data |

---

## 9. Implementation Order

1. **Database migrations** — Create tables
2. **Laravel models** — Set up relationships
3. **API routes** — Define endpoints
4. **Laravel controllers** — Implement business logic
5. **Repository** — Flutter data layer
6. **Providers** — State management
7. **Onboarding screen** — First screen
8. **Dashboard screen** — Hub screen
9. **Athlete discovery** — Core feature
10. **Athlete profile view** — Detail screen
11. **Shortlist** — Save functionality
12. **Connection** — Contact feature
13. **Role selection** — Add 6th card
14. **Seeding** — Test data
15. **Testing** — End-to-end flows

---

## 10. Pending Actions

> **Migrations not yet run.** Execute the following before using the feature:

```bash
cd sportx-api
php artisan migrate
php artisan db:seed --class=TalentScoutSeeder
```

---

## 11. Reference Documents

| Document | Description |
|----------|-------------|
| `docs/SportX_India_Updated_Screen_Inventory_MVP_with_talent_scout.md` | Screen specifications |
| `docs/SportX_India_Updated_MVP_Feature_List_with_talent_scout.pdf` | Feature list |
| `docs/Functional-Requirements.md` | FR-TS-1 through FR-TS-8 |
| `docs/Jira-Tickets.md` | Epic P1-E5 and P2-E7 |
| `docs/Phased-Roadmap.md` | Phase 1 P1-6, Phase 2 P2-21 to P2-25 |

---

*Last Updated: 2026-09-04*
