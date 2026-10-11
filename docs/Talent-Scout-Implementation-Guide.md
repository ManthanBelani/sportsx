> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

# Talent Scout Feature — AI Implementation Guide

This document provides step-by-step instructions for implementing the **Talent Scout** role in SportX India.

> **⚠️ v3 UPDATE:** Transactions changed — read first:
> - The scout role is now **first-class** (not a side-guide): enum value **`scout`** (not `talent_scout`), and the canonical profile table is **`talent_scout_profiles`** with **30 fields** (`SportX_Mandatory_Fields.md` §4, `Database-Design.md` §4).
> - `sponsor`/`Sponsor-Brand` is **REMOVED**; sponsorship is now an `opportunities.type` (delta D2).
> - Shortlist gains **status (under_review/good/high/final) + tags + private notes** (BE-M10.1); **observations** are new (BE-M10.2); contact to a **U-18 athlete routes to the guardian** (BE-M10.3).
> - The draft `scout_connections` table is **superseded** by the shared `connection_requests` table (BE-M7.3/BE-M10.3).

---

## Overview

Talent Scout is a **first-class role** in the platform alongside Athlete, Coach, Academy, Organizer and Admin (`athlete, coach, academy, organizer, scout, admin`). Talent Scouts discover athletes, shortlist promising profiles with a pipeline status, record observations, and contact athletes/parents.

### Feature Summary

| Capability | Description |
|-----------|-------------|
| Scout Profile | Professional profile (`talent_scout_profiles`, 30 fields): scout type, sports specialization, experience, location, availability |
| Athlete Discovery | Search athletes with advanced filters (sport, age, location, skill, position, achievements) |
| Athlete Profile View | View sports history, achievements, media gallery |
| Shortlist | Save promising athletes with pipeline **status** + **tags** + private notes |
| Observations | Quick note + rating + optional media (SC.10) |
| Connection Request | Contact athlete/**guardian** through the platform (shared connection-request flow) |
| Scout Reports (P1) | 5-dimension assessment + conclusion (SC.8/SC.9) |

---

## 1. Database Changes

> **Canonical schema:** `Database-Design.md` §4 (`talent_scout_profiles`), §10 (`scout_shortlists`, `observations`, `scout_reports`), §9 (`connection_requests`). The drafts below are **[SUPERSEDED — see Backend-Feature-Delta.md]** and kept for history only.

### 1.1 Tables — canonical (build these)

**`talent_scout_profiles`** (30 fields — `SportX_Mandatory_Fields.md` §4). Mandatory: `full_name`, `photo_media_id`, `cover_media_id`, `scout_type`, `specializations`, `city_id`, `bio`. Optional: `experience_years`, `scouting_level`, `age_groups_scouted`, `organization_name`, `previous_organizations`, `certifications`, `scouting_methods`, `evaluation_areas`, `athletes_scouted`, `discoveries`, `scouting_achievements`, `regions`, `events_covered`, `services`, `recruitment_focus`, `affiliations`, `availability`, `fee_structure`, `website`, `social_links`, `verification_status`, `listing_status`, `profile_completeness`. Downstream: `talent_scout_sports` pivot (Field 4); `scout_reports` (Field 23); `media_items` (Field 24); `reviews` (Field 25).

**`scout_shortlists`** (BE-M10.1): `scout_user_id` (FK users), `athlete_id` (FK athlete_profiles), `status` enum(`under_review`,`good`,`high`,`final`) default `under_review`, `tags` json nullable, `notes` text (private). Unique `(scout_user_id, athlete_id)`.

**`observations`** (BE-M10.2): `scout_user_id`, `athlete_id`, `rating` tinyint nullable, `note` text, `media` json nullable. Index `(scout_user_id, athlete_id)`.

**`scout_reports`** (P1, BE-P1.6): `scout_user_id`, `athlete_id`, `scores` json (5-dimension), `conclusion` enum(`recommend`,`watch`,`pass`), `notes`, `status` enum(`draft`,`final`).

**Contact/connections:** use the shared **`connection_requests`** table (`Database-Design.md` §9) — **not** a scout-specific table. U-18 contact routes to the guardian (BE-M10.3).

### 1.2 User Role Update

> **v3:** use the enum value **`scout`** (not `talent_scout`). Remove `sponsor`.

```php
// In the users table migration
$table->enum('role', ['athlete', 'coach', 'academy', 'organizer', 'scout', 'admin']);
```

### 1.3 Superseded drafts (history)

> The three migrations below (`talent_scout_profiles` with `organization`/`affiliation`, `scout_shortlists` keyed by `talent_scout_profile_id` with notes-only, and `scout_connections`) are **[SUPERSEDED — see Backend-Feature-Delta.md]**. Do not build as-is; use §1.1.

```php
// [SUPERSEDED] draft talent_scout_profiles (was organization/affiliation, no 30 fields)
// [SUPERSEDED] draft scout_shortlists (was notes-only, no status/tags)
// [SUPERSEDED] draft scout_connections (replace with connection_requests)
```

## 2. Backend API Endpoints

> Conventions per `API-Specification.md`: base `/api/v1`, `{data, meta}` envelope, Bearer Sanctum. Status tags: `EXISTS`/`NEW`/`CHANGED`/`P1`.

### 2.1 Auth & Onboarding

| Method | Endpoint | Status | Description |
|--------|----------|--------|-------------|
| POST | `/api/v1/onboarding/scout` | NEW | Create talent scout profile (30 fields) |
| GET | `/api/v1/me/scout-profile` | NEW | Get current scout's profile |
| PUT | `/api/v1/me/scout-profile` | NEW | Update scout profile |

> The old path `/onboarding/talent-scout` is **[SUPERSEDED — see Backend-Feature-Delta.md]** — use `/onboarding/scout` (delta §11.2).

### 2.2 Athlete Discovery

| Method | Endpoint | Status | Description |
|--------|----------|--------|-------------|
| GET | `/api/v1/athletes` | CHANGED | List athletes with filters (open to scout; add `position_id`, `level`, `has_achievements`) |
| GET | `/api/v1/athletes/{id}` | CHANGED | Athlete public profile (minors restricted — AT.10) |
| GET | `/api/v1/me/scout-dashboard` | NEW | Dashboard aggregates (or fold into `/me/home`) |

**Query Parameters for `/api/v1/athletes`:**
- `sport_id`, `age_group_id`, `city_id`, `skill_level`, `position_id`, `level`
- `has_achievements` (boolean), `search`, `page`, `per_page`

### 2.3 Shortlist (status + tags + private notes)

| Method | Endpoint | Status | Description |
|--------|----------|--------|-------------|
| GET | `/api/v1/me/shortlist` | CHANGED | Get scout's shortlist (pipeline tabs All/Under Review/Final) |
| POST | `/api/v1/me/shortlist` | CHANGED | Add athlete (`athlete_id`, `status`, `tags`, `notes`) |
| PATCH | `/api/v1/me/shortlist/{athlete_id}` | CHANGED | Update `status`/`tags`/`notes` |
| DELETE | `/api/v1/me/shortlist/{athlete_id}` | CHANGED | Remove from shortlist |

> Shortlist/notes/reports are **owner-only** (scout-data-privacy policy). `status` ∈ `under_review`/`good`/`high`/`final` (BE-M10.1).

### 2.4 Observations

| Method | Endpoint | Status | Description |
|--------|----------|--------|-------------|
| POST | `/api/v1/observations` | NEW | Quick note + rating + optional media (SC.10) |
| GET | `/api/v1/observations` | NEW | List observations (owner-only) |

### 2.5 Connections & Contact

| Method | Endpoint | Status | Description |
|--------|----------|--------|-------------|
| GET | `/api/v1/me/connections` | NEW | List scout's connections (shared table, tabs Connections/Requests/Sent) |
| POST | `/api/v1/athletes/{id}/contact` | NEW | Send contact/connection request with `purpose` (trial invite/enquiry) |
| PATCH | `/api/v1/connections/{id}` | NEW | Accept/decline |
| DELETE | `/api/v1/connections/{id}` | NEW | Cancel/remove |

> **Minors (BE-M10.3):** for a U-18 athlete, `/athletes/{id}/contact` notifies the **guardian**; guardian consent is required before chat unlocks. The old `/athletes/{id}/connect` + `scout_connections` design is **[SUPERSEDED — see Backend-Feature-Delta.md]**. Chat opens only after an accepted connection (no cold DMs).

### 2.6 Scout Reports (P1)

| Method | Endpoint | Status | Description |
|--------|----------|--------|-------------|
| POST/GET | `/api/v1/scout-reports` | P1 | 5-dimension assessment + conclusion (SC.8/SC.9) |
| GET | `/api/v1/scout/compare?ids=` | P1 | Side-by-side scores (SC.7) |

## 3. Laravel Backend Implementation

### 3.1 Create Controllers

```bash
# Create TalentScoutController
php artisan make:controller Api/V1/TalentScoutController
php artisan make:controller Api/V1/ScoutShortlistController
php artisan make:controller Api/V1/ScoutObservationController
php artisan make:controller Api/V1/AthleteDiscoveryController
php artisan make:controller Api/V1/ConnectionController
```

### 3.2 Routes (routes/api/v1.php)

```php
// Talent Scout routes (role = scout)
Route::middleware(['auth:sanctum', 'role:scout'])->group(function () {
    // Scout Profile
    Route::get('/me/scout-profile', [TalentScoutController::class, 'show']);
    Route::put('/me/scout-profile', [TalentScoutController::class, 'update']);
    Route::get('/me/scout-dashboard', [TalentScoutController::class, 'dashboard']);

    // Shortlist (status + tags + notes)
    Route::get('/me/shortlist', [ScoutShortlistController::class, 'index']);
    Route::post('/me/shortlist', [ScoutShortlistController::class, 'store']);
    Route::patch('/me/shortlist/{athlete}', [ScoutShortlistController::class, 'update']);
    Route::delete('/me/shortlist/{athlete}', [ScoutShortlistController::class, 'destroy']);

    // Observations
    Route::get('/observations', [ScoutObservationController::class, 'index']);
    Route::post('/observations', [ScoutObservationController::class, 'store']);

    // Connections (shared connection_requests)
    Route::get('/me/connections', [ConnectionController::class, 'index']);
    Route::patch('/connections/{connection}', [ConnectionController::class, 'update']);
    Route::delete('/connections/{connection}', [ConnectionController::class, 'destroy']);
});

// Athlete discovery (authenticated users)
Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/athletes', [AthleteDiscoveryController::class, 'index']);
    Route::get('/athletes/{athlete}', [AthleteDiscoveryController::class, 'show']);
    // Contact: guardian-routed for U-18
    Route::post('/athletes/{athlete}/contact', [ConnectionController::class, 'store']);
});
```

> The old `role:talent_scout` middleware name and `/athletes/{athlete}/connect` route are **[SUPERSEDED — see Backend-Feature-Delta.md]** (BE-M1.2/BE-M10.3).

### 3.3 Models

```php
// app/Models/TalentScoutProfile.php
class TalentScoutProfile extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id', 'full_name', 'photo_media_id', 'cover_media_id',
        'scout_type', 'specializations', 'city_id', 'bio',
        'experience_years', 'scouting_level', 'age_groups_scouted',
        'organization_name', 'previous_organizations', 'certifications',
        'scouting_methods', 'evaluation_areas', 'athletes_scouted',
        'discoveries', 'scouting_achievements', 'regions', 'events_covered',
        'services', 'recruitment_focus', 'affiliations', 'availability',
        'fee_structure', 'website', 'social_links', 'verification_status',
        'listing_status', 'profile_completeness',
    ];

    protected $casts = [
        'specializations' => 'array',
        'age_groups_scouted' => 'array',
        'previous_organizations' => 'array',
        'certifications' => 'array',
        'scouting_methods' => 'array',
        'evaluation_areas' => 'array',
        'scouting_achievements' => 'array',
        'regions' => 'array',
        'events_covered' => 'array',
        'services' => 'array',
        'recruitment_focus' => 'array',
        'affiliations' => 'array',
        'social_links' => 'array',
    ];
}

// app/Models/ScoutShortlist.php — status/tags/notes, unique (scout_user_id, athlete_id)
// app/Models/Observation.php — scout_user_id, athlete_id, rating, note, media
// Connections use app/Models/ConnectionRequest.php (shared)
```

### 3.4 Middleware

```php
// app/Http/Middleware/CheckRole.php
case 'scout':
    return $user->role === 'scout';
```

> `talent_scout` is **REMOVED** as an enum value; use `scout` (BE-M1.2).

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
// talent_scout_profile.dart (30 fields — see SportX_Mandatory_Fields.md §4)
class TalentScoutProfile {
  final String id;
  final String fullName;
  final String? photoMediaId;
  final String scoutingType;          // scout_type
  final List<int> primarySportIds;
  final List<String> specializations;
  final int? cityId;
  final String? bio;
  final int? experienceYears;
  final String? scoutingLevel;
  final String? organizationName;
  final String? availability;
  // ...remaining optional fields per Mandatory Fields
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
enum ShortlistStatus { underReview, good, high, final }

class ScoutShortlistItem {
  final String id;
  final AthleteDiscovery athlete;
  final ShortlistStatus status;   // pipeline tab
  final List<String> tags;
  final String? notes;            // private
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
  Future<void> updateStatus(String athleteId, ShortlistStatus status) async { ... }
  Future<void> updateTags(String athleteId, List<String> tags) async { ... }
  Future<void> updateNotes(String athleteId, String notes) async { ... }
}

// scout_observation_provider.dart
class ScoutObservationNotifier extends StateNotifier<AsyncValue<List<Observation>>> {
  final Dio _dio;

  Future<void> load() async { ... }
  Future<void> create(String athleteId, int rating, String note) async { ... }
}
```

### 4.4 Screens

#### 4.4.1 Onboarding Screen (`/scout-onboarding`)

Fields (30-field schema, `SportX_Mandatory_Fields.md` §4 — mandatory marked 🔴):
- 🔴 Full name (text)
- 🔴 Profile photo (+ cover)
- 🔴 Scout type (Independent / Club / Academy / Federation)
- 🔴 Primary sport(s) (multi-select chips)
- 🔴 Scouting specialization(s) (Batting, Bowling, Wicketkeeping…)
- 🔴 City / State (autocomplete)
- 🔴 Short bio (text area)
- 🟠/🟢 Experience years, scouting level, age groups scouted, organization, previous organizations, certifications, methods, evaluation areas, achievements, regions, services, recruitment focus, availability, fees, social links

Flow:
1. User fills form
2. POST to `/api/v1/onboarding/scout`
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
- Pipeline **tabs**: All / Under Review / Good / High / Final (status)
- List of shortlisted athlete cards
- Each card: photo, name, sport, city, **status chip**, **tags**, remove button
- Tap card → Athlete Profile View
- Edit **status / tags / private notes** via long-press or swipe
- "Compare" input (P1)

#### 4.4.6 Observations Screen (`/scout-observations`)

Features:
- Quick note + rating (1–5) + optional media against an athlete
- POST to `/api/v1/observations`
- Owner-only list

#### 4.4.7 Connection Screen (`/scout-connect/{athleteId}`)

Form:
- Athlete name (display only)
- **Purpose** (trial invite / enquiry)
- Message text area
- Submit button

Flow:
1. User fills message + purpose
2. POST to `/api/v1/athletes/{id}/contact`
3. **U-18:** request is routed to the guardian; chat unlocks only after acceptance + guardian consent
4. On success: show confirmation, navigate back

### 4.5 Navigation Routes

Add to `lib/core/router.dart`:

```dart
'/scout-onboarding': (context) => const TalentScoutOnboardingScreen(),
'/scout-dashboard': (context) => const TalentScoutDashboardScreen(),
'/scout-discovery': (context) => const TalentScoutAthleteDiscoveryScreen(),
'/scout-athlete/:id': (context) => TalentScoutAthleteProfileViewScreen(athleteId: id),
'/scout-shortlist': (context) => const TalentScoutShortlistScreen(),
'/scout-observations': (context) => const TalentScoutObservationsScreen(),
'/scout-connect/:athleteId': (context) => TalentScoutConnectionScreen(athleteId: athleteId),
```

### 4.6 Role Selection Update

In `role_selection_screen.dart`, add the Scout role card (`scout` is now first-class; `sponsor` card removed):

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
if (user.role == 'scout') ...[
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
  QuickLinkTile(
    icon: Icons.visibility,
    title: 'Observations',
    onTap: () => context.go('/scout-observations'),
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
        'role' => 'scout',                 // v3 enum value
        'email_verified_at' => now(),
    ]);

    TalentScoutProfile::create([
        'user_id' => $user->id,
        'full_name' => 'Kiran Patel',
        'scout_type' => 'club',
        'specializations' => ['Batting', 'Bowling'],
        'city_id' => 1,
        'bio' => 'Talent scout with 12 years experience',
        'experience_years' => 12,
        'organization_name' => 'Elite Talent Agency',
    ]);
    // sports via talent_scout_sports pivot
}
```

---

## 7. Screen-to-Screen Navigation Map

```
Scout Onboarding (SC.1)
    ↓
Scout Dashboard (SC.2 / /me/home)
    ├── Discover Athletes (SC.4)
    │       ↓
    │   Athlete Profile View
    │       ├── Shortlist (SC.5/SC.6) → status/tags/notes
    │       ├── Observations (SC.10)
    │       └── Contact (SC.13) → guardian if U-18
    │
    ├── My Shortlist (SC.5/SC.6) — pipeline tabs
    │       ↓
    │   Athlete Profile View
    │           ↓
    │       Remove / Update status/tags/notes
    │
    └── Scout Reports (SC.8/SC.9) — P1
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
| `lib/features/talent_scout/presentation/screens/talent_scout_shortlist_screen.dart` | Shortlist (pipeline tabs) |
| `lib/features/talent_scout/presentation/screens/talent_scout_observations_screen.dart` | Observations |
| `lib/features/talent_scout/presentation/screens/talent_scout_connection_screen.dart` | Contact form (guardian-routed) |

### Laravel

| File | Purpose |
|------|---------|
| `app/Http/Controllers/Api/V1/TalentScoutController.php` | Scout profile CRUD + dashboard |
| `app/Http/Controllers/Api/V1/ScoutShortlistController.php` | Shortlist management (status/tags/notes) |
| `app/Http/Controllers/Api/V1/ScoutObservationController.php` | Observations |
| `app/Http/Controllers/Api/V1/AthleteDiscoveryController.php` | Athlete search |
| `app/Http/Controllers/Api/V1/ConnectionController.php` | Shared connection requests (guardian routing) |
| `app/Models/TalentScoutProfile.php` | Scout profile model (30 fields) |
| `app/Models/ScoutShortlist.php` | Shortlist model |
| `app/Models/Observation.php` | Observation model |
| `database/migrations/xxxx_create_talent_scout_profiles_table.php` | Migration (30 fields) |
| `database/migrations/xxxx_create_talent_scout_sports_table.php` | Sport pivot |
| `database/migrations/xxxx_create_scout_shortlists_table.php` | Migration (status/tags/notes) |
| `database/migrations/xxxx_create_observations_table.php` | Migration |
| `database/seeders/TalentScoutSeeder.php` | Test data |

> `scout_connections` migration/model are **[SUPERSEDED — see Backend-Feature-Delta.md]** (use shared `connection_requests`).

---

## 9. Implementation Order

1. **Database migrations** — `talent_scout_profiles` (30 fields), `talent_scout_sports`, `scout_shortlists` (status/tags/notes), `observations`
2. **Laravel models** — set up relationships (shared `connection_requests` for contact)
3. **API routes** — `/onboarding/scout`, `/me/scout-profile`, `/me/shortlist`, `/observations`, `/athletes/{id}/contact`
4. **Laravel controllers** — implement business logic (owner-only scout data)
5. **Repository** — Flutter data layer
6. **Providers** — state management
7. **Onboarding screen** — first screen
8. **Dashboard screen** — hub screen
9. **Athlete discovery** — core feature
10. **Athlete profile view** — detail screen
11. **Shortlist** — pipeline status/tags/notes
12. **Observations** — record + list
13. **Contact** — connection request (guardian routing for U-18)
14. **Role selection** — Scout card (sponsor removed)
15. **Seeding** — test data
16. **Testing** — end-to-end flows

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
| `docs/Backend-Feature-Delta.md` | **v3 source of truth** — §1 M10 scouting (BE-M10.x), §11.12 scouting endpoints |
| `sportsx-design-v3/new_design_docs/SportX_Mandatory_Fields.md` | Scout 30 fields (§4) |
| `docs/Database-Design.md` | Canonical v3 schema (`talent_scout_profiles`, `scout_shortlists`, `observations`, `scout_reports`) |
| `docs/API-Specification.md` | §16E Scouting endpoints |
| `docs/SportX_India_Updated_Screen_Inventory_MVP_with_talent_scout.md` | Legacy screen specifications |
| `docs/Functional-Requirements.md` | FR-TS-1 through FR-TS-8 |
| `docs/Jira-Tickets.md` | Epic P1-E5 and P2-E7 |
| `docs/Phased-Roadmap.md` | Phase 1 P1-6, Phase 2 P2-21 to P2-25 |

---

*Last Updated: 2026-09-04 (v3 sync — scout first-class, 30 fields, shortlist status/tags/notes, observations, guardian contact)*
