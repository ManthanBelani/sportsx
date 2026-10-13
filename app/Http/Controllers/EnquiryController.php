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
            'subject_type' => 'required|string|in:coach_profile,academy,organizer_profile,sponsor_profile,sports_venue,program,opportunity',
            'subject_id' => 'required|integer',
            'message' => 'required|string|max:1000',
            'preferred_datetime' => 'nullable|date',
        ]);

        $athlete = $request->user()->athleteProfile;
        abort_if(! $athlete, 403, 'Athlete profile required');

        $this->assertSubjectExists($validated['subject_type'], (int) $validated['subject_id']);

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
            'coach' => array_merge(
                $user->coachProfile ? [['coach_profile', $user->coachProfile->id]] : [],
                $this->programPairs('coach_profile', $user->coachProfile?->id),
            ),
            'academy' => array_merge(
                $user->academies ? [['academy', $user->academies->id]] : [],
                $this->programPairs('academy', $user->academies?->id),
            ),
            'organizer' => array_merge(
                $user->organizerProfile ? [['organizer_profile', $user->organizerProfile->id]] : [],
                $this->opportunityPairs($user->id),
            ),
            'sponsor' => $user->sponsorProfile ? [['sponsor_profile', $user->sponsorProfile->id]] : [],
            'talent_scout', 'scout' => $this->opportunityPairs($user->id),
            'athlete' => [], // athletes use sent side below
            default => [],
        };

        // Coaches/academies also receive enquiries on opportunities they posted.
        if (in_array($user->role, ['coach', 'academy'], true)) {
            $pairs = array_merge($pairs, $this->opportunityPairs($user->id));
        }

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
            $this->subjectOwnerId($enquiry),
        ]);

        abort_unless($isOwner || $user->isAdmin(), 403);
    }

    /**
     * Owning user id behind any enquiry subject (Phase 5 adds program +
     * opportunity, whose owners live behind a profile or creator column).
     */
    private function subjectOwnerId(Enquiry $enquiry): ?int
    {
        $subject = $enquiry->subject;

        if (! $subject) {
            return null;
        }

        return match ($enquiry->subject_type) {
            'academy' => $subject->owner_user_id,
            'program' => $this->programOwnerId($subject),
            'opportunity' => $subject->created_by_user_id,
            default => $subject->user_id ?? $subject->owner_user_id,
        };
    }

    private function programOwnerId($program): ?int
    {
        $owner = $program->owner;

        if (! $owner) {
            return $program->created_by_user_id;
        }

        return $owner->owner_user_id ?? $owner->user_id ?? $program->created_by_user_id;
    }

    /**
     * Enquiry subjects for programs owned by a profile (coach/academy).
     *
     * @return list<array{0: string, 1: int}>
     */
    private function programPairs(string $ownerType, ?int $ownerId): array
    {
        if (! $ownerId) {
            return [];
        }

        return \App\Models\Program::where('owner_type', $ownerType)
            ->where('owner_id', $ownerId)
            ->pluck('id')
            ->map(fn ($id) => ['program', $id])
            ->all();
    }

    /**
     * Enquiry subjects for opportunities posted by a user.
     *
     * @return list<array{0: string, 1: int}>
     */
    private function opportunityPairs(int $userId): array
    {
        return \App\Models\Opportunity::where('created_by_user_id', $userId)
            ->pluck('id')
            ->map(fn ($id) => ['opportunity', $id])
            ->all();
    }

    /**
     * The subject must exist — otherwise the thread points at nothing and the
     * provider never sees it.
     */
    private function assertSubjectExists(string $type, int $id): void
    {
        $model = match ($type) {
            'coach_profile' => \App\Models\CoachProfile::class,
            'academy' => \App\Models\Academy::class,
            'organizer_profile' => \App\Models\OrganizerProfile::class,
            'sponsor_profile' => \App\Models\SponsorProfile::class,
            'sports_venue' => \App\Models\SportsVenue::class,
            'program' => \App\Models\Program::class,
            'opportunity' => \App\Models\Opportunity::class,
        };

        abort_unless($model::whereKey($id)->exists(), 404, 'Enquiry subject not found.');
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
            'program' => $subject->title ?? 'Program',
            'opportunity' => $subject->title ?? 'Opportunity',
            default => 'a listing',
        };
    }
}
