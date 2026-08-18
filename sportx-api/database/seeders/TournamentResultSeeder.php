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

        $count = 0;
        foreach ($athletes as $index => $athlete) {
            if ($index < 3) {
                TournamentResult::updateOrCreate(
                    [
                        'tournament_id' => $tournament->id,
                        'category_id' => $category->id,
                        'place' => $index + 1,
                    ],
                    [
                        'winner_name' => $athlete->full_name,
                        'published_at' => now(),
                    ]
                );
                $count++;
            }
        }

        $this->command->info('Tournament results seeded: ' . $count);
    }
}
