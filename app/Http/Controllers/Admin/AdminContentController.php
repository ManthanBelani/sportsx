<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AdminContentController extends Controller
{
    private array $models = [
        'academies' => \App\Models\Academy::class,
        'coaches' => \App\Models\CoachProfile::class,
        'trials' => \App\Models\Trial::class,
        'tournaments' => \App\Models\Tournament::class,
        'scholarships' => \App\Models\Scholarship::class,
        'sponsorships' => \App\Models\Sponsorship::class,
        'sports_venues' => \App\Models\SportsVenue::class,
        'opportunities' => \App\Models\Opportunity::class,
        'programs' => \App\Models\Program::class,
        'facilities' => \App\Models\Facility::class,
        'posts' => \App\Models\Post::class,
    ];

    // Not every content table uses the same status column — academies, coaches
    // and sports_venues use `listing_status`, the rest use `status`.
    // programs use active/draft/past; facilities + posts have no status
    // column (null = unfiltered, counts report totals only).
    private array $statusColumn = [
        'academies' => 'listing_status',
        'coaches' => 'listing_status',
        'trials' => 'status',
        'tournaments' => 'status',
        'scholarships' => 'status',
        'sponsorships' => 'status',
        'sports_venues' => 'listing_status',
        'opportunities' => 'status',
        'programs' => 'status',
        'facilities' => null,
        'posts' => null,
    ];

    public function picker(): JsonResponse
    {
        $counts = [];
        foreach ($this->models as $type => $model) {
            $col = $this->statusColumn[$type];
            if ($col === null) {
                $counts[$type] = ['total' => $model::count()];
                continue;
            }
            $counts[$type] = [
                'total' => $model::count(),
                'published' => $model::where($col, 'published')->count(),
                'draft' => $model::where($col, 'draft')->count(),
            ];
        }

        return response()->json([
            'data' => $counts
        ]);
    }

    public function index(Request $request, string $type): JsonResponse
    {
        if (!isset($this->models[$type])) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Content type not found.',
                ]
            ], 404);
        }

        $model = $this->models[$type];
        $query = $model::query();

        // Apply filters
        if ($request->has('status') && $this->statusColumn[$type] !== null) {
            $query->where($this->statusColumn[$type], $request->status);
        }

        if ($request->has('q')) {
            $col = $type === 'posts' ? 'body' : ($type === 'programs' ? 'title' : 'name');
            $query->where($col, 'like', '%' . $request->q . '%');
        }

        // Sorting — whitelist to prevent injection
        $allowedSorts = ['created_at', 'updated_at', 'name', 'title', 'status', 'listing_status'];
        $sortField = in_array($request->get('sort'), $allowedSorts, true) ? $request->get('sort') : 'created_at';
        $sortDir = strtolower($request->get('direction', 'desc')) === 'asc' ? 'asc' : 'desc';
        $query->orderBy($sortField, $sortDir);

        $perPage = min($request->get('per_page', 20), 50);

        // Tournaments carry their registration counters so the admin
        // tournament management view can show "Registrations: N" next to the
        // external register-button clicks.
        if ($type === 'tournaments') {
            $query->withRegistrationCounts();
        }

        $items = $query->paginate($perPage);

        if ($type === 'tournaments') {
            $items->setCollection($items->getCollection()->map(fn ($t) => array_merge(
                $t->toArray(),
                $t->registrationStats()
            )));
        }

        return response()->json([
            'data' => $items->items(),
            'meta' => [
                'current_page' => $items->currentPage(),
                'per_page' => $items->perPage(),
                'total' => $items->total(),
                'last_page' => $items->lastPage(),
            ]
        ]);
    }

    public function show(string $type, int $id): JsonResponse
    {
        if (!isset($this->models[$type])) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Content type not found.',
                ]
            ], 404);
        }

        $model = $this->models[$type];
        $item = $model::find($id);

        if (!$item) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Item not found.',
                ]
            ], 404);
        }

        if ($type === 'tournaments' && $item instanceof \App\Models\Tournament) {
            return response()->json([
                'data' => $this->decorateTournament($item)
            ]);
        }

        return response()->json([
            'data' => $item
        ]);
    }

    /**
     * Tournament rows expose their registration counters so the admin
     * tournament management view can show "Registrations: N" alongside the
     * external register-button clicks.
     */
    private function decorateTournament($tournament): array
    {
        $tournament->loadMissing('sport', 'city', 'categories')->withRegistrationCounts();

        return array_merge($tournament->toArray(), $tournament->registrationStats());
    }

    public function store(Request $request, string $type): JsonResponse
    {
        if (!isset($this->models[$type])) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Content type not found.',
                ]
            ], 404);
        }

        $model = $this->models[$type];
        $rules = method_exists($model, 'rules') ? $model::rules() : [];
        // If model defines no rules, accept all fillable input (admin is trusted)
        if (empty($rules)) {
            $validated = $request->all();
            // Validate only owner_user_id if present
            $request->validate(['owner_user_id' => 'nullable|integer|exists:users,id']);
        } else {
            $validated = $request->validate(array_merge($rules, [
                'owner_user_id' => 'nullable|integer|exists:users,id',
            ]));
        }

        $validated = $this->injectOwner($request, $type, $validated);
        $validated = $this->validateTournamentRegistrationLink($request, $type, $validated);

        $item = $model::create($validated);

        return response()->json([
            'data' => $item
        ], 201);
    }

    public function update(Request $request, string $type, int $id): JsonResponse
    {
        if (!isset($this->models[$type])) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Content type not found.',
                ]
            ], 404);
        }

        $model = $this->models[$type];
        $item = $model::find($id);

        if (!$item) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Item not found.',
                ]
            ], 404);
        }

        $rules = method_exists($model, 'rules') ? $model::rules() : [];
        if (empty($rules)) {
            $validated = $request->all();
            $request->validate(['owner_user_id' => 'nullable|integer|exists:users,id']);
        } else {
            $validated = $request->validate(array_merge($rules, [
                'owner_user_id' => 'nullable|integer|exists:users,id',
            ]));
        }
        $validated = $this->injectOwner($request, $type, $validated, $item);
        $validated = $this->validateTournamentRegistrationLink($request, $type, $validated);

        $item->update($validated);

        return response()->json([
            'data' => $item
        ]);
    }

    /**
     * Admin edits of a tournament go through the same external-URL validation
     * as the organizer's own form.
     */
    private function validateTournamentRegistrationLink(Request $request, string $type, array $validated): array
    {
        if ($type !== 'tournaments') {
            return $validated;
        }

        if (! $request->has('external_registration_url')) {
            return $validated;
        }

        $request->validate([
            'external_registration_url' => ['nullable', 'string', 'max:500', new \App\Rules\ExternalRegistrationUrl],
        ]);

        $value = $request->input('external_registration_url');
        $validated['external_registration_url'] = (is_string($value) && trim($value) !== '') ? trim($value) : null;

        return $validated;
    }

    private function ownerColumnForType(string $type): ?string
    {
        return match ($type) {
            'trials' => 'posted_by_user_id',
            'tournaments' => 'organizer_id',
            'academies' => 'owner_user_id',
            'coaches' => 'user_id',
            'scholarships' => 'created_by',
            'sponsorships' => 'sponsor_id',
            default => null,
        };
    }

    private function injectOwner(Request $request, string $type, array $validated, ?object $existing = null): array
    {
        $col = $this->ownerColumnForType($type);
        if (! $col) return collect($validated)->except('owner_user_id')->toArray();

        $ownerUserId = $validated['owner_user_id'] ?? $request->input('owner_user_id');
        // If not provided on store, fallback to admin; on update, keep existing
        if (empty($ownerUserId)) {
            if ($existing && ! empty($existing->{$col})) {
                unset($validated['owner_user_id']);
                return $validated;
            }
            $ownerUserId = $request->user()?->id;
        }
        unset($validated['owner_user_id']);
        if (! $ownerUserId) return $validated;

        if ($type === 'tournaments') {
            $profile = \App\Models\OrganizerProfile::firstOrCreate(
                ['user_id' => (int) $ownerUserId],
                ['organization_name' => \App\Models\User::find($ownerUserId)?->name ?? 'Admin Organization', 'org_type' => 'other', 'verification_status' => 'verified']
            );
            $validated[$col] = $profile->id;
        } elseif ($type === 'sponsorships') {
            $profile = \App\Models\SponsorProfile::firstOrCreate(
                ['user_id' => (int) $ownerUserId],
                ['brand_name' => \App\Models\User::find($ownerUserId)?->name ?? 'Admin Sponsor']
            );
            $validated[$col] = $profile->id;
        } else {
            $validated[$col] = (int) $ownerUserId;
        }
        return $validated;
    }

    public function destroy(string $type, int $id): JsonResponse
    {
        if (!isset($this->models[$type])) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Content type not found.',
                ]
            ], 404);
        }

        $model = $this->models[$type];
        $item = $model::find($id);

        if (!$item) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Item not found.',
                ]
            ], 404);
        }

        $item->delete();

        return response()->json(null, 204);
    }
}
