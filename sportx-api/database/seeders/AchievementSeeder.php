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
            [
                'athlete_profile_id' => $athlete->id,
                'title' => 'District Cricket Championship Winner',
                'description' => 'First place in District Level Cricket Championship 2025',
                'date_achieved' => '2025-11-15',
                'award_type' => 'trophy',
            ],
            [
                'athlete_profile_id' => $athlete->id,
                'title' => 'Best Batsman Award',
                'description' => 'Awarded Best Batsman in inter-school tournament',
                'date_achieved' => '2025-09-20',
                'award_type' => 'medal',
            ],
        ];

        foreach ($achievements as $achievement) {
            DB::table('achievements')->updateOrInsert(
                [
                    'athlete_profile_id' => $achievement['athlete_profile_id'],
                    'title' => $achievement['title'],
                ],
                $achievement
            );
        }

        $this->command->info('Achievements seeded: ' . count($achievements));
    }
}
