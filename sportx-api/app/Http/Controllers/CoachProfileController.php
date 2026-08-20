<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class CoachProfileController extends Controller
{
    public function show(Request $request)
    {
        return response()->json(['data' => $request->user()->coachProfile?->load(['sport', 'city', 'photo', 'academy'])]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'full_name' => 'required|string|max:100',
            'sport_id' => 'required|exists:sports,id',
            'city_id' => 'required|exists:cities,id',
            'contact_number' => 'required|string|max:20',
            'experience' => 'required|string',
            'qualification' => 'nullable|string',
            'certifications' => 'nullable|array',
            'academy_id' => 'nullable|exists:academies,id',
            'languages' => 'nullable|array',
            'email' => 'nullable|email',
            'personal_coaching' => 'boolean',
            'fee_structure' => 'nullable|string|max:120',
            'bio' => 'nullable|string',
            'photo_media_id' => 'nullable|exists:media_items,id',
        ]);

        $profile = $request->user()->coachProfile;
        $profile->update($validated);

        return response()->json(['data' => $profile->fresh()]);
    }
}
