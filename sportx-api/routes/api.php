<?php

use App\Http\Controllers\AcademyController;
use App\Http\Controllers\ActivityController;
use App\Http\Controllers\AthleteDiscoveryController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ConnectionController;
use App\Http\Controllers\ConversationController;
use App\Http\Controllers\CoachProfileController;
use App\Http\Controllers\DirectoryController;
use App\Http\Controllers\EnquiryController;
use App\Http\Controllers\MediaController;
use App\Http\Controllers\MetaController;
use App\Http\Controllers\NotificationController;
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
use App\Http\Controllers\SponsorEngagementController;
use App\Http\Controllers\SponsorshipController;
use App\Http\Controllers\SportsVenueController;
use App\Http\Controllers\TournamentController;
use App\Http\Controllers\TrialController;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\Admin\AdminContentController;
use App\Http\Controllers\Admin\AdminModerationController;
use App\Http\Controllers\Admin\AdminExpiryController;
use App\Http\Controllers\Admin\AdminCategoryController;
use App\Http\Controllers\AdminUserController;
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

    // ── Auth (public) ──
    // Throttle credential endpoints to mitigate brute-force / abuse.
    Route::middleware(['throttle:10,1'])->group(function () {
        Route::post('/auth/register', [AuthController::class, 'register']);
        Route::post('/auth/verify-email', [AuthController::class, 'verifyEmail']);
        Route::post('/auth/login', [AuthController::class, 'login']);
        Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);
    });
    Route::post('/auth/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
    Route::get('/auth/me', [AuthController::class, 'me'])->middleware('auth:sanctum');

    // ── Meta / Master Data (public read) ──
    Route::get('/meta/sports', [MetaController::class, 'sports']);
    Route::get('/meta/cities', [MetaController::class, 'cities']);
    Route::get('/meta/age-groups', [MetaController::class, 'ageGroups']);
    Route::get('/meta/trending-searches', [MetaController::class, 'trendingSearches']);

    // ── Onboarding ──
    Route::post('/onboarding/athlete', [OnboardingController::class, 'athlete'])->middleware('auth:sanctum');
    Route::post('/onboarding/coach', [OnboardingController::class, 'coach'])->middleware('auth:sanctum');
    Route::post('/onboarding/academy', [OnboardingController::class, 'academy'])->middleware('auth:sanctum');
    Route::post('/onboarding/organizer', [OnboardingController::class, 'organizer'])->middleware('auth:sanctum');
    Route::post('/onboarding/sponsor', [OnboardingController::class, 'sponsor'])->middleware('auth:sanctum');

    // ── Directories (public read) ──
    Route::get('/academies', [DirectoryController::class, 'academies']);
    Route::get('/academies/{id}', [DirectoryController::class, 'academy']);
    Route::get('/coaches', [DirectoryController::class, 'coaches']);
    Route::get('/coaches/{id}', [DirectoryController::class, 'coach']);
    Route::get('/trials', [TrialController::class, 'index']);
    Route::get('/trials/{id}', [TrialController::class, 'show']);
    Route::get('/tournaments', [TournamentController::class, 'index']);
    Route::get('/tournaments/{id}', [TournamentController::class, 'show']);
    Route::get('/scholarships', [ScholarshipController::class, 'index']);
    Route::get('/scholarships/{id}', [ScholarshipController::class, 'show']);
    Route::get('/sponsorships', [SponsorshipController::class, 'index']);
    Route::get('/sponsorships/{id}', [SponsorshipController::class, 'show']);
    Route::get('/sports-venues', [SportsVenueController::class, 'index']);
    Route::get('/sports-venues/{id}', [SportsVenueController::class, 'show']);

    // ── Universal Search ──
    Route::get('/search', [SearchController::class, 'search']);

    // ── Media ──
    Route::post('/media/upload', [MediaController::class, 'upload'])->middleware('auth:sanctum');
    Route::delete('/media/{id}', [MediaController::class, 'destroy'])->middleware('auth:sanctum');
    Route::put('/media/reorder', [MediaController::class, 'reorder'])->middleware('auth:sanctum');
    Route::get('/media/download/{id}', [MediaController::class, 'download'])->name('media.download');

    // ── Saved Items ──
    Route::get('/me/saved', [SavedItemController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/me/saved', [SavedItemController::class, 'store'])->middleware('auth:sanctum');
    Route::delete('/me/saved', [SavedItemController::class, 'destroy'])->middleware('auth:sanctum');

    // ── Reports ──
    Route::post('/reports', [ReportController::class, 'store'])->middleware('auth:sanctum');

    // ── Athlete self-service ──
    Route::get('/me/profile', [ProfileController::class, 'show'])->middleware('auth:sanctum');
    Route::put('/me/profile', [ProfileController::class, 'update'])->middleware('auth:sanctum');
    Route::put('/me/profile/sports', [ProfileController::class, 'updateSports'])->middleware('auth:sanctum');

    // ── Provider self-service (Phase 2) ──
    Route::get('/me/coach-profile', [CoachProfileController::class, 'show'])->middleware(['auth:sanctum', 'role:coach']);
    Route::put('/me/coach-profile', [CoachProfileController::class, 'update'])->middleware(['auth:sanctum', 'role:coach']);
    Route::get('/me/academy', [AcademyController::class, 'show'])->middleware(['auth:sanctum', 'role:academy']);
    Route::put('/me/academy', [AcademyController::class, 'update'])->middleware(['auth:sanctum', 'role:academy']);

    // ── Enquiries ──
    Route::post('/enquiries', [EnquiryController::class, 'store'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/me/enquiries', [EnquiryController::class, 'inbox'])->middleware('auth:sanctum');
    Route::get('/enquiries/{id}', [EnquiryController::class, 'show'])->middleware('auth:sanctum');
    Route::post('/enquiries/{id}/messages', [EnquiryController::class, 'reply'])->middleware('auth:sanctum');
    Route::put('/enquiries/{id}/read', [EnquiryController::class, 'markRead'])->middleware('auth:sanctum');

    // ── Athlete Discovery (sponsor) ──
    Route::get('/athletes', [AthleteDiscoveryController::class, 'index'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::get('/athletes/{id}', [AthleteDiscoveryController::class, 'show'])->middleware('auth:sanctum');

    // ── Registrations (Phase 2) ──
    Route::post('/trials/{trial}/register', [RegistrationController::class, 'storeTrial'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/trials/{trial}/registrations', [RegistrationController::class, 'trialIndex'])->middleware('auth:sanctum');
    Route::get('/registrations/trials/{registration}', [RegistrationController::class, 'trialShow'])->middleware('auth:sanctum');
    Route::post('/registrations/trials/{registration}/verify', [RegistrationController::class, 'verifyTrial'])->middleware('auth:sanctum');
    Route::post('/registrations/trials/{registration}/reject', [RegistrationController::class, 'rejectTrial'])->middleware('auth:sanctum');
    Route::post('/registrations/trials/{registration}/reminder', [RegistrationController::class, 'toggleTrialReminder'])->middleware('auth:sanctum');

    Route::post('/tournaments/{tournament}/register', [RegistrationController::class, 'storeTournament'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/tournaments/{tournament}/registrations', [RegistrationController::class, 'tournamentIndex'])->middleware('auth:sanctum');
    Route::get('/tournaments/{tournament}/capacity', [RegistrationController::class, 'tournamentCapacity'])->middleware('auth:sanctum');
    Route::put('/tournaments/{tournament}/capacity', [RegistrationController::class, 'updateTournamentCapacity'])->middleware('auth:sanctum');
    Route::patch('/registrations/tournaments/{registration}/payment', [RegistrationController::class, 'updateTournamentPayment'])->middleware('auth:sanctum');
    Route::get('/me/registrations', [RegistrationController::class, 'myRegistrations'])->middleware('auth:sanctum');
    Route::get('/registrations/trials/{registration}/ics', [RegistrationController::class, 'downloadTrialIcs'])->middleware('auth:sanctum');
    Route::get('/registrations/tournaments/{registration}/ics', [RegistrationController::class, 'downloadTournamentIcs'])->middleware('auth:sanctum');

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

    // ── Sponsor Engagement (Phase 2) ──
    Route::get('/me/sponsorships', [SponsorEngagementController::class, 'mySponsorships'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::post('/me/sponsorships', [SponsorEngagementController::class, 'storeSponsorship'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::put('/me/sponsorships/{sponsorship}', [SponsorEngagementController::class, 'updateSponsorship'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::post('/me/sponsorships/{sponsorship}/publish', [SponsorEngagementController::class, 'publishSponsorship'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::post('/me/sponsorships/{sponsorship}/close', [SponsorEngagementController::class, 'closeSponsorship'])->middleware(['auth:sanctum', 'role:sponsor']);

    Route::post('/sponsorships/{sponsorship}/apply', [SponsorEngagementController::class, 'apply'])->middleware(['auth:sanctum', 'role:athlete']);
    Route::get('/me/applications', [SponsorEngagementController::class, 'myApplications'])->middleware('auth:sanctum');

    Route::get('/sponsorships/{sponsorship}/applications', [SponsorEngagementController::class, 'applications'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::patch('/sponsorships/{sponsorship}/applications/{application}', [SponsorEngagementController::class, 'updateApplication'])->middleware(['auth:sanctum', 'role:sponsor']);

    Route::get('/me/shortlist', [SponsorEngagementController::class, 'shortlist'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::post('/me/shortlist', [SponsorEngagementController::class, 'addToShortlist'])->middleware(['auth:sanctum', 'role:sponsor']);
    Route::delete('/me/shortlist/{entry}', [SponsorEngagementController::class, 'removeFromShortlist'])->middleware(['auth:sanctum', 'role:sponsor']);

    // ── Notifications (Phase 2) ──
    Route::get('/me/notifications', [NotificationController::class, 'index'])->middleware('auth:sanctum');
    Route::patch('/me/notifications/{notification}/read', [NotificationController::class, 'markRead'])->middleware('auth:sanctum');
    Route::post('/me/notifications/read-all', [NotificationController::class, 'markAllRead'])->middleware('auth:sanctum');
    Route::delete('/me/notifications/{notification}', [NotificationController::class, 'destroy'])->middleware('auth:sanctum');

    // ── Settings (Phase 2) ──
    Route::get('/me/settings', [SettingsController::class, 'show'])->middleware('auth:sanctum');
    Route::put('/me/settings', [SettingsController::class, 'update'])->middleware('auth:sanctum');
    Route::put('/me/settings/password', [SettingsController::class, 'updatePassword'])->middleware('auth:sanctum');
    Route::delete('/me/account', [SettingsController::class, 'destroy'])->middleware('auth:sanctum');

    // ── Activity (Phase 2) ──
    Route::get('/me/activity', [ActivityController::class, 'index'])->middleware('auth:sanctum');

    // ── Recent Searches ──
    Route::get('/me/recent-searches', [SearchController::class, 'recentSearches'])->middleware('auth:sanctum');

    // ── Conversations / Chat (Phase 4) ──
    Route::get('/me/conversations', [ConversationController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/me/conversations', [ConversationController::class, 'store'])->middleware('auth:sanctum');
    Route::get('/conversations/{id}', [ConversationController::class, 'show'])->middleware('auth:sanctum');
    Route::post('/conversations/{id}/messages', [ConversationController::class, 'sendMessage'])->middleware('auth:sanctum');
    Route::put('/conversations/{id}/read', [ConversationController::class, 'markRead'])->middleware('auth:sanctum');

    // ── Connections (Phase 4) ──
    Route::get('/me/connections', [ConnectionController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/me/connections/request', [ConnectionController::class, 'request'])->middleware('auth:sanctum');
    Route::post('/me/connections/{id}/accept', [ConnectionController::class, 'accept'])->middleware('auth:sanctum');
    Route::delete('/me/connections/{id}', [ConnectionController::class, 'destroy'])->middleware('auth:sanctum');
    Route::get('/me/connections/requests', [ConnectionController::class, 'requests'])->middleware('auth:sanctum');

    // ── Social Posts (Phase 4) ──
    Route::get('/posts', [PostController::class, 'index'])->middleware('auth:sanctum');
    Route::post('/posts', [PostController::class, 'store'])->middleware('auth:sanctum');
    Route::get('/posts/{id}', [PostController::class, 'show'])->middleware('auth:sanctum');
    Route::post('/posts/{id}/like', [PostController::class, 'toggleLike'])->middleware('auth:sanctum');
    Route::post('/posts/{id}/comments', [PostController::class, 'comment'])->middleware('auth:sanctum');

    // ── Onboarding Schema ──
    Route::get('/onboarding/{role}', [OnboardingController::class, 'schema'])->middleware('auth:sanctum');

    // ═══════════════════════════════════════════════════════════════
    // ADMIN ROUTES
    // ═══════════════════════════════════════════════════════════════
    Route::prefix('admin')->group(function () {

        // Admin Auth
        Route::post('/login', [AdminAuthController::class, 'login']);
        Route::post('/verify-2fa', [AdminAuthController::class, 'verify2fa'])->middleware('auth:sanctum');
        Route::post('/logout', [AdminAuthController::class, 'logout'])->middleware('auth:sanctum');
        Route::get('/me', [AdminAuthController::class, 'me'])->middleware(['auth:sanctum', 'role:admin']);

        // Admin Dashboard
        Route::get('/dashboard', [AdminDashboardController::class, 'index'])
            ->middleware(['auth:sanctum', 'role:admin']);

        // Admin Content Management
        Route::get('/content', [AdminContentController::class, 'picker'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::get('/content/{type}', [AdminContentController::class, 'index'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/content/{type}', [AdminContentController::class, 'store'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::get('/content/{type}/{id}', [AdminContentController::class, 'show'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::put('/content/{type}/{id}', [AdminContentController::class, 'update'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::delete('/content/{type}/{id}', [AdminContentController::class, 'destroy'])
            ->middleware(['auth:sanctum', 'role:admin']);

        // Admin Moderation
        Route::get('/moderation/queue', [AdminModerationController::class, 'queue'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::get('/moderation/reports/{id}', [AdminModerationController::class, 'show'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/moderation/reports/{id}/approve', [AdminModerationController::class, 'approve'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/moderation/reports/{id}/remove', [AdminModerationController::class, 'remove'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/moderation/reports/{id}/warn', [AdminModerationController::class, 'warn'])
            ->middleware(['auth:sanctum', 'role:admin']);

        // Admin Expiry
        Route::get('/expiry-rules', [AdminExpiryController::class, 'getRules'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::put('/expiry-rules', [AdminExpiryController::class, 'updateRules'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::get('/expiry/monitor', [AdminExpiryController::class, 'monitor'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/expiry/events/{id}/override', [AdminExpiryController::class, 'override'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/expiry/events/{id}/restore', [AdminExpiryController::class, 'restore'])
            ->middleware(['auth:sanctum', 'role:admin']);

        // Admin Categories
        Route::get('/categories/sports', [AdminCategoryController::class, 'sportsIndex'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/categories/sports', [AdminCategoryController::class, 'sportsStore'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::put('/categories/sports/{id}', [AdminCategoryController::class, 'sportsUpdate'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::delete('/categories/sports/{id}', [AdminCategoryController::class, 'sportsDestroy'])
            ->middleware(['auth:sanctum', 'role:admin']);

        Route::get('/categories/cities', [AdminCategoryController::class, 'citiesIndex'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/categories/cities', [AdminCategoryController::class, 'citiesStore'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::put('/categories/cities/{id}', [AdminCategoryController::class, 'citiesUpdate'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::delete('/categories/cities/{id}', [AdminCategoryController::class, 'citiesDestroy'])
            ->middleware(['auth:sanctum', 'role:admin']);

        Route::get('/categories/age-groups', [AdminCategoryController::class, 'ageGroupsIndex'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/categories/age-groups', [AdminCategoryController::class, 'ageGroupsStore'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::put('/categories/age-groups/{id}', [AdminCategoryController::class, 'ageGroupsUpdate'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::delete('/categories/age-groups/{id}', [AdminCategoryController::class, 'ageGroupsDestroy'])
            ->middleware(['auth:sanctum', 'role:admin']);

        // Admin User Management (Phase 4 completion)
        Route::get('/users', [AdminUserController::class, 'index'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::get('/users/{id}', [AdminUserController::class, 'show'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/users/{id}/approve', [AdminUserController::class, 'approve'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/users/{id}/reject', [AdminUserController::class, 'reject'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/users/{id}/suspend', [AdminUserController::class, 'suspend'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::delete('/users/{id}', [AdminUserController::class, 'destroy'])
            ->middleware(['auth:sanctum', 'role:admin']);

        // Admin Opportunity (sponsorship) review queue
        Route::get('/opportunities', [AdminUserController::class, 'opportunities'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/opportunities/{id}/approve', [AdminUserController::class, 'approveOpportunity'])
            ->middleware(['auth:sanctum', 'role:admin']);
        Route::post('/opportunities/{id}/reject', [AdminUserController::class, 'rejectOpportunity'])
            ->middleware(['auth:sanctum', 'role:admin']);

        // Admin Notification broadcast
        Route::post('/notifications/broadcast', [AdminUserController::class, 'broadcast'])
            ->middleware(['auth:sanctum', 'role:admin']);
    });
});
