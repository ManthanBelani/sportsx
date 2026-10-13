<?php

namespace App\Services;

use App\Models\GuardianConsent;
use App\Models\OtpCode;
use App\Models\User;
use Carbon\CarbonImmutable;

/**
 * Guardian consent for athletes under 18.
 *
 * The gate is: an athlete whose date of birth puts them under 18 stays
 * `pending` until a guardian has proven control of a phone number and
 * confirmed consent. Both steps must happen — a guardian name typed by the
 * minor proves nothing.
 *
 * @see \App\Models\GuardianConsent
 * @see docs/Security-and-NonFunctional.md §2.2
 */
class GuardianConsentService
{
    /** Ages below this require guardian consent. */
    public const MINOR_AGE = 18;

    /**
     * Whether a date of birth makes the athlete a minor.
     */
    public function isMinor(?string $dateOfBirth): bool
    {
        if (empty($dateOfBirth)) {
            return false;
        }

        try {
            return CarbonImmutable::parse($dateOfBirth)->age < self::MINOR_AGE;
        } catch (\Throwable) {
            return false;
        }
    }

    /**
     * Record a guardian's details and send the confirmation code.
     *
     * Any previous pending consent for this athlete is superseded so a stale
     * half-finished attempt cannot be verified later.
     */
    public function request(User $athlete, array $data, OtpService $otp): GuardianConsent
    {
        $athlete->guardianConsents()
            ->where('consent_status', GuardianConsent::STATUS_PENDING)
            ->update(['consent_status' => GuardianConsent::STATUS_REVOKED, 'revoked_at' => now()]);

        $consent = $athlete->guardianConsents()->create([
            'guardian_name' => $data['guardian_name'],
            'guardian_phone' => $data['guardian_phone'],
            'relationship' => $data['relationship'] ?? 'parent',
            'consent_status' => GuardianConsent::STATUS_PENDING,
        ]);

        // The code goes to the *guardian*, not the athlete. With no SMS vendor
        // selected (AS-60) this throws OtpDeliveryException, which the
        // controller surfaces as 503 rather than recording a consent nobody can
        // actually confirm.
        $otp->generateAndSend(
            null,
            'phone',
            $data['guardian_phone'],
            OtpCode::PURPOSE_GUARDIAN_CONSENT,
        );

        return $consent;
    }

    /**
     * Confirm the guardian's code and activate consent.
     */
    public function verify(User $athlete, string $code, OtpService $otp): GuardianConsent
    {
        $consent = $athlete->guardianConsents()
            ->where('consent_status', GuardianConsent::STATUS_PENDING)
            ->latest('id')
            ->first();

        if (! $consent) {
            abort(422, 'No pending guardian consent found for this athlete.');
        }

        $verified = $otp->verify(
            null,
            'phone',
            $consent->guardian_phone,
            $code,
            OtpCode::PURPOSE_GUARDIAN_CONSENT,
        );

        if (! $verified) {
            abort(422, 'That code is incorrect or has expired.');
        }

        $consent->markVerified();

        // Consent unlocks the profile, but the defaults stay restricted:
        // messaging stays guardian-gated and the profile is not public.
        $athlete->forceFill(['status' => 'active'])->save();

        return $consent->refresh();
    }

    /**
     * The active consent for an athlete, if any.
     */
    public function activeFor(User $athlete): ?GuardianConsent
    {
        return $athlete->guardianConsents()
            ->where('consent_status', GuardianConsent::STATUS_VERIFIED)
            ->latest('verified_at')
            ->first();
    }

    /**
     * Whether an athlete's profile may be publicly visible.
     *
     * A minor's profile stays hidden unless a guardian explicitly enabled it.
     */
    public function allowsPublicProfile(User $athlete): bool
    {
        $dob = $athlete->athleteProfile?->date_of_birth;

        if (! $this->isMinor($dob)) {
            return true;
        }

        return (bool) $this->activeFor($athlete)?->allow_public_profile;
    }

    /**
     * Whether the athlete may receive direct messages.
     *
     * Minors are guardian-gated: even with verified consent, direct messages
     * default off and route to the guardian.
     */
    public function allowsMessages(User $athlete): bool
    {
        $dob = $athlete->athleteProfile?->date_of_birth;

        if (! $this->isMinor($dob)) {
            return true;
        }

        return (bool) $this->activeFor($athlete)?->allow_messages;
    }

    /**
     * How the athlete's name appears on a leaderboard.
     */
    public function leaderboardNameMode(User $athlete): string
    {
        $dob = $athlete->athleteProfile?->date_of_birth;

        if (! $this->isMinor($dob)) {
            return 'full_name';
        }

        return $this->activeFor($athlete)?->leaderboard_name_mode ?? 'first_name_initial';
    }

    /**
     * Revoke consent and restore restricted defaults.
     */
    public function revoke(User $athlete): void
    {
        $athlete->guardianConsents()
            ->where('consent_status', GuardianConsent::STATUS_VERIFIED)
            ->get()
            ->each->revoke();
    }
}