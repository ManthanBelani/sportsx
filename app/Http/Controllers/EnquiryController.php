<?php

namespace App\Http\Controllers;

use App\Models\Enquiry;
use App\Models\EnquiryMessage;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class EnquiryController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'subject_type' => 'required|string|in:coach_profile,academy,organizer_profile,sponsor_profile,sports_venue',
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

        // Build per-role subject map so organizer/sponsor also see their inbox (previous only coach/academy)
        $pairs = match ($user->role) {
            'coach' => $user->coachProfile ? [['coach_profile', $user->coachProfile->id]] : [],
            'academy' => $user->academies ? [['academy', $user->academies->id]] : [],
            'organizer' => $user->organizerProfile ? [['organizer_profile', $user->organizerProfile->id]] : [],
            'sponsor' => $user->sponsorProfile ? [['sponsor_profile', $user->sponsorProfile->id]] : [],
            'athlete' => [], // athletes use sent side below
            default => [],
        };

        $query = Enquiry::query()->with(['athlete.user', 'athlete.photo', 'messages' => fn ($m) => $m->latest()]);

        if ($user->role === 'athlete' && $user->athleteProfile) {
            $query->where('athlete_id', $user->athleteProfile->id);
        } elseif (!empty($pairs)) {
            $query->where(function ($q) use ($pairs) {
                foreach ($pairs as $i => [$type, $id]) {
                    $q->when($i === 0, fn ($qq) => $qq->where('subject_type', $type)->where('subject_id', $id),
                        fn ($qq) => $qq->orWhere(fn ($qq2) => $qq2->where('subject_type', $type)->where('subject_id', $id)));
                }
            });
        } else {
            // No subject for this role → return empty paginator instead of leaking all
            $query->whereRaw('1=0');
        }

        $filter = $request->query('filter');
        if ($filter === 'unread') {
            $query->whereHas('messages', fn ($m) => $m->whereNull('read_at')->where('sender_user_id', '!=', $user->id));
        }

        return response()->json($query->latest('updated_at')->paginate(20));
    }

    public function show(Request $request, string $id)
    {
        $enquiry = Enquiry::with(['athlete.user', 'athlete.photo', 'messages.sender'])->findOrFail($id);
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

        $enquiry->load('athlete.user');
        $athleteUserId = $enquiry->athlete?->user_id;

        if ($athleteUserId && $athleteUserId !== $request->user()->id) {
            $subjectLabel = $this->getSubjectLabel($enquiry->subject_type, $enquiry->subject);
            NotificationService::createStatic([
                'user_id' => $athleteUserId,
                'type' => 'enquiry_reply',
                'title' => 'New reply to your enquiry',
                'body' => mb_substr($validated['body'], 0, 100),
                'notifiable_type' => 'enquiry',
                'notifiable_id' => $enquiry->id,
                'action_url' => "/enquiry/{$enquiry->id}",
            ]);
        }

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

    private function getSubjectLabel(string $subjectType, $subject): string
    {
        if (!$subject) return 'an enquiry';
        return match ($subjectType) {
            'coach_profile' => $subject->full_name ?? 'Coach',
            'academy' => $subject->name ?? 'Academy',
            'organizer_profile' => $subject->organization_name ?? 'Organizer',
            'sponsor_profile' => $subject->organization_name ?? 'Sponsor',
            'sports_venue' => $subject->name ?? 'Venue',
            default => 'a listing',
        };
    }
}
