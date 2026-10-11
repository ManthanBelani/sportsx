# Backend Architecture — SportX India (Laravel)

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

Laravel API architecture: folder structure, layers (controllers → services → models), queues/jobs, auth strategy. Consistent with `Database-Design.md` and `Class-Diagram.md`.

> **New-design deltas applied here:** `sponsor` role removed (→ `opportunities`), `scout` added; OTP (phone + email) restored to P0; guardian consent; social feed/network/messaging; leaderboard engine; 30-field profiles; verification queue + admin user management.

> **Assumptions**
> - Laravel 11.x (latest stable as of spec authoring — AS-23). Folder structure follows the Laravel 11 default (`app/`, `routes/`, `database/`).
> - PHP 8.2+ (AS-24).
> - **Auth:** Laravel Sanctum for API token management — AS-16. OTP (phone or email) is the primary signup/login path.
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
│   │   │   ├── AuthController.php                    # register/login OTP (phone/email) + password + Google
│   │   │   ├── GuardianController.php                # guardian consent + parent controls (minors)
│   │   │   ├── OnboardingController.php              # athlete/coach/academy/organizer/scout/generalized
│   │   │   ├── MetaController.php                    # sports, cities, age-groups, positions, facilities, faqs
│   │   │   ├── ProfileController.php                 # own/public profile, privacy, completion checklist
│   │   │   ├── AchievementController.php             # typed achievements CRUD (athlete/coach)
│   │   │   ├── VerificationController.php            # request blue check (A.10)
│   │   │   ├── DirectoryController.php              # academies, coaches, organizers, scouts (list + detail)
│   │   │   ├── TrialController.php                  # trials (list + detail)
│   │   │   ├── TournamentController.php              # tournaments (list + detail)
│   │   │   ├── OpportunityController.php             # unified scholarships/sponsorships/tryouts/camps + apply
│   │   │   ├── ProgramController.php                 # training programs + enquiry
│   │   │   ├── FacilityController.php                # academy facilities CRUD
│   │   │   ├── SportsVenueController.php             # sports venues (list + detail)
│   │   │   ├── FeedController.php                    # social feed tabs
│   │   │   ├── PostController.php                    # posts + likes + comments
│   │   │   ├── NetworkController.php                 # follow + connection requests
│   │   │   ├── ConversationController.php            # 1:1 chat threads + messages
│   │   │   ├── BlockController.php                   # block/unblock
│   │   │   ├── LeaderboardController.php             # ranks + home strip
│   │   │   ├── SearchController.php
│   │   │   ├── HomeController.php                    # role-aware dashboard
│   │   │   ├── ExploreController.php                 # grouped explore sections
│   │   │   ├── EnquiryController.php
│   │   │   ├── RegistrationController.php           # trial + tournament registrations
│   │   │   ├── ScoutController.php                   # scout dashboard/shortlist/observations/reports/contact
│   │   │   ├── ProviderTrialController.php           # coach/academy/organizer trial CRUD
│   │   │   ├── ProviderTournamentController.php       # organizer tournament CRUD
│   │   │   ├── ProviderEventController.php            # unified /me/events + registrant export
│   │   │   ├── RegistrantController.php              # registrant management
│   │   │   ├── CapacityController.php                # capacity management
│   │   │   ├── ResultsController.php                 # results publish/view
│   │   │   ├── SavedItemController.php
│   │   │   ├── ReportController.php                  # reports (user/post/listing morphs)
│   │   │   ├── NotificationController.php            # tabs + device tokens
│   │   │   ├── SettingsController.php
│   │   │   ├── AnalyticsController.php               # product/funnel event log
│   │   │   ├── ShareController.php                   # public deep-link resolver (P1)
│   │   │   ├── SupportController.php                 # report-a-problem / contact
│   │   │   ├── CoachProfileController.php            # coach self-service
│   │   │   ├── AcademyListingController.php          # academy self-service
│   │   │   └── AthleteDiscoveryController.php       # scout / universal athlete search
│   │   └── Admin/
│   │       ├── AdminAuthController.php
│   │       ├── AdminDashboardController.php
│   │       ├── AdminUserController.php               # AD.3 users + suspend/ban/verify
│   │       ├── AdminVerificationController.php       # AD.4 verification queue
│   │       ├── AdminContentController.php            # + opportunities/programs/facilities/posts
│   │       ├── AdminModerationController.php
│   │       ├── AdminBroadcastController.php          # AD.12 (P1)
│   │       ├── AdminExpiryController.php
│   │       ├── AdminLeaderboardController.php        # AD.11 config + reset (P1)
│   │       └── AdminCategoryController.php           # sports/cities/age-groups/positions
│   ├── Middleware/
│   │   ├── EnsureJsonResponse.php
│   │   ├── SetUserLocale.php                         # future: i18n
│   │   └── RateLimitOtp.php
│   ├── Requests/
│   │   ├── Auth/
│   │   │   ├── RegisterRequest.php
│   │   │   ├── SendOtpRequest.php
│   │   │   ├── VerifyOtpRequest.php
│   │   │   ├── ResendOtpRequest.php
│   │   │   ├── LoginRequest.php
│   │   │   └── ForgotPasswordRequest.php
│   │   ├── Guardian/
│   │   │   ├── GuardianConsentRequest.php
│   │   │   ├── VerifyGuardianOtpRequest.php
│   │   │   └── UpdateGuardianControlsRequest.php
│   │   ├── Onboarding/
│   │   │   ├── AthleteOnboardingRequest.php
│   │   │   ├── CoachOnboardingRequest.php
│   │   │   ├── AcademyOnboardingRequest.php
│   │   │   ├── OrganizerOnboardingRequest.php
│   │   │   ├── ScoutOnboardingRequest.php
│   │   │   └── GeneralizedOnboardingRequest.php
│   │   ├── Profile/
│   │   │   ├── UpdateAthleteProfileRequest.php
│   │   │   ├── UpdateCoachProfileRequest.php
│   │   │   ├── UpdateScoutProfileRequest.php
│   │   │   ├── UpdateOrgProfileRequest.php
│   │   │   ├── UpdatePrivacyRequest.php
│   │   │   └── StoreVerificationRequest.php
│   │   ├── Listing/
│   │   │   ├── StoreTrialRequest.php
│   │   │   ├── UpdateTrialRequest.php
│   │   │   ├── StoreTournamentRequest.php
│   │   │   ├── StoreEventRequest.php
│   │   │   ├── StoreOpportunityRequest.php
│   │   │   ├── StoreProgramRequest.php
│   │   │   ├── StoreFacilityRequest.php
│   │   │   ├── StoreEnquiryRequest.php
│   │   │   ├── StoreTrialRegistrationRequest.php
│   │   │   └── ...
│   │   ├── Social/
│   │   │   ├── StorePostRequest.php
│   │   │   ├── StoreCommentRequest.php
│   │   │   ├── StoreConnectionRequest.php
│   │   │   ├── StoreConversationRequest.php
│   │   │   ├── SendMessageRequest.php
│   │   │   └── StoreBlockRequest.php
│   │   ├── Scout/
│   │   │   ├── ShortlistRequest.php
│   │   │   ├── StoreObservationRequest.php
│   │   │   ├── StoreScoutReportRequest.php
│   │   │   └── StoreContactRequest.php
│   │   ├── Admin/
│   │   │   ├── UpdateExpiryRulesRequest.php
│   │   │   ├── RejectVerificationRequest.php
│   │   │   ├── StoreBroadcastRequest.php
│   │   │   ├── UpdateLeaderboardConfigRequest.php
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
│   ├── GuardianConsent.php
│   ├── VerificationRequest.php
│   ├── AdminProfile.php
│   ├── AthleteProfile.php
│   ├── AthleteSport.php
│   ├── CoachProfile.php
│   ├── CoachSport.php
│   ├── Academy.php
│   ├── AcademySport.php
│   ├── AcademyCoach.php
│   ├── Facility.php
│   ├── OrganizerProfile.php
│   ├── OrganizerSport.php
│   ├── TalentScoutProfile.php
│   ├── TalentScoutSport.php
│   ├── GeneralizedProfile.php
│   ├── Position.php
│   ├── Program.php
│   ├── Trial.php
│   ├── TrialRegistration.php
│   ├── TrialRegistrationDocument.php
│   ├── Tournament.php
│   ├── TournamentCategory.php
│   ├── TournamentRegistration.php
│   ├── TournamentResult.php
│   ├── EventSchedule.php
│   ├── EventView.php
│   ├── Opportunity.php
│   ├── OpportunityApplication.php
│   ├── Post.php
│   ├── PostLike.php
│   ├── PostComment.php
│   ├── Follow.php
│   ├── ConnectionRequest.php
│   ├── Conversation.php
│   ├── ConversationParticipant.php
│   ├── Message.php
│   ├── Block.php
│   ├── ScoutShortlist.php
│   ├── Observation.php
│   ├── ScoutReport.php
│   ├── Review.php
│   ├── LeaderboardSeason.php
│   ├── LeaderboardScore.php
│   ├── LeaderboardConfig.php
│   ├── Broadcast.php
│   ├── AnalyticsEvent.php
│   ├── AcademyAthleteInvite.php
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
│   ├── Achievement.php                     # typed records (owner morph athlete/coach)
│   └── MediaItem.php
│
│   # [REMOVED] SponsorProfile, Scholarship, Sponsorship, SponsorshipApplication, ShortlistEntry
│
├── Services/
│   ├── AuthService.php
│   ├── OtpService.php
│   ├── GuardianConsentService.php
│   ├── ProfileService.php
│   ├── VerificationService.php
│   ├── SearchService.php
│   ├── FilterService.php
│   ├── FeedService.php
│   ├── PostService.php
│   ├── OpportunityService.php
│   ├── ProgramService.php
│   ├── FacilityService.php
│   ├── EnquiryService.php
│   ├── ConnectionService.php
│   ├── ChatService.php
│   ├── RegistrationService.php
│   ├── ScoutService.php
│   ├── LeaderboardService.php
│   ├── ReviewService.php
│   ├── ExpiryService.php
│   ├── ReminderService.php
│   ├── ModerationService.php
│   ├── AnalyticsService.php
│   └── NotificationService.php
│
├── Policies/
│   ├── CoachProfilePolicy.php
│   ├── AcademyPolicy.php
│   ├── TrialPolicy.php
│   ├── TournamentPolicy.php
│   ├── RegistrantPolicy.php
│   ├── OpportunityPolicy.php
│   ├── OpportunityApplicationPolicy.php
│   ├── ProgramPolicy.php
│   ├── FacilityPolicy.php
│   ├── PostPolicy.php
│   ├── ConnectionPolicy.php
│   ├── ConversationPolicy.php
│   ├── BlockPolicy.php
│   ├── ScoutDataPolicy.php
│   ├── ReviewPolicy.php
│   ├── VerificationPolicy.php
│   ├── GuardianConsentPolicy.php
│   ├── LeaderboardPolicy.php
│   ├── ReportPolicy.php
│   ├── SavedItemPolicy.php
│   └── AdminPolicy.php
│
├── Enums/
│   ├── UserRole.php                          # athlete|coach|academy|organizer|scout|admin (sponsor removed)
│   ├── UserStatus.php
│   ├── SkillLevel.php
│   ├── ListingStatus.php
│   ├── DocumentStatus.php
│   ├── VerificationStatus.php
│   ├── VerificationRequestStatus.php
│   ├── ConsentStatus.php
│   ├── RegistrationStatus.php
│   ├── ManualPaymentStatus.php
│   ├── OpportunityType.php                  # scholarship|sponsorship|tryout|camp
│   ├── ApplicationStatus.php
│   ├── ConnectionStatus.php
│   ├── ConversationStatus.php
│   ├── ShortlistStatus.php                  # under_review|good|high|final
│   ├── ReportConclusion.php
│   ├── ReviewStatus.php
│   ├── ProgramStatus.php
│   ├── FacilityType.php
│   ├── BroadcastStatus.php
│   ├── LeaderboardNameMode.php
│   ├── Audience.php
│   ├── ExpiryStatus.php
│   ├── ReportReason.php                     # + misleading|spam
│   ├── ReportStatus.php
│   ├── NotificationType.php                 # + follow|connection|message|registration_decision|verification_result|mention|broadcast
│   ├── OtpChannel.php                       # email|phone
│   └── OtpPurpose.php
│
├── Events/
│   ├── EnquiryReplied.php
│   ├── RegistrationConfirmed.php
│   ├── RegistrationDecided.php
│   ├── VerificationDecided.php
│   ├── ConnectionAccepted.php
│   ├── MentionCreated.php
│   ├── ContentReported.php
│   ├── ContentExpired.php
│   ├── ListingRemoved.php
│   └── ListingWarned.php
│
├── Listeners/
│   ├── SendEnquiryReplyNotification.php
│   ├── ArmRegistrationReminder.php
│   ├── NotifyRegistrationDecision.php
│   ├── NotifyVerificationResult.php
│   ├── UnlockChatOnConnection.php
│   ├── SendMentionNotification.php
│   ├── RouteContentReport.php
│   └── NotifyListingOwnerOnModeration.php
│
├── Jobs/
│   ├── SendOtpJob.php
│   ├── SweepExpiredContentJob.php
│   ├── SendDueRemindersJob.php
│   ├── PurgeExpiredOtpsJob.php
│   ├── RecalculateLeaderboardJob.php         # on triggers + nightly rebuild
│   ├── ResetLeaderboardSeasonJob.php
│   └── BroadcastNotificationJob.php          # P1
│
├── Notifications/                    # Laravel notification classes (in-app DB channel)
│   ├── OtpNotification.php
│   ├── EnquiryReplyNotification.php
│   ├── RegistrationReminderNotification.php
│   ├── RegistrationDecisionNotification.php
│   ├── VerificationResultNotification.php
│   ├── ConnectionRequestNotification.php
│   ├── MessageNotification.php
│   ├── FollowNotification.php
│   ├── MentionNotification.php
│   ├── LeaderboardMilestoneNotification.php
│   ├── DeadlineReminderNotification.php
│   ├── BroadcastNotification.php
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
│   ├── PositionSeeder.php              # sport-scoped positions (S.4)
│   ├── ExpiryRuleSeeder.php
│   └── LeaderboardConfigSeeder.php     # default weights + season
└── factories/                           # per model

routes/
├── api.php                             # all /api/v1/* routes
└── console.php

tests/
├── Feature/
│   ├── Auth/
│   ├── Guardian/
│   ├── Onboarding/
│   ├── Directory/
│   ├── Trials/
│   ├── Tournaments/
│   ├── Opportunities/
│   ├── Programs/
│   ├── Social/
│   ├── Enquiries/
│   ├── Scout/
│   ├── Leaderboard/
│   ├── Verification/
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
| **OTP (P0)** | `POST /auth/register` triggers OTP; `POST /auth/send-otp` / `resend-otp` (rate-limited 60s, max 5 attempts via `RateLimitOtp`); `POST /auth/verify-otp` over **email or phone** sets `email_verified_at`/`phone_verified_at`. |
| **Token issuance** | `POST /auth/verify-otp` or `POST /auth/login` → `Sanctum::createTokenFor()` → plain token in response |
| **Guardian consent** | `POST /guardian/consent` → `POST /guardian/verify-otp` gates minor profile activation (DOB < 18). |
| **Client sends** | `Authorization: Bearer <token>` |
| **Middleware** | `auth:sanctum` on all authenticated routes; custom middleware for role checks |
| **Admin 2FA** | `POST /admin/verify-2fa` validates TOTP; session flag `admin_2fa_verified_at` stored on the token or user model (AS-26 — implementation detail) |
| **Token revocation** | `POST /auth/logout` → `currentAccessToken()->delete()` |
| **Expiry** | Tokens have a configurable lifetime via `sanctum.token_lifetime` (default: 1 year for MVP — adjustable in `config/sportx.php`) |

---

## 4. Queues & Jobs

| Job | Trigger | Queue | Description |
|---|---|---|---|
| `SendOtpJob` | Auth register / resend OTP | `notifications` | Sends OTP via `OtpProvider` interface (email or phone). Rate-limited to 1 per minute per destination. |
| `SweepExpiredContentJob` | Scheduler (hourly) | `default` | Scans published listings against `expiry_events` table; executes pending expirations (trial/tournament/opportunity/program/facility). |
| `SendDueRemindersJob` | Scheduler (every 15 min) | `notifications` | Dispatches `ReminderSubscription` entries where `remind_at <= now` and `sent_at IS NULL`; includes opportunity deadlines + nearby trials. |
| `PurgeExpiredOtpsJob` | Scheduler (daily) | `default` | Deletes OTP rows where `expires_at < now - 24h`. |
| `RecalculateLeaderboardJob` | Points triggers + nightly | `default` | Rebuilds `leaderboard_scores` from verified achievements, completion milestones and activity. |
| `ResetLeaderboardSeasonJob` | Scheduler / admin | `default` | Closes the active season and opens the next (AD.11). |
| `BroadcastNotificationJob` | Admin broadcast (P1) | `notifications` | FCM fan-out for `broadcasts` audience filter. |

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
| `RegistrationDecided` | `NotifyRegistrationDecision` | Push + in-app decision notification to athlete (approve/reject) |
| `VerificationDecided` | `NotifyVerificationResult` | Notifies requester of blue-check approval/rejection (+reason) |
| `ConnectionAccepted` | `UnlockChatOnConnection` | Notifies both parties; unlocks 1:1 chat |
| `MentionCreated` | `SendMentionNotification` | P1 — mention notification in posts/comments |
| `ContentReported` | `RouteContentReport` | Routes user/post/listing reports to the moderation queue |
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
        'channels' => ['email', 'phone'],   // P0: phone OR email (D1/D5)
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

        // Social / network / messaging (P0)
        Route::get('feed', [FeedController::class, 'index']);
        Route::apiResource('posts', PostController::class);
        Route::prefix('connections')->group(...);
        Route::prefix('conversations')->group(...);
        Route::get('leaderboard', [LeaderboardController::class, 'index']);

        // Role-scoped
        Route::middleware('role:coach')->prefix('coach')->group(...);
        Route::middleware('role:academy')->prefix('academy')->group(...);
        Route::middleware('role:organizer')->prefix('organizer')->group(...);
        Route::middleware('role:scout')->prefix('scout')->group(...);
    });

    // Admin
    Route::prefix('admin')->group(function () {
        Route::post('login', [AdminAuthController::class, 'login']);
        Route::post('verify-2fa', [AdminAuthController::class, 'verify2fa']);
        Route::middleware(['auth:sanctum', 'role:admin', 'admin.2fa'])->group(function () {
            Route::get('dashboard', ...);
            Route::prefix('users')->group(...);           // AD.3 user management
            Route::prefix('verification')->group(...);    // AD.4 queue
            Route::prefix('content')->group(...);
            Route::prefix('moderation')->group(...);
            Route::prefix('broadcasts')->group(...);      // AD.12 (P1)
            Route::prefix('expiry')->group(...);
            Route::prefix('leaderboard')->group(...);     // AD.11 (P1)
            Route::prefix('categories')->group(...);      // + positions
        });
    });
});
```

> Custom `role:coach` middleware checks `$user->role === 'coach'`. `admin.2fa` middleware checks `admin_2fa_verified_at` timestamp is recent (within session, AS-26).

---

## 9. Testing Strategy

| Layer | Tool | Coverage target |
|---|---|---|
| Unit — Services | PHPUnit | Business rules: registration constraints, expiry logic, capacity enforcement, leaderboard points, chat unlock rules |
| Unit — Policies | PHPUnit | Role + ownership assertions (incl. minors/guardian gating, no cold DMs) |
| Feature — API | PHPUnit/Pest | Full request → response cycle per endpoint, edge cases (duplicate registration, closed trial, duplicate application, blocked user) |
| Jobs | PHPUnit | `SweepExpiredContentJob` creates expiry events; `RecalculateLeaderboardJob` scores correctly |
| Integration | — | No third-party integration tests until vendor selected |

> Test environment uses `database` queue driver and `LogOtpProvider` to avoid external dependencies.
