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
            'org_type' => 'sometimes|required|in:federation,club,other,state_association,district_association,private_club,school_college',
            'registration_number' => 'nullable|string|max:100',
            'website' => 'nullable|url|max:255',
            'verification_doc_media_id' => 'nullable|integer|exists:media_items,id',
        ]);

        $typeMap = [
            'state_association' => 'federation',
            'district_association' => 'federation',
            'private_club' => 'club',
            'school_college' => 'other',
        ];
        if (isset($validated['org_type']) && isset($typeMap[$validated['org_type']])) {
            $validated['org_type'] = $typeMap[$validated['org_type']];
        }

        $fillable = $profile->getFillable();
        $persist = array_intersect_key($validated, array_flip($fillable));
        // website/registration_number may not be in fillable on older DB — ignore gracefully
        if (empty($persist) && !empty($validated)) {
            // at minimum try organization_name/org_type
            $persist = array_intersect_key($validated, array_flip(['organization_name','org_type']));
        }

        $profile->update($persist);

        return response()->json(['data' => $profile->fresh()]);
    }
}
