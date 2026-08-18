<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Arr;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();
        $profile = match ($user->role) {
            'athlete' => $user->athleteProfile?->load(['sports', 'ageGroup', 'city', 'photo', 'achievements', 'mediaItems']),
            'coach' => $user->coachProfile?->load(['sport', 'city', 'photo', 'academy']),
            'academy' => $user->academies?->load(['city', 'sports.sport', 'logo', 'cover']),
            'organizer' => $user->organizerProfile,
            'sponsor' => $user->sponsorProfile?->load('logo'),
            default => null,
        };

        return response()->json(['data' => $profile]);
    }

    public function update(Request $request)
    {
        $user = $request->user();

        if ($user->role === 'athlete') {
            $validated = $request->validate([
                'full_name' => 'required|string|max:100',
                'date_of_birth' => 'required|date|before:today',
                'gender' => 'required|in:male,female,other,prefer_not_to_say',
                'skill_level' => 'required|in:beginner,intermediate,advanced,competitive',
                'city_id' => 'required|exists:cities,id',
                'phone' => 'nullable|string|max:20',
                'academy_id' => 'nullable|exists:academies,id',
                'coach_id' => 'nullable|exists:coach_profiles,id',
                'position' => 'nullable|string|max:100',
                'experience' => 'nullable|string',
                'achievements' => 'nullable|array',
                'photo_media_id' => 'nullable|integer|exists:media_items,id',
            ]);

            $profile = $user->athleteProfile;
            $profile->update(Arr::except($validated, ['achievements']));
            $user->update(['name' => $validated['full_name']]);

            if (isset($validated['achievements'])) {
                $profile->achievements()->delete();
                foreach ($validated['achievements'] as $i => $achievement) {
                    $profile->achievements()->create(['text' => $achievement['text'] ?? $achievement, 'sort_order' => $i]);
                }
            }

            return response()->json(['data' => $profile->fresh(['sports', 'achievements', 'photo'])]);
        }

        return response()->json(['data' => null, 'message' => 'Not implemented for this role'], 501);
    }

    public function updateSports(Request $request)
    {
        $validated = $request->validate(['sports' => 'required|array|min:1', 'sports.*' => 'exists:sports,id']);

        $request->user()->athleteProfile->sports()->sync($validated['sports']);

        return response()->json(['data' => $request->user()->athleteProfile->fresh('sports')]);
    }
}
