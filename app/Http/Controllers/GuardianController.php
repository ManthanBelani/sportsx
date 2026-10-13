<?php

namespace App\Http\Controllers;

use App\Exceptions\OtpDeliveryException;
use App\Models\GuardianConsent;
use App\Models\User;
use App\Services\GuardianConsentService;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Guardian consent for athletes under 18.
 *
 * @see \App\Services\GuardianConsentService
 * @see docs/API-Specification.md §1
 */
class GuardianController extends Controller
{
    public function __construct(
        protected GuardianConsentService $guardians,
        protected OtpService $otp,
    ) {}

    /**
     * POST /guardian/consent
     *
     * Records the guardian's details and sends a confirmation code to the
     * guardian's phone. Requires the athlete's own session — a guardian
     * cannot enrol someone else's child.
     */
    public function request(Request $request): JsonResponse
    {
        $user = $request->user();

        abort_if($user->role !== 'athlete', 403, 'Only athlete accounts require guardian consent.');

        $validated = $request->validate([
            'guardian_name' => 'required|string|max:120',
            'guardian_phone' => 'required|string|max:20',
            'relationship' => ['required', Rule::in(GuardianConsent::RELATIONSHIPS)],
        ]);

        try {
            $consent = $this->guardians->request($user, $validated, $this->otp);
        } catch (OtpDeliveryException $e) {
            return response()->json([
                'error' => [
                    'code' => 'CHANNEL_UNAVAILABLE',
                    'message' => $e->getMessage(),
                ],
            ], 503);
        }

        return response()->json([
            'data' => [
                'consent_status' => $consent->consent_status,
                'guardian_name' => $consent->guardian_name,
                'relationship' => $consent->relationship,
                'message' => 'A confirmation code has been sent to the guardian.',
            ],
        ], 201);
    }

    /**
     * POST /guardian/verify-otp
     */
    public function verify(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string|max:10',
        ]);

        $consent = $this->guardians->verify($request->user(), $validated['code'], $this->otp);

        return response()->json([
            'data' => [
                'consent_status' => $consent->consent_status,
                'verified_at' => $consent->verified_at?->toIso8601String(),
                'message' => 'Guardian consent verified.',
            ],
        ]);
    }

    /**
     * GET /me/guardian-controls
     *
     * Consent status plus the guardian-controlled settings. Readable by the
     * athlete so the UI can explain why something is restricted.
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $consent = $this->guardians->activeFor($user);
        $dob = $user->athleteProfile?->date_of_birth;

        return response()->json([
            'data' => [
                'is_minor' => $this->guardians->isMinor($dob),
                'consent_status' => $consent?->consent_status ?? null,
                'guardian_name' => $consent?->guardian_name,
                'relationship' => $consent?->relationship,
                'verified_at' => $consent?->verified_at?->toIso8601String(),
                'allow_messages' => $this->guardians->allowsMessages($user),
                'allow_public_profile' => $this->guardians->allowsPublicProfile($user),
                'leaderboard_name_mode' => $this->guardians->leaderboardNameMode($user),
            ],
        ]);
    }

    /**
     * PUT /me/guardian-controls
     *
     * Only the guardian-facing switches are mutable here. Consent status itself
     * changes through verify/revoke, never through this endpoint.
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $consent = $this->guardians->activeFor($user);

        if (! $consent) {
            return response()->json([
                'error' => [
                    'code' => 'NO_VERIFIED_CONSENT',
                    'message' => 'Guardian consent has not been verified yet.',
                ],
            ], 422);
        }

        $validated = $request->validate([
            'allow_messages' => 'sometimes|boolean',
            'allow_public_profile' => 'sometimes|boolean',
            'leaderboard_name_mode' => 'sometimes|in:first_name_initial,hidden',
        ]);

        $consent->update($validated);

        return response()->json(['data' => $consent->refresh()]);
    }

    /**
     * DELETE /me/guardian-consent
     *
     * Revocation immediately re-hides the profile.
     */
    public function revoke(Request $request): JsonResponse
    {
        $this->guardians->revoke($request->user());

        return response()->json([
            'data' => ['message' => 'Guardian consent revoked.'],
        ]);
    }
}