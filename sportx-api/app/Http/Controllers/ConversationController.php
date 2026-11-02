<?php

namespace App\Http\Controllers;

use App\Models\Block;
use App\Models\Connection;
use App\Models\Conversation;
use App\Models\GuardianConsent;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;

class ConversationController extends Controller
{
    /** List the authenticated user's conversations with the latest message + unread count. */
    public function index(Request $request)
    {
        $user = $request->user();

        $conversations = Conversation::whereHas('participants', fn ($q) => $q->where('user_id', $user->id))
            ->with(['participants', 'messages' => fn ($m) => $m->latest()->limit(1)])
            ->withCount(['messages as unread_count' => function ($m) use ($user) {
                // Messages newer than the caller's last_read_at (NULL read
                // timestamp = never read → count everything not sent by me).
                $m->where('sender_user_id', '!=', $user->id)
                    ->where('created_at', '>', function ($sub) use ($user) {
                        $sub->selectRaw('COALESCE(last_read_at, ?)', ['1970-01-01 00:00:00'])
                            ->from('conversation_participants')
                            ->whereColumn('conversation_participants.conversation_id', 'conversations.id')
                            ->where('conversation_participants.user_id', $user->id)
                            ->limit(1);
                    });
            }])
            ->latest('updated_at')
            ->paginate(20);

        return response()->json($conversations);
    }

    /** Show a conversation with its latest messages (newest page size, chronological order). */
    public function show(Request $request, string $id)
    {
        $limit = min(max((int) $request->query('messages_limit', 100), 1), 200);

        $conversation = Conversation::with(['participants'])->findOrFail($id);
        $this->authorizeAccess($request->user(), $conversation);
        // id is the tiebreaker — messages sent in the same second must keep
        // a deterministic order.
        $conversation->load(['messages' => fn ($m) => $m->with('sender')->latest()->orderBy('id', 'desc')->limit($limit)]);
        // Latest N, oldest-first for rendering.
        $messages = $conversation->messages->reverse()->values();

        return response()->json(['data' => [
            ...$conversation->toArray(),
            'messages' => $messages->toArray(),
            'has_more' => $conversation->messages()->count() > $limit,
        ]]);
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

        $isPrivate = count($ids) === 1 && (int) $ids[0] !== $user->id;

        if ($isPrivate) {
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
        } else {
            // Group conversations must not become a side door around the
            // 1:1 safety gates: every participant is block-checked, minor
            // consent is re-checked, and the creator must share an accepted
            // connection (or scout connection) with each participant.
            foreach (array_unique(array_map('intval', $ids)) as $pid) {
                if ((int) $pid === $user->id) {
                    continue;
                }
                if (Block::hasBlockBetween($user->id, $pid)) {
                    return response()->json(['error' => ['code' => 'BLOCKED', 'message' => 'Chat unavailable.']], 403);
                }
                if ($minorError = $this->minorChatGate($user->id, $pid)) {
                    return $minorError;
                }
                $linked = Connection::where('status', 'accepted')
                    ->where(fn ($q) => $q
                        ->where(fn ($w) => $w->where('follower_user_id', $user->id)->where('followee_user_id', $pid))
                        ->orWhere(fn ($w) => $w->where('follower_user_id', $pid)->where('followee_user_id', $user->id)))
                    ->exists()
                    || $this->scoutConnected($user->id, $pid);
                if (! $linked) {
                    return response()->json(['error' => ['code' => 'CONNECTION_REQUIRED', 'message' => 'You can only group people you are connected with.']], 403);
                }
            }
        }

        $conversation = Conversation::create([
            'type' => count($ids) > 1 ? 'group' : 'private',
        ]);

        $conversation->participants()->sync(array_unique([$user->id, ...array_map('intval', $ids)]));

        return response()->json(['data' => $conversation->load('participants')], 201);
    }

    /** Send a message to a conversation. */
    public function sendMessage(Request $request, string $id)
    {
        $validated = $request->validate([
            'body' => 'required|string|max:5000',
            // 'system' is reserved for platform-generated rows (e.g. the
            // connection-accepted intro) — clients can never forge it.
            'type' => 'in:text,image',
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

        // Group sends re-check guardian consent between the sender and every
        // other participant (creation-time gates can go stale).
        if ($conversation->type === 'group') {
            foreach ($conversation->participants as $p) {
                if ($p->id === $request->user()->id) {
                    continue;
                }
                if ($minorError = $this->minorChatGate($request->user()->id, $p->id)) {
                    return $minorError;
                }
            }
        }

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_user_id' => $request->user()->id,
            'body' => $validated['body'],
            'type' => $validated['type'] ?? 'text',
        ]);

        $conversation->touch();

        // Notify the other participants (in-app row + push fan-out inside the
        // service). Never let a notification failure fail the message send.
        foreach ($conversation->participants as $p) {
            if ($p->id === $request->user()->id || Block::hasBlockBetween($request->user()->id, $p->id)) {
                continue;
            }
            try {
                \App\Services\NotificationService::createStatic([
                    'user_id' => $p->id,
                    'type' => 'message',
                    'title' => ($request->user()->name ?? 'New message'),
                    'body' => \Illuminate\Support\Str::limit($validated['body'], 120),
                    'notifiable_type' => 'conversation',
                    'notifiable_id' => $conversation->id,
                    'action_url' => '/chat-screen',
                ]);
            } catch (\Throwable) {
                // Notification is best-effort; the message itself already saved.
            }
        }

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

    /** Accepted scout connection between two users (either direction). */
    private function scoutConnected(int $userId, int $otherUserId): bool
    {
        return \App\Models\ScoutConnection::where('status', 'accepted')
            ->where(fn ($q) => $q
                ->where(fn ($w) => $w->where('talent_scout_profile_id', \App\Models\TalentScoutProfile::where('user_id', $userId)->value('id'))
                    ->where('athlete_profile_id', \App\Models\AthleteProfile::where('user_id', $otherUserId)->value('id')))
                ->orWhere(fn ($w) => $w->where('talent_scout_profile_id', \App\Models\TalentScoutProfile::where('user_id', $otherUserId)->value('id'))
                    ->where('athlete_profile_id', \App\Models\AthleteProfile::where('user_id', $userId)->value('id'))))
            ->exists();
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
