<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use App\Models\Observation;
use Illuminate\Http\Request;

class ObservationController extends Controller
{
    /** GET /observations?athlete_profile_id= — own scout's notes. */
    public function index(Request $request)
    {
        $scoutProfile = $request->user()->talentScoutProfile;
        abort_if(!$scoutProfile, 403, 'Scout profile required.');

        $q = Observation::where('talent_scout_profile_id', $scoutProfile->id)
            ->with(['athlete.user'])
            ->latest();
        if ($request->query('athlete_profile_id')) {
            $q->where('athlete_profile_id', $request->query('athlete_profile_id'));
        }

        return response()->json($q->paginate(20));
    }

    /** POST /observations {athlete_profile_id, rating 1-5, note, media_id} */
    public function store(Request $request)
    {
        $scoutProfile = $request->user()->talentScoutProfile;
        abort_if(!$scoutProfile, 403, 'Scout profile required.');

        $validated = $request->validate([
            'athlete_profile_id' => 'required|integer|exists:athlete_profiles,id',
            'rating' => 'nullable|integer|min:1|max:5',
            'note' => 'nullable|string|max:2000',
            'media_id' => 'nullable|integer|exists:media_items,id',
        ]);
        abort_if(empty($validated['rating']) && empty($validated['note']), 422, 'Rating or note required.');

        $obs = Observation::create([
            'talent_scout_profile_id' => $scoutProfile->id,
            ...$validated,
        ]);

        return response()->json(['data' => $obs->load('athlete.user')], 201);
    }
}
