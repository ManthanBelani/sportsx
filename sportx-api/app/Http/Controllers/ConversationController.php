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
}
