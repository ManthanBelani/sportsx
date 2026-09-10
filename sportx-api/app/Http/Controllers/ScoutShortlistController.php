<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use App\Models\ScoutShortlist;
use App\Models\TalentScoutProfile;
use Illuminate\Http\Request;

class ScoutShortlistController extends Controller
{
    public function index(Request $request)
    {
        $scoutProfile = $request->user()->talentScoutProfile;

        if (!$scoutProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Scout profile required.']], 403);
        }

        $shortlist = ScoutShortlist::where('talent_scout_profile_id', $scoutProfile->id)
            ->with(['athlete.user', 'athlete.sports', 'athlete.ageGroup', 'athlete.city', 'athlete.photo'])
            ->withCount(['athlete as athlete_achievements_count' => fn ($q) => $q->select(\Illuminate\Support\Facades\DB::raw('COUNT(*)'))])
            ->get()
            ->map(function ($item) {
                // Inject achievements_count into nested athlete for frontend AthleteDiscovery.fromJson compatibility
                $item->athlete->setAttribute('achievements_count', $item->athlete->achievements()->count());
                return $item;
            });

        return response()->json(['data' => $shortlist]);
    }

    public function store(Request $request, string $athleteId)
    {
        $scoutProfile = $request->user()->talentScoutProfile;

        if (!$scoutProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Scout profile required.']], 403);
        }

        $athlete = AthleteProfile::findOrFail($athleteId);

        $existing = ScoutShortlist::where('talent_scout_profile_id', $scoutProfile->id)
            ->where('athlete_profile_id', $athlete->id)
            ->first();

        if ($existing) {
            return response()->json(['error' => ['code' => 'CONFLICT', 'message' => 'Athlete already shortlisted.']], 409);
        }

        $shortlist = ScoutShortlist::create([
            'talent_scout_profile_id' => $scoutProfile->id,
            'athlete_profile_id' => $athlete->id,
            'notes' => $request->input('notes'),
        ]);

        return response()->json(['data' => $shortlist], 201);
    }

    public function destroy(Request $request, string $athleteId)
    {
        $scoutProfile = $request->user()->talentScoutProfile;

        if (!$scoutProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Scout profile required.']], 403);
        }

        $deleted = ScoutShortlist::where('talent_scout_profile_id', $scoutProfile->id)
            ->where('athlete_profile_id', $athleteId)
            ->delete();

        if (!$deleted) {
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Not in shortlist.']], 404);
        }

        return response()->json(['message' => 'Removed from shortlist']);
    }

    public function update(Request $request, string $athleteId)
    {
        $scoutProfile = $request->user()->talentScoutProfile;

        if (!$scoutProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Scout profile required.']], 403);
        }

        $validated = $request->validate([
            'notes' => 'nullable|string|max:1000',
        ]);

        $shortlist = ScoutShortlist::where('talent_scout_profile_id', $scoutProfile->id)
            ->where('athlete_profile_id', $athleteId)
            ->first();

        if (!$shortlist) {
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Not in shortlist.']], 404);
        }

        $shortlist->update($validated);

        return response()->json(['data' => $shortlist]);
    }
}
