<?php

namespace App\Http\Controllers;

use App\Exceptions\OtpDeliveryException;
use App\Models\GuardianConsent;
use App\Models\OtpCode;
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
     * guardian's email. Requires the athlete's own session — a guardian
     * cannot enrol someone else's child.
     */
    public function request(Request $request): JsonResponse
    {
        $user = $request->user();

        abort_if($user->role !== 'athlete', 403, 'Only athlete accounts require guardian consent.');

        $validated = $request->validate([
            'guardian_name' => 'required|string|max:120',
            'guardian_email' => 'required|email|max:255',
            'guardian_phone' => 'nullable|string|max:20',
            'relationship' => ['required', Rule::in(GuardianConsent::RELATIONSHIPS)],
        ]);

        // The minor must not be able to consent to themselves — the guardian
        // email has to belong to someone else.
        if (strcasecmp($validated['guardian_email'], (string) $user->email) === 0) {
            return response()->json([
                'error' => [
                    'code' => 'GUARDIAN_EMAIL_INVALID',
                    'message' => 'The guardian email must belong to a parent or guardian, not the athlete.',
                ],
            ], 422);
        }

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
                'guardian_email' => $consent->guardian_email,
                'relationship' => $consent->relationship,
                'message' => 'A confirmation code has been emailed to the guardian.',
            ],
        ], 201);
    }

    /**
     * POST /guardian/resend
     *
     * Re-issues the confirmation email for a still-pending consent. The
     * OtpService resend cooldown enforces the rate limit.
     */
    public function resend(Request $request): JsonResponse
    {
        $user = $request->user();

        abort_if($user->role !== 'athlete', 403, 'Only athlete accounts require guardian consent.');

        $consent = $user->guardianConsents()
            ->where('consent_status', GuardianConsent::STATUS_PENDING)
            ->latest('id')
            ->first();

        if (! $consent || ! $consent->guardian_email) {
            return response()->json([
                'error' => [
                    'code' => 'NO_PENDING_CONSENT',
                    'message' => 'No pending guardian consent found for this athlete.',
                ],
            ], 422);
        }

        try {
            $this->otp->resend(null, 'email', $consent->guardian_email, OtpCode::PURPOSE_GUARDIAN_CONSENT);
        } catch (OtpDeliveryException $e) {
            return response()->json([
                'error' => [
                    'code' => 'CHANNEL_UNAVAILABLE',
                    'message' => $e->getMessage(),
                ],
            ], 503);
        } catch (\Symfony\Component\HttpKernel\Exception\HttpException $e) {
            // OtpService::resend() aborts 429 inside the cooldown window.
            return response()->json([
                'error' => [
                    'code' => 'RESEND_COOLDOWN',
                    'message' => $e->getMessage(),
                ],
            ], 429);
        }

        return response()->json([
            'data' => ['message' => 'Confirmation email re-sent to the guardian.'],
        ]);
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
                'guardian_email' => $consent?->guardian_email,
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