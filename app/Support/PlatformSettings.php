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

    /**
     * Effective settings = defaults overlaid with stored overrides.
     */
    public static function effective(): array
    {
        return array_merge(static::defaults(), array_intersect_key(static::all(), static::defaults()));
    }

    /**
     * Persist an allow-listed subset of settings. Returns the effective map.
     */
    public static function update(array $values): array
    {
        $allowed = static::writable();
        $patch = array_intersect_key($values, array_flip($allowed));

        $current = static::all();
        foreach ($patch as $k => $v) {
            $current[$k] = $v;
        }

        @file_put_contents(
            storage_path('app/platform_settings.json'),
            json_encode($current, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES)
        );

        return static::effective();
    }

    /**
     * Keys the mobile admin screen (and the web panel) may change at runtime.
     */
    public static function writable(): array
    {
        return [
            'maintenance_mode',
            'registrations_open',
            'auto_approve_trials',
            'auto_approve_tournaments',
            'push_notifications',
            'email_alerts',
        ];
    }

    public static function defaults(): array
    {
        return [
            'moderation_required' => true,
            'auto_verify_coaches' => false,
            'auto_approve_coach' => false,
            'auto_approve_sponsor' => false,
            'auto_approve_talent_scout' => false,
            'auto_approve_trials' => false,
            'auto_approve_tournaments' => false,
            'auto_approve_scholarships' => false,
            'auto_approve_sponsorships' => false,
            'auto_approve_academies' => false,
            'auto_approve_venues' => false,
            'email_alerts' => true,
            'push_notifications' => true,
            'suspicious_login_detection' => true,
            'maintenance_mode' => false,
            'registrations_open' => true,
            'max_listings_per_user_per_day' => 5,
            'media_max_size_mb' => 10,
            'session_lifetime_minutes' => 30,
            'rate_limit_login_per_minute' => 10,
            'audit_log_enabled' => true,
            'data_retention_days' => 365,
            'allow_user_data_export' => true,
            'allow_user_data_delete' => true,
        ];
    }
}