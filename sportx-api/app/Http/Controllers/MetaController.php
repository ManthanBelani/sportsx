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
     * Admin-managed `positions` master (Phase 9); falls back to the curated
     * config when the table is empty. Shape ([{sport_id, sport,
     * positions[]}]) is stable for both sources.
     */
    public function positions()
    {
        try {
            $rows = \App\Models\Position::with('sport')->orderBy('name')->get();
            if ($rows->isNotEmpty()) {
                $grouped = [];
                foreach ($rows as $row) {
                    $key = $row->sport_id ?? 0;
                    $grouped[$key] ??= [
                        'sport_id' => $row->sport_id,
                        'sport' => $row->sport?->name ?? 'General',
                        'positions' => [],
                    ];
                    $grouped[$key]['positions'][] = $row->name;
                }

                return response()->json(['data' => array_values($grouped)]);
            }
        } catch (\Throwable) {
        }

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
