<?php

namespace Database\Seeders\Support;

use App\Models\AgeGroup;
use App\Models\City;
use App\Models\Sport;
use App\Models\User;

/**
 * Small lookup helpers shared by the seeders.
 *
 * Seeders reference master data (sports, cities, age groups) by NAME rather
 * than by hard-coded id, so re-seeding against a database that already has
 * rows — or one where the master data was seeded in a different order —
 * still resolves the right foreign keys.
 */
final class SeedLookup
{
    /** @var array<string, int|null> */
    private static array $cache = [];

    public static function sportId(string $name): ?int
    {
        return self::$cache['sport:'.strtolower($name)] ??= Sport::where('name', $name)->value('id');
    }

    public static function cityId(string $name): ?int
    {
        return self::$cache['city:'.strtolower($name)] ??= City::where('name', $name)->value('id');
    }

    public static function ageGroupId(string $name): ?int
    {
        return self::$cache['age_group:'.strtolower($name)] ??= AgeGroup::where('name', $name)->value('id');
    }

    /**
     * @param  array<int, string>  $names
     * @return array<int, int>
     */
    public static function sportIds(array $names): array
    {
        return array_values(array_filter(array_map(fn ($n) => self::sportId($n), $names)));
    }

    /**
     * @param  array<int, string>  $names
     * @return array<int, int>
     */
    public static function cityIds(array $names): array
    {
        return array_values(array_filter(array_map(fn ($n) => self::cityId($n), $names)));
    }

    /**
     * @param  array<int, string>  $names
     * @return array<int, int>
     */
    public static function ageGroupIds(array $names): array
    {
        return array_values(array_filter(array_map(fn ($n) => self::ageGroupId($n), $names)));
    }

    /**
     * Resolve a seeded user by email. Returns null when the user is missing so
     * seeders can degrade gracefully instead of exploding.
     */
    public static function userId(string $email): ?int
    {
        return self::$cache['user:'.strtolower($email)] ??= User::where('email', $email)->value('id');
    }

    /**
     * Same as {@see userId()} but throws a hard error, because continuing
     * without the user would silently skip a whole slice of the fixture.
     */
    public static function requireUserId(string $email): int
    {
        $id = self::userId($email);

        if (! $id) {
            throw new \RuntimeException("Seeded user [{$email}] is missing. Run UserSeeder first.");
        }

        return $id;
    }
}
