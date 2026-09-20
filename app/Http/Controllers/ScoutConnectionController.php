<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use App\Models\ScoutConnection;
use App\Services\NotificationService;
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
            ->with(['athlete.user', 'athlete.sports', 'athlete.ageGroup', 'athlete.city', 'athlete.photo'])
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

        $scoutProfile->load('user');
        NotificationService::createStatic([
            'user_id' => $athlete->user_id,
            'type' => 'status_update',
            'title' => 'New scout connection request',
            'body' => "{$scoutProfile->user->name} wants to connect with you.",
            'notifiable_type' => 'scout_connection',
            'notifiable_id' => $connection->id,
            'action_url' => '/scout-requests',
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

    /**
     * Incoming scout requests for the authenticated athlete.
     */
    public function indexForAthlete(Request $request)
    {
        $athleteProfile = $request->user()->athleteProfile;

        if (!$athleteProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Athlete profile required.']], 403);
        }

        $requests = ScoutConnection::where('athlete_profile_id', $athleteProfile->id)
            ->with(['scout.user', 'scout.city', 'scout.photo'])
            ->latest()
            ->get();

        return response()->json(['data' => $requests]);
    }

    /**
     * Accept a scout connection request (athlete side).
     */
    public function accept(Request $request, string $connectionId)
    {
        $connection = $this->athleteConnection($request, $connectionId, 'pending');

        if (!$connection) {
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Pending scout request not found.']], 404);
        }

        $connection->update(['status' => 'accepted']);
        $connection->load('scout.user');

        NotificationService::createStatic([
            'user_id' => $connection->scout->user_id,
            'type' => 'status_update',
            'title' => 'Connection accepted',
            'body' => "{$request->user()->name} accepted your connection request.",
            'notifiable_type' => 'scout_connection',
            'notifiable_id' => $connection->id,
            'action_url' => '/scout-connections',
        ]);

        return response()->json(['data' => $connection->fresh(['scout.user', 'scout.city', 'scout.photo'])]);
    }

    /**
     * Reject a scout connection request (athlete side).
     */
    public function reject(Request $request, string $connectionId)
    {
        $connection = $this->athleteConnection($request, $connectionId, 'pending');

        if (!$connection) {
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Pending scout request not found.']], 404);
        }

        $connection->update(['status' => 'rejected']);
        $connection->load('scout.user');

        NotificationService::createStatic([
            'user_id' => $connection->scout->user_id,
            'type' => 'status_update',
            'title' => 'Connection declined',
            'body' => "{$request->user()->name} declined your connection request.",
            'notifiable_type' => 'scout_connection',
            'notifiable_id' => $connection->id,
            'action_url' => '/scout-connections',
        ]);

        return response()->json(['data' => $connection->fresh(['scout.user', 'scout.city', 'scout.photo'])]);
    }

    /**
     * Scope a scout connection to the authenticated athlete's profile.
     */
    private function athleteConnection(Request $request, string $connectionId, ?string $status = null): ?ScoutConnection
    {
        $athleteProfile = $request->user()->athleteProfile;

        if (!$athleteProfile) {
            return null;
        }

        return ScoutConnection::where('athlete_profile_id', $athleteProfile->id)
            ->where('id', $connectionId)
            ->when($status, fn ($q) => $q->where('status', $status))
            ->first();
    }
}
