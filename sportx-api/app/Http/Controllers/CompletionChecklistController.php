<?php

namespace App\Http\Controllers;

use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\OrganizerProfile;
use App\Models\TalentScoutProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Per-role profile completion checklist.
 *
 * Powers the "finish your profile" nudge in the app: which fields are still
 * missing and where tapping each one should take the user.
 *
 * @see docs/API-Specification.md §1
 * @see docs/Functional-Requirements.md AT.6
 */
class CompletionChecklistController extends Controller
{
    /**
     * GET /me/completion-checklist
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        $checks = $this->checksFor($user);

        $missing = array_values(array_filter($checks, fn (array $c) => ! $c['done']));

        $total = count($checks);
        $complete = $total - count($missing);

        return response()->json([
            'data' => [
                'role' => $user->role,
                'completion' => $total > 0 ? (int) round(($complete / $total) * 100) : 0,
                'total' => $total,
                'complete' => $complete,
                'missing' => $missing,
                'checks' => $checks,
            ],
        ]);
    }

    /**
     * @return array<int, array{key: string, label: string, deep_link: string, done: bool}>
     */
    protected function checksFor($user): array
    {
        return match ($user->role) {
            'athlete' => $this->athleteChecks($user),
            'coach' => $this->coachChecks($user),
            'academy' => $this->academyChecks($user),
            'organizer' => $this->organizerChecks($user),
            'talent_scout' => $this->scoutChecks($user),
            default => [],
        };
    }

    /**
     * Whether a value counts as complete.
     *
     * Booleans are handled explicitly: a `false` guard result is *incomplete*,
     * and a loose `! empty()`-style comparison would report it as done because
     * `false !== null`.
     *
     * @param  mixed  $value
     */
    protected function isComplete($value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        if ($value instanceof \BackedEnum) {
            return true;
        }

        return $value !== null && $value !== '' && $value !== [];
    }

    /**
     * @param  mixed  $value
     */
    protected function check(string $key, string $label, string $deepLink, $value, array &$out): void
    {
        $out[] = [
            'key' => $key,
            'label' => $label,
            'deep_link' => $deepLink,
            'done' => $this->isComplete($value),
        ];
    }

    protected function athleteChecks($user): array
    {
        $checks = [];
        $profile = $user->athleteProfile;

        $this->check('profile', 'Complete your profile', 'profile/edit', $profile, $checks);
        $this->check('photo_media_id', 'Profile Photo', 'profile/photo', $profile?->photo_media_id, $checks);
        $this->check('date_of_birth', 'Date of Birth', 'profile/edit', $profile?->date_of_birth, $checks);
        $this->check('sports', 'Add your sport(s)', 'profile/sports', $profile?->sports, $checks);
        $this->check('city_id', 'Set your city', 'profile/edit', $profile?->city_id, $checks);
        $this->check('guardian_consent', 'Guardian consent (under 18)', 'settings/guardian', $this->hasGuardianConsent($user), $checks);
        $this->check('achievements', 'Add an achievement', 'profile/achievements', $profile?->achievements, $checks);

        return $checks;
    }

    protected function coachChecks($user): array
    {
        $checks = [];
        $profile = $user->coachProfile;

        $this->check('profile', 'Complete your profile', 'profile/edit', $profile, $checks);
        $this->check('photo_media_id', 'Profile Photo', 'profile/photo', $profile?->photo_media_id, $checks);
        $this->check('sports', 'Add your sport(s)', 'profile/sports', $profile?->sports, $checks);
        $this->check('experience_years', 'Years of experience', 'profile/edit', $profile?->experience_years, $checks);
        $this->check('certifications', 'Add certifications', 'profile/certifications', $profile?->certifications, $checks);
        $this->check('city_id', 'Set your city', 'profile/edit', $profile?->city_id, $checks);

        return $checks;
    }

    protected function academyChecks($user): array
    {
        $checks = [];
        $academy = $user->academies;

        $this->check('academy', 'Complete the academy profile', 'academy/edit', $academy, $checks);
        $this->check('description', 'About the academy', 'academy/edit', $academy?->description, $checks);
        $this->check('logo_media_id', 'Academy logo', 'academy/photos', $academy?->logo_media_id, $checks);
        $this->check('sports', 'Add sports offered', 'academy/sports', $academy?->sports, $checks);
        $this->check('city_id', 'Set the location', 'academy/edit', $academy?->city_id, $checks);
        $this->check('verification', 'Request verification', 'profile/verification', $this->isVerified($academy), $checks);

        return $checks;
    }

    protected function organizerChecks($user): array
    {
        $checks = [];
        $profile = $user->organizerProfile;

        $this->check('profile', 'Complete the organiser profile', 'organizer/edit', $profile, $checks);
        $this->check('organization_name', 'Organisation name', 'organizer/edit', $profile?->organization_name, $checks);
        $this->check('sports', 'Add sports organised', 'organizer/sports', $profile?->sports, $checks);
        $this->check('city_id', 'Set the location', 'organizer/edit', $profile?->city_id, $checks);
        $this->check('verification', 'Request verification', 'profile/verification', $this->isVerified($profile), $checks);

        return $checks;
    }

    protected function scoutChecks($user): array
    {
        $checks = [];
        $profile = $user->talentScoutProfile;

        $this->check('profile', 'Complete the scout profile', 'scout/edit', $profile, $checks);
        $this->check('photo_media_id', 'Profile Photo', 'scout/photo', $profile?->photo_media_id, $checks);
        $this->check('sports', 'Add your sport specialisations', 'scout/sports', $profile?->sports, $checks);
        $this->check('experience_years', 'Years of experience', 'scout/edit', $profile?->experience_years, $checks);
        $this->check('city_id', 'Set your base city', 'scout/edit', $profile?->city_id, $checks);

        return $checks;
    }

    /**
     * Whether a verified guardian consent exists (only meaningful for minors).
     */
    protected function hasGuardianConsent($user): bool
    {
        return $user->guardianConsents()
            ->where('consent_status', 'verified')
            ->exists();
    }

    /**
     * Whether an entity already carries the verified badge.
     */
    protected function isVerified($entity): bool
    {
        if ($entity === null) {
            return false;
        }

        if (in_array('verification_badge', $entity->getFillable(), true) || $entity->getAttribute('verification_badge') !== null) {
            return (bool) $entity->getAttribute('verification_badge');
        }

        if ($entity->getAttribute('verification_status') !== null) {
            return $entity->getAttribute('verification_status') === 'verified';
        }

        return false;
    }
}