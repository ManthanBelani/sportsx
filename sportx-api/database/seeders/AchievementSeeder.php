<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AchievementSeeder extends Seeder
{
    public function run(): void
    {
        $athlete = AthleteProfile::first();

        if (!$athlete) {
            $this->command->warn('No athlete profile found. Run AthleteProfileSeeder first.');
            return;
        }

        $achievements = [
            ['text' => 'District Cricket Championship Winner'],
            ['text' => 'Best Batsman Award'],
        ];

        foreach ($achievements as $i => $achievement) {
            \App\Models\Achievement::firstOrCreate(
                [
                    'athlete_id' => $athlete->id,
                    'text' => $achievement['text'],
                ],
                ['sort_order' => $i]
            );
        }

        $this->command->info('Achievements seeded: ' . count($achievements));
    }
}
