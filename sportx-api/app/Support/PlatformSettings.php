<?php

namespace App\Support;

/**
 * Canonical reader for `storage/app/platform_settings.json`.
 *
 * The file holds runtime admin overrides (approval toggles, mail provider).
 * It is read in several places across the codebase, and duplicated readers
 * have already caused one real bug: two registration paths consulted
 * `auto_approve_*` while a third hardcoded the answer, so flipping the toggle
 * silently stopped working for one sign-up method.
 *
 * New code must use this class instead of reading the file directly.
 */
final class PlatformSettings
{
    /**
     * @return array<string, mixed>
     */
    public static function all(): array
    {
        $path = storage_path('app/platform_settings.json');

        if (! is_file($path)) {
            return [];
        }

        $decoded = json_decode((string) @file_get_contents($path), true);

        return is_array($decoded) ? $decoded : [];
    }

    public static function get(string $key, mixed $default = null): mixed
    {
        return static::all()[$key] ?? $default;
    }

    /**
     * Whether a freshly registered account of the given role must wait for
     * admin approval.
     *
     * The ONLY place this decision is made. Every registration path —
     * password, OTP, Google — must call this instead of reimplementing the
     * rule, or an admin flipping an `auto_approve_*` toggle will silently stop
     * working for one sign-up method.
     */
    public static function needsApproval(string $role): bool
    {
        $role = UserRoles::normalize($role);

        return match ($role) {
            'coach' => ! (bool) static::get('auto_approve_coach', false),
            'sponsor' => ! (bool) static::get('auto_approve_sponsor', false),
            UserRoles::SCOUT => ! (bool) static::get('auto_approve_talent_scout', false),
            default => false,
        };
    }
}