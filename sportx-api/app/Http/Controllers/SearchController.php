<?php

namespace App\Http\Controllers;

use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\Scholarship;
use App\Models\Sponsorship;
use App\Models\SportsVenue;
use App\Models\Tournament;
use App\Models\Trial;
use App\Models\RecentSearch;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function search(Request $request)
    {
        $request->validate([
            'q' => 'nullable|string|max:120',
            'sport_id' => 'nullable|integer',
            'city_id' => 'nullable|integer',
            'age_group_id' => 'nullable|integer',
            'date_from' => 'nullable|date',
            'date_to' => 'nullable|date',
            'gender' => 'nullable|in:male,female,mixed,open,all',
        ]);

        $q = (string) $request->input('q', '');
        $limit = (int) ($request->per_page ?? 5);
        $sportId = $request->sport_id;
        $cityId = $request->city_id;
        $ageGroupId = $request->age_group_id;
        $dateFrom = $request->date_from;
        $dateTo = $request->date_to;
        $gender = $request->gender && $request->gender !== 'all' ? $request->gender : null;

        $hasFilters = $sportId || $cityId || $ageGroupId || $dateFrom || $dateTo || $gender;
        abort_unless($q !== '' || $hasFilters, 422, 'A query or at least one filter is required');

        // Save search for logged-in user
        if ($q !== '' && $request->user()) {
            RecentSearch::updateOrCreate(
                ['user_id' => $request->user()->id, 'query' => $q],
                ['created_at' => now()]
            );
        }

        $textMatch = function (array $fields) use ($q) {
            if ($q === '') {
                return null;
            }
            return function ($s) use ($fields, $q) {
                $s->where(function ($sub) use ($fields, $q) {
                    foreach ($fields as $i => $field) {
                        if ($i === 0) {
                            $sub->where($field, 'like', "%{$q}%");
                        } else {
                            $sub->orWhere($field, 'like', "%{$q}%");
                        }
                    }
                });
            };
        };

        $data = [
            'academies' => Academy::published()
                ->when($textMatch(['name', 'description']), fn ($query, $cond) => $query->where($cond))
                ->when($sportId, fn ($s) => $s->whereHas('sports', fn ($sp) => $sp->where('sport_id', $sportId)))
                ->when($cityId, fn ($s) => $s->where('city_id', $cityId))
                ->when($ageGroupId, fn ($s) => $s->whereJsonContains('age_groups', (int) $ageGroupId))
                ->with('city')->limit($limit)->get(),
            'coaches' => CoachProfile::where('listing_status', 'published')
                ->when($textMatch(['full_name', 'bio']), fn ($query, $cond) => $query->where($cond))
                ->when($sportId, fn ($s) => $s->where('sport_id', $sportId))
                ->when($cityId, fn ($s) => $s->where('city_id', $cityId))
                ->with(['sport', 'city'])->limit($limit)->get(),
            'trials' => Trial::published()
                ->when($textMatch(['name', 'organization_name']), fn ($query, $cond) => $query->where($cond))
                ->when($sportId, fn ($s) => $s->where('sport_id', $sportId))
                ->when($cityId, fn ($s) => $s->where('city_id', $cityId))
                ->when($dateFrom, fn ($s) => $s->whereDate('event_datetime', '>=', $dateFrom))
                ->when($dateTo, fn ($s) => $s->whereDate('event_datetime', '<=', $dateTo))
                ->with(['sport', 'city'])->limit($limit)->get(),
            'tournaments' => Tournament::published()
                ->when($textMatch(['name']), fn ($query, $cond) => $query->where($cond))
                ->when($sportId, fn ($s) => $s->where('sport_id', $sportId))
                ->when($cityId, fn ($s) => $s->where('city_id', $cityId))
                ->when($gender, fn ($s) => $s->where('gender', $gender))
                ->when($dateFrom, fn ($s) => $s->whereDate('start_date', '>=', $dateFrom))
                ->when($dateTo, fn ($s) => $s->whereDate('start_date', '<=', $dateTo))
                ->with(['sport', 'city'])->limit($limit)->get(),
            'scholarships' => Scholarship::published()
                ->when($textMatch(['name', 'organization_name']), fn ($query, $cond) => $query->where($cond))
                ->when($sportId, fn ($s) => $s->where('sport_id', $sportId))
                ->when($dateTo, fn ($s) => $s->whereDate('deadline', '<=', $dateTo))
                ->with('sport')->limit($limit)->get(),
            'sponsorships' => Sponsorship::published()
                ->when($textMatch(['title', 'organization_name']), fn ($query, $cond) => $query->where($cond))
                ->when($sportId, fn ($s) => $s->where('sport_id', $sportId))
                ->when($dateTo, fn ($s) => $s->whereDate('deadline', '<=', $dateTo))
                ->with('sport')->limit($limit)->get(),
            'sports_venues' => SportsVenue::published()
                ->when($textMatch(['name', 'address']), fn ($query, $cond) => $query->where($cond))
                ->when($sportId, fn ($s) => $s->where('sport_id', $sportId))
                ->when($cityId, fn ($s) => $s->where('city_id', $cityId))
                ->with(['sport', 'city'])->limit($limit)->get(),
            'athletes' => $this->athletesGroup($request, $q, $sportId, $cityId, $ageGroupId, $limit),
        ];

        return response()->json([
            'data' => $data,
            'meta' => ['query' => $q],
        ]);
    }

    public function recentSearches(Request $request)
    {
        $searches = RecentSearch::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->pluck('query');

        return response()->json([
            'data' => $searches
        ]);
    }

    /**
     * POST /me/recent-searches — explicitly persist a query (the GET /search
     * auto-save covers typed queries; this covers filter-only exploration).
     */
    public function storeRecentSearch(Request $request)
    {
        $validated = $request->validate(['query' => 'required|string|max:120']);

        RecentSearch::updateOrCreate(
            ['user_id' => $request->user()->id, 'query' => $validated['query']],
            ['created_at' => now()]
        );

        return response()->json(['data' => ['query' => $validated['query']]], 201);
    }

    /**
     * Athletes group (Phase 3): authenticated callers only, privacy-gated and
     * minor-masked like athlete discovery.
     *
     * @return \Illuminate\Support\Collection
     */
    protected function athletesGroup(Request $request, string $q, $sportId, $cityId, $ageGroupId, int $limit)
    {
        $viewer = $request->user();

        if (! $viewer) {
            return collect();
        }

        $query = AthleteProfile::with(['sports', 'city', 'ageGroup', 'photo'])
            ->withCount('achievements')
            ->whereHas('sports');

        $ownAthleteId = $viewer->athleteProfile?->id;
        if ($ownAthleteId) {
            $query->where('id', '!=', $ownAthleteId);
        }

        if ($q !== '') {
            $query->where(function ($w) use ($q) {
                $w->where('full_name', 'like', "%{$q}%")
                    ->orWhereHas('user', fn ($u) => $u->where('name', 'like', "%{$q}%"));
            });
        }

        $query->when($sportId, fn ($s) => $s->whereHas('sports', fn ($sp) => $sp->whereIn('sports.id', (array) $sportId)))
            ->when($cityId, fn ($s) => $s->where('city_id', $cityId))
            ->when($ageGroupId, fn ($s) => $s->where('age_group_id', $ageGroupId));

        $athletes = $query->limit($limit + 20)->get();

        $delegate = new AthleteDiscoveryController();

        return $athletes
            ->filter(fn ($a) => $delegate->isVisibleTo($a, $viewer))
            ->take($limit)
            ->each(fn ($a) => $delegate->maskMinor($a, $viewer))
            ->values();
    }
}
