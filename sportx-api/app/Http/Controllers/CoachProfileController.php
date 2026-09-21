<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class CoachProfileController extends Controller
{
    public function show(Request $request)
    {
        $profile = $request->user()->coachProfile?->load(['sport', 'city', 'photo', 'academy', 'mediaItems']);
        if ($profile) {
            $profile->setAttribute('media_items', $profile->mediaItems);
            if ($profile->achievements === null) {
                $profile->setAttribute('achievements', []);
            }
            SocialLinksController::attach($profile, $request->user());
        }
        return response()->json(['data' => $profile]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'full_name' => 'sometimes|required|string|max:100',
            'sport_id' => 'sometimes|required|exists:sports,id',
            'city_id' => 'sometimes|required|exists:cities,id',
            'contact_number' => 'sometimes|required|string|max:20',
            'experience' => 'sometimes|required|string',
            'qualification' => 'nullable|string',
            'certifications' => 'nullable|array',
            'achievements' => 'nullable|array',
            'achievements.*.text' => 'nullable|string',
            'achievements.*.title' => 'nullable|string',
            'academy_id' => 'nullable|exists:academies,id',
            'languages' => 'nullable|array',
            'email' => 'nullable|email',
            'personal_coaching' => 'boolean',
            'fee_structure' => 'nullable|string|max:120',
            'bio' => 'nullable|string',
            'photo_media_id' => 'nullable|exists:media_items,id',
            'headline' => 'nullable|string|max:200',
            'location' => 'nullable|string|max:200',
            'fee_per_session' => 'nullable|numeric',
            'fee_monthly' => 'nullable|numeric',
            'fee_quarterly' => 'nullable|numeric',
            'availability' => 'nullable|array',
        ]);

        $profile = $request->user()->coachProfile;
        if (isset($validated['achievements'])) {
            $validated['achievements'] = array_map(fn ($a) => is_string($a) ? ['text' => $a] : $a, $validated['achievements']);
        }
        $profile->update($validated);
        if (isset($validated['full_name'])) {
            $request->user()->update(['name' => $validated['full_name']]);
        }

        $fresh = $profile->fresh()->load(['sport', 'city', 'photo', 'mediaItems']);
        $fresh->setAttribute('media_items', $fresh->mediaItems);
        return response()->json(['data' => $fresh]);
    }
}
