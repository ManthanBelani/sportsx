<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\Tournament;
use App\Models\TournamentCategory;
use App\Models\TournamentResult;
use Illuminate\Database\Seeder;

class TournamentResultSeeder extends Seeder
{
    public function run(): void
    {
        $tournament = Tournament::first();
        $category = TournamentCategory::first();
        $athletes = AthleteProfile::limit(3)->get();

        if (!$tournament || !$category) {
            $this->command->warn('Run TournamentSeeder and TournamentCategorySeeder first.');
            return;
        }

        $positions = ['Winner', 'Runner-up', 'Third Place'];
        $results = [];
        foreach ($athletes as $index => $athlete) {
            if ($index < 3) {
                $results[] = [
                    'tournament_id' => $tournament->id,
                    'category_id' => $category->id,
                    'athlete_profile_id' => $athlete->id,
                    'position' => $positions[$index],
                    'team_name' => $index === 0 ? 'Young Strikers' : null,
                    'score' => $index === 0 ? 'Wins: 5, Losses: 0' : null,
                    'awards' => $index === 0 ? 'Trophy + Medal' : ($index === 1 ? 'Medal' : 'Certificate'),
                ];
            }
        }

        foreach ($results as $result) {
            TournamentResult::updateOrCreate(
                [
                    'tournament_id' => $result['tournament_id'],
                    'category_id' => $result['category_id'],
                    'athlete_profile_id' => $result['athlete_profile_id'],
                ],
                $result
            );
        }

        $this->command->info('Tournament results seeded: ' . count($results));
    }
}
