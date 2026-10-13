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
            'coach' => $user->coachProfile?->load(['sport', 'city', 'photo', 'academy', 'mediaItems']),
            'academy' => $user->academies?->load(['city', 'sports.sport', 'logo', 'cover']),
            'organizer' => $user->organizerProfile,
            'sponsor' => $user->sponsorProfile?->load('logo'),
            'talent_scout' => $user->talentScoutProfile?->load(['city', 'photo']),
            'scout' => $user->talentScoutProfile?->load(['city', 'photo']),
            default => null,
        };

        // For coach, ensure media_items and achievements are appended as attributes
        // so media_gallery_screen can read them uniformly regardless of role.
        if ($user->role === 'coach' && $profile) {
            $profile->setAttribute('media_items', $profile->mediaItems);
            // achievements already cast as array; if null, default to empty array via accessor
            if (! isset($profile->achievements) || $profile->achievements === null) {
                $profile->setAttribute('achievements', []);
            }
        }

        if ($profile) {
            SocialLinksController::attach($profile, $user);
        }

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

        if ($user->role === 'coach') {
            $validated = $request->validate([
                'full_name' => 'sometimes|required|string|max:100',
                'sport_id' => 'sometimes|required|exists:sports,id',
                'city_id' => 'sometimes|required|exists:cities,id',
                'contact_number' => 'sometimes|required|string|max:20',
                'experience' => 'sometimes|required|string',
                'achievements' => 'nullable|array',
                'achievements.*.text' => 'nullable|string',
                'achievements.*.title' => 'nullable|string',
            ]);

            $profile = $user->coachProfile;
            if (isset($validated['achievements'])) {
                // Normalize achievements to consistent shape {text, title?, description?, year?}
                $normalized = array_map(fn ($a) => is_string($a) ? ['text' => $a] : $a, $validated['achievements']);
                $profile->update(['achievements' => $normalized]);
                if (isset($validated['full_name'])) {
                    $user->update(['name' => $validated['full_name']]);
                }
            } else {
                // No achievements-only update should not overwrite other fields accidentally
                $updateData = Arr::except($validated, ['achievements']);
                if (! empty($updateData)) {
                    $profile->update($updateData);
                }
            }

            $fresh = $profile->fresh()->load(['sport', 'city', 'photo', 'mediaItems']);
            $fresh->setAttribute('media_items', $fresh->mediaItems);
            return response()->json(['data' => $fresh]);
        }

        return response()->json(['data' => null, 'message' => 'Not implemented for this role'], 501);
    }

    public function updateSports(Request $request)
    {
        $validated = $request->validate([
            'sports' => 'required|array|min:1',
            'sports.*.sport_id' => 'required_without:sports.*|integer|exists:sports,id',
        ]);

        // Accept both shapes: plain ids `[1,2]` and rich objects
        // `[{sport_id, playing_role, level, experience_years, is_primary}]`.
        $raw = $validated['sports'];
        $rich = isset($raw[0]) && is_array($raw[0]);

        if ($rich) {
            $request->validate([
                'sports.*.sport_id' => 'required|integer|exists:sports,id',
                'sports.*.playing_role' => 'nullable|string|max:100',
                'sports.*.level' => 'nullable|string|max:50',
                'sports.*.experience_years' => 'nullable|integer|min:0|max:80',
                'sports.*.is_primary' => 'nullable|boolean',
            ]);
        }

        $profile = $request->user()->athleteProfile;
        abort_unless($profile, 422, 'Complete your athlete profile first.');

        $extended = \Illuminate\Support\Facades\Schema::hasColumn('athlete_sports', 'playing_role');

        if ($rich && $extended) {
            $sync = [];
            foreach ($raw as $entry) {
                $sync[(int) $entry['sport_id']] = [
                    'playing_role' => $entry['playing_role'] ?? null,
                    'level' => $entry['level'] ?? null,
                    'experience_years' => $entry['experience_years'] ?? null,
                    'is_primary' => (bool) ($entry['is_primary'] ?? false),
                ];
            }
            $profile->sports()->sync($sync);
        } else {
            $ids = $rich ? array_map(fn ($e) => (int) $e['sport_id'], $raw) : $raw;
            $profile->sports()->sync($ids);
        }

        return response()->json(['data' => $profile->fresh('sports')]);
    }
}
