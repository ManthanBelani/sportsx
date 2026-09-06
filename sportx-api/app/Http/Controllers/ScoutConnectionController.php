<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use App\Models\ScoutConnection;
use Illuminate\Http\Request;

class ScoutConnectionController extends Controller
{
    public function index(Request $request)
    {
        $scoutProfile = $request->user()->talentScoutProfile;

        if (!$scoutProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Scout profile required.']], 403);
        }

        $connections = ScoutConnection::where('talent_scout_profile_id', $scoutProfile->id)
            ->with(['athlete.user', 'athlete.sports', 'athlete.ageGroup', 'athlete.city'])
            ->get();

        return response()->json(['data' => $connections]);
    }

    public function store(Request $request, string $athleteId)
    {
        $user = $request->user();
        $scoutProfile = $user->talentScoutProfile;

        if (!$scoutProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Scout profile required.']], 403);
        }

        $athlete = AthleteProfile::findOrFail($athleteId);

        $existing = ScoutConnection::where('talent_scout_profile_id', $scoutProfile->id)
            ->where('athlete_profile_id', $athlete->id)
            ->first();

        if ($existing) {
            return response()->json(['error' => ['code' => 'CONFLICT', 'message' => 'Connection already exists.']], 409);
        }

        $validated = $request->validate([
            'message' => 'nullable|string|max:1000',
        ]);

        $connection = ScoutConnection::create([
            'talent_scout_profile_id' => $scoutProfile->id,
            'athlete_profile_id' => $athlete->id,
            'status' => 'pending',
            'message' => $validated['message'] ?? null,
        ]);

        return response()->json(['data' => $connection], 201);
    }

    public function destroy(Request $request, string $connectionId)
    {
        $scoutProfile = $request->user()->talentScoutProfile;

        if (!$scoutProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Scout profile required.']], 403);
        }

        $connection = ScoutConnection::where('talent_scout_profile_id', $scoutProfile->id)
            ->where('id', $connectionId)
            ->where('status', 'pending')
            ->first();

        if (!$connection) {
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Pending connection not found.']], 404);
        }

        $connection->delete();

        return response()->json(['message' => 'Connection request cancelled.']);
    }
}
