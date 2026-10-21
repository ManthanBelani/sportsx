<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\User;
use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\Trial;
use App\Models\Tournament;
use App\Models\TournamentRegistration;
use App\Models\Sponsorship;
use App\Models\Scholarship;
use App\Models\ListingReport;
use App\Models\ExpiryEvent;
use App\Models\VerificationRequest;

class AdminDashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $activeListings = Academy::where('listing_status', 'published')->count()
            + CoachProfile::where('listing_status', 'published')->count()
            + Trial::where('status', 'published')->count()
            + Tournament::where('status', 'published')->count()
            + Sponsorship::where('status', 'published')->count();

        $flaggedCount = ListingReport::where('status', 'pending')->count();

        $pendingExpirations = ExpiryEvent::where('status', 'pending')->count();

        $newSignups = User::where('created_at', '>=', now()->subDays(30))->count();

        $totalUsers = User::count();

        $pendingApprovals = VerificationRequest::where('status', 'pending')->count()
            + User::where('status', 'pending')->count();

        // ── Registration activity ──────────────────────────────────────────
        // Confirmed registrations live in tournament_registrations; external
        // register-button clicks live on the tournament row. They are counted
        // separately because an external click is NOT a confirmed
        // registration — the external site never shares its data with us.
        $confirmedRegistrations = TournamentRegistration::where('approval_status', 'approved')->count();
        $pendingRegistrations = TournamentRegistration::where('approval_status', 'pending')->count();
        $totalRegistrations = TournamentRegistration::count();
        $externalClicks = (int) Tournament::sum('external_registration_clicks');
        $tournamentsWithExternal = Tournament::whereNotNull('external_registration_url')->count();

        return response()->json([
            'data' => [
                'active_listings' => $activeListings,
                'flagged_items' => $flaggedCount,
                'pending_expirations' => $pendingExpirations,
                'new_signups_30d' => $newSignups,
                'total_users' => $totalUsers,
                'pending_approvals' => $pendingApprovals,
                'tournament_registrations' => $totalRegistrations,
                'confirmed_tournament_registrations' => $confirmedRegistrations,
                'pending_tournament_registrations' => $pendingRegistrations,
                'external_registration_clicks' => $externalClicks,
                'tournaments_with_external_registration' => $tournamentsWithExternal,
            ]
        ]);
    }
}
