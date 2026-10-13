<?php

namespace App\Support;

/**
 * Canonical Phase-1 (v3) roles.
 *
 * Canonical: `athlete, coach, academy, organizer, scout, admin`.
 * `sponsor` is REMOVED (sponsorship becomes `opportunities.type` in Phase 4).
 * `talent_scout` is the legacy storage value for `scout` — the DB enum still
 * carries `talent_scout`, so this helper normalises input (`scout` alias) and
 * maps back to the stored value until the rename migration lands.
 *
 * @see docs/PHASE_WISE_IMPLEMENTATION_PLAN.md Phase 1
 */
final class UserRoles
{
    public const ATHLETE = 'athlete';

    public const COACH = 'coach';

    public const ACADEMY = 'academy';

    public const ORGANIZER = 'organizer';

    /** Canonical v3 name for talent scouts. */
    public const SCOUT = 'scout';

    public const ADMIN = 'admin';

    /** Legacy storage value for scouts (users.role enum). */
    public const TALENT_SCOUT = 'talent_scout';

    /** Removed in v3 — new signups must be refused (410). */
    public const SPONSOR = 'sponsor';

    /**
     * Roles a new account may register as (canonical names).
     *
     * @return list<string>
     */
    public static function signupRoles(): array
    {
        return [
            self::ATHLETE,
            self::COACH,
            self::ACADEMY,
            self::ORGANIZER,
            self::SCOUT,
        ];
    }

    /**
     * Normalise a client-supplied role to its canonical form.
     *
     * `talent_scout` → `scout`. Everything else passes through lowercased.
     */
    public static function normalize(?string $role): ?string
    {
        if ($role === null || $role === '') {
            return $role;
        }

        $role = strtolower(trim($role));

        return $role === self::TALENT_SCOUT ? self::SCOUT : $role;
    }

    /**
     * Map a canonical role to the value stored in `users.role`.
     *
     * Only `scout` differs (`talent_scout`) until the rename migration lands.
     */
    public static function toStorage(string $canonicalRole): string
    {
        return $canonicalRole === self::SCOUT ? self::TALENT_SCOUT : $canonicalRole;
    }

    /**
     * Whether a stored `users.role` value matches a required role,
     * accepting the `scout`/`talent_scout` alias in both directions.
     */
    public static function matches(string $storedRole, string $requiredRole): bool
    {
        if ($storedRole === $requiredRole) {
            return true;
        }

        $aliases = [self::SCOUT, self::TALENT_SCOUT];

        return in_array($storedRole, $aliases, true)
            && in_array($requiredRole, $aliases, true);
    }
}
