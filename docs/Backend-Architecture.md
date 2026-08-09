# Backend Architecture — SportX India (Laravel)

Laravel API architecture: folder structure, layers (controllers → services → models), queues/jobs, auth strategy. Consistent with `Database-Design.md` and `Class-Diagram.md`.

> **Assumptions**
> - Laravel 11.x (latest stable as of spec authoring — AS-23). Folder structure follows the Laravel 11 default (`app/`, `routes/`, `database/`).
> - PHP 8.2+ (AS-24).
> - **Auth:** Laravel Sanctum for API token management — AS-16.
> - **Queue driver:** database (synchronous-capable for local dev); production recommendation: Redis (AS-25).
> - **Storage:** local disk for dev; S3-compatible (e.g. AWS S3, Cloudflare R2) for production with CDN (NFR-4, AS-07).
> - **Testing:** PHPUnit feature tests + Pest (optional) at developer discretion.

---

## 1. Folder Structure

```
app/
├── Http/
│   ├── Controllers/
│   │   ├── Api/
│   │   │   ├── AuthController.php
│   │   │   ├── OnboardingController.php
│   │   │   ├── MetaController.php                    # sports, cities, age-groups
│   │   │   ├── ProfileController.php
│   │   │   ├── DirectoryController.php              # academies, coaches (list + detail)
│   │   │   ├── TrialController.php                  # trials (list + detail)
│   │   │   ├── TournamentController.php              # tournaments (list + detail)
│   │   │   ├── ScholarshipController.php             # scholarships (list + detail)
│   │   │   ├── SponsorshipController.php             # sponsorships (list + detail)
│   │   │   ├── SportsVenueController.php             # sports venues (list + detail) — new from PDF
│   │   │   ├── SearchController.php
│   │   │   ├── EnquiryController.php
│   │   │   ├── RegistrationController.php           # trial + tournament registrations
│   │   │   ├── SponsorEngagementController.php       # sponsor apply/discover/shortlist
│   │   │   ├── ProviderTrialController.php           # coach/academy/organizer trial CRUD
│   │   │   ├── ProviderTournamentController.php       # organizer tournament CRUD
│   │   │   ├── RegistrantController.php              # registrant management
│   │   │   ├── CapacityController.php                # capacity management
│   │   │   ├── ResultsController.php                 # results publish/view
│   │   │   ├── SavedItemController.php
│   │   │   ├── ReportController.php
│   │   │   ├── NotificationController.php
│   │   │   ├── SettingsController.php
│   │   │   ├── CoachProfileController.php            # coach self-service
│   │   │   ├── AcademyListingController.php          # academy self-service
│   │   │   └── AthleteDiscoveryController.php       # sponsor athlete search
│   │   └── Admin/
│   │       ├── AdminAuthController.php
│   │       ├── AdminDashboardController.php
│   │       ├── AdminContentController.php
│   │       ├── AdminModerationController.php
│   │       ├── AdminExpiryController.php
│   │       └── AdminCategoryController.php
│   ├── Middleware/
│   │   ├── EnsureJsonResponse.php
│   │   ├── SetUserLocale.php                         # future: i18n
│   │   └── RateLimitOtp.php
│   ├── Requests/
│   │   ├── Auth/
│   │   │   ├── RegisterRequest.php
│   │   │   ├── VerifyOtpRequest.php
│   │   │   ├── LoginRequest.php
│   │   │   └── ForgotPasswordRequest.php
│   │   ├── Onboarding/
│   │   │   ├── AthleteOnboardingRequest.php
│   │   │   ├── CoachOnboardingRequest.php
│   │   │   ├── AcademyOnboardingRequest.php
│   │   │   ├── OrganizerOnboardingRequest.php
│   │   │   └── SponsorOnboardingRequest.php
│   │   ├── Profile/
│   │   │   ├── UpdateAthleteProfileRequest.php
│   │   │   └── UpdateCoachProfileRequest.php
│   │   ├── Listing/
│   │   │   ├── StoreTrialRequest.php
│   │   │   ├── UpdateTrialRequest.php
│   │   │   ├── StoreTournamentRequest.php
│   │   │   ├── StoreSponsorshipRequest.php
│   │   │   ├── StoreEnquiryRequest.php
│   │   │   ├── StoreTrialRegistrationRequest.php
│   │   │   └── ...
│   │   ├── Admin/
│   │   │   ├── UpdateExpiryRulesRequest.php
│   │   │   └── ...
│   │   └── Media/
│   │       └── UploadMediaRequest.php
│   └── Resources/
│       ├── AthleteProfileResource.php
│       ├── TrialResource.php
│       ├── TrialListResource.php          # card list (T1 fields only)
│       ├── ... (per entity: Detail + List variant)
│       └── MetaResource.php
│
├── Models/
│   ├── User.php
│   ├── OtpCode.php
│   ├── AdminProfile.php
│   ├── AthleteProfile.php
│   ├── CoachProfile.php
│   ├── Academy.php
│   ├── OrganizerProfile.php
│   ├── SponsorProfile.php
│   ├── Trial.php
│   ├── TrialRegistration.php
│   ├── TrialRegistrationDocument.php
│   ├── Tournament.php
│   ├── TournamentCategory.php
│   ├── TournamentRegistration.php
│   ├── TournamentResult.php
│   ├── Scholarship.php
│   ├── Sponsorship.php
│   ├── SponsorshipApplication.php
│   ├── ShortlistEntry.php
│   ├── SportsVenue.php                     # New from PDF (AS-47)
│   ├── Enquiry.php
│   ├── EnquiryMessage.php
│   ├── SavedItem.php
│   ├── ListingReport.php
│   ├── Notification.php
│   ├── ExpiryRule.php
│   ├── ExpiryEvent.php
│   ├── ReminderSubscription.php
│   ├── Sport.php
│   ├── City.php
│   ├── AgeGroup.php
│   ├── Achievement.php
│   ├── MediaItem.php
│   ├── AthleteSport.php
│   ├── AcademySport.php
│   └── AcademyCoach.php
│
├── Services/
│   ├── AuthService.php
│   ├── OtpService.php
│   ├── ProfileService.php
│   ├── SearchService.php
│   ├── FilterService.php
│   ├── EnquiryService.php
│   ├── RegistrationService.php
│   ├── SponsorshipService.php
│   ├── ExpiryService.php
│   ├── ReminderService.php
│   ├── ModerationService.php
│   └── NotificationService.php
│
├── Policies/
│   ├── CoachProfilePolicy.php
│   ├── AcademyPolicy.php
│   ├── TrialPolicy.php
│   ├── TournamentPolicy.php
│   ├── RegistrantPolicy.php
│   ├── SponsorshipPolicy.php
│   ├── ApplicationPolicy.php
│   ├── ShortlistPolicy.php
│   ├── ReportPolicy.php
│   ├── SavedItemPolicy.php
│   └── AdminPolicy.php
│
├── Enums/
│   ├── UserRole.php
│   ├── UserStatus.php
│   ├── SkillLevel.php
│   ├── ListingStatus.php
│   ├── DocumentStatus.php
│   ├── VerificationStatus.php
│   ├── RegistrationStatus.php
│   ├── ManualPaymentStatus.php
│   ├── ApplicationStatus.php
│   ├── ExpiryStatus.php
│   ├── ReportReason.php
│   ├── ReportStatus.php
│   ├── NotificationType.php
│   └── OtpChannel.php
│
├── Events/
│   ├── EnquiryReplied.php
│   ├── RegistrationConfirmed.php
│   ├── ContentExpired.php
│   ├── ListingRemoved.php
│   └── ListingWarned.php
│
├── Listeners/
│   ├── SendEnquiryReplyNotification.php
│   ├── ArmRegistrationReminder.php
│   └── NotifyListingOwnerOnModeration.php
│
├── Jobs/
│   ├── SendOtpJob.php
│   ├── SweepExpiredContentJob.php
│   ├── SendDueRemindersJob.php
│   └── PurgeExpiredOtpsJob.php
│
├── Notifications/                    # Laravel notification classes (in-app DB channel)
│   ├── OtpNotification.php
│   ├── EnquiryReplyNotification.php
│   ├── RegistrationReminderNotification.php
│   ├── DeadlineReminderNotification.php
│   ├── ListingRemovedNotification.php
│   └── ListingWarnedNotification.php
│
├── Providers/
│   ├── AuthServiceProvider.php       # Sanctum guard
│   ├── AppServiceProvider.php          # bind interfaces
│   └── OtpServiceProvider.php         # register OtpProvider implementations
│
└── Support/
    ├── Helpers.php                     # (minimal; prefer service classes)
    └── Constants.php

bootstrap/
├── app.php

config/
├── app.php
├── sanctum.php
├── cors.php
├── filesystems.php
├── queue.php
└── sportx.php                         # app-specific config (expiry defaults, OTP settings, etc.)

database/
├── migrations/                          # per Database-Design.md migration order
├── seeders/
│   ├── SportSeeder.php
│   ├── CitySeeder.php
│   ├── AgeGroupSeeder.php
│   ├── ExpiryRuleSeeder.php
│   └── ScholarshipSeeder.php           # admin-maintained initial set
└── factories/                           # per model

routes/
├── api.php                             # all /api/v1/* routes
└── console.php

tests/
├── Feature/
│   ├── Auth/
│   ├── Onboarding/
│   ├── Directory/
│   ├── Trials/
│   ├── Tournaments/
│   ├── Enquiries/
│   ├── Sponsorship/
│   ├── Admin/
│   └── Jobs/
└── Unit/
    ├── Services/
    ├── Policies/
    └── Models/
```

---

## 2. Architecture Layers

### Controllers (thin)

Responsibility: validate request → authorize (policy) → delegate to service → return API resource.

```php
// Example: TrialController@index (athlete-facing browse)
public function index(FilterRequest $request)
{
    $trials = $this->filterService->applyToTrials(Trial::published(), $request->validated());

    return TrialListResource::collection($trials->paginate());
}
```

### Services (business logic)

Responsibility: orchestrate models, enforce rules, wrap transactions, dispatch events/jobs.

```php
// Example: RegistrationService@registerForTrial
public function registerForTrial(AthleteProfile $athlete, Trial $trial, array $payload): TrialRegistration
{
    return DB::transaction(function () use ($athlete, $trial, $payload) {
        $this->assertTrialOpen($trial);
        $this->assertNotDuplicate($athlete, $trial);

        $registration = TrialRegistration::create([
            'trial_id' => $trial->id,
            'athlete_id' => $athlete->id,
            'registration_ref' => $this->generateRef(),
            'reminder_enabled' => $payload['reminder_enabled'] ?? false,
        ]);

        foreach ($payload['document_media_ids'] as $mediaId) {
            $registration->documents()->create(['media_item_id' => $mediaId]);
        }

        $registration->update(['document_status' => 'submitted']);

        event(new RegistrationConfirmed($registration));

        return $registration;
    });
}
```

### Form Requests (validation)

Every endpoint with input has a dedicated FormRequest class. Rules derive from the wireframe field specs and `Database-Design.md` column constraints.

```php
class StoreTrialRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:150'],
            'sport_id' => ['required', 'exists:sports,id'],
            'event_datetime' => ['required', 'date', 'after:now'],
            'venue' => ['required', 'string', 'max:190'],
            'city_id' => ['required', 'exists:cities,id'],
            'eligibility' => ['nullable', 'string'],
            'entry_fee' => ['nullable', 'string', 'max:60'],
            'required_documents' => ['nullable', 'array'],
            'contact' => ['required', 'string', 'max:150'],
            'publish' => ['boolean'],
        ];
    }
}
```

### API Resources (response formatting)

Two variants per entity:
- `*Resource` — full detail (for detail pages, T2).
- `*ListResource` — card-list subset (for directory pages, T1). Typically: id, name, subtitle (sport·city), meta (fee/date), thumbnail, status.

### Policies (authorization)

Implemented as Laravel policy classes registered in `AuthServiceProvider`. Controllers call `$this->authorize('update', $trial)`; policies check role + ownership.

```php
class TrialPolicy
{
    public function create(User $user): bool
    {
        return in_array($user->role, ['academy', 'organizer']);
    }

    public function update(User $user, Trial $trial): bool
    {
        if ($user->role === 'admin') return true;
        if ($trial->academy_id) {
            return $trial->academy->owner_user_id === $user->id;
        }
        return $trial->posted_by_user_id === $user->id;
    }

    public function register(User $user, Trial $trial): bool
    {
        return $user->role === 'athlete'
            && $trial->status === 'published'
            && ($trial->expires_at === null || $trial->expires_at->isFuture());
    }
}
```

---

## 3. Auth Strategy — Laravel Sanctum

| Flow | Mechanism |
|---|---|
| **Token issuance** | `POST /auth/verify-otp` or `POST /auth/login` → ` Sanctum::createTokenFor()` → plain token in response |
| **Client sends** | `Authorization: Bearer <token>` |
| **Middleware** | `auth:sanctum` on all authenticated routes; custom middleware for role checks |
| **Admin 2FA** | `POST /admin/verify-2fa` validates TOTP; session flag `admin_2fa_verified_at` stored on the token or user model (AS-26 — implementation detail) |
| **Token revocation** | `POST /auth/logout` → `currentAccessToken()->delete()` |
| **Expiry** | Tokens have a configurable lifetime via `sanctum.token_lifetime` (default: 1 year for MVP — adjustable in `config/sportx.php`) |

---

## 4. Queues & Jobs

| Job | Trigger | Queue | Description |
|---|---|---|---|
| `SendOtpJob` | Auth register / resend OTP | `notifications` | Sends OTP via `OtpProvider` interface. Rate-limited to 1 per minute per user. |
| `SweepExpiredContentJob` | Scheduler (hourly) | `default` | Scans published listings against `expiry_events` table; executes pending expirations. |
| `SendDueRemindersJob` | Scheduler (every 15 min) | `notifications` | Dispatches `ReminderSubscription` entries where `remind_at <= now` and `sent_at IS NULL`. |
| `PurgeExpiredOtpsJob` | Scheduler (daily) | `default` | Deletes OTP rows where `expires_at < now - 24h`. |

### Scheduler (`routes/console.php`)

```php
Schedule::command('otp:purge')->dailyAt('02:00');
Schedule::job(new SweepExpiredContentJob)->hourly();
Schedule::job(new SendDueRemindersJob)->everyFifteenMinutes();
```

---

## 5. Event → Listener Wiring

| Event | Listener | Effect |
|---|---|---|
| `EnquiryReplied` | `SendEnquiryReplyNotification` | In-app notification to athlete (via `NotificationService`) |
| `RegistrationConfirmed` | `ArmRegistrationReminder` | Creates `reminder_subscription` rows (T-2d, T-1d offsets — AS-05) |
| `ContentExpired` | (no auto-listener) | Logged; admin can restore via monitor |
| `ListingRemoved` | `NotifyListingOwnerOnModeration` | In-app notification to listing owner |
| `ListingWarned` | `NotifyListingOwnerOnModeration` | In-app notification to listing owner |

---

## 6. Provider Interfaces (vendor-abstraction)

```php
interface OtpProvider {
    public function send(string $destination, string $code): bool;
}

interface NotificationProvider {
    public function push(User $user, array $payload): void;
}
```

Registered in `AppServiceProvider`:
- Default dev implementation: `LogOtpProvider`, `DatabaseNotificationProvider` (writes to `notifications` table only).
- Production swap: bind to `SmsOtpProvider`, `FcmPushProvider` (or vendor of choice) when selected — no code changes beyond config (AS-03).

---

## 7. Configuration (`config/sportx.php`)

```php
return [
    'otp' => [
        'code_length' => 6,
        'expiry_minutes' => 5,
        'max_attempts' => 5,
        'resend_cooldown_seconds' => 60,
        'channel' => 'email',
    ],
    'reminder' => [
        'offsets' => [    // AS-05 — offsets before the event date
            '2_days' => 2,
            '1_day' => 1,
        ],
    ],
    'expiry' => [
        'sweep_frequency_minutes' => 60,
    ],
    'pagination' => [
        'default_per_page' => 20,
        'max_per_page' => 50,
    ],
    'media' => [
        'max_upload_mb' => 10,
        'allowed_image_types' => ['jpg', 'jpeg', 'png', 'webp'],
        'allowed_video_types' => ['mp4'],
        'allowed_document_types' => ['pdf', 'jpg', 'jpeg', 'png'],
    ],
];
```

---

## 8. Route Grouping

```php
// routes/api.php

Route::prefix('v1')->group(function () {

    // Public
    Route::prefix('auth')->group(...);
    Route::prefix('onboarding')->group(...);
    Route::get('meta/{type}', [MetaController::class, 'index']);

    // Authenticated
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('search', [SearchController::class, 'results']);
        Route::apiResource('academies', DirectoryController::class)->only(['index', 'show']);
        // ... directories, enquiries, registrations, saved, notifications, settings, profile

        // Role-scoped
        Route::middleware('role:coach')->prefix('coach')->group(...);
        Route::middleware('role:academy')->prefix('academy')->group(...);
        Route::middleware('role:organizer')->prefix('organizer')->group(...);
        Route::middleware('role:sponsor')->prefix('sponsor')->group(...);
    });

    // Admin
    Route::prefix('admin')->group(function () {
        Route::post('login', [AdminAuthController::class, 'login']);
        Route::post('verify-2fa', [AdminAuthController::class, 'verify2fa']);
        Route::middleware(['auth:sanctum', 'role:admin', 'admin.2fa'])->group(function () {
            Route::get('dashboard', ...);
            Route::prefix('content')->group(...);
            Route::prefix('moderation')->group(...);
            Route::prefix('expiry')->group(...);
            Route::prefix('categories')->group(...);
        });
    });
});
```

> Custom `role:coach` middleware checks `$user->role === 'coach'`. `admin.2fa` middleware checks `admin_2fa_verified_at` timestamp is recent (within session, AS-26).

---

## 9. Testing Strategy

| Layer | Tool | Coverage target |
|---|---|---|
| Unit — Services | PHPUnit | Business rules: registration constraints, expiry logic, capacity enforcement |
| Unit — Policies | PHPUnit | Role + ownership assertions |
| Feature — API | PHPUnit/Pest | Full request → response cycle per endpoint, edge cases (duplicate registration, closed trial) |
| Jobs | PHPUnit | Sweep job creates expiry events correctly |
| Integration | — | No third-party integration tests until vendor selected |

> Test environment uses `database` queue driver and `LogOtpProvider` to avoid external dependencies.
