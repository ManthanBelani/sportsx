<?php

namespace App\Http\Controllers;

use App\Models\Enquiry;
use App\Models\Program;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Training programs (Phase 5): owner morph coach / academy.
 *
 * Athletes browse active programs and enquire — the enquiry opens a chat
 * thread with the owning provider.
 *
 * @see docs/PHASE_WISE_IMPLEMENTATION_PLAN.md Phase 5
 */
class ProgramController extends Controller
{
    /**
     * GET /programs (public, active only)
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'sport_id' => 'nullable|integer|exists:sports,id',
            'age_group_id' => 'nullable|integer|exists:age_groups,id',
            'mode' => 'nullable|in:online,offline,hybrid',
            'q' => 'nullable|string|max:120',
        ]);

        $query = Program::active()->with(['sport', 'ageGroup']);

        $query->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->age_group_id, fn ($q) => $q->where('age_group_id', $request->age_group_id))
            ->when($request->mode, fn ($q) => $q->where('mode', $request->mode))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub
                ->where('title', 'like', "%{$request->q}%")
                ->orWhere('about', 'like', "%{$request->q}%")))
            ->latest();

        return response()->json($query->paginate(min((int) ($request->per_page ?? 20), 50))->withQueryString());
    }

    /**
     * GET /programs/{id}
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $program = Program::with(['sport', 'ageGroup'])->findOrFail($id);

        $viewer = $request->user();
        $isOwner = $viewer && ((int) $viewer->id === (int) $program->created_by_user_id || $viewer->isAdmin());

        abort_unless($program->status === 'active' || $isOwner, 404);

        return response()->json(['data' => $program]);
    }

    /**
     * GET /me/programs (own programs, optional ?status=draft|active|past)
     */
    public function mine(Request $request): JsonResponse
    {
        $request->validate(['status' => 'nullable|in:draft,active,past']);

        $query = Program::with(['sport', 'ageGroup'])
            ->where('created_by_user_id', $request->user()->id)
            ->latest();

        if ($request->status) {
            $query->where('status', $request->status);
        }

        return response()->json($query->paginate(20));
    }

    /**
     * POST /me/programs
     */
    public function store(Request $request): JsonResponse
    {
        [$ownerType, $ownerId] = $this->resolveOwner($request);

        $validated = $this->rules($request);

        $program = Program::create(array_merge($validated, [
            'owner_type' => $ownerType,
            'owner_id' => $ownerId,
            'created_by_user_id' => $request->user()->id,
            'status' => $validated['status'] ?? 'draft',
        ]));

        return response()->json(['data' => $program->load(['sport', 'ageGroup'])], 201);
    }

    /**
     * PUT /me/programs/{id}
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $program = Program::findOrFail($id);
        $this->authorizeOwner($request, $program);

        $validated = $this->rules($request, sometimes: true);
        $program->update($validated);

        return response()->json(['data' => $program->fresh(['sport', 'ageGroup'])]);
    }

    /**
     * POST /programs/{id}/enquire — creates (or reuses) the athlete's thread
     * with the owning provider and returns the open thread.
     */
    public function enquire(Request $request, string $id): JsonResponse
    {
        $program = Program::findOrFail($id);
        abort_unless($program->status === 'active', 422, 'This program is not currently accepting enquiries.');

        $athlete = $request->user()->athleteProfile;
        abort_unless($athlete, 403, 'Athlete profile required.');

        $validated = $request->validate([
            'message' => 'required|string|max:1000',
            'preferred_datetime' => 'nullable|date',
        ]);

        $existing = Enquiry::where('athlete_id', $athlete->id)
            ->where('subject_type', 'program')
            ->where('subject_id', $program->id)
            ->first();

        if ($existing) {
            \App\Models\EnquiryMessage::create([
                'enquiry_id' => $existing->id,
                'sender_user_id' => $request->user()->id,
                'body' => $validated['message'],
            ]);
            $existing->touch();

            return response()->json(['data' => $existing->load(['messages' => fn ($m) => $m->latest()])]);
        }

        $enquiry = Enquiry::create([
            'athlete_id' => $athlete->id,
            'subject_type' => 'program',
            'subject_id' => $program->id,
            'preferred_datetime' => $validated['preferred_datetime'] ?? null,
        ]);

        \App\Models\EnquiryMessage::create([
            'enquiry_id' => $enquiry->id,
            'sender_user_id' => $request->user()->id,
            'body' => $validated['message'],
        ]);

        return response()->json(['data' => $enquiry->load('messages')], 201);
    }

    /* ------------------------------------------------------------------ */

    /**
     * @return array{0: string, 1: int}
     */
    protected function resolveOwner(Request $request): array
    {
        $user = $request->user();

        return match ($user->role) {
            'coach' => ['coach_profile', $user->coachProfile?->id ?? abort(403, 'Coach profile required.')],
            'academy' => ['academy', $user->academies?->id ?? abort(403, 'Academy profile required.')],
            default => abort(403, 'Only coach or academy accounts can post programs.'),
        };
    }

    protected function authorizeOwner(Request $request, Program $program): void
    {
        $user = $request->user();
        abort_unless(
            (int) $program->created_by_user_id === (int) $user->id || $user->isAdmin(),
            403
        );
    }

    protected function rules(Request $request, bool $sometimes = false): array
    {
        $prefix = $sometimes ? 'sometimes|' : '';

        return $request->validate([
            'title' => $prefix.'required|string|max:255',
            'sport_id' => 'nullable|exists:sports,id',
            'age_group_id' => 'nullable|exists:age_groups,id',
            'duration' => 'nullable|string|max:120',
            'mode' => 'nullable|in:online,offline,hybrid',
            'price' => 'nullable|numeric|min:0',
            'schedule' => 'nullable|string',
            'about' => 'nullable|string',
            'status' => 'nullable|in:draft,active,past',
        ]);
    }
}
