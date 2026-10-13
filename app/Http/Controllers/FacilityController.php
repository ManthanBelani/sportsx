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
     */
    public function mine(Request $request): JsonResponse
    {
        $academy = $request->user()->academies;
        abort_unless($academy, 403, 'Academy profile required.');

        return response()->json([
            'data' => Facility::where('academy_id', $academy->id)->orderBy('name')->get(),
        ]);
    }

    /**
     * POST /me/facilities
     */
    public function store(Request $request): JsonResponse
    {
        $academy = $request->user()->academies;
        abort_unless($academy, 403, 'Academy profile required.');

        $validated = $this->rules($request);

        $facility = Facility::create(array_merge($validated, ['academy_id' => $academy->id]));

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
        $academy = $request->user()->academies;
        abort_unless($academy, 403, 'Academy profile required.');

        return Facility::where('academy_id', $academy->id)->findOrFail($id);
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

        $validated['type'] = strtolower($validated['type'] ?? 'other');

        return $validated;
    }
}
