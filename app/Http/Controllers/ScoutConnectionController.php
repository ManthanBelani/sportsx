<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use App\Models\Conversation;
use App\Models\ScoutConnection;
use App\Models\TalentScoutProfile;
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
            ->latest()
            ->get();

        return response()->json(['data' => $connections]);
    }

    /**
     * Scout -> Athlete connect request.
     * POST /athletes/{athlete}/connect
     */
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
            'requested_by_user_id' => $user->id,
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

    /**
     * Athlete -> Scout connect request (two-way connect).
     * POST /scouts/{scout}/connect  [role:athlete]
     */
    public function storeFromAthlete(Request $request, string $scoutId)
    {
        $user = $request->user();
        $athleteProfile = $user->athleteProfile;

        if (!$athleteProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Athlete profile required.']], 403);
        }

        $scout = TalentScoutProfile::findOrFail($scoutId);

        $existing = ScoutConnection::where('talent_scout_profile_id', $scout->id)
            ->where('athlete_profile_id', $athleteProfile->id)
            ->first();

        if ($existing) {
            return response()->json(['error' => ['code' => 'CONFLICT', 'message' => 'Connection already exists.']], 409);
        }

        $validated = $request->validate([
            'message' => 'nullable|string|max:1000',
        ]);

        $connection = ScoutConnection::create([
            'talent_scout_profile_id' => $scout->id,
            'athlete_profile_id' => $athleteProfile->id,
            'requested_by_user_id' => $user->id,
            'status' => 'pending',
            'message' => $validated['message'] ?? null,
        ]);

        NotificationService::createStatic([
            'user_id' => $scout->user_id,
            'type' => 'status_update',
            'title' => 'New athlete connection request',
            'body' => "{$user->name} wants to connect with you.",
            'notifiable_type' => 'scout_connection',
            'notifiable_id' => $connection->id,
            'action_url' => '/scout-connections',
        ]);

        return response()->json(['data' => $connection->fresh(['scout.user', 'athlete.user'])], 201);
    }

    /**
     * Incoming requests for the authenticated scout (initiated by athletes).
     * GET /me/scout-connections/incoming [role:talent_scout]
     */
    public function incomingForScout(Request $request)
    {
        $scoutProfile = $request->user()->talentScoutProfile;

        if (!$scoutProfile) {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Scout profile required.']], 403);
        }

        $requests = ScoutConnection::where('talent_scout_profile_id', $scoutProfile->id)
            ->where('status', 'pending')
            ->where('requested_by_user_id', '!=', $request->user()->id)
            ->with(['athlete.user', 'athlete.sports', 'athlete.city', 'athlete.photo'])
            ->latest()
            ->get();

        return response()->json(['data' => $requests]);
    }

    /**
     * Accept an athlete-initiated request (scout side).
     * POST /me/scout-connections/{connection}/accept [role:talent_scout]
     */
    public function acceptForScout(Request $request, string $connectionId)
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
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Pending request not found.']], 404);
        }

        $connection->update(['status' => 'accepted']);
        $connection->load(['athlete.user', 'scout.user']);
        $this->ensurePrivateConversation($connection);

        NotificationService::createStatic([
            'user_id' => $connection->athlete->user_id,
            'type' => 'status_update',
            'title' => 'Connection accepted',
            'body' => "{$request->user()->name} accepted your connection request. You can now chat.",
            'notifiable_type' => 'scout_connection',
            'notifiable_id' => $connection->id,
            'action_url' => '/scout-requests',
        ]);

        return response()->json(['data' => $connection->fresh(['athlete.user', 'scout.user'])]);
    }

    /**
     * Reject an athlete-initiated request (scout side).
     */
    public function rejectForScout(Request $request, string $connectionId)
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
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Pending request not found.']], 404);
        }

        $connection->update(['status' => 'rejected']);
        $connection->load(['athlete.user']);

        NotificationService::createStatic([
            'user_id' => $connection->athlete->user_id,
            'type' => 'status_update',
            'title' => 'Connection declined',
            'body' => "{$request->user()->name} declined your connection request.",
            'notifiable_type' => 'scout_connection',
            'notifiable_id' => $connection->id,
            'action_url' => '/scout-requests',
        ]);

        return response()->json(['data' => $connection->fresh(['athlete.user', 'scout.user'])]);
    }

    public function destroy(Request $request, string $connectionId)
    {
        $user = $request->user();

        // Either side may cancel/remove their own connection.
        $query = ScoutConnection::where('id', $connectionId);

        if ($user->talentScoutProfile) {
            $query->where('talent_scout_profile_id', $user->talentScoutProfile->id);
        } elseif ($user->athleteProfile) {
            $query->where('athlete_profile_id', $user->athleteProfile->id);
        } else {
            return response()->json(['error' => ['code' => 'FORBIDDEN', 'message' => 'Profile required.']], 403);
        }

        $connection = $query->first();

        if (!$connection) {
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Connection not found.']], 404);
        }

        $connection->delete();

        return response()->json(['message' => 'Connection removed.']);
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
        $connection->load(['scout.user', 'athlete.user']);
        $this->ensurePrivateConversation($connection);

        NotificationService::createStatic([
            'user_id' => $connection->scout->user_id,
            'type' => 'status_update',
            'title' => 'Connection accepted',
            'body' => "{$request->user()->name} accepted your connection request. You can now chat.",
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
     * Connection status between the authenticated user and a counterpart.
     * GET /scout-connection-status/{type}/{id} — type: athlete|scout
     */
    public function status(Request $request, string $type, string $id)
    {
        $user = $request->user();

        $connection = ScoutConnection::query()
            ->when($type === 'athlete', fn ($q) => $q->where('athlete_profile_id', $id))
            ->when($type === 'scout', fn ($q) => $q->where('talent_scout_profile_id', $id))
            ->when($type === 'athlete' && $user->talentScoutProfile, fn ($q) => $q->where('talent_scout_profile_id', $user->talentScoutProfile->id))
            ->when($type === 'scout' && $user->athleteProfile, fn ($q) => $q->where('athlete_profile_id', $user->athleteProfile->id))
            ->first();

        return response()->json(['data' => $connection]);
    }

    /**
     * Create (or reuse) a private 1:1 conversation between the linked users
     * once a scout connection is accepted, so both inboxes show "Say hi".
     */
    private function ensurePrivateConversation(ScoutConnection $connection): void
    {
        $connection->loadMissing(['scout.user', 'athlete.user']);
        $scoutUserId = $connection->scout->user_id ?? null;
        $athleteUserId = $connection->athlete->user_id ?? null;

        if (!$scoutUserId || !$athleteUserId) {
            return;
        }

        $exists = Conversation::where('type', 'private')
            ->whereHas('participants', fn ($q) => $q->where('user_id', $scoutUserId))
            ->whereHas('participants', fn ($q) => $q->where('user_id', $athleteUserId))
            ->exists();

        if ($exists) {
            return;
        }

        $conversation = Conversation::create(['type' => 'private']);
        $conversation->participants()->sync([$scoutUserId, $athleteUserId]);
        $conversation->messages()->create([
            'sender_user_id' => $scoutUserId,
            'body' => 'You are now connected. Say hi!',
            'type' => 'system',
        ]);
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
