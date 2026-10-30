<?php

namespace App\Http\Controllers;

use App\Models\Block;
use App\Models\Conversation;
use App\Models\GuardianConsent;
use App\Models\Message;
use App\Models\User;
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
            if (Block::hasBlockBetween($user->id, (int) $ids[0])) {
                return response()->json(['error' => ['code' => 'BLOCKED', 'message' => 'Chat unavailable.']], 403);
            }
            if ($minorError = $this->minorChatGate($user->id, (int) $ids[0])) {
                return $minorError;
            }
            // Gate BEFORE the reuse check so stale conversations can't bypass it (B1).
            $gateError = $this->peerChatGate($user->id, (int) $ids[0]);
            if ($gateError) {
                return $gateError;
            }

            $existing = Conversation::where('type', 'private')
                ->whereHas('participants', fn ($q) => $q->where('user_id', $user->id))
                ->whereHas('participants', fn ($q) => $q->where('user_id', $ids[0]))
                ->first();

            if ($existing) {
                return response()->json(['data' => $existing->load('participants')]);
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

        foreach ($conversation->participants as $p) {
            if ($p->id !== $request->user()->id && Block::hasBlockBetween($request->user()->id, $p->id)) {
                return response()->json(['error' => ['code' => 'BLOCKED', 'message' => 'Chat disabled.']], 403);
            }
        }

        // Private 1:1 sends are re-gated (B2): block/removed connections kill chat access.
        if ($sendGateError = $this->privateSendGate($request->user(), $conversation)) {
            return $sendGateError;
        }

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
     * Minors: peer chat only when the minor athlete has verified guardian
     * consent (guardian-allowed). Enquiry/registration threads bypass this
     * because they live in the Enquiry model, not conversations.
     */
    private function minorChatGate(int $userId, int $otherUserId): ?\Illuminate\Http\JsonResponse
    {
        foreach ([$userId, $otherUserId] as $candidateId) {
            $profile = \App\Models\AthleteProfile::where('user_id', $candidateId)->first();
            if (!$profile || !$profile->date_of_birth) {
                continue;
            }
            try {
                $age = \Carbon\Carbon::parse($profile->date_of_birth)->age;
            } catch (\Throwable) {
                continue;
            }
            if ($age >= 18) {
                continue;
            }
            $ok = GuardianConsent::where('athlete_user_id', $candidateId)
                ->where('consent_status', GuardianConsent::STATUS_VERIFIED)
                ->where('allow_messages', true)
                ->exists();
            if (!$ok) {
                return response()->json(['error' => ['code' => 'GUARDIAN_REQUIRED', 'message' => 'Minor chat requires guardian consent.']], 403);
            }
        }

        return null;
    }

    /**
     * Require DM permission before peer chats:
     *  - scout <-> athlete needs an accepted ScoutConnection (profile graphs)
     *  - ALL other role pairs need an accepted generic Connection
     *  - the target's `who_can_message` privacy is enforced:
     *      everyone     → normal rules (above)
     *      connections  → accepted generic Connection required (covers athlete pairs too)
     *      nobody       → rejected
     * Admins bypass.
     * Returns a 403 JSON response when blocked, null when allowed.
     */
    private function peerChatGate(int $userId, int $otherUserId): ?\Illuminate\Http\JsonResponse
    {
        $a = \App\Models\User::find($userId);
        $b = \App\Models\User::find($otherUserId);

        if (!$a || !$b) {
            return null;
        }

        if ($a->isAdmin() || $b->isAdmin()) {
            return null;
        }

        $isScoutAthletePair = ($a->role === 'talent_scout' && $b->role === 'athlete')
            || ($a->role === 'athlete' && $b->role === 'talent_scout');

        if ($isScoutAthletePair) {
            return $this->scoutAthleteGate($a, $b);
        }

        // who_can_message of the conversation TARGET (the other party) —
        // uses PrivacyController::settings() which applies minor-specific defaults.
        $targetPolicy = \App\Http\Controllers\PrivacyController::settings($b)['who_can_message'];

        if ($targetPolicy === 'nobody' && $a->role !== 'admin') {
            return response()->json(['error' => ['code' => 'MESSAGING_DISABLED', 'message' => 'This user does not accept messages.']], 403);
        }

        if ($targetPolicy === 'connections') {
            // B1: every non-scout role pair requires an accepted generic Connection.
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

    /** Send-time gate for private conversations (closes the stale-conversation hole). */
    private function privateSendGate($user, Conversation $conversation): ?\Illuminate\Http\JsonResponse
    {
        if ($conversation->type !== 'private' || $conversation->participants->count() !== 2) {
            return null;
        }

        $other = $conversation->participants->firstWhere('id', '!=', $user->id);
        if (!$other) {
            return null;
        }

        return $this->peerChatGate($user->id, $other->id);
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
