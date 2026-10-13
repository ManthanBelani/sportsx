<?php

namespace App\Http\Controllers;

use App\Models\Tournament;
use Illuminate\Http\Request;

class TournamentController extends Controller
{
    public function index(Request $request)
    {
        $query = Tournament::published()->with(['sport', 'city', 'organizer', 'categories.ageGroup']);

        $query->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->city_id, fn ($q) => $q->where('city_id', $request->city_id))
            ->when($request->month, fn ($q) => $q->whereYear('start_date', substr($request->month, 0, 4))->whereMonth('start_date', substr($request->month, 5)))
            ->orderBy('start_date', 'asc');

        $perPage = min((int) ($request->per_page ?? 20), 50);

        return response()->json($query->paginate($perPage)->withQueryString());
    }

    public function show(Request $request, string $id)
    {
        $tournament = Tournament::published()->with(['sport', 'city', 'organizer', 'categories.ageGroup', 'results'])->findOrFail($id);

        $data = $tournament->toArray();
        $data['registration_status'] = $this->registrationStatus($tournament, $request->user());

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
