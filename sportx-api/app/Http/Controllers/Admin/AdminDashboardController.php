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
use App\Models\Sponsorship;
use App\Models\Scholarship;
use App\Models\ListingReport;
use App\Models\ExpiryEvent;

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

        return response()->json([
            'data' => [
                'active_listings' => $activeListings,
                'flagged_items' => $flaggedCount,
                'pending_expirations' => $pendingExpirations,
                'new_signups_30d' => $newSignups,
            ]
        ]);
    }
}
