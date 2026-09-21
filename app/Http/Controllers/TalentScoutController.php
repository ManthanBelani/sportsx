<?php

namespace App\Http\Controllers;

use App\Models\TalentScoutProfile;
use Illuminate\Http\Request;

class TalentScoutController extends Controller
{
    /**
     * Athlete-facing directory of scouts (two-way discovery).
     * GET /scouts [role:athlete]
     */
    public function index(Request $request)
    {
        $query = TalentScoutProfile::with(['user', 'city', 'photo'])
            ->whereHas('user', fn ($q) => $q->where('status', 'active'));

        $search = $request->input('q') ?? $request->input('search');
        $cityId = $request->input('city_id');
        $sportId = $request->input('sport_id');

        $query->when($search, fn ($q) => $q->where(function ($w) use ($search) {
            $w->where('organization', 'like', "%{$search}%")
                ->orWhere('affiliation', 'like', "%{$search}%")
                ->orWhereHas('user', fn ($u) => $u->where('name', 'like', "%{$search}%"));
        }))
        ->when($cityId, fn ($q) => $q->where('city_id', $cityId))
        ->when($sportId, fn ($q) => $q->whereJsonContains('sports_specialization', (int) $sportId));

        // Append connection status for the authenticated athlete, if any.
        $athleteProfileId = $request->user()?->athleteProfile?->id;

        $paginator = $query->latest()->paginate(min((int) ($request->input('per_page') ?? 20), 50));

        if ($athleteProfileId) {
            $scoutIds = $paginator->getCollection()->pluck('id');
            $connections = \App\Models\ScoutConnection::where('athlete_profile_id', $athleteProfileId)
                ->whereIn('talent_scout_profile_id', $scoutIds)
                ->get()
                ->keyBy('talent_scout_profile_id');
            $paginator->getCollection()->transform(function ($scout) use ($connections) {
                $conn = $connections->get($scout->id);
                $scout->setAttribute('connection_status', $conn?->status);
                $scout->setAttribute('connection_id', $conn?->id);
                return $scout;
            });
        }

        return response()->json($paginator);
    }

    public function show(Request $request)
    {
        $profile = $request->user()->talentScoutProfile()->with(['city', 'photo'])->first();

        if (!$profile) {
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Scout profile not found.']], 404);
        }

        SocialLinksController::attach($profile, $request->user());

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

        return response()->json(['data' => $profile->load(['city', 'photo'])]);
    }
}
