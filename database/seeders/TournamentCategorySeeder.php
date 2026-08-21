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
        $tournaments = Tournament::published()->get();
        $ageGroups = AgeGroup::limit(4)->get();

        if ($tournaments->isEmpty()) {
            $this->command->warn('No published tournaments found. Run TournamentSeeder first.');
            return;
        }

        $totalCategories = 0;
        foreach ($tournaments as $tournament) {
            foreach ($ageGroups as $index => $ageGroup) {
                $category = [
                    'tournament_id' => $tournament->id,
                    'age_group_id' => $ageGroup->id,
                    'name' => $ageGroup->name . ' Boys',
                    'capacity' => 24 + ($index * 4),
                    'waitlist_enabled' => true,
                ];
                TournamentCategory::updateOrCreate(
                    [
                        'tournament_id' => $category['tournament_id'],
                        'age_group_id' => $category['age_group_id'],
                    ],
                    $category
                );
                $totalCategories++;
            }
        }

        $this->command->info("Tournament categories seeded: {$totalCategories} for {$tournaments->count()} tournaments");
    }
}
