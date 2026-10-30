<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Models\User;

/**
 * Profile privacy (Phase 2).
 *
 * Stored on `users.privacy_settings` (JSON) so no profile-table migration is
 * needed per role. Enforcement happens at read time: directories, search and
 * athlete discovery consult these settings (see AthleteDiscoveryController).
 *
 * @see docs/PHASE_WISE_IMPLEMENTATION_PLAN.md Phase 2
 */
class PrivacyController extends Controller
{
    /**
     * Get default privacy settings for a user.
     * Minors default to more restrictive settings.
     */
    public function defaultsFor(User $user): array
    {
        $isMinor = $user->isMinor();
        return [
            'profile_visibility' => $isMinor ? 'followers' : 'public',
            'who_can_message' => $isMinor ? 'connections' : 'everyone',
            'who_can_connect' => $isMinor ? 'nobody' : 'everyone',
        ];
    }

    /**
     * GET /me/privacy
     */
    public function show(Request $request): JsonResponse
    {
        return response()->json(['data' => $this->settings($request->user())]);
    }

    /**
     * PUT /me/privacy
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $isMinor = $user->isMinor();

        // Minors cannot override certain settings to less restrictive values
        $rules = [
            'profile_visibility' => 'sometimes|in:public,followers,private',
            'who_can_message' => 'sometimes|in:everyone,connections,nobody',
            'who_can_connect' => 'sometimes|in:everyone,nobody',
        ];

        // For minors, restrict the allowed values
        if ($isMinor) {
            // Minors can only choose between connections and nobody for messaging
            $rules['who_can_message'] = 'sometimes|in:connections,nobody';
            // Minors can only choose between followers and private for profile visibility
            $rules['profile_visibility'] = 'sometimes|in:followers,private';
            // Minors cannot set who_can_connect to everyone
            $rules['who_can_connect'] = 'sometimes|in:nobody';
        }

        $validated = $request->validate($rules);

        if (! \Illuminate\Support\Facades\Schema::hasColumn('users', 'privacy_settings')) {
            return response()->json([
                'error' => [
                    'code' => 'PENDING_MIGRATION',
                    'message' => 'Privacy settings need a pending database migration. Your settings were not saved.',
                ],
            ], 503);
        }

        $user->forceFill([
            'privacy_settings' => array_merge($this->settings($user), $validated),
        ])->save();

        return response()->json(['data' => $this->settings($user->fresh())]);
    }

    /**
     * @return array{profile_visibility: string, who_can_message: string, who_can_connect: string}
     */
    public function settings($user): array
    {
        $stored = $user->privacy_settings;

        if (is_string($stored)) {
            $stored = json_decode($stored, true);
        }

        $defaults = $this->defaultsFor($user);

        return array_merge($defaults, is_array($stored) ? $stored : []);
    }
}
