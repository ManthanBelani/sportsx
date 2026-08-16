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

        $registrations = [];
        foreach ($athletes as $index => $athlete) {
            $registrations[] = [
                'tournament_id' => $tournament->id,
                'category_id' => $category->id,
                'athlete_profile_id' => $athlete->id,
                'team_name' => $index === 0 ? 'Young Strikers' : null,
                'status' => $index === 0 ? 'confirmed' : 'registered',
                'registration_date' => now()->subDays(rand(1, 10))->toDateString(),
            ];
        }

        foreach ($registrations as $registration) {
            TournamentRegistration::updateOrCreate(
                [
                    'tournament_id' => $registration['tournament_id'],
                    'category_id' => $registration['category_id'],
                    'athlete_profile_id' => $registration['athlete_profile_id'],
                ],
                $registration
            );
        }

        $this->command->info('Tournament registrations seeded: ' . count($registrations));
    }
}
