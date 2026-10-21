<?php

namespace App\Http\Controllers;

use App\Models\OrganizerTeamMember;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * OR.16 — the organizer's own team (co-organizers, volunteers, staff).
 */
class OrganizerTeamController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $organizer = $this->organizer($request);

        return response()->json([
            'data' => OrganizerTeamMember::where('organizer_id', $organizer->id)
                ->orderBy('status')
                ->orderBy('name')
                ->get(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $organizer = $this->organizer($request);

        $validated = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email|max:150',
            'role' => 'nullable|in:'.implode(',', OrganizerTeamMember::ROLES),
        ]);

        $email = strtolower(trim($validated['email']));

        $existing = OrganizerTeamMember::where('organizer_id', $organizer->id)
            ->where('email', $email)
            ->first();
        if ($existing) {
            return response()->json([
                'error' => ['code' => 'ALREADY_EXISTS', 'message' => 'This person is already on your team.'],
            ], 422);
        }

        $user = User::where('email', $email)->first();

        $member = OrganizerTeamMember::create([
            'organizer_id' => $organizer->id,
            'user_id' => $user?->id,
            'name' => $validated['name'],
            'email' => $email,
            'role' => $validated['role'] ?? 'volunteer',
            'status' => $user ? 'active' : 'pending',
            'invited_at' => now(),
            'joined_at' => $user ? now() : null,
        ]);

        return response()->json(['data' => $member], 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $organizer = $this->organizer($request);

        $validated = $request->validate([
            'role' => 'sometimes|in:'.implode(',', OrganizerTeamMember::ROLES),
            'status' => 'sometimes|in:pending,active',
        ]);

        $member = OrganizerTeamMember::where('organizer_id', $organizer->id)->findOrFail($id);
        $member->update($validated);

        return response()->json(['data' => $member->fresh()]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $organizer = $this->organizer($request);

        $member = OrganizerTeamMember::where('organizer_id', $organizer->id)->findOrFail($id);
        $member->delete();

        return response()->json(['data' => ['message' => 'Member removed.']]);
    }

    private function organizer(Request $request)
    {
        $organizer = $request->user()->organizerProfile;
        abort_unless($organizer, 403, 'Organizer profile required.');

        return $organizer;
    }
}
