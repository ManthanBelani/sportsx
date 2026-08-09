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
}
