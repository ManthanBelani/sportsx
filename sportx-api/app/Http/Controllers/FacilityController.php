<?php

namespace App\Http\Controllers;

use App\Models\Facility;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Academy facilities (Phase 5): structured rows replacing the free-form
 * `academies.facilities` JSON (backfilled by migration).
 *
 * @see docs/PHASE_WISE_IMPLEMENTATION_PLAN.md Phase 5
 */
class FacilityController extends Controller
{
    /**
     * GET /facilities/{id} (public)
     */
    public function show(string $id): JsonResponse
    {
        return response()->json([
            'data' => Facility::with('academy:id,name')->findOrFail($id),
        ]);
    }

    /**
     * GET /me/facilities
     *
     * Academies see their own grounds, organizers see the venues they run.
     */
    public function mine(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $this->ownedQuery($request)->orderBy('name')->get(),
        ]);
    }

    /**
     * POST /me/facilities
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $this->rules($request);

        $facility = Facility::create(array_merge($validated, $this->ownerColumns($request)));

        return response()->json(['data' => $facility], 201);
    }

    /**
     * PUT /me/facilities/{id}
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $facility = $this->owned($request, $id);
        $facility->update($this->rules($request, sometimes: true));

        return response()->json(['data' => $facility->fresh()]);
    }

    /**
     * DELETE /me/facilities/{id}
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $this->owned($request, $id)->delete();

        return response()->json(['data' => ['message' => 'Facility deleted.']]);
    }

    protected function owned(Request $request, string $id): Facility
    {
        return $this->ownedQuery($request)->findOrFail($id);
    }

    /**
     * The rows the caller owns (academy grounds or organizer venues).
     */
    protected function ownedQuery(Request $request)
    {
        $user = $request->user();

        $academy = $user->academies;
        if ($academy) {
            return Facility::where('academy_id', $academy->id);
        }

        $organizer = $user->organizerProfile;
        abort_unless($organizer, 403, 'Academy or organizer profile required.');

        return Facility::where('organizer_id', $organizer->id);
    }

    /**
     * The owner columns for a newly created facility.
     */
    protected function ownerColumns(Request $request): array
    {
        $user = $request->user();

        $academy = $user->academies;
        if ($academy) {
            return ['academy_id' => $academy->id, 'organizer_id' => null];
        }

        $organizer = $user->organizerProfile;
        abort_unless($organizer, 403, 'Academy or organizer profile required.');

        return ['academy_id' => null, 'organizer_id' => $organizer->id];
    }

    protected function rules(Request $request, bool $sometimes = false): array
    {
        $prefix = $sometimes ? 'sometimes|' : '';

        $validated = $request->validate([
            'name' => $prefix.'required|string|max:150',
            'type' => 'nullable|in:ground,indoor,gym,other',
            'size' => 'nullable|string|max:120',
            'amenities' => 'nullable|array',
            'amenities.*' => 'string|max:80',
            'image_media_ids' => 'nullable|array',
            'image_media_ids.*' => 'integer|exists:media_items,id',
        ]);

        // Only normalise the type when it was actually sent — a partial
        // update (e.g. renaming a venue) must not reset it to "other".
        if (array_key_exists('type', $validated)) {
            $validated['type'] = strtolower($validated['type'] ?? 'other');
        }

        return $validated;
    }
}
