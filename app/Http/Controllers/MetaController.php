<?php

namespace App\Http\Controllers;

use App\Models\AgeGroup;
use App\Models\City;
use App\Models\Sport;

class MetaController extends Controller
{
    public function sports()
    {
        $sports = Sport::where('is_active', true)->orderBy('sort_order')->orderBy('name')->get();

        return response()->json(['data' => $sports]);
    }

    public function cities()
    {
        $cities = City::where('is_active', true)->orderBy('state')->orderBy('name')->get()
            ->groupBy('state')
            ->map(fn ($group) => $group->values());

        return response()->json(['data' => $cities]);
    }

    public function ageGroups()
    {
        $groups = AgeGroup::where('is_active', true)->orderBy('min_age')->get();

        return response()->json(['data' => $groups]);
    }

    public function trendingSearches()
    {
        // AS-11: trending search terms enhancement — derive from actual search queries in production
        return response()->json(['data' => Sport::where('is_active', true)->orderBy('sort_order')->pluck('name')]);
    }

    /**
     * GET /meta/positions — playing positions grouped by sport.
     *
     * Curated static master for Phase 3 (powers the position filter). An
     * admin-managed `positions` master ships in Phase 9; the shape
     * (`[{sport_id, sport, positions[]}]`) is kept stable for that swap.
     */
    public function positions()
    {
        return response()->json(['data' => config('sportx.masters.positions', [])]);
    }

    /**
     * GET /meta/facilities — facility/amenity vocabulary for filters.
     *
     * Same arrangement as positions: curated now, admin-managed in Phase 9.
     */
    public function facilities()
    {
        return response()->json(['data' => config('sportx.masters.facilities', [])]);
    }
}
