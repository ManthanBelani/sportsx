<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\Request;

class ConversationController extends Controller
{
    /** List the authenticated user's conversations with the latest message + counterpart. */
    public function index(Request $request)
    {
        $user = $request->user();

        $conversations = Conversation::whereHas('participants', fn ($q) => $q->where('user_id', $user->id))
            ->with(['participants', 'messages' => fn ($m) => $m->latest()->limit(1)])
            ->latest('updated_at')
            ->paginate(20);

        return response()->json($conversations);
    }

    /** Show a conversation with its messages (paginated). */
    public function show(Request $request, string $id)
    {
        $conversation = Conversation::with(['participants', 'messages.sender'])->findOrFail($id);
        $this->authorizeAccess($request->user(), $conversation);

        return response()->json(['data' => $conversation]);
    }

    /** Start or resume a 1:1 conversation, or create a group. */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'participant_id' => 'required_without:participant_ids|integer|exists:users,id',
            'participant_ids' => 'required_without:participant_id|array|min:1',
            'participant_ids.*' => 'integer|exists:users,id',
        ]);

        $user = $request->user();
        $ids = isset($validated['participant_id'])
            ? [$validated['participant_id']]
            : $validated['participant_ids'];

        // Reuse an existing private conversation between these two users.
        if (count($ids) === 1 && $ids[0] !== $user->id) {
            $existing = Conversation::where('type', 'private')
                ->whereHas('participants', fn ($q) => $q->where('user_id', $user->id))
                ->whereHas('participants', fn ($q) => $q->where('user_id', $ids[0]))
                ->first();

            if ($existing) {
                return response()->json(['data' => $existing->load('participants')]);
            }

            // Gate scout <-> athlete and athlete <-> athlete DMs on an accepted connection.
            $gateError = $this->peerChatGate($user->id, (int) $ids[0]);
            if ($gateError) {
                return $gateError;
            }
        }

        $conversation = Conversation::create([
            'type' => count($ids) > 1 ? 'group' : 'private',
        ]);

        $conversation->participants()->sync(array_unique([$user->id, ...$ids]));

        return response()->json(['data' => $conversation->load('participants')], 201);
    }

    /** Send a message to a conversation. */
    public function sendMessage(Request $request, string $id)
    {
        $validated = $request->validate([
            'body' => 'required|string|max:5000',
            'type' => 'in:text,image,system',
        ]);

        $conversation = Conversation::findOrFail($id);
        $this->authorizeAccess($request->user(), $conversation);

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_user_id' => $request->user()->id,
            'body' => $validated['body'],
            'type' => $validated['type'] ?? 'text',
        ]);

        $conversation->touch();

        return response()->json(['data' => $message->load('sender')], 201);
    }

    /** Mark a conversation's messages as read for the user. */
    public function markRead(Request $request, string $id)
    {
        $conversation = Conversation::findOrFail($id);
        $this->authorizeAccess($request->user(), $conversation);

        $conversation->participants()->updateExistingPivot($request->user()->id, [
            'last_read_at' => now(),
        ]);

        return response()->json(['data' => ['message' => 'Marked as read']]);
    }

    private function authorizeAccess($user, Conversation $conversation): void
    {
        $isParticipant = $conversation->participants()->where('user_id', $user->id)->exists();
        abort_unless($isParticipant || $user->isAdmin(), 403);
    }

    /**
     * Require an accepted connection before peer DMs:
     *  - scout <-> athlete needs an accepted ScoutConnection
     *  - athlete <-> athlete needs an accepted generic Connection
     * Other role pairs are unaffected.
     * Returns a 403 JSON response when blocked, null when allowed.
     */
    private function peerChatGate(int $userId, int $otherUserId): ?\Illuminate\Http\JsonResponse
    {
        $a = \App\Models\User::find($userId);
        $b = \App\Models\User::find($otherUserId);

        if (!$a || !$b) {
            return null;
        }

        $isScoutAthletePair = ($a->role === 'talent_scout' && $b->role === 'athlete')
            || ($a->role === 'athlete' && $b->role === 'talent_scout');

        if ($isScoutAthletePair) {
            return $this->scoutAthleteGate($a, $b);
        }

        if ($a->role === 'athlete' && $b->role === 'athlete') {
            $connected = \App\Models\Connection::where('status', 'accepted')
                ->where(fn ($q) => $q
                    ->where(fn ($w) => $w->where('follower_user_id', $a->id)->where('followee_user_id', $b->id))
                    ->orWhere(fn ($w) => $w->where('follower_user_id', $b->id)->where('followee_user_id', $a->id)))
                ->exists();

            if (!$connected) {
                return response()->json(['error' => ['code' => 'CONNECTION_REQUIRED', 'message' => 'Connect and get accepted before chatting.']], 403);
            }
        }

        return null;
    }

    private function scoutAthleteGate(\App\Models\User $a, \App\Models\User $b): ?\Illuminate\Http\JsonResponse
    {

        $scoutUserId = $a->role === 'talent_scout' ? $a->id : $b->id;
        $athleteUserId = $a->role === 'athlete' ? $a->id : $b->id;

        $scoutProfileId = \App\Models\TalentScoutProfile::where('user_id', $scoutUserId)->value('id');
        $athleteProfileId = \App\Models\AthleteProfile::where('user_id', $athleteUserId)->value('id');

        if (!$scoutProfileId || !$athleteProfileId) {
            return response()->json(['error' => ['code' => 'CONNECTION_REQUIRED', 'message' => 'Connect first before chatting.']], 403);
        }

        $accepted = \App\Models\ScoutConnection::where('talent_scout_profile_id', $scoutProfileId)
            ->where('athlete_profile_id', $athleteProfileId)
            ->where('status', 'accepted')
            ->exists();

        if (!$accepted) {
            return response()->json(['error' => ['code' => 'CONNECTION_REQUIRED', 'message' => 'Connect and get accepted before chatting.']], 403);
        }

        return null;
    }
}
