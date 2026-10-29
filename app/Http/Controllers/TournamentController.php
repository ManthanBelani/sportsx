<?php

namespace App\Http\Controllers;

use App\Models\Tournament;
use Illuminate\Http\Request;

class TournamentController extends Controller
{
    public function index(Request $request)
    {
        $query = Tournament::published()->with(['sport', 'city', 'organizer', 'bannerMedia', 'categories.ageGroup'])->withRegistrationCounts();

        $query->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->city_id, fn ($q) => $q->where('city_id', $request->city_id))
            ->when($request->q, fn ($q) => $q->where('name', 'like', "%{$request->q}%"))
            ->when($request->age_group_id, fn ($q) => $q->whereHas('categories', fn ($c) => $c->where('age_group_id', $request->age_group_id)))
            ->when($request->level && \Illuminate\Support\Facades\Schema::hasColumn('tournaments', 'level'),
                fn ($q) => $q->where('level', $request->level))
            ->when($request->month, function ($q) use ($request) {
                $m = $request->month;
                $q->where(function ($w) use ($m) {
                    $w->whereYear('start_date', substr($m, 0, 4))->whereMonth('start_date', substr($m, 5, 2));
                });
            })
            ->orderBy('start_date', 'asc');

        $perPage = min((int) ($request->per_page ?? 20), 50);

        $paginator = $query->paginate($perPage);

        return response()->json(
            $paginator->through(fn ($t) => array_merge($t->toArray(), $t->registrationStats(), ['banner_url' => $t->bannerUrl()]))
                ->withQueryString()
        );
    }

    public function show(Request $request, string $id)
    {
        $tournament = Tournament::with(['sport', 'city', 'organizer', 'bannerMedia', 'categories.ageGroup', 'results'])
            ->withRegistrationCounts()
            ->findOrFail($id);

        $isOwn = false;
        // This route is public, so the default guard is "web" and a Bearer
        // token would be ignored. Resolve the SANCTUM user explicitly so
        // organizers can still view their own draft tournaments and so the
        // registration_status block works for authenticated athletes.
        $viewer = auth('sanctum')->user();
        if ($viewer) {
            if ($viewer->isAdmin()) {
                $isOwn = true;
            } elseif ($viewer->organizerProfile) {
                $isOwn = (int) $tournament->organizer_id === (int) $viewer->organizerProfile->id;
            }
            $isOwn = $isOwn || (int) $tournament->organizer_id === (int) $viewer->id;
        }
        abort_unless($tournament->status === 'published' || $isOwn, 404);

        $data = $tournament->toArray();
        $data = array_merge($data, $tournament->registrationStats());
        $data['banner_url'] = $tournament->bannerUrl();
        $data['registration_status'] = $this->registrationStatus($tournament, $viewer);

        return response()->json(['data' => $data]);
    }

    /**
     * Per-category seats + the viewer's own registration state (Phase 3).
     *
     * @return array{registered: bool, approval_status: ?string, categories: array}
     */
    protected function registrationStatus(\App\Models\Tournament $tournament, $viewer): array
    {
        $status = ['registered' => false, 'approval_status' => null, 'categories' => []];

        foreach ($tournament->categories as $category) {
            $taken = $category->registrations()->where('approval_status', 'approved')->count();
            $status['categories'][] = [
                'id' => $category->id,
                'name' => $category->name,
                'capacity' => $category->capacity,
                'seats_taken' => $taken,
                'seats_left' => $category->capacity !== null ? max(0, $category->capacity - $taken) : null,
            ];
        }

        $athleteId = $viewer?->athleteProfile?->id;
        if ($athleteId) {
            $mine = $tournament->registrations()->where('athlete_id', $athleteId)->latest('id')->first();
            if ($mine) {
                $status['registered'] = true;
                $status['approval_status'] = $mine->approval_status;
            }
        }

        return $status;
    }
}
