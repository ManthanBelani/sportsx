<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class CoachProfileSeeder extends Seeder
{
    public function run(): void
    {
        $coaches = User::where('role', 'coach')->get();

        if ($coaches->isEmpty()) {
            $this->command->warn('No coach users found. Run UserSeeder first.');
            return;
        }

        $profiles = [
            [
                'user_id' => 3,
                'full_name' => 'Sarah Coach',
                'phone' => '+91 98765 44444',
                'gender' => 'female',
                'sport_id' => 1,
                'city_id' => 1,
                'bio' => 'Certified cricket coach with 10 years experience',
                'qualifications' => 'BCCI Level 2, NCCF Certified',
                'experience_years' => 10,
                'specializations' => json_encode(['Batting', 'Fielding']),
                'available_for' => 'Trials, Training, Mentoring',
                'hourly_rate' => 1500,
                'status' => 'active',
            ],
            [
                'user_id' => 9,
                'full_name' => 'Vikram Singh',
                'phone' => '+91 98765 55555',
                'gender' => 'male',
                'sport_id' => 1,
                'city_id' => 1,
                'bio' => 'Former Ranji player turned coach',
                'qualifications' => 'BCCI Level 1, Sports Science Degree',
                'experience_years' => 8,
                'specializations' => json_encode(['Bowling', 'Mental Training']),
                'available_for' => 'Trials, Training',
                'hourly_rate' => 2000,
                'status' => 'active',
            ],
        ];

        foreach ($profiles as $profile) {
            \App\Models\CoachProfile::updateOrCreate(
                ['user_id' => $profile['user_id']],
                $profile
            );
        }

        $this->command->info('Coach profiles seeded: ' . count($profiles));
    }
}
