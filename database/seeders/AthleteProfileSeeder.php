<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\User;
use Illuminate\Database\Seeder;

class AthleteProfileSeeder extends Seeder
{
    public function run(): void
    {
        $athletes = User::where('role', 'athlete')->get();

        if ($athletes->isEmpty()) {
            $this->command->warn('No athlete users found. Run UserSeeder first.');
            return;
        }

        $profiles = [
            [
                'user_id' => 2,
                'full_name' => 'John Athlete',
                'phone' => '+91 98765 11111',
                'date_of_birth' => '2012-05-15',
                'gender' => 'male',
                'city_id' => 1,
                'age_group_id' => 3,
                'bio' => 'Passionate cricketer with 3 years of experience',
                'height_cm' => 155,
                'weight_kg' => 45,
                'playing_role' => 'Batsman',
                'batting_style' => 'Right-hand bat',
                'bowling_style' => 'Right-arm off-break',
                'dominant_hand' => 'right',
                'achievements' => 'District level champion 2025',
                'current_academy' => 'Elite Cricket Academy',
                'coach_name' => 'Vikram Singh',
                'status' => 'active',
            ],
            [
                'user_id' => 7,
                'full_name' => 'Rahul Sharma',
                'phone' => '+91 98765 22222',
                'date_of_birth' => '2010-08-22',
                'gender' => 'male',
                'city_id' => 2,
                'age_group_id' => 4,
                'bio' => 'Football enthusiast, captain of school team',
                'height_cm' => 165,
                'weight_kg' => 55,
                'playing_role' => 'Midfielder',
                'dominant_hand' => 'right',
                'achievements' => 'Best Player Award 2025',
                'current_academy' => 'Surat Football Academy',
                'status' => 'active',
            ],
            [
                'user_id' => 8,
                'full_name' => 'Priya Patel',
                'phone' => '+91 98765 33333',
                'date_of_birth' => '2013-03-10',
                'gender' => 'female',
                'city_id' => 1,
                'age_group_id' => 2,
                'bio' => 'Young swimming champion',
                'height_cm' => 140,
                'weight_kg' => 35,
                'dominant_hand' => 'right',
                'achievements' => 'State swimming gold 2025',
                'status' => 'active',
            ],
        ];

        foreach ($profiles as $profile) {
            AthleteProfile::updateOrCreate(
                ['user_id' => $profile['user_id']],
                $profile
            );
        }

        $this->command->info('Athlete profiles seeded: ' . count($profiles));
    }
}
