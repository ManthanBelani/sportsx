<?php

namespace App\Http\Controllers;

use App\Models\Tournament;
use App\Models\TournamentCategory;
use App\Services\ExpiryService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProviderTournamentController extends Controller
{
    public function __construct(private ExpiryService $expiryService) {}

    public function index(Request $request)
    {
        $user = $request->user();

        $tournaments = Tournament::where('organizer_id', $user->id)
            ->with(['sport', 'city', 'categories'])
            ->orderBy('start_date', 'desc')
            ->paginate(20);

        return response()->json([
            'data' => $tournaments->items(),
            'meta' => ['pagination' => [
                'total' => $tournaments->total(),
                'per_page' => $tournaments->perPage(),
                'current_page' => $tournaments->currentPage(),
                'last_page' => $tournaments->lastPage(),
            ]],
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        abort_unless($user->role === 'organizer', 403, 'Only organizers can create tournaments');

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'sport_id' => 'required|integer|exists:sports,id',
            'city_id' => 'required|integer|exists:cities,id',
            'venue' => 'required|string|max:500',
            'google_maps_url' => 'nullable|url|max:1000',
            'format' => 'nullable|in:single-elimination,double-elimination,round-robin,league,knockout',
            'start_date' => 'required|date|after:now',
            'end_date' => 'required|date|after:start_date',
            'registration_deadline' => 'nullable|date|before:start_date',
            'entry_fee' => 'nullable|numeric|min:0',
            'prize_pool' => 'nullable|string|max:500',
            'rules' => 'nullable|string',
            'banner_media_id' => 'nullable|integer|exists:media_items,id',
            'contact_number' => 'nullable|string|max:20',
            'registration_link' => 'nullable|url|max:500',
            'gender' => 'nullable|in:male,female,mixed',
            'categories' => 'nullable|array',
            'categories.*.name' => 'required_with:categories|string|max:100',
            'categories.*.age_group_id' => 'nullable|integer|exists:age_groups,id',
            'categories.*.capacity' => 'nullable|integer|min:1',
            'categories.*.waitlist_enabled' => 'nullable|boolean',
            'status' => 'nullable|in:draft,published,closed',
        ]);

        return DB::transaction(function () use ($validated, $user) {
            $tournamentData = array_merge(
                collect($validated)->except('categories')->toArray(),
                ['organizer_id' => $user->id]
            );
            $tournament = Tournament::create($tournamentData);

            foreach ($validated['categories'] ?? [] as $cat) {
                $tournament->categories()->create($cat);
            }

            return response()->json(['data' => $tournament->load(['sport', 'city', 'categories'])], 201);
        });
    }

    public function update(Request $request, Tournament $tournament)
    {
        $this->authorizeOwner($request, $tournament);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'sport_id' => 'sometimes|integer|exists:sports,id',
            'city_id' => 'sometimes|integer|exists:cities,id',
            'venue' => 'sometimes|string|max:500',
            'google_maps_url' => 'nullable|url|max:1000',
            'format' => 'nullable|in:single-elimination,double-elimination,round-robin,league,knockout',
            'start_date' => 'sometimes|date|after:now',
            'end_date' => 'sometimes|date|after:start_date',
            'registration_deadline' => 'nullable|date|before:start_date',
            'entry_fee' => 'nullable|numeric|min:0',
            'prize_pool' => 'nullable|string|max:500',
            'rules' => 'nullable|string',
            'banner_media_id' => 'nullable|integer|exists:media_items,id',
            'contact_number' => 'nullable|string|max:20',
            'registration_link' => 'nullable|url|max:500',
            'gender' => 'nullable|in:male,female,mixed',
            'status' => 'nullable|in:draft,published,closed',
        ]);

        $tournament->update(collect($validated)->except(['categories'])->toArray());

        return response()->json(['data' => $tournament->load(['sport', 'city', 'categories'])]);
    }

    public function updateCategories(Request $request, Tournament $tournament)
    {
        $this->authorizeOwner($request, $tournament);

        $validated = $request->validate([
            'categories' => 'required|array',
            'categories.*.id' => 'nullable|integer|exists:tournament_categories,id',
            'categories.*.name' => 'required|string|max:100',
            'categories.*.age_group_id' => 'nullable|integer|exists:age_groups,id',
            'categories.*.capacity' => 'nullable|integer|min:1',
            'categories.*.waitlist_enabled' => 'nullable|boolean',
        ]);

        return DB::transaction(function () use ($validated, $tournament) {
            $existingIds = $tournament->categories()->pluck('id')->toArray();
            $incoming = collect($validated['categories']);

            foreach ($validated['categories'] as $catData) {
                if (! empty($catData['id']) && in_array($catData['id'], $existingIds)) {
                    $tournament->categories()->where('id', $catData['id'])->update(collect($catData)->except('id')->toArray());
                } else {
                    $tournament->categories()->create($catData);
                }
            }

            return response()->json(['data' => $tournament->load(['categories'])]);
        });
    }

    public function publish(Request $request, Tournament $tournament)
    {
        $this->authorizeOwner($request, $tournament);

        $tournament->update(['status' => 'published']);
        $this->expiryService->onPublish($tournament, 'tournament');

        return response()->json(['data' => $tournament]);
    }

    public function close(Request $request, Tournament $tournament)
    {
        $this->authorizeOwner($request, $tournament);

        $tournament->update(['status' => 'closed']);

        return response()->json(['data' => $tournament]);
    }

    private function authorizeOwner(Request $request, Tournament $tournament): void
    {
        $user = $request->user();
        abort_unless($tournament->organizer_id === $user->id || $user->isAdmin(), 403);
    }
}
