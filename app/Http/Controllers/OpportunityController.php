<?php

namespace App\Http\Controllers;

use App\Models\Opportunity;
use App\Models\OpportunityApplication;
use App\Models\SavedItem;
use App\Services\ExpiryService;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Unified opportunities (Phase 4).
 *
 * Providers (academy / organizer / coach / scout) post scholarships,
 * sponsorships, tryouts and camps; athletes apply in-app; providers review.
 * Replaces the legacy scholarships / sponsorships endpoints (410 Gone).
 *
 * @see docs/PHASE_WISE_IMPLEMENTATION_PLAN.md Phase 4
 */
class OpportunityController extends Controller
{
    public function __construct(
        protected ExpiryService $expiry,
        protected NotificationService $notifications,
    ) {}

    /**
     * GET /opportunities (public, open listings only)
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'type' => 'nullable|in:'.implode(',', Opportunity::TYPES),
            'sport_id' => 'nullable|integer|exists:sports,id',
            'age_group_id' => 'nullable|integer|exists:age_groups,id',
            'deadline_from' => 'nullable|date',
            'deadline_to' => 'nullable|date',
            'q' => 'nullable|string|max:120',
        ]);

        $query = Opportunity::open()->with(['sport', 'ageGroup', 'logo']);

        $query->when($request->type, fn ($q) => $q->where('type', $request->type))
            ->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->age_group_id, fn ($q) => $q->where('age_group_id', $request->age_group_id))
            ->when($request->deadline_from, fn ($q) => $q->whereDate('deadline', '>=', $request->deadline_from))
            ->when($request->deadline_to, fn ($q) => $q->whereDate('deadline', '<=', $request->deadline_to))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub
                ->where('title', 'like', "%{$request->q}%")
                ->orWhere('description', 'like', "%{$request->q}%")))
            ->latest();

        $perPage = min((int) ($request->per_page ?? 20), 50);

        return response()->json($query->paginate($perPage)->withQueryString());
    }

    /**
     * GET /opportunities/{id}
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $opportunity = Opportunity::with(['sport', 'ageGroup', 'logo'])->findOrFail($id);

        // Public route → default guard is "web"; resolve the SANCTUM user so
        // authenticated viewers still see applied/saved state.
        $viewer = auth('sanctum')->user();
        $isOwner = $viewer && ((int) $viewer->id === (int) $opportunity->created_by_user_id || $viewer->isAdmin());

        abort_unless($opportunity->status === 'published' || $isOwner, 404);

        $data = $opportunity->toArray();
        $data['applied'] = false;
        $data['application_status'] = null;
        $data['saved'] = false;

        $athleteId = $viewer?->athleteProfile?->id;
        if ($athleteId) {
            $mine = $opportunity->applications()->where('athlete_id', $athleteId)->first();
            if ($mine) {
                $data['applied'] = true;
                $data['application_status'] = $mine->status;
            }
            $data['saved'] = SavedItem::where('user_id', $viewer->id)
                ->where('item_type', 'opportunity')
                ->where('item_id', $opportunity->id)
                ->exists();
        }

        return response()->json(['data' => $data]);
    }

    /**
     * POST /me/opportunities
     */
    public function store(Request $request): JsonResponse
    {
        [$providerType, $providerId] = $this->resolveProvider($request);

        $validated = $request->validate([
            'type' => 'required|in:'.implode(',', Opportunity::TYPES),
            'title' => 'required|string|max:255',
            'sport_id' => 'nullable|exists:sports,id',
            'age_group_id' => 'nullable|exists:age_groups,id',
            'eligibility' => 'nullable|string',
            'benefits' => 'nullable|string',
            'amount' => 'nullable|numeric|min:0',
            'deadline' => 'nullable|date|after:now',
            'documents_required' => 'nullable|array',
            'documents_required.*' => 'string',
            'description' => 'nullable|string',
            'logo_media_id' => 'nullable|exists:media_items,id',
            'status' => 'nullable|in:draft,published',
        ]);

        $opportunity = Opportunity::create(array_merge($validated, [
            'provider_type' => $providerType,
            'provider_id' => $providerId,
            'created_by_user_id' => $request->user()->id,
            'status' => $validated['status'] ?? 'draft',
        ]));

        if ($opportunity->status === 'published') {
            $this->expiry->onPublish($opportunity, 'opportunity');
        }

        return response()->json(['data' => $opportunity->load(['sport', 'ageGroup', 'logo'])], 201);
    }

    /**
     * PUT/PATCH /me/opportunities/{id}
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $opportunity = Opportunity::findOrFail($id);
        $this->authorizeOwner($request, $opportunity);

        $validated = $request->validate([
            'type' => 'sometimes|in:'.implode(',', Opportunity::TYPES),
            'title' => 'sometimes|string|max:255',
            'sport_id' => 'nullable|exists:sports,id',
            'age_group_id' => 'nullable|exists:age_groups,id',
            'eligibility' => 'nullable|string',
            'benefits' => 'nullable|string',
            'amount' => 'nullable|numeric|min:0',
            'deadline' => 'nullable|date|after:now',
            'documents_required' => 'nullable|array',
            'documents_required.*' => 'string',
            'description' => 'nullable|string',
            'logo_media_id' => 'nullable|exists:media_items,id',
        ]);

        $opportunity->update($validated);

        return response()->json(['data' => $opportunity->fresh(['sport', 'ageGroup', 'logo'])]);
    }

    /**
     * POST /me/opportunities/{id}/publish
     */
    public function publish(Request $request, string $id): JsonResponse
    {
        $opportunity = Opportunity::findOrFail($id);
        $this->authorizeOwner($request, $opportunity);

        $opportunity->update(['status' => 'published']);
        $this->expiry->onPublish($opportunity->fresh(), 'opportunity');

        return response()->json(['data' => $opportunity->fresh()]);
    }

    /**
     * POST /me/opportunities/{id}/close
     */
    public function close(Request $request, string $id): JsonResponse
    {
        $opportunity = Opportunity::findOrFail($id);
        $this->authorizeOwner($request, $opportunity);

        $opportunity->update(['status' => 'closed']);

        return response()->json(['data' => $opportunity->fresh()]);
    }

    /**
     * POST /opportunities/{id}/apply (athlete, 409 on duplicate)
     */
    public function apply(Request $request, string $id): JsonResponse
    {
        $opportunity = Opportunity::findOrFail($id);
        abort_unless($opportunity->isRegisterable(), 422, 'This opportunity is not open for applications.');

        $athlete = $request->user()->athleteProfile;
        abort_unless($athlete, 403, 'Athlete profile required.');

        $validated = $request->validate([
            'pitch' => 'required|string|max:2000',
            'document_media_ids' => 'nullable|array',
            'document_media_ids.*' => 'integer|exists:media_items,id',
        ]);

        abort_if(
            OpportunityApplication::where('opportunity_id', $opportunity->id)
                ->where('athlete_id', $athlete->id)->exists(),
            409, 'Already applied.'
        );

        $application = OpportunityApplication::create([
            'opportunity_id' => $opportunity->id,
            'athlete_id' => $athlete->id,
            'pitch' => $validated['pitch'],
            'document_media_ids' => $validated['document_media_ids'] ?? null,
            'snapshot' => $this->athleteSnapshot($athlete),
            'status' => 'submitted',
        ]);

        $ownerId = $this->providerOwnerId($opportunity);
        if ($ownerId) {
            $this->notifications->create([
                'user_id' => $ownerId,
                'type' => 'opportunity_application',
                'title' => 'New application received',
                'body' => "{$athlete->full_name} applied for \"{$opportunity->title}\".",
                'notifiable_type' => 'opportunity_application',
                'notifiable_id' => $application->id,
                'action_url' => "/opportunity-applications/{$opportunity->id}",
            ]);
        }

        return response()->json(['data' => $application], 201);
    }

    /**
     * GET /me/opportunities?type=applied|saved|created
     */
    public function mine(Request $request): JsonResponse
    {
        $validated = $request->validate(['type' => 'nullable|in:applied,saved,created']);

        $user = $request->user();
        // Athletes default to their applications; providers (academy/coach/
        // organizer/scout) have no athlete profile, so default to their
        // created listings instead of 403ing on the "applied" tab.
        $tab = $validated['type'] ?? ($user->athleteProfile ? 'applied' : 'created');

        if ($tab === 'applied') {
            $athlete = $user->athleteProfile;
            abort_unless($athlete, 403, 'Athlete profile required.');

            $applications = OpportunityApplication::with(['opportunity.sport'])
                ->where('athlete_id', $athlete->id)
                ->latest()
                ->paginate(20);

            return response()->json($applications);
        }

        if ($tab === 'saved') {
            $ids = SavedItem::where('user_id', $user->id)
                ->where('item_type', 'opportunity')
                ->pluck('item_id');

            $items = Opportunity::open()->with(['sport', 'ageGroup', 'logo'])
                ->whereIn('id', $ids)
                ->latest()
                ->paginate(20);

            return response()->json($items);
        }

        $items = Opportunity::with(['sport', 'ageGroup'])
            ->where('created_by_user_id', $user->id)
            ->latest()
            ->paginate(20);

        return response()->json($items);
    }

    /**
     * GET /opportunities/{id}/applications (owner/admin)
     */
    public function applications(Request $request, string $id): JsonResponse
    {
        $opportunity = Opportunity::findOrFail($id);
        $this->authorizeOwner($request, $opportunity);

        $applications = OpportunityApplication::with(['athlete.user', 'athlete.sports'])
            ->where('opportunity_id', $opportunity->id)
            ->latest()
            ->paginate(20);

        return response()->json($applications);
    }

    /**
     * PATCH /opportunities/{id}/applications/{app} (shortlist/decline + note)
     */
    public function review(Request $request, string $id, string $appId): JsonResponse
    {
        $opportunity = Opportunity::findOrFail($id);
        $this->authorizeOwner($request, $opportunity);

        $application = OpportunityApplication::where('opportunity_id', $opportunity->id)->findOrFail($appId);

        $validated = $request->validate([
            'status' => 'required|in:shortlisted,declined',
            'decision_note' => 'nullable|string|max:1000',
        ]);

        $application->update([
            'status' => $validated['status'],
            'decision_note' => $validated['decision_note'] ?? null,
            'replied_at' => now(),
        ]);

        $title = $validated['status'] === 'shortlisted' ? 'Application shortlisted!' : 'Application not selected';
        $body = $validated['decision_note']
            ?? "Your application for \"{$opportunity->title}\" was {$validated['status']}.";

        $this->notifications->create([
            'user_id' => $application->athlete->user_id,
            'type' => 'status_update',
            'title' => $title,
            'body' => $body,
            'notifiable_type' => 'opportunity_application',
            'notifiable_id' => $application->id,
            'action_url' => '/my-opportunities',
        ]);

        return response()->json(['data' => $application->load(['athlete.user'])]);
    }

    /* ------------------------------------------------------------------ */

    /**
     * @return array{0: string, 1: int}
     */
    protected function resolveProvider(Request $request): array
    {
        $user = $request->user();

        return match ($user->role) {
            'academy' => ['academy', $user->academies?->id ?? abort(403, 'Academy profile required.')],
            'organizer' => ['organizer_profile', $user->organizerProfile?->id ?? abort(403, 'Organizer profile required.')],
            'coach' => ['coach_profile', $user->coachProfile?->id ?? abort(403, 'Coach profile required.')],
            'talent_scout', 'scout' => ['talent_scout_profile', $user->talentScoutProfile?->id ?? abort(403, 'Scout profile required.')],
            default => abort(403, 'Only academy, organizer, coach or scout accounts can post opportunities.'),
        };
    }

    protected function authorizeOwner(Request $request, Opportunity $opportunity): void
    {
        $user = $request->user();
        abort_unless(
            (int) $opportunity->created_by_user_id === (int) $user->id || $user->isAdmin(),
            403
        );
    }

    protected function providerOwnerId(Opportunity $opportunity): ?int
    {
        $provider = $opportunity->provider;

        if (! $provider) {
            return $opportunity->created_by_user_id;
        }

        return $provider->owner_user_id ?? $provider->user_id ?? $opportunity->created_by_user_id;
    }

    protected function athleteSnapshot($athlete): array
    {
        $athlete->loadMissing(['sports', 'city', 'ageGroup']);

        return [
            'full_name' => $athlete->full_name,
            'sports' => $athlete->sports->pluck('name')->all(),
            'city' => $athlete->city?->name,
            'age_group' => $athlete->ageGroup?->name,
            'skill_level' => $athlete->skill_level,
            'achievements_count' => $athlete->achievements()->count(),
        ];
    }
}
