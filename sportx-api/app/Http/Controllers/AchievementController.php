<?php

namespace App\Http\Controllers;

use App\Models\Achievement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Typed achievement CRUD (Phase 2).
 *
 * Each row is owned by the caller's athlete profile OR coach profile
 * (whichever exists). Coaches previously stored achievements as a JSON blob
 * on `coach_profiles`; the typed table is the way forward, the blob stays
 * readable.
 *
 * @see docs/PHASE_WISE_IMPLEMENTATION_PLAN.md Phase 2
 */
class AchievementController extends Controller
{
    /**
     * GET /me/achievements
     */
    public function index(Request $request): JsonResponse
    {
        $query = $this->scope($request)->with($this->availableRelations())
            ->orderBy('sort_order');

        if (\Illuminate\Support\Facades\Schema::hasColumn('achievements', 'year')) {
            $query->orderByDesc('year');
        }

        return response()->json(['data' => $query->get()]);
    }

    /**
     * POST /me/achievements
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:190',
            'type' => 'nullable|string|max:50',
            'sport_id' => 'nullable|exists:sports,id',
            'level' => 'nullable|string|max:50',
            'year' => 'nullable|integer|min:1900|max:'.(date('Y') + 1),
            'certificate_media_id' => 'nullable|exists:media_items,id',
            'description' => 'nullable|string|max:2000',
        ]);

        $owner = $this->owner($request);
        abort_unless($owner !== null, 422, 'Complete your athlete or coach profile before adding achievements.');

        // Only persist columns that exist: the typed columns arrive with the
        // Phase-2 migration, but the endpoint must already work before it runs.
        $attributes = array_merge($validated, $owner, [
            'text' => $validated['title'],
            'sort_order' => $this->scope($request)->max('sort_order') + 1,
        ]);
        $attributes = array_intersect_key(
            $attributes,
            array_flip($this->writableColumns())
        );

        $achievement = Achievement::create($attributes);

        return response()->json(['data' => $achievement->load($this->availableRelations())], 201);
    }

    /**
     * PUT /me/achievements/{id}
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $achievement = $this->scope($request)->findOrFail($id);

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:190',
            'type' => 'nullable|string|max:50',
            'sport_id' => 'nullable|exists:sports,id',
            'level' => 'nullable|string|max:50',
            'year' => 'nullable|integer|min:1900|max:'.(date('Y') + 1),
            'certificate_media_id' => 'nullable|exists:media_items,id',
            'description' => 'nullable|string|max:2000',
            'sort_order' => 'sometimes|integer|min:0',
        ]);

        if (isset($validated['title'])) {
            $validated['text'] = $validated['title'];
        }

        $achievement->update(array_intersect_key(
            $validated,
            array_flip($this->writableColumns())
        ));

        return response()->json(['data' => $achievement->fresh($this->availableRelations())]);
    }

    /**
     * DELETE /me/achievements/{id}
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $achievement = $this->scope($request)->findOrFail($id);
        $achievement->delete();

        return response()->json(['data' => ['message' => 'Achievement deleted.']]);
    }

    /**
     * Columns safe to write on this database (typed columns need the Phase-2
     * migration; legacy columns always exist).
     *
     * @return list<string>
     */
    protected function writableColumns(): array
    {
        $columns = ['athlete_id', 'text', 'sort_order'];

        foreach (['coach_profile_id', 'title', 'type', 'sport_id', 'level', 'year', 'certificate_media_id', 'description'] as $column) {
            if (\Illuminate\Support\Facades\Schema::hasColumn('achievements', $column)) {
                $columns[] = $column;
            }
        }

        return $columns;
    }

    /**
     * @return list<string>
     */
    protected function availableRelations(): array
    {
        $relations = [];

        if (\Illuminate\Support\Facades\Schema::hasColumn('achievements', 'sport_id')) {
            $relations[] = 'sport';
        }

        if (\Illuminate\Support\Facades\Schema::hasColumn('achievements', 'certificate_media_id')) {
            $relations[] = 'certificate';
        }

        return $relations;
    }

    /**
     * Rows owned by the caller — athlete profile first, then coach profile.
     */
    protected function scope(Request $request)
    {
        $user = $request->user();

        if ($user->athleteProfile) {
            return Achievement::where('athlete_id', $user->athleteProfile->id);
        }

        if ($user->coachProfile) {
            return Achievement::where('coach_profile_id', $user->coachProfile->id);
        }

        // No profile yet: an empty scope so index returns [] and
        // store aborts with a helpful message instead of a 500.
        return Achievement::whereRaw('1 = 0');
    }

    /**
     * @return array{athlete_id: ?int, coach_profile_id: ?int}|null
     */
    protected function owner(Request $request): ?array
    {
        $user = $request->user();

        if ($user->athleteProfile) {
            return ['athlete_id' => $user->athleteProfile->id, 'coach_profile_id' => null];
        }

        if ($user->coachProfile) {
            return ['athlete_id' => null, 'coach_profile_id' => $user->coachProfile->id];
        }

        return null;
    }
}
