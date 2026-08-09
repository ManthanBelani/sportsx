<?php

namespace App\Http\Controllers;

use App\Models\Academy;
use App\Models\AcademySport;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;

class AcademyController extends Controller
{
    public function show(Request $request)
    {
        $academy = $request->user()->academies;
        abort_if(! $academy, 404);

        return response()->json(['data' => $academy->load(['city', 'sports.sport', 'logo', 'cover'])]);
    }

    public function update(Request $request)
    {
        $academy = $request->user()->academies;
        abort_if(! $academy, 404);

        $validated = $request->validate([
            'name' => 'required|string|max:150',
            'description' => 'required|string',
            'address' => 'required|string',
            'city_id' => 'required|exists:cities,id',
            'contact_number' => 'required|string|max:20',
            'google_maps_url' => 'nullable|url',
            'facilities' => 'nullable|array',
            'fee_range' => 'nullable|string|max:60',
            'timings' => 'nullable|string|max:120',
            'age_groups' => 'nullable|array',
            'year_established' => 'nullable|integer',
            'achievements' => 'nullable|array',
            'email' => 'nullable|email',
            'website' => 'nullable|url',
            'logo_media_id' => 'nullable|exists:media_items,id',
            'cover_media_id' => 'nullable|exists:media_items,id',
            'sports' => 'nullable|array',
            'sports.*' => 'exists:sports,id',
            'listing_status' => 'in:draft,published,closed',
        ]);

        $academy->update(Arr::except($validated, ['sports']));

        if (isset($validated['sports'])) {
            AcademySport::where('academy_id', $academy->id)->delete();
            foreach ($validated['sports'] as $sportId) {
                AcademySport::create(['academy_id' => $academy->id, 'sport_id' => $sportId]);
            }
        }

        return response()->json(['data' => $academy->fresh(['city', 'sports.sport', 'logo', 'cover'])]);
    }
}
