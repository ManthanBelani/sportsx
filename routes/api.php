<?php

use App\Http\Controllers\AcademyController;
use App\Http\Controllers\ActivityController;
use App\Http\Controllers\AthleteDiscoveryController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\GoogleAuthController;
use App\Http\Controllers\GuardianController;
use App\Http\Controllers\VerificationController;
use App\Http\Controllers\OtpController;
use App\Http\Controllers\CompletionChecklistController;
use App\Http\Controllers\ConnectionController;
use App\Http\Controllers\ConversationController;
use App\Http\Controllers\BlockController;
use App\Http\Controllers\FollowController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\EventRegistrationController;
use App\Http\Controllers\LeaderboardController;
use App\Http\Controllers\ObservationController;
use App\Http\Controllers\AthleteContactController;
use App\Http\Controllers\ScoutDashboardController;
use App\Http\Controllers\CoachProfileController;
use App\Http\Controllers\DirectoryController;
use App\Http\Controllers\EnquiryController;
use App\Http\Controllers\MediaController;
use App\Http\Controllers\MetaController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\NotificationPreferenceController;
use App\Http\Controllers\OpportunityController;
use App\Http\Controllers\ProgramController;
use App\Http\Controllers\FacilityController;
use App\Http\Controllers\AchievementController;
use App\Http\Controllers\PrivacyController;
use App\Http\Controllers\AnalyticsController;
use App\Http\Controllers\OnboardingController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ProviderTrialController;
use App\Http\Controllers\ProviderTournamentController;
use App\Http\Controllers\RegistrationController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\ResultsController;
use App\Http\Controllers\SavedItemController;
use App\Http\Controllers\ScholarshipController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\SettingsController;
use App\Http\Controllers\SocialLinksController;
use App\Http\Controllers\SponsorEngagementController;
use App\Http\Controllers\SponsorshipController;
use App\Http\Controllers\SportsVenueController;
use App\Http\Controllers\OrganizerAnalyticsController;
use App\Http\Controllers\TournamentController;
use App\Http\Controllers\TournamentRegistrationClickController;
use App\Http\Controllers\TalentScoutController;
use App\Http\Controllers\ScoutShortlistController;
use App\Http\Controllers\ScoutConnectionController;
use App\Http\Controllers\TrialController;
use App\Http\Controllers\CoachingEnrollmentController;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\Admin\AdminContentController;
use App\Http\Controllers\Admin\AdminModerationController;
use App\Http\Controllers\Admin\AdminExpiryController;
use App\Http\Controllers\Admin\AdminCategoryController;
use App\Http\Controllers\Admin\AdminSettingsController;
use App\Http\Controllers\Admin\EmailSettingsController;
use App\Http\Controllers\Admin\RegistrationAnalyticsController;
use App\Http\Controllers\AdminUserController;
use App\Http\Controllers\Admin\AdminAuditController;
use App\Http\Controllers\LegacyGoneController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {

    // API root — prevents a 404 on the bare prefix and lists key entry points.
    Route::get('/', function () {
        return response()->json([
            'name' => 'SportX India API',
            'version' => 'v1',
            'status' => 'ok',
            'endpoints' => [
                'health' => '/api/v1/health',
                'auth' => '/api/v1/auth/register, /login, /verify-email',
                'directories' => '/api/v1/academies, /coaches, /trials, /tournaments, /scholarships, /sponsorships, /sports-venues',
                'meta' => '/api/v1/meta/sports, /cities, /age-groups',
            ],
        ]);
    });

    Route::get('/health', function () {
        try {
            \Illuminate\Support\Facades\DB::connection()->getPdo();
            return response()->json(['status' => 'ok', 'db' => 'connected']);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'db' => 'disconnected'], 500);
        }
    });
    // Canonical platform health path (plan Phase 0). Keep /health for compat.
    Route::get('/system/health', function () {
        try {
            \Illuminate\Support\Facades\DB::connection()->getPdo();
            return response()->json(['status' => 'ok', 'db' => 'connected', 'version' => 'v1']);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'db' => 'disconnected'], 500);
        }
    });

    // ── Auth (public) ──
    // Throttle credential endpoints to mitigate brute-force / abuse.
    Route::middleware(['throttle:10,1'])->group(function () {
        Route::post('/auth/register', [AuthController::class, 'register']);
        Route::post('/auth/verify-email', [AuthController::class, 'verifyEmail']);
        Route::post('/auth/login', [AuthController::class, 'login']);
        Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);

        // "Continue with Google" — the backend verifies the ID token, so this
        // is an unauthenticated credential exchange like the routes above.
        Route::post('/auth/google', [GoogleAuthController::class, 'login']);
        Route::post('/auth/resend-verification', [AuthController::class, 'resendVerification']);
    });

    // OTP issue/verify. Abused heavily and unauthenticated by necessity (the
    // code is what establishes identity), so these carry their own stricter
    // per-destination throttles inside OtpController.
    Route::middleware(['throttle:20,1'])->group(function () {
        Route::post('/auth/send-otp', [OtpController::class, 'send']);
        Route::post('/auth/resend-otp', [OtpController::class, 'resend']);
        Route::post('/auth/verify-otp', [OtpController::class, 'verify']);
    });
    Route::post('/auth/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

    // Linked third-party identities
    Route::get('/me/social-accounts', [GoogleAuthController::class, 'index'])->middleware('auth:sanctum');
    Route::delete('/me/social-accounts/{provider}', [GoogleAuthController::class, 'destroy'])->middleware('auth:sanctum');
    Route::get('/auth/me', [AuthController::class, 'me'])->middleware('auth:sanctum');

    // ── Guardian consent (minors, DOB < 18) ──
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/guardian/consent', [GuardianController::class, 'request'])->middleware('throttle:5,1');
        Route::post('/guardian/verify-otp', [GuardianController::class, 'verify'])->middleware('throttle:10,1');
        Route::get('/me/guardian-controls', [GuardianController::class, 'show']);
        Route::put('/me/guardian-controls', [GuardianController::class, 'update']);
        Route::delete('/me/guardian-consent', [GuardianController::class, 'revoke']);
    });

    // ── Verification requests (blue check) ──
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/me/verification', [VerificationController::class, 'store'])->middleware('throttle:5,1');
        Route::get('/me/verification', [VerificationController::class, 'index']);

        // Profile completion nudge
        Route::get('/me/completion-checklist', [CompletionChecklistController::class, 'show']);
    });

    // ── Meta / Master Data (public read) ──
    Route::get('/meta/sports', [MetaController::class, 'sports']);
    Route::get('/meta/cities', [MetaController::class, 'cities']);
    Route::get('/meta/age-groups', [MetaController::class, 'ageGroups']);
    Route::get('/meta/positions', [MetaController::class, 'positions']);
    Route::get('/meta/facilities', [MetaController::class, 'facilities']);
    Route::get('/meta/trending-searches', [MetaController::class, 'trendingSearches']);

    // ── Onboarding ──
    Route::post('/onboarding/athlete', [OnboardingController::class, 'athlete'])->middleware('auth:sanctum');
    Route::post('/onboarding/coach', [OnboardingController::class, 'coach'])->middleware('auth:sanctum');
    Route::post('/onboarding/academy', [OnboardingController::class, 'academy'])->middleware('auth:sanctum');
    Route::post('/onboarding/organizer', [OnboardingController::class, 'organizer'])->middleware('auth:sanctum');
    Route::post('/onboarding/sponsor', [OnboardingController::class, 'sponsor'])->middleware('auth:sanctum');
    Route::post('/onboarding/talent-scout', [OnboardingController::class, 'talentScout'])->middleware('auth:sanctum');
    // Canonical v3 alias for the scout role (storage still `talent_scout`).
    Route::post('/onboarding/scout', [OnboardingController::class, 'scout'])->middleware('auth:sanctum');

    // ── Directories (public read) ──
    Route::get('/academies', [DirectoryController::class, 'academies']);
    Route::get('/academies/{id}', [DirectoryController::class, 'academy']);
    Route::get('/coaches', [DirectoryController::class, 'coaches']);
    Route::get('/coaches/{id}', [DirectoryController::class, 'coach']);
    Route::get('/trials', [TrialController::class, 'index']);
    Route::get('/trials/{id}', [TrialController::class, 'show']);
    Route::get('/tournaments', [TournamentController::class, 'index']);
    Route::get('/tournaments/{id}', [TournamentController::class, 'show']);
    // External registration link clicks (tournaments that point "Register" at
    // a third-party form). Throttled and idempotent per click_token.
    Route::post('/tournaments/{id}/registration-click', [TournamentRegistrationClickController::class, 'store'])
        ->middleware('throttle:120,1');
    // Phase 4 cutover: legacy scholarship/sponsorship directories are gone —
    // everything lives under /opportunities (type=scholarship|sponsorship).
    Route::get('/scholarships', [LegacyGoneController::class, 'gone']);
    Route::get('/scholarships/{id}', [LegacyGoneController::class, 'gone']);
    Route::get('/sponsorships', [LegacyGoneController::class, 'gone']);
    Route::get('/sponsorships/{id}', [LegacyGoneController::class, 'gone']);
    Route::get('/sports-venues', [SportsVenueController::class, 'index']);
    Route::get('/sports-venues/{id}', [SportsVenueController::class, 'show']);

    // ── Universal Search ──
    Route::get('/search', [SearchController::class, 'search']);

    // ── Home + Explore (Phase 3) ──
    Route::get('/me/home', [\App\Http\Controllers\HomeController::class, 'home'])->middleware('auth:sanctum');
    Route::get('/explore', [\App\Http\Controllers\HomeController::class, 'explore']);

    // ── Media ──
    Route::get('/me/media', [MediaController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/media/upload', [MediaController::class, 'upload'])->middleware('auth:sanctum');
    Route::delete('/media/{id}', [MediaController::class, 'destroy'])->middleware('auth:sanctum');
    Route::put('/media/reorder', [MediaController::class, 'reorder'])->middleware('auth:sanctum');
    Route::get('/media/download/{id}', [MediaController::class, 'download'])->name('media.download');
    Route::get('/media/{id}/signed-url', [MediaController::class, 'signedUrl'])->middleware('auth:sanctum');

    // ── Saved Items ──
    Route::get('/me/saved', [SavedItemController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/me/saved', [SavedItemController::class, 'store'])->middleware('auth:sanctum');
    Route::delete('/me/saved', [SavedItemController::class, 'destroy'])->middleware('auth:sanctum');

    // ── Reports ──
    Route::post('/reports', [ReportController::class, 'store'])->middleware(['auth:sanctum', 'throttle:20,1']);

    // ── Athlete self-service ──
    Route::get('/me/profile', [ProfileController::class, 'show'])->middleware('auth:sanctum');
    Route::put('/me/profile', [ProfileController::class, 'update'])->middleware('auth:sanctum');
    Route::put('/me/profile/sports', [ProfileController::class, 'updateSports'])->middleware('auth:sanctum');
    Route::put('/me/profile/images', [ProfileController::class, 'updateImages'])->middleware('auth:sanctum');

    // ── Provider self-service (Phase 2) ──
    Route::get('/me/coach-profile', [CoachProfileController::class, 'show'])->middleware(['auth:sanctum', 'role:coach']);
    Route::put('/me/coach-profile', [CoachProfileController::class, 'update'])->middleware(['auth:sanctum', 'role:coach']);
    Route::get('/me/academy', [AcademyController::class, 'show'])->middleware(['auth:sanctum', 'role:academy']);
    Route::put('/me/academy', [AcademyController::class, 'update'])->middleware(['auth:sanctum', 'role:academy']);
    Route::get('/me/organizer', [\App\Http\Controllers\OrganizerProfileController::class, 'show'])->middleware(['auth:sanctum', 'role:organizer']);
    Route::put('/me/organizer', [\App\Http\Controllers\OrganizerProfileController::class, 'update'])->middleware(['auth:sanctum', 'role:organizer']);
    // Organizer team (co-organizers / volunteers).
    Route::get('/me/organizer/team', [\App\Http\Controllers\OrganizerTeamController::class, 'index'])->middleware(['auth:sanctum', 'role:organizer']);
    Route::post('/me/organizer/team', [\App\Http\Controllers\OrganizerTeamController::class, 'store'])->middleware(['auth:sanctum', 'role:organizer']);
    Route::patch('/me/organizer/team/{id}', [\App\Http\Controllers\OrganizerTeamController::class, 'update'])->middleware(['auth:sanctum', 'role:organizer']);
    Route::delete('/me/organizer/team/{id}', [\App\Http\Controllers\OrganizerTeamController::class, 'destroy'])->middleware(['auth:sanctum', 'role:organizer']);

    // ── Organizer public card (Phase 2) ──
    Route::get('/organizers/{id}', [\App\Http\Controllers\OrganizerProfileController::class, 'publicShow']);

    // ── Programs (Phase 5: owner morph coach/academy) ──
    Route::get('/programs', [\App\Http\Controllers\ProgramController::class, 'index']);
    Route::get('/programs/{id}', [\App\Http\Controllers\ProgramController::class, 'show']);
    Route::get('/me/programs', [\App\Http\Controllers\ProgramController::class, 'mine'])->middleware('auth:sanctum');
    Route::post('/me/programs', [\App\Http\Controllers\ProgramController::class, 'store'])->middleware('auth:sanctum');
    Route::put('/me/programs/{id}', [\App\Http\Controllers\ProgramController::class, 'update'])->middleware('auth:sanctum');
    Route::post('/programs/{id}/enquire', [\App\Http\Controllers\ProgramController::class, 'enquire'])->middleware(['auth:sanctum', 'role:athlete']);

    // ── Facilities (Phase 5: academy-owned rows) ──
    Route::get('/facilities/{id}', [\App\Http\Controllers\FacilityController::class, 'show']);
    // Facilities / venues — owned by an academy or by an organizer.
    Route::get('/me/facilities', [\App\Http\Controllers\FacilityController::class, 'mine'])->middleware(['auth:sanctum', 'role:academy,organizer']);
    Route::post('/me/facilities', [\App\Http\Controllers\FacilityController::class, 'store'])->middleware(['auth:sanctum', 'role:academy,organizer']);
    Route::put('/me/facilities/{id}', [\App\Http\Controllers\FacilityController::class, 'update'])->middleware(['auth:sanctum', 'role:academy,organizer']);
    Route::delete('/me/facilities/{id}', [\App\Http\Controllers\FacilityController::class, 'destroy'])->middleware(['auth:sanctum', 'role:academy,organizer']);

    // ── Enquiries ──
    Route::post('/enquiries', [EnquiryController::class, 'store'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/me/enquiries', [EnquiryController::class, 'inbox'])->middleware('auth:sanctum');
    Route::get('/enquiries/{id}', [EnquiryController::class, 'show'])->middleware('auth:sanctum');
    Route::post('/enquiries/{id}/messages', [EnquiryController::class, 'reply'])->middleware('auth:sanctum');
    Route::put('/enquiries/{id}/read', [EnquiryController::class, 'markRead'])->middleware('auth:sanctum');

    // ── Athlete Discovery (sponsor/scout + athlete peer discovery) ──
    Route::get('/athletes', [AthleteDiscoveryController::class, 'index'])->middleware(['auth:sanctum', 'role:sponsor,talent_scout,athlete']);
    Route::get('/athletes/{id}', [AthleteDiscoveryController::class, 'show'])->middleware('auth:sanctum');

    // ── Talent Scout routes ──
    Route::middleware(['auth:sanctum', 'role:talent_scout'])->group(function () {
        // Scout Profile
        Route::get('/me/scout-profile', [TalentScoutController::class, 'show']);
        Route::put('/me/scout-profile', [TalentScoutController::class, 'update']);

        // Shortlist (namespaced to avoid clashing with sponsor GET /me/shortlist)
        Route::get('/me/scout-shortlist', [ScoutShortlistController::class, 'index']);
        Route::post('/me/scout-shortlist/{athlete}', [ScoutShortlistController::class, 'store']);
        Route::delete('/me/scout-shortlist/{athlete}', [ScoutShortlistController::class, 'destroy']);
        Route::patch('/me/scout-shortlist/{athlete}', [ScoutShortlistController::class, 'update']);

        // Connections (namespaced to avoid clashing with generic GET /me/connections)
        Route::get('/me/scout-connections', [ScoutConnectionController::class, 'index']);
        Route::get('/me/scout-connections/incoming', [ScoutConnectionController::class, 'incomingForScout']);
        Route::post('/me/scout-connections/{connection}/accept', [ScoutConnectionController::class, 'acceptForScout']);
        Route::post('/me/scout-connections/{connection}/reject', [ScoutConnectionController::class, 'rejectForScout']);
        Route::delete('/me/scout-connections/{connection}', [ScoutConnectionController::class, 'destroy']);
        Route::get('/scout-connection-status/{type}/{id}', [ScoutConnectionController::class, 'status']);
    });

    // ── Scout directory (athlete discovers scouts — two-way connect) ──
    Route::get('/scouts', [TalentScoutController::class, 'index'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/scouts/{id}', [TalentScoutController::class, 'publicShow'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::middleware(['auth:sanctum', 'role:athlete'])->group(function () {
        Route::post('/scouts/{scout}/connect', [ScoutConnectionController::class, 'storeFromAthlete']);
    });

    Route::middleware(['auth:sanctum'])->group(function () {
        Route::post('/athletes/{athlete}/connect', [ScoutConnectionController::class, 'store']);
    });

    // ── Athlete side of scout connections (incoming requests + accept/reject) ──
    Route::middleware(['auth:sanctum', 'role:athlete'])->group(function () {
        Route::get('/me/scout-connection-requests', [ScoutConnectionController::class, 'indexForAthlete']);
        Route::post('/me/scout-connection-requests/{connection}/accept', [ScoutConnectionController::class, 'accept']);
        Route::post('/me/scout-connection-requests/{connection}/reject', [ScoutConnectionController::class, 'reject']);
    });

    // ── Registrations (Phase 2) ──
    Route::post('/trials/{trial}/register', [RegistrationController::class, 'storeTrial'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/trials/{trial}/registrations', [RegistrationController::class, 'trialIndex'])->middleware('auth:sanctum');
    Route::get('/trials/{trial}/pending-requests', [RegistrationController::class, 'pendingTrialRequests'])->middleware('auth:sanctum');
    Route::get('/registrations/trials/{registration}', [RegistrationController::class, 'trialShow'])->middleware('auth:sanctum');
    Route::post('/registrations/trials/{registration}/verify', [RegistrationController::class, 'verifyTrial'])->middleware('auth:sanctum');
    Route::patch('/registrations/trials/{registration}/approve', [RegistrationController::class, 'approveTrial'])->middleware('auth:sanctum');
    Route::patch('/registrations/trials/{registration}/reject', [RegistrationController::class, 'rejectTrial'])->middleware('auth:sanctum');
    Route::post('/registrations/trials/{registration}/reminder', [RegistrationController::class, 'toggleTrialReminder'])->middleware('auth:sanctum');
    Route::get('/me/registrations/trials', [RegistrationController::class, 'myTrialRegistrations'])->middleware('auth:sanctum');

    Route::post('/tournaments/{tournament}/register', [RegistrationController::class, 'storeTournament'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/tournaments/{tournament}/registrations', [RegistrationController::class, 'tournamentIndex'])->middleware('auth:sanctum');
    Route::get('/tournaments/{tournament}/pending-requests', [RegistrationController::class, 'pendingTournamentRequests'])->middleware('auth:sanctum');
    Route::patch('/registrations/tournaments/{registration}/approve', [RegistrationController::class, 'approveTournament'])->middleware('auth:sanctum');
    Route::patch('/registrations/tournaments/{registration}/reject', [RegistrationController::class, 'rejectTournament'])->middleware('auth:sanctum');
    Route::get('/tournaments/{tournament}/capacity', [RegistrationController::class, 'tournamentCapacity'])->middleware('auth:sanctum');
    Route::put('/tournaments/{tournament}/capacity', [RegistrationController::class, 'updateTournamentCapacity'])->middleware('auth:sanctum');
    Route::patch('/registrations/tournaments/{registration}/payment', [RegistrationController::class, 'updateTournamentPayment'])->middleware('auth:sanctum');
    Route::get('/me/registrations/tournaments', [RegistrationController::class, 'myTournamentRegistrations'])->middleware('auth:sanctum');
    Route::get('/me/registrations', [RegistrationController::class, 'myRegistrations'])->middleware('auth:sanctum');
    Route::get('/registrations/trials/{registration}/ics', [RegistrationController::class, 'downloadTrialIcs'])->middleware('auth:sanctum');
    Route::get('/registrations/tournaments/{registration}/ics', [RegistrationController::class, 'downloadTournamentIcs'])->middleware('auth:sanctum');

    // ── Coaching Enrollments (Approval-Based) ──
    Route::post('/coaches/{coach}/enroll', [CoachingEnrollmentController::class, 'store'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/me/coaching-enrollments', [CoachingEnrollmentController::class, 'myEnrollments'])->middleware('auth:sanctum');
    Route::get('/coach/enrollments', [CoachingEnrollmentController::class, 'coachEnrollments'])->middleware(['auth:sanctum', 'role:coach']);
    Route::patch('/coaching-enrollments/{enrollment}/approve', [CoachingEnrollmentController::class, 'approve'])->middleware(['auth:sanctum', 'role:coach']);
    Route::patch('/coaching-enrollments/{enrollment}/reject', [CoachingEnrollmentController::class, 'reject'])->middleware(['auth:sanctum', 'role:coach']);

    // ── Results (Phase 2) ──
    Route::get('/tournaments/{tournament}/results', [ResultsController::class, 'index']);
    Route::post('/tournaments/{tournament}/results', [ResultsController::class, 'store'])->middleware('auth:sanctum');
    Route::post('/tournaments/{tournament}/results/{result}/publish', [ResultsController::class, 'publish'])->middleware('auth:sanctum');
    Route::post('/tournaments/{tournament}/results/{result}/unpublish', [ResultsController::class, 'unpublish'])->middleware('auth:sanctum');

    // ── Provider Trials (Phase 2) ──
    Route::get('/me/trials', [ProviderTrialController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/me/trials', [ProviderTrialController::class, 'store'])->middleware('auth:sanctum');
    Route::put('/me/trials/{trial}', [ProviderTrialController::class, 'update'])->middleware('auth:sanctum');
    Route::post('/me/trials/{trial}/publish', [ProviderTrialController::class, 'publish'])->middleware('auth:sanctum');
    Route::post('/me/trials/{trial}/close', [ProviderTrialController::class, 'close'])->middleware('auth:sanctum');

    // ── Provider Tournaments (Phase 2) ──
    Route::get('/me/tournaments', [ProviderTournamentController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/me/tournaments', [ProviderTournamentController::class, 'store'])->middleware('auth:sanctum');
    Route::put('/me/tournaments/{tournament}', [ProviderTournamentController::class, 'update'])->middleware('auth:sanctum');
    Route::put('/me/tournaments/{tournament}/categories', [ProviderTournamentController::class, 'updateCategories'])->middleware('auth:sanctum');
    Route::post('/me/tournaments/{tournament}/publish', [ProviderTournamentController::class, 'publish'])->middleware('auth:sanctum');
    Route::post('/me/tournaments/{tournament}/close', [ProviderTournamentController::class, 'close'])->middleware('auth:sanctum');

    // ── Unified events (Phase 8: single API over trials/tournaments; camp→trial) ──
    Route::post('/me/events', [EventController::class, 'store'])->middleware('auth:sanctum');
    Route::get('/me/events', [EventController::class, 'mine'])->middleware('auth:sanctum');
    Route::get('/events/{id}', [EventController::class, 'show'])->middleware('auth:sanctum');
    Route::put('/me/events/{id}', [EventController::class, 'update'])->middleware('auth:sanctum');
    Route::patch('/me/events/{id}', [EventController::class, 'update'])->middleware('auth:sanctum');
    Route::post('/me/events/{id}/publish', [EventController::class, 'publish'])->middleware('auth:sanctum');
    Route::post('/me/events/{id}/close', [EventController::class, 'close'])->middleware('auth:sanctum');

    // ── Unified registrant ops (Phase 8 plan shape; per-type PATCH kept) ──
    Route::get('/events/{id}/registrations', [EventRegistrationController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/events/{id}/registrations/bulk', [EventRegistrationController::class, 'bulk'])->middleware('auth:sanctum');
    Route::get('/events/{id}/registrations/export', [EventRegistrationController::class, 'export'])->middleware('auth:sanctum');
    Route::get('/registrations/{id}', [EventRegistrationController::class, 'show'])->middleware('auth:sanctum');
    Route::post('/registrations/{id}/approve', [EventRegistrationController::class, 'approve'])->middleware('auth:sanctum');
    Route::post('/registrations/{id}/reject', [EventRegistrationController::class, 'reject'])->middleware('auth:sanctum');
    Route::delete('/me/registrations/{id}', [EventRegistrationController::class, 'cancel'])->middleware('auth:sanctum');

    // ── Organizer Analytics ──
    Route::get('/me/organizer/analytics', [OrganizerAnalyticsController::class, 'index'])->middleware(['auth:sanctum', 'role:organizer,admin']);

    // ── Opportunities, unified (Phase 4 — replaces scholarships/sponsorships) ──
    Route::get('/opportunities', [OpportunityController::class, 'index']);
    Route::get('/opportunities/{id}', [OpportunityController::class, 'show']);
    Route::post('/me/opportunities', [OpportunityController::class, 'store'])->middleware('auth:sanctum');
    Route::put('/me/opportunities/{id}', [OpportunityController::class, 'update'])->middleware('auth:sanctum');
    Route::patch('/me/opportunities/{id}', [OpportunityController::class, 'update'])->middleware('auth:sanctum');
    Route::post('/me/opportunities/{id}/publish', [OpportunityController::class, 'publish'])->middleware('auth:sanctum');
    Route::post('/me/opportunities/{id}/close', [OpportunityController::class, 'close'])->middleware('auth:sanctum');
    Route::get('/me/opportunities', [OpportunityController::class, 'mine'])->middleware('auth:sanctum');
    Route::post('/opportunities/{id}/apply', [OpportunityController::class, 'apply'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/opportunities/{id}/applications', [OpportunityController::class, 'applications'])->middleware('auth:sanctum');
    Route::patch('/opportunities/{id}/applications/{appId}', [OpportunityController::class, 'review'])->middleware('auth:sanctum');

    // ── Sponsor Engagement, legacy (Phase 4 cutover — all 410 Gone) ──
    Route::get('/me/sponsorships', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::post('/me/sponsorships', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::put('/me/sponsorships/{sponsorship}', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::post('/me/sponsorships/{sponsorship}/publish', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::post('/me/sponsorships/{sponsorship}/close', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);

    Route::post('/sponsorships/{sponsorship}/apply', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/me/applications', [LegacyGoneController::class, 'gone'])->middleware('auth:sanctum');

    Route::get('/sponsorships/{sponsorship}/applications', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::patch('/sponsorships/{sponsorship}/applications/{application}', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);

    Route::get('/me/shortlist', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::post('/me/shortlist', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::delete('/me/shortlist/{entry}', [LegacyGoneController::class, 'gone'])->middleware(['auth:sanctum', 'role:sponsor']);

    // ── Notifications (Phase 2) ──
    Route::get('/me/notifications', [NotificationController::class, 'index'])->middleware('auth:sanctum');
    Route::patch('/me/notifications/{notification}/read', [NotificationController::class, 'markRead'])->middleware('auth:sanctum');
    Route::post('/me/notifications/read-all', [NotificationController::class, 'markAllRead'])->middleware('auth:sanctum');
    Route::delete('/me/notifications/{notification}', [NotificationController::class, 'destroy'])->middleware('auth:sanctum');
    Route::get('/me/notification-preferences', [NotificationPreferenceController::class, 'show'])->middleware('auth:sanctum');
    Route::put('/me/notification-preferences', [NotificationPreferenceController::class, 'update'])->middleware('auth:sanctum');
    Route::post('/analytics/events', [AnalyticsController::class, 'store'])->middleware('auth:sanctum');
    Route::post('/me/device-tokens', [NotificationController::class, 'registerDeviceToken'])->middleware('auth:sanctum');
    Route::delete('/me/device-tokens', [NotificationController::class, 'unregisterDeviceToken'])->middleware('auth:sanctum');
    // Plan-spec aliases (Phase 3E): same handlers, canonical names.
    Route::post('/me/device-tokens/subscribe', [NotificationController::class, 'registerDeviceToken'])->middleware('auth:sanctum');
    Route::post('/me/device-tokens/test', [NotificationController::class, 'testDeviceToken'])->middleware('auth:sanctum');
    Route::post('/me/notifications/{notification}/send-push', [NotificationController::class, 'sendPushNotification'])->middleware('auth:sanctum');

    // ── Social Links (all roles — stored on users.social_links) ──
    Route::get('/me/social-links', [SocialLinksController::class, 'show'])->middleware('auth:sanctum');
    Route::put('/me/social-links', [SocialLinksController::class, 'update'])->middleware('auth:sanctum');

    // ── Privacy (Phase 2) ──
    Route::get('/me/privacy', [PrivacyController::class, 'show'])->middleware('auth:sanctum');
    Route::put('/me/privacy', [PrivacyController::class, 'update'])->middleware('auth:sanctum');

    // ── Achievements, typed CRUD (Phase 2, owner = own athlete/coach profile) ──
    Route::get('/me/achievements', [AchievementController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/me/achievements', [AchievementController::class, 'store'])->middleware('auth:sanctum');
    Route::put('/me/achievements/{id}', [AchievementController::class, 'update'])->middleware('auth:sanctum');
    Route::delete('/me/achievements/{id}', [AchievementController::class, 'destroy'])->middleware('auth:sanctum');

    // ── Settings (Phase 2) ──
    Route::get('/me/settings', [SettingsController::class, 'show'])->middleware('auth:sanctum');
    Route::put('/me/settings', [SettingsController::class, 'update'])->middleware('auth:sanctum');
    Route::put('/me/settings/password', [SettingsController::class, 'updatePassword'])->middleware('auth:sanctum');
    // Phase-1 spec aliases (FR-AUTH): same handlers, spec-compliant paths.
    Route::post('/me/change-password', [SettingsController::class, 'updatePassword'])->middleware('auth:sanctum');
    Route::delete('/me/account', [SettingsController::class, 'destroy'])->middleware('auth:sanctum');
    Route::post('/me/delete-account', [SettingsController::class, 'destroy'])->middleware('auth:sanctum');

    // ── Activity (Phase 2) ──
    Route::get('/me/activity', [ActivityController::class, 'index'])->middleware('auth:sanctum');

    // ── Recent Searches ──
    Route::get('/me/recent-searches', [SearchController::class, 'recentSearches'])->middleware('auth:sanctum');
    Route::post('/me/recent-searches', [SearchController::class, 'storeRecentSearch'])->middleware('auth:sanctum');

    // ── Conversations / Chat (Phase 6) ──
    Route::get('/me/conversations', [ConversationController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/me/conversations', [ConversationController::class, 'store'])->middleware('auth:sanctum');
    Route::post('/conversations', [ConversationController::class, 'store'])->middleware(['auth:sanctum', 'throttle:60,1']);
    Route::get('/conversations/{id}', [ConversationController::class, 'show'])->middleware('auth:sanctum');
    Route::post('/conversations/{id}/messages', [ConversationController::class, 'sendMessage'])->middleware(['auth:sanctum', 'throttle:120,1']);
    Route::post('/conversations/{id}/read', [ConversationController::class, 'markRead'])->middleware('auth:sanctum');
    Route::put('/conversations/{id}/read', [ConversationController::class, 'markRead'])->middleware('auth:sanctum');
    Route::patch('/conversations/{id}/read', [ConversationController::class, 'markRead'])->middleware('auth:sanctum');

    // ── Connections (Phase 6: POST canonical + legacy aliases) ──
    Route::get('/me/connections', [ConnectionController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/connections', [ConnectionController::class, 'request'])->middleware(['auth:sanctum', 'throttle:30,1']);
    Route::post('/me/connections/request', [ConnectionController::class, 'request'])->middleware('auth:sanctum');
    Route::post('/me/connections/{id}/accept', [ConnectionController::class, 'accept'])->middleware('auth:sanctum');
    Route::patch('/connections/{id}', [ConnectionController::class, 'update'])->middleware('auth:sanctum');
    Route::delete('/connections/{id}', [ConnectionController::class, 'destroy'])->middleware('auth:sanctum');
    Route::delete('/me/connections/{id}', [ConnectionController::class, 'destroy'])->middleware('auth:sanctum');
    Route::get('/me/connections/requests', [ConnectionController::class, 'requests'])->middleware('auth:sanctum');
    Route::get('/me/connections/status/{userId}', [ConnectionController::class, 'status'])->middleware('auth:sanctum');
    Route::get('/me/connections/count', [ConnectionController::class, 'count'])->middleware('auth:sanctum');

    // ── Follows, one-way (Phase 6) ──
    Route::post('/follow/{type}/{id}', [FollowController::class, 'store'])->middleware(['auth:sanctum', 'throttle:60,1']);
    Route::delete('/follow/{type}/{id}', [FollowController::class, 'destroy'])->middleware('auth:sanctum');
    Route::get('/me/following', [FollowController::class, 'following'])->middleware('auth:sanctum');
    Route::get('/me/followers', [FollowController::class, 'followers'])->middleware('auth:sanctum');
    Route::get('/follow/status/{type}/{id}', [FollowController::class, 'status'])->middleware('auth:sanctum');

    // ── Safety: blocks + reports (Phase 6) ──
    Route::get('/blocks', [BlockController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/blocks', [BlockController::class, 'store'])->middleware(['auth:sanctum', 'throttle:30,1']);
    Route::delete('/blocks/{user}', [BlockController::class, 'destroy'])->middleware('auth:sanctum');
    Route::get('/me/reports', [ReportController::class, 'index'])->middleware('auth:sanctum');

    // ── Leaderboard (Phase 7: athletes P0; coach/academy tabs P1) ──
    Route::get('/leaderboard', [LeaderboardController::class, 'index'])->middleware('auth:sanctum');
    Route::get('/leaderboard/strip', [LeaderboardController::class, 'strip'])->middleware('auth:sanctum');

    // ── Scout extensions (Phase 7) ──
    Route::get('/observations', [ObservationController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/observations', [ObservationController::class, 'store'])->middleware(['auth:sanctum', 'throttle:60,1']);
    Route::post('/athletes/{id}/contact', [AthleteContactController::class, 'store'])->middleware('auth:sanctum');
    Route::get('/scout/dashboard', [ScoutDashboardController::class, 'show'])->middleware('auth:sanctum');

    // ── Social Posts (Phase 6) ──
    Route::get('/feed', [PostController::class, 'index'])->middleware('auth:sanctum');
    Route::get('/posts', [PostController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/posts', [PostController::class, 'store'])->middleware(['auth:sanctum', 'throttle:30,1']);
    Route::get('/posts/{id}', [PostController::class, 'show'])->middleware('auth:sanctum');
    Route::patch('/posts/{id}', [PostController::class, 'update'])->middleware('auth:sanctum');
    Route::delete('/posts/{id}', [PostController::class, 'destroy'])->middleware('auth:sanctum');
    Route::post('/posts/{id}/like', [PostController::class, 'toggleLike'])->middleware('auth:sanctum');
    Route::delete('/posts/{id}/like', [PostController::class, 'unlike'])->middleware('auth:sanctum');
    Route::get('/posts/{id}/comments', [PostController::class, 'comments'])->middleware('auth:sanctum');
    Route::post('/posts/{id}/comments', [PostController::class, 'comment'])->middleware('auth:sanctum');
    Route::delete('/comments/{id}', [PostController::class, 'deleteComment'])->middleware('auth:sanctum');

    // ── Onboarding Schema ──
    Route::get('/onboarding/{role}', [OnboardingController::class, 'schema'])->middleware('auth:sanctum');

    // ═══════════════════════════════════════════════════════════════
    // ADMIN ROUTES
    // ═══════════════════════════════════════════════════════════════
    Route::prefix('admin')->middleware(['auth:sanctum', 'role:admin', 'admin.2fa'])->group(function () {

        // Admin Dashboard
        Route::get('/dashboard', [AdminDashboardController::class, 'index']);

        // Verification review queue (blue check)
        Route::get('/verification', [VerificationController::class, 'queue']);
        Route::get('/verification/{id}', [VerificationController::class, 'show']);
        Route::patch('/verification/{id}/approve', [VerificationController::class, 'approve']);
        Route::patch('/verification/{id}/reject', [VerificationController::class, 'reject']);

        // Admin Content Management
        Route::get('/content', [AdminContentController::class, 'picker']);
        Route::get('/content/{type}', [AdminContentController::class, 'index']);
        Route::post('/content/{type}', [AdminContentController::class, 'store']);
        Route::get('/content/{type}/{id}', [AdminContentController::class, 'show']);
        Route::put('/content/{type}/{id}', [AdminContentController::class, 'update']);
        Route::delete('/content/{type}/{id}', [AdminContentController::class, 'destroy']);

        // Admin Moderation
        Route::get('/moderation/queue', [AdminModerationController::class, 'queue']);
        Route::get('/moderation/reports/{id}', [AdminModerationController::class, 'show']);
        Route::post('/moderation/reports/{id}/approve', [AdminModerationController::class, 'approve']);
        Route::post('/moderation/reports/{id}/remove', [AdminModerationController::class, 'remove']);
        Route::post('/moderation/reports/{id}/warn', [AdminModerationController::class, 'warn']);
        Route::post('/moderation/reports/{id}/suspend', [AdminModerationController::class, 'suspend']);

        // Admin Expiry
        Route::get('/expiry-rules', [AdminExpiryController::class, 'getRules']);
        Route::put('/expiry-rules', [AdminExpiryController::class, 'updateRules']);
        Route::get('/expiry/monitor', [AdminExpiryController::class, 'monitor']);
        Route::post('/expiry/events/{id}/override', [AdminExpiryController::class, 'override']);
        Route::post('/expiry/events/{id}/restore', [AdminExpiryController::class, 'restore']);

        // Admin Categories
        Route::get('/categories/sports', [AdminCategoryController::class, 'sportsIndex']);
        Route::post('/categories/sports', [AdminCategoryController::class, 'sportsStore']);
        Route::put('/categories/sports/{id}', [AdminCategoryController::class, 'sportsUpdate']);
        Route::delete('/categories/sports/{id}', [AdminCategoryController::class, 'sportsDestroy']);

        Route::get('/categories/cities', [AdminCategoryController::class, 'citiesIndex']);
        Route::post('/categories/cities', [AdminCategoryController::class, 'citiesStore']);
        Route::put('/categories/cities/{id}', [AdminCategoryController::class, 'citiesUpdate']);
        Route::delete('/categories/cities/{id}', [AdminCategoryController::class, 'citiesDestroy']);

        Route::get('/categories/age-groups', [AdminCategoryController::class, 'ageGroupsIndex']);
        Route::post('/categories/age-groups', [AdminCategoryController::class, 'ageGroupsStore']);
        Route::put('/categories/age-groups/{id}', [AdminCategoryController::class, 'ageGroupsUpdate']);
        Route::delete('/categories/age-groups/{id}', [AdminCategoryController::class, 'ageGroupsDestroy']);

        Route::get('/categories/positions', [AdminCategoryController::class, 'positionsIndex']);
        Route::post('/categories/positions', [AdminCategoryController::class, 'positionsStore']);
        Route::put('/categories/positions/{id}', [AdminCategoryController::class, 'positionsUpdate']);
        Route::delete('/categories/positions/{id}', [AdminCategoryController::class, 'positionsDestroy']);

        // Admin platform settings (JSON API for the mobile System Settings screen)
        Route::get('/settings', [AdminSettingsController::class, 'index']);
        Route::put('/settings', [AdminSettingsController::class, 'update']);

        // Admin Email settings (Phase 3E: provider status, runtime switch, test)
        Route::get('/email-settings', [EmailSettingsController::class, 'show']);
        Route::get('/email-settings/diagnostics', [EmailSettingsController::class, 'diagnostics']);
        Route::post('/email-settings/switch', [EmailSettingsController::class, 'switchProvider']);
        Route::post('/email-settings/test', [EmailSettingsController::class, 'test']);
        Route::post('/email-settings/clear-token-cache', [EmailSettingsController::class, 'clearTokenCache']);

        // Admin User Management
        Route::get('/users', [AdminUserController::class, 'index']);
        Route::get('/users/{id}', [AdminUserController::class, 'show']);
        Route::post('/users/{id}/approve', [AdminUserController::class, 'approve']);
        Route::post('/users/{id}/reject', [AdminUserController::class, 'reject']);
        Route::post('/users/{id}/suspend', [AdminUserController::class, 'suspend']);
        Route::delete('/users/{id}', [AdminUserController::class, 'destroy']);

        // Admin Opportunity (sponsorship) review queue
        Route::get('/opportunities', [AdminUserController::class, 'opportunities']);
        Route::post('/opportunities/{id}/approve', [AdminUserController::class, 'approveOpportunity']);
        Route::post('/opportunities/{id}/reject', [AdminUserController::class, 'rejectOpportunity']);

        // Admin Notification broadcast + delivery stats (Phase 3E/9)
        Route::post('/notifications/broadcast', [AdminUserController::class, 'broadcast']);
        Route::get('/notifications/stats', [NotificationController::class, 'stats']);

        // Admin audit trail (Phase 10: moderation/status/override/provider-switch log)
        Route::get('/audit-logs', [AdminAuditController::class, 'apiIndex']);
        Route::get('/audit-logs/{id}', [AdminAuditController::class, 'apiShow']);

        // Admin approval analytics + overrides
        Route::get('/registrations/analytics/dashboard', [RegistrationAnalyticsController::class, 'dashboard']);
        Route::get('/registrations/activity-log', [RegistrationAnalyticsController::class, 'activityLog']);
        Route::patch('/registrations/tournaments/{registration}/admin-approve', [RegistrationController::class, 'adminApproveTournament']);
        Route::patch('/registrations/tournaments/{registration}/admin-reject', [RegistrationController::class, 'adminRejectTournament']);
        Route::patch('/registrations/trials/{registration}/admin-approve', [RegistrationController::class, 'adminApproveTrial']);
        Route::patch('/registrations/trials/{registration}/admin-reject', [RegistrationController::class, 'adminRejectTrial']);
        Route::patch('/coaching-enrollments/{enrollment}/admin-approve', [CoachingEnrollmentController::class, 'adminApprove']);
        Route::patch('/coaching-enrollments/{enrollment}/admin-reject', [CoachingEnrollmentController::class, 'adminReject']);
    });

    // Admin Auth (no 2FA required - these handle the initial login and 2FA verification)
    Route::prefix('admin')->group(function () {
        Route::post('/login', [AdminAuthController::class, 'login']);
        Route::post('/verify-2fa', [AdminAuthController::class, 'verify2fa'])->middleware('auth:sanctum');
        Route::post('/logout', [AdminAuthController::class, 'logout'])->middleware('auth:sanctum');
        Route::get('/me', [AdminAuthController::class, 'me'])->middleware('auth:sanctum');
    });
});
