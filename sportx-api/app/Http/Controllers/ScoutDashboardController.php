<?php

namespace App\Http\Controllers;

use App\Models\LeaderboardScore;
use App\Models\ScoutShortlist;
use App\Models\Trial;
use App\Services\LeaderboardService;
use Illuminate\Http\Request;

class ScoutDashboardController extends Controller
{
    /**
     * GET /scout/dashboard — top talents (leaderboard slice), upcoming
     * trials, counts. Folded into /me/home later; standalone for SC.2 now.
     */
    public function show(Request $request)
    {
        $scoutProfile = $request->user()->talentScoutProfile;
        abort_if(!$scoutProfile, 403, 'Scout profile required.');

        $season = LeaderboardService::activeSeason();
        $top = LeaderboardScore::with(['athlete.user', 'sport'])
            ->where('season_id', $season->id)
            ->orderByDesc('points')
            ->limit(5)
            ->get()
            ->map(fn ($r) => [
                'athlete_profile_id' => $r->athlete_profile_id,
                'display_name' => $r->athlete?->user?->name ?? 'Athlete',
                'points' => (int) $r->points,
                'sport' => $r->sport ? ['id' => $r->sport->id, 'name' => $r->sport->name] : null,
            ]);

        $upcomingTrials = Trial::orderBy('event_datetime')->limit(5)->get();

        $shortlistCount = ScoutShortlist::where('talent_scout_profile_id', $scoutProfile->id)->count();

        return response()->json(['data' => [
            'top_talents' => $top,
            'upcoming_trials' => $upcomingTrials,
            'counts' => [
                'shortlisted' => $shortlistCount,
            ],
        ]]);
    }
}
