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

    public function show(string $id)
    {
        $tournament = Tournament::published()->with(['sport', 'city', 'organizer', 'categories.ageGroup', 'results'])->findOrFail($id);

        return response()->json(['data' => $tournament]);
    }
}
