<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Schema;

/**
 * Shared audience targeting for notification broadcasts (API + admin panel):
 * narrows an active-user query by role, city, and sport.
 *
 * City resolves through each role's profile table (with the correct user join
 * column — academies use owner_user_id); sport resolves through the
 * athlete_sports pivot and coach_profiles.sport_id.
 */
class BroadcastTargeting
{
    /** [role => [profile table, user join column]] used for the city filter. */
    public const PROFILE_TABLES = [
        'athlete' => ['athlete_profiles', 'user_id'],
        'coach' => ['coach_profiles', 'user_id'],
        'academy' => ['academies', 'owner_user_id'],
        'organizer' => ['organizer_profiles', 'user_id'],
        'talent_scout' => ['talent_scout_profiles', 'user_id'],
    ];

    /** Apply role/city/sport filters to an active-user query. */
    public static function apply(Builder $query, array $roles = [], ?int $cityId = null, ?int $sportId = null): Builder
    {
        $query->where('status', 'active');

        $roles = $roles ?: array_keys(self::PROFILE_TABLES);
        $query->whereIn('role', $roles);

        if ($cityId) {
            $query->where(function ($q) use ($roles, $cityId) {
                foreach ($roles as $role) {
                    [$table, $userCol] = self::PROFILE_TABLES[$role] ?? [null, null];
                    if (! $table || ! Schema::hasColumn($table, 'city_id')) {
                        continue;
                    }
                    $q->orWhereExists(function ($sub) use ($table, $userCol, $cityId) {
                        $sub->from($table)
                            ->whereColumn("$table.$userCol", 'users.id')
                            ->where("$table.city_id", $cityId);
                    });
                }
            });
        }

        if ($sportId) {
            $query->where(function ($q) use ($sportId) {
                $q->whereExists(function ($sub) use ($sportId) {
                    $sub->from('athlete_sports')
                        ->join('athlete_profiles as ap', 'ap.id', '=', 'athlete_sports.athlete_id')
                        ->whereColumn('ap.user_id', 'users.id')
                        ->where('athlete_sports.sport_id', $sportId);
                })->orWhereExists(function ($sub) use ($sportId) {
                    $sub->from('coach_profiles')
                        ->whereColumn('coach_profiles.user_id', 'users.id')
                        ->where('coach_profiles.sport_id', $sportId);
                });
            });
        }

        return $query;
    }
}
