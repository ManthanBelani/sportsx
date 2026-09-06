<?php

namespace App\Http\Controllers;

use App\Models\TalentScoutProfile;
use Illuminate\Http\Request;

class TalentScoutController extends Controller
{
    public function show(Request $request)
    {
        $profile = $request->user()->talentScoutProfile()->with(['city'])->first();

        if (!$profile) {
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Scout profile not found.']], 404);
        }

        return response()->json(['data' => $profile]);
    }

    public function update(Request $request)
    {
        $user = $request->user();
        $validated = $request->validate([
            'organization' => 'nullable|string|max:150',
            'affiliation' => 'nullable|string|max:150',
            'sports_specialization' => 'sometimes|array|min:1',
            'sports_specialization.*' => 'exists:sports,id',
            'experience_years' => 'nullable|integer|min:0',
            'city_id' => 'nullable|exists:cities,id',
            'bio' => 'nullable|string|max:1000',
            'photo_media_id' => 'nullable|exists:media_items,id',
            'listing_status' => 'sometimes|boolean',
        ]);

        $profile = TalentScoutProfile::updateOrCreate(
            ['user_id' => $user->id],
            $validated
        );

        return response()->json(['data' => $profile->load('city')]);
    }
}
