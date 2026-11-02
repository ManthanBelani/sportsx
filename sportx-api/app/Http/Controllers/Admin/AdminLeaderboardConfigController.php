<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\LeaderboardService;
use App\Support\PlatformSettings;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin leaderboard configuration (AD.11): runtime point weights, the active
 * season, and a manual full rebuild. Weights live in PlatformSettings so the
 * scoring engine picks them up without a deploy.
 */
class AdminLeaderboardConfigController extends Controller
{
    public function show(): JsonResponse
    {
        $season = LeaderboardService::activeSeason();

        return response()->json(['data' => [
            'weights' => [
                'leaderboard_points_achievement' => LeaderboardService::pointsPerAchievement(),
                'leaderboard_points_completion' => LeaderboardService::pointsForCompletion(),
                'leaderboard_points_participation' => LeaderboardService::pointsPerParticipation(),
                'leaderboard_participation_cap' => LeaderboardService::participationCap(),
            ],
            'active_season' => [
                'id' => $season->id,
                'name' => $season->name,
                'starts_on' => $season->starts_on,
                'is_active' => (bool) $season->is_active,
            ],
        ]]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'weights' => 'required|array',
            'weights.leaderboard_points_achievement' => 'required|integer|min:0|max:500',
            'weights.leaderboard_points_completion' => 'required|integer|min:0|max:500',
            'weights.leaderboard_points_participation' => 'required|integer|min:0|max:500',
            'weights.leaderboard_participation_cap' => 'required|integer|min:0|max:1000',
        ]);

        PlatformSettings::update($validated['weights']);

        return $this->show();
    }

    /** Rebuild every athlete's score from the current weights. */
    public function reset(): JsonResponse
    {
        $rebuilt = LeaderboardService::rebuildAll();

        return response()->json(['data' => [
            'rebuilt' => $rebuilt,
            'message' => 'Leaderboard recalculated for all athletes.',
        ]]);
    }
}
