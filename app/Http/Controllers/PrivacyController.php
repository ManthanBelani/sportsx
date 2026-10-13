<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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
    public const DEFAULTS = [
        'profile_visibility' => 'public',
        'who_can_message' => 'everyone',
        'who_can_connect' => 'everyone',
    ];

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
        $validated = $request->validate([
            'profile_visibility' => 'sometimes|in:public,followers,private',
            'who_can_message' => 'sometimes|in:everyone,connections,nobody',
            'who_can_connect' => 'sometimes|in:everyone,nobody',
        ]);

        if (! \Illuminate\Support\Facades\Schema::hasColumn('users', 'privacy_settings')) {
            return response()->json([
                'error' => [
                    'code' => 'PENDING_MIGRATION',
                    'message' => 'Privacy settings need a pending database migration. Your settings were not saved.',
                ],
            ], 503);
        }

        $user = $request->user();
        $user->forceFill([
            'privacy_settings' => array_merge($this->settings($user), $validated),
        ])->save();

        return response()->json(['data' => $this->settings($user->fresh())]);
    }

    /**
     * @return array{profile_visibility: string, who_can_message: string, who_can_connect: string}
     */
    public static function settings($user): array
    {
        $stored = $user->privacy_settings;

        if (is_string($stored)) {
            $stored = json_decode($stored, true);
        }

        return array_merge(self::DEFAULTS, is_array($stored) ? $stored : []);
    }
}
