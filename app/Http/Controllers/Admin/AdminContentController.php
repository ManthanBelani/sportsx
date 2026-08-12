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
    ];

    // Not every content table uses the same status column — academies, coaches
    // and sports_venues use `listing_status`, the rest use `status`.
    private array $statusColumn = [
        'academies' => 'listing_status',
        'coaches' => 'listing_status',
        'trials' => 'status',
        'tournaments' => 'status',
        'scholarships' => 'status',
        'sponsorships' => 'status',
        'sports_venues' => 'listing_status',
    ];

    public function picker(): JsonResponse
    {
        $counts = [];
        foreach ($this->models as $type => $model) {
            $col = $this->statusColumn[$type];
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
        if ($request->has('status')) {
            $query->where($this->statusColumn[$type], $request->status);
        }

        if ($request->has('q')) {
            $query->where('name', 'like', '%' . $request->q . '%');
        }

        // Sorting
        $sortField = $request->get('sort', 'created_at');
        $sortDir = $request->get('direction', 'desc');
        $query->orderBy($sortField, $sortDir);

        $perPage = min($request->get('per_page', 20), 50);
        $items = $query->paginate($perPage);

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

        return response()->json([
            'data' => $item
        ]);
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
        $validated = $request->validate($model::rules() ?? []);

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

        $validated = $request->validate($model::rules() ?? []);
        $item->update($validated);

        return response()->json([
            'data' => $item
        ]);
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
