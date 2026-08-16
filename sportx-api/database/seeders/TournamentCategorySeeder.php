<?php

namespace Database\Seeders;

use App\Models\AgeGroup;
use App\Models\Tournament;
use App\Models\TournamentCategory;
use Illuminate\Database\Seeder;

class TournamentCategorySeeder extends Seeder
{
    public function run(): void
    {
        $tournament = Tournament::first();
        $ageGroups = AgeGroup::limit(4)->get();

        if (!$tournament) {
            $this->command->warn('No tournament found. Run TournamentSeeder first.');
            return;
        }

        $categories = [];
        foreach ($ageGroups as $index => $ageGroup) {
            $categories[] = [
                'tournament_id' => $tournament->id,
                'age_group_id' => $ageGroup->id,
                'name' => $ageGroup->name . ' Boys',
                'capacity' => 24 + ($index * 4),
                'waitlist_enabled' => true,
                'fees' => 500 + ($index * 100),
            ];
        }

        foreach ($categories as $category) {
            TournamentCategory::updateOrCreate(
                [
                    'tournament_id' => $category['tournament_id'],
                    'age_group_id' => $category['age_group_id'],
                ],
                $category
            );
        }

        $this->command->info('Tournament categories seeded: ' . count($categories));
    }
}
