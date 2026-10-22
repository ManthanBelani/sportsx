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

        // Canonical: organizer_id FKs organizer_profiles.id (see migration).
        // Legacy rows created via store() used user_id — match both for back-compat
        // (same dual-lookup as OrganizerAnalyticsController).
        $query = Tournament::with(['sport', 'city', 'bannerMedia', 'categories'])->withRegistrationCounts()
            ->orderBy('start_date', 'desc');
        $profileId = $user->organizerProfile?->id;
        if ($profileId) {
            $query->where(function ($q) use ($user, $profileId) {
                $q->where('organizer_id', $user->id)
                  ->orWhere('organizer_id', $profileId);
            });
        } else {
            $query->where('organizer_id', $user->id);
        }
        $tournaments = $query->paginate(20);

        return response()->json([
            'data' => $tournaments->getCollection()->map(fn ($t) => array_merge(
                $t->toArray(),
                $t->registrationStats()
            ))->values(),
            'current_page' => $tournaments->currentPage(),
            'last_page' => $tournaments->lastPage(),
            'per_page' => $tournaments->perPage(),
            'total' => $tournaments->total(),
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
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'registration_deadline' => 'nullable|date',
            'entry_fee' => 'nullable|numeric|min:0',
            'prize_pool' => 'nullable|string|max:500',
            'rules' => 'nullable|string',
            'banner_media_id' => 'nullable|integer|exists:media_items,id',
            'contact_number' => 'nullable|string|max:20',
            'registration_link' => 'nullable|url|max:500',
            'external_registration_url' => ['nullable', 'string', 'max:500', new \App\Rules\ExternalRegistrationUrl],
            'gender' => 'nullable|in:male,female',
            'categories' => 'nullable|array',
            'categories.*.name' => 'required_with:categories|string|max:100',
            'categories.*.age_group_id' => 'nullable|integer|exists:age_groups,id',
            'categories.*.capacity' => 'nullable|integer|min:1',
            'categories.*.max_teams' => 'nullable|integer|min:1',
            'categories.*.waitlist_enabled' => 'nullable|boolean',
            'status' => 'nullable|in:draft,published,closed',
        ]);

        return DB::transaction(function () use ($validated, $user) {
            $cats = $validated['categories'] ?? null;
            // Normalize max_teams alias to capacity
            if (is_array($cats)) {
                foreach ($cats as &$c) {
                    if (isset($c['max_teams']) && !isset($c['capacity'])) $c['capacity'] = $c['max_teams'];
                    unset($c['max_teams']);
                    if (empty($c['age_group_id'])) unset($c['age_group_id']);
                }
                unset($c);
            }
            $tournamentData = array_merge(
                collect($validated)->except('categories')->toArray(),
                // Canonical FK: organizer_profiles.id (migration constrains
                // organizer_id -> organizer_profiles). Fall back to user_id
                // only when the user has no organizer profile yet.
                ['organizer_id' => $user->organizerProfile?->id ?? $user->id]
            );
            // Remove alias leftover
            unset($tournamentData['categories']);
            // An empty external link means "use the in-app registration flow".
            if (array_key_exists('external_registration_url', $tournamentData)) {
                $tournamentData['external_registration_url'] = $this->normalizeExternalUrl($tournamentData['external_registration_url']);
            }
            // Honor auto-approve setting
            $settings = $this->platformSettings();
            $autoApprove = $settings['auto_approve_tournaments'] ?? false;
            if (($tournamentData['status'] ?? 'draft') === 'published' && !$autoApprove) {
                $tournamentData['status'] = 'draft';
            }
            $tournament = Tournament::create($tournamentData);

            foreach ($cats ?? [] as $cat) {
                // Ensure unique age_group handling: if age_group_id missing, create with null may violate unique — so add fallback
                if (!isset($cat['age_group_id'])) {
                    // Use a dummy age_group_id fetch or set to first available
                    $cat['age_group_id'] = \App\Models\AgeGroup::first()?->id ?? 1;
                }
                $tournament->categories()->create($cat);
            }

            return response()->json([
                'data' => array_merge(
                    $tournament->load(['sport', 'city', 'categories'])->toArray(),
                    $tournament->registrationStats()
                ),
            ], 201);
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
            'external_registration_url' => ['nullable', 'string', 'max:500', new \App\Rules\ExternalRegistrationUrl],
            'gender' => 'nullable|in:male,female',
            'status' => 'nullable|in:draft,published,closed',
        ]);

        $payload = collect($validated)->except(['categories'])->toArray();
        if (array_key_exists('external_registration_url', $payload)) {
            $payload['external_registration_url'] = $this->normalizeExternalUrl($payload['external_registration_url']);
        }

        $tournament->update($payload);

        return response()->json([
            'data' => array_merge(
                $tournament->load(['sport', 'city', 'categories'])->toArray(),
                $tournament->registrationStats()
            ),
        ]);
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
            'categories.*.max_teams' => 'nullable|integer|min:1',
            'categories.*.waitlist_enabled' => 'nullable|boolean',
        ]);

        return DB::transaction(function () use ($validated, $tournament) {
            foreach ($validated['categories'] as $catData) {
                if (isset($catData['max_teams']) && !isset($catData['capacity'])) $catData['capacity'] = $catData['max_teams'];
                unset($catData['max_teams']);

                // 1) Explicit id wins.
                $existing = null;
                if (! empty($catData['id'])) {
                    $existing = $tournament->categories()->where('id', $catData['id'])->first();
                }

                // 2) Otherwise match on age_group_id — the (tournament_id,
                //    age_group_id) unique index makes inserting a duplicate
                //    age group impossible, so treat it as an update instead.
                if (! $existing && ! empty($catData['age_group_id'])) {
                    $existing = $tournament->categories()
                        ->where('age_group_id', $catData['age_group_id'])
                        ->first();
                }

                // 3) Rows created WITHOUT an explicit age group got the
                //    fallback AgeGroup::first() — that row would collide with
                //    the duplicate insert below, so match it too.
                if (! $existing && empty($catData['age_group_id'])) {
                    $fallbackId = \App\Models\AgeGroup::first()?->id ?? 1;
                    $existing = $tournament->categories()
                        ->where('age_group_id', $fallbackId)
                        ->first();
                }

                if ($existing) {
                    $existing->update(collect($catData)->except('id')->toArray());
                } else {
                    if (empty($catData['age_group_id'])) $catData['age_group_id'] = \App\Models\AgeGroup::first()?->id ?? 1;
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
        if ($user->isAdmin()) return;
        // Canonical: organizer_id = organizer_profiles.id; legacy: user_id.
        if ($user->organizerProfile && (int) $tournament->organizer_id === (int) $user->organizerProfile->id) return;
        abort_unless((int) $tournament->organizer_id === (int) $user->id, 403);
    }

    /**
     * Empty / whitespace-only links are stored as NULL so the tournament
     * falls back to the in-app registration flow.
     */
    private function normalizeExternalUrl($value): ?string
    {
        if (! is_string($value)) {
            return null;
        }

        $value = trim($value);

        return $value === '' ? null : $value;
    }

    private function platformSettings(): array
    {
        $path = storage_path('app/platform_settings.json');
        if (file_exists($path)) {
            return json_decode((string) file_get_contents($path), true) ?: [];
        }
        return [];
    }
}
