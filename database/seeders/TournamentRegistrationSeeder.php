<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\Tournament;
use App\Models\TournamentCategory;
use App\Models\TournamentRegistration;
use Illuminate\Database\Seeder;

class TournamentRegistrationSeeder extends Seeder
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
            TournamentRegistration::firstOrCreate(
                [
                    'tournament_id' => $tournament->id,
                    'category_id' => $category->id,
                    'athlete_id' => $athlete->id,
                ],
                [
                    'participation_type' => 'individual',
                    'team_name' => $index === 0 ? 'Young Strikers' : null,
                    'payment_status' => 'pending',
                    'status' => 'pending',
                ]
            );
            $count++;
        }

        $this->command->info('Tournament registrations seeded: ' . $count);
    }
}
