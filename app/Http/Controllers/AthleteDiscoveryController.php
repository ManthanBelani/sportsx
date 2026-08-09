<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use Illuminate\Http\Request;

class AthleteDiscoveryController extends Controller
{
    public function index(Request $request)
    {
        $query = AthleteProfile::with(['sports', 'city', 'ageGroup', 'photo'])
            ->whereHas('sports');

        $query->when($request->sport_id, fn ($q) => $q->whereHas('sports', fn ($s) => $s->where('sport_id', $request->sport_id)))
            ->when($request->age_group_id, fn ($q) => $q->where('age_group_id', $request->age_group_id))
            ->when($request->city_id, fn ($q) => $q->where('city_id', $request->city_id))
            ->when($request->skill_level, fn ($q) => $q->where('skill_level', $request->skill_level))
            ->when($request->q, fn ($q) => $q->where('full_name', 'like', "%{$request->q}%"));

        return response()->json($query->paginate(min((int) ($request->per_page ?? 20), 50)));
    }

    public function show(string $id)
    {
        $athlete = AthleteProfile::with(['sports', 'city', 'ageGroup', 'photo', 'academy', 'coach'])->findOrFail($id);

        return response()->json(['data' => $athlete]);
    }
}
