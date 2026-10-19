<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class OrganizerProfileController extends Controller
{
    public function show(Request $request)
    {
        $profile = $request->user()->organizerProfile;
        abort_if(! $profile, 404, 'Organizer profile not found');
        SocialLinksController::attach($profile, $request->user());

        return response()->json(['data' => $profile]);
    }

    public function update(Request $request)
    {
        $profile = $request->user()->organizerProfile;
        abort_if(! $profile, 404, 'Organizer profile not found');

        $validated = $request->validate([
            'organization_name' => 'sometimes|required|string|max:150',
            'org_type' => 'sometimes|required|in:event_company,individual,club,college,federation,ngo,other',
            'registration_number' => 'nullable|string|max:100',
            'website' => 'nullable|url|max:255',
            'verification_doc_media_id' => 'nullable|integer|exists:media_items,id',
            'logo_media_id' => 'nullable|integer|exists:media_items,id',
            'cover_media_id' => 'nullable|integer|exists:media_items,id',
            'city_id' => 'nullable|exists:cities,id',
            'description' => 'nullable|string|max:2000',
            // Spec §5 #5: Tournament, Trial, Championship, Camp, League, Workshop,
            // Sports Meet, Marathon, Other.
            'event_types' => 'nullable|array|max:20',
            'event_types.*' => 'string|max:50',
            'sports' => 'nullable|array',
            'sports.*' => 'exists:sports,id',
        ]);

        $fillable = $profile->getFillable();
        $persist = array_intersect_key($validated, array_flip($fillable));

        // Sync sports when supplied (spec §5 #4).
        if (isset($validated['sports']) && is_array($validated['sports'])) {
            $profile->sports()->sync($validated['sports']);
        }

        $profile->update($persist);

        return response()->json([
            'data' => $profile->fresh(['city', 'logo', 'cover', 'sports']),
        ]);
    }

    /**
     * GET /organizers/{id} — public listing card (no contact internals).
     */
    public function publicShow(string $id)
    {
        $profile = \App\Models\OrganizerProfile::findOrFail($id);

        $data = $profile->toArray();
        $data['is_verified'] = ($profile->verification_status ?? null) === 'verified'
            || \App\Models\VerificationRequest::where('requester_user_id', $profile->user_id)
                ->where('status', \App\Models\VerificationRequest::STATUS_APPROVED)
                ->exists();

        return response()->json(['data' => $data]);
    }
}
