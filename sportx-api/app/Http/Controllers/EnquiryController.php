<?php

namespace App\Http\Controllers;

use App\Models\Enquiry;
use App\Models\EnquiryMessage;
use Illuminate\Http\Request;

class EnquiryController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'subject_type' => 'required|string|in:coach_profile,academy,sponsorship_application',
            'subject_id' => 'required|integer',
            'message' => 'required|string|max:1000',
            'preferred_datetime' => 'nullable|date',
        ]);

        $athlete = $request->user()->athleteProfile;
        abort_if(! $athlete, 403, 'Athlete profile required');

        $enquiry = Enquiry::create([
            'athlete_id' => $athlete->id,
            'subject_type' => $validated['subject_type'],
            'subject_id' => $validated['subject_id'],
            'preferred_datetime' => $validated['preferred_datetime'] ?? null,
        ]);

        EnquiryMessage::create([
            'enquiry_id' => $enquiry->id,
            'sender_user_id' => $request->user()->id,
            'body' => $validated['message'],
        ]);

        return response()->json(['data' => $enquiry->load('athlete.user')], 201);
    }

    public function inbox(Request $request)
    {
        $user = $request->user();
        $subjectIds = match ($user->role) {
            'coach' => [$user->coachProfile?->id],
            'academy' => $user->academies->pluck('id')->toArray(),
            default => [],
        };

        $query = Enquiry::where(function ($q) use ($subjectIds, $request) {
            $q->whereIn('subject_id', $subjectIds)
                ->whereIn('subject_type', ['coach_profile', 'academy']);
        })->with(['athlete.user', 'messages' => fn ($m) => $m->latest()]);

        $query->when($request->filter === 'new', fn ($q) => $q->whereDoesntHave('messages', fn ($m) => $m->where('sender_user_id', $user->id)))
            ->when($request->filter === 'replied', fn ($q) => $q->whereHas('messages', fn ($m) => $m->where('sender_user_id', $user->id)));

        return response()->json($query->latest('updated_at')->paginate(20));
    }

    public function show(Request $request, string $id)
    {
        $enquiry = Enquiry::with(['athlete.user', 'messages.sender'])->findOrFail($id);
        $this->authorizeAccess($request->user(), $enquiry);

        return response()->json(['data' => $enquiry]);
    }

    public function reply(Request $request, string $id)
    {
        $validated = $request->validate(['body' => 'required|string|max:2000']);

        $enquiry = Enquiry::findOrFail($id);
        $this->authorizeAccess($request->user(), $enquiry);

        $message = EnquiryMessage::create([
            'enquiry_id' => $enquiry->id,
            'sender_user_id' => $request->user()->id,
            'body' => $validated['body'],
        ]);

        $enquiry->touch();

        return response()->json(['data' => $message], 201);
    }

    public function markRead(Request $request, string $id)
    {
        $enquiry = Enquiry::findOrFail($id);
        $this->authorizeAccess($request->user(), $enquiry);

        EnquiryMessage::where('enquiry_id', $enquiry->id)
            ->where('sender_user_id', '!=', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['data' => ['message' => 'Marked as read']]);
    }

    private function authorizeAccess($user, Enquiry $enquiry): void
    {
        $isOwner = in_array($user->id, [
            $enquiry->athlete?->user_id,
            $enquiry->subject?->user_id ?? $enquiry->subject?->owner_user_id,
        ]);

        abort_unless($isOwner || $user->isAdmin(), 403);
    }
}
