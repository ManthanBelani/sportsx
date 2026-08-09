<?php

namespace App\Http\Controllers;

use App\Models\Academy;
use App\Models\AcademySport;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\OrganizerProfile;
use App\Models\SponsorProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;

class OnboardingController extends Controller
{
    public function athlete(Request $request)
    {
        $user = $request->user();
        abort_if($user->role !== 'athlete', 403, 'Only athletes can complete athlete onboarding');

        $validated = $request->validate([
            'full_name' => 'required|string|max:100',
            'date_of_birth' => 'required|date|before:today',
            'gender' => 'required|in:male,female,other,prefer_not_to_say',
            'sports' => 'required|array|min:1',
            'sports.*' => 'exists:sports,id',
            'age_group_id' => 'required|exists:age_groups,id',
            'skill_level' => 'required|in:beginner,intermediate,advanced,competitive',
            'city_id' => 'required|exists:cities,id',
            'phone' => 'nullable|string|max:20',
            'photo_media_id' => 'nullable|exists:media_items,id',
        ]);

        $profile = AthleteProfile::updateOrCreate(
            ['user_id' => $user->id],
            Arr::except($validated, ['sports'])
        );

        $profile->sports()->sync($validated['sports']);

        $user->update(['name' => $validated['full_name']]);

        return response()->json([
            'data' => $profile->load(['sports', 'ageGroup', 'city', 'photo']),
            'message' => 'Athlete profile created',
        ], 201);
    }

    public function coach(Request $request)
    {
        $user = $request->user();
        abort_if($user->role !== 'coach', 403);

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
            'personal_coaching' => 'nullable|boolean',
            'fee_structure' => 'nullable|string|max:120',
            'bio' => 'nullable|string',
            'photo_media_id' => 'nullable|exists:media_items,id',
        ]);

        CoachProfile::updateOrCreate(['user_id' => $user->id], $validated);
        $user->update(['name' => $validated['full_name']]);

        return response()->json(['data' => CoachProfile::where('user_id', $user->id)->with(['sport', 'city'])->first()], 201);
    }

    public function academy(Request $request)
    {
        $user = $request->user();
        abort_if($user->role !== 'academy', 403);

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
            'year_established' => 'nullable|integer|min:1800|max:'.date('Y'),
            'achievements' => 'nullable|array',
            'email' => 'nullable|email',
            'website' => 'nullable|url',
            'logo_media_id' => 'nullable|exists:media_items,id',
            'cover_media_id' => 'nullable|exists:media_items,id',
            'sports' => 'required|array|min:1',
            'sports.*' => 'exists:sports,id',
        ]);

        $academy = Academy::updateOrCreate(
            ['owner_user_id' => $user->id],
            Arr::except($validated, ['sports'])
        );

        AcademySport::where('academy_id', $academy->id)->delete();
        foreach ($validated['sports'] as $sportId) {
            AcademySport::create(['academy_id' => $academy->id, 'sport_id' => $sportId]);
        }

        return response()->json(['data' => $academy->load(['city', 'sports.sport'])], 201);
    }

    public function organizer(Request $request)
    {
        $user = $request->user();
        abort_if($user->role !== 'organizer', 403);

        $validated = $request->validate([
            'organization_name' => 'required|string|max:150',
            'org_type' => 'required|in:federation,club,other',
        ]);

        $profile = OrganizerProfile::updateOrCreate(
            ['user_id' => $user->id],
            $validated
        );

        return response()->json(['data' => $profile], 201);
    }

    public function sponsor(Request $request)
    {
        $user = $request->user();
        abort_if($user->role !== 'sponsor', 403);

        $validated = $request->validate([
            'brand_name' => 'required|string|max:150',
            'category' => 'nullable|string|max:80',
            'logo_media_id' => 'nullable|exists:media_items,id',
        ]);

        $profile = SponsorProfile::updateOrCreate(
            ['user_id' => $user->id],
            $validated
        );

        return response()->json(['data' => $profile], 201);
    }

    public function schema(Request $request, string $role)
    {
        $schemas = [
            'athlete' => [
                'fields' => [
                    ['name' => 'full_name', 'type' => 'text', 'required' => true, 'label' => 'Full Name'],
                    ['name' => 'date_of_birth', 'type' => 'date', 'required' => true, 'label' => 'Date of Birth'],
                    ['name' => 'gender', 'type' => 'select', 'required' => true, 'label' => 'Gender', 'options' => ['male' => 'Male', 'female' => 'Female', 'other' => 'Other', 'prefer_not_to_say' => 'Prefer not to say']],
                    ['name' => 'sports', 'type' => 'multi-select', 'required' => true, 'label' => 'Sports'],
                    ['name' => 'age_group_id', 'type' => 'select', 'required' => true, 'label' => 'Age Group'],
                    ['name' => 'skill_level', 'type' => 'select', 'required' => true, 'label' => 'Skill Level', 'options' => ['beginner' => 'Beginner', 'intermediate' => 'Intermediate', 'advanced' => 'Advanced', 'competitive' => 'Competitive']],
                    ['name' => 'city_id', 'type' => 'select', 'required' => true, 'label' => 'City'],
                    ['name' => 'phone', 'type' => 'text', 'required' => false, 'label' => 'Phone Number'],
                    ['name' => 'photo_media_id', 'type' => 'file', 'required' => false, 'label' => 'Profile Photo'],
                ],
                'step' => 2,
            ],
            'coach' => [
                'fields' => [
                    ['name' => 'full_name', 'type' => 'text', 'required' => true, 'label' => 'Full Name'],
                    ['name' => 'sport_id', 'type' => 'select', 'required' => true, 'label' => 'Primary Sport'],
                    ['name' => 'city_id', 'type' => 'select', 'required' => true, 'label' => 'City'],
                    ['name' => 'contact_number', 'type' => 'text', 'required' => true, 'label' => 'Contact Number'],
                    ['name' => 'experience', 'type' => 'text', 'required' => true, 'label' => 'Years of Experience'],
                    ['name' => 'qualification', 'type' => 'text', 'required' => false, 'label' => 'Qualification'],
                    ['name' => 'certifications', 'type' => 'multi-text', 'required' => false, 'label' => 'Certifications'],
                    ['name' => 'fee_structure', 'type' => 'text', 'required' => false, 'label' => 'Fee Structure'],
                    ['name' => 'bio', 'type' => 'textarea', 'required' => false, 'label' => 'Bio'],
                ],
                'step' => 1,
            ],
            'academy' => [
                'fields' => [
                    ['name' => 'name', 'type' => 'text', 'required' => true, 'label' => 'Academy Name'],
                    ['name' => 'description', 'type' => 'textarea', 'required' => true, 'label' => 'Description'],
                    ['name' => 'address', 'type' => 'text', 'required' => true, 'label' => 'Address'],
                    ['name' => 'city_id', 'type' => 'select', 'required' => true, 'label' => 'City'],
                    ['name' => 'contact_number', 'type' => 'text', 'required' => true, 'label' => 'Contact Number'],
                    ['name' => 'google_maps_url', 'type' => 'url', 'required' => false, 'label' => 'Google Maps URL'],
                    ['name' => 'sports', 'type' => 'multi-select', 'required' => true, 'label' => 'Sports Offered'],
                    ['name' => 'fee_range', 'type' => 'text', 'required' => false, 'label' => 'Fee Range'],
                    ['name' => 'timings', 'type' => 'text', 'required' => false, 'label' => 'Training Timings'],
                    ['name' => 'facilities', 'type' => 'multi-text', 'required' => false, 'label' => 'Facilities'],
                ],
                'step' => 1,
            ],
            'organizer' => [
                'fields' => [
                    ['name' => 'organization_name', 'type' => 'text', 'required' => true, 'label' => 'Organization Name'],
                    ['name' => 'org_type', 'type' => 'select', 'required' => true, 'label' => 'Organization Type', 'options' => ['federation' => 'Federation', 'club' => 'Club', 'other' => 'Other']],
                    ['name' => 'verification_doc_media_id', 'type' => 'file', 'required' => false, 'label' => 'Verification Document'],
                ],
                'step' => 1,
            ],
            'sponsor' => [
                'fields' => [
                    ['name' => 'brand_name', 'type' => 'text', 'required' => true, 'label' => 'Brand Name'],
                    ['name' => 'category', 'type' => 'text', 'required' => false, 'label' => 'Category'],
                    ['name' => 'logo_media_id', 'type' => 'file', 'required' => false, 'label' => 'Logo'],
                ],
                'step' => 1,
            ],
        ];

        if (!isset($schemas[$role])) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Onboarding schema not found for role.',
                ]
            ], 404);
        }

        return response()->json([
            'data' => $schemas[$role]
        ]);
    }
}
