<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\LeaderboardScore;
use App\Models\LeaderboardSeason;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Leaderboard seasons and scores (Phase 7).
 *
 * One active season plus a closed previous season, so the season rollover
 * and the historical views both have data.
 */
class LeaderboardSeeder extends Seeder
{
    public function run(): void
    {
        $current = LeaderboardSeason::updateOrCreate(
            ['name' => 'Season 2026'],
            [
                'starts_on' => now()->startOfYear()->toDateString(),
                'ends_on' => now()->endOfYear()->toDateString(),
                'is_active' => true,
            ]
        );

        $previous = LeaderboardSeason::updateOrCreate(
            ['name' => 'Season 2025'],
            [
                'starts_on' => now()->subYear()->startOfYear()->toDateString(),
                'ends_on' => now()->subYear()->endOfYear()->toDateString(),
                'is_active' => false,
            ]
        );

        // Exactly one active season at a time — LeaderboardService::activeSeason()
        // picks the newest active row, so a stale active season would win.
        LeaderboardSeason::where('id', '!=', $current->id)->update(['is_active' => false]);

        $rows = [
            ['athlete' => 'athlete@sportx.test', 'sport' => 'Cricket', 'points' => 980, 'season' => 'current'],
            ['athlete' => 'rahul@sportx.test', 'sport' => 'Football', 'points' => 1240, 'season' => 'current'],
            ['athlete' => 'priya@sportx.test', 'sport' => 'Swimming', 'points' => 1500, 'season' => 'current'],
            ['athlete' => 'aarav@sportx.test', 'sport' => 'Basketball', 'points' => 860, 'season' => 'current'],
            ['athlete' => 'diya@sportx.test', 'sport' => 'Tennis', 'points' => 720, 'season' => 'current'],
            ['athlete' => 'kabir@sportx.test', 'sport' => 'Kabaddi', 'points' => 640, 'season' => 'current'],
            ['athlete' => 'athlete@sportx.test', 'sport' => 'Cricket', 'points' => 640, 'season' => 'previous'],
            ['athlete' => 'rahul@sportx.test', 'sport' => 'Football', 'points' => 810, 'season' => 'previous'],
        ];

        $created = 0;

        foreach ($rows as $row) {
            $userId = SeedLookup::userId($row['athlete']);
            $profileId = $userId
                ? AthleteProfile::where('user_id', $userId)->value('id')
                : null;

            if (! $profileId) {
                continue;
            }

            $season = $row['season'] === 'current' ? $current : $previous;

            LeaderboardScore::updateOrCreate(
                [
                    'athlete_profile_id' => $profileId,
                    'sport_id' => SeedLookup::sportId($row['sport']),
                    'season_id' => $season->id,
                ],
                ['points' => $row['points']]
            );

            $created++;
        }

        $this->command->info('Leaderboard seeded: '.$created.' score rows, '.$current->name.' active');
    }
}
