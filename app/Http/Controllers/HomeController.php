<?php

namespace App\Http\Controllers;

use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\Notification;
use App\Models\Post;
use App\Models\SavedItem;
use App\Models\SportsVenue;
use App\Models\Tournament;
use App\Models\Trial;
use App\Models\TrialRegistration;
use App\Models\TournamentRegistration;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Role-aware home + grouped Explore (Phase 3).
 *
 * - `GET /me/home`: greeting, completion %, leaderboard strip (empty until
 *   Phase 7), counts, feed preview.
 * - `GET /explore`: capped grouped sections for the Explore shell.
 *
 * @see docs/PHASE_WISE_IMPLEMENTATION_PLAN.md Phase 3
 */
class HomeController extends Controller
{
    /**
     * GET /me/home
     */
    public function home(Request $request): JsonResponse
    {
        $user = $request->user();

        $hour = (int) now()->format('G');
        $greeting = $hour < 12 ? 'Good morning' : ($hour < 17 ? 'Good afternoon' : 'Good evening');

        return response()->json([
            'data' => [
                'greeting' => $greeting,
                'name' => $user->name,
                'role' => $user->role,
                'needs_onboarding' => ! $user->hasRoleProfile(),
                'completion_percent' => CompletionChecklistController::completionFor($user),
                'is_verified' => $user->isVerified(),
                'leaderboard_strip' => $this->leaderboardStrip(),
                'counts' => $this->counts($user),
                'feed_preview' => $this->feedPreview(),
            ],
        ]);
    }

    /**
     * GET /explore (public)
     */
    public function explore(Request $request): JsonResponse
    {
        $n = min((int) ($request->input('per_section', 6)), 10);

        return response()->json([
            'data' => [
                'academies' => Academy::published()->with(['city', 'logo'])->latest()->limit($n)->get(),
                'coaches' => CoachProfile::where('listing_status', 'published')->with(['sport', 'city'])->latest()->limit($n)->get(),
                'trials' => Trial::open()->with(['sport', 'city'])->orderBy('event_datetime')->limit($n)->get(),
                'tournaments' => Tournament::published()->with(['sport', 'city'])->orderBy('start_date')->limit($n)->get(),
                'venues' => SportsVenue::published()->with(['sport', 'city'])->latest()->limit($n)->get(),
            ],
        ]);
    }

    /**
     * @return array<string, int>
     */
    protected function counts($user): array
    {
        $counts = [
            'saved' => SavedItem::where('user_id', $user->id)->count(),
            'unread_notifications' => Notification::where('user_id', $user->id)->whereNull('read_at')->count(),
        ];

        if ($user->role === 'athlete' && $user->athleteProfile) {
            $athleteId = $user->athleteProfile->id;
            $counts['registrations'] = TrialRegistration::where('athlete_id', $athleteId)->count()
                + TournamentRegistration::where('athlete_id', $athleteId)->count();
        } else {
            $counts['listings'] = Trial::where('posted_by_user_id', $user->id)->count();
        }

        return $counts;
    }

    protected function feedPreview()
    {
        return Post::with(['user:id,name'])
            ->withCount(['likes', 'comments'])
            ->latest()
            ->limit(3)
            ->get();
    }

    /** Top-5 leaderboard slice for AT.1 home strip (Phase 7). */
    protected function leaderboardStrip(): array
    {
        try {
            $season = \App\Services\LeaderboardService::activeSeason();
            return \App\Models\LeaderboardScore::with(['athlete.user', 'sport'])
                ->where('season_id', $season->id)
                ->orderByDesc('points')
                ->limit(5)
                ->get()
                ->map(fn ($r) => [
                    'athlete_profile_id' => $r->athlete_profile_id,
                    'display_name' => $r->athlete?->user?->name ?? 'Athlete',
                    'points' => (int) $r->points,
                    'sport' => $r->sport ? ['id' => $r->sport->id, 'name' => $r->sport->name] : null,
                ])->all();
        } catch (\Throwable) {
            return [];
        }
    }
}
