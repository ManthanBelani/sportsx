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
                'skill_level' => 'intermediate',
                'position' => 'Batsman',
                'experience' => '3 years',
            ],
            [
                'user_id' => 7,
                'full_name' => 'Rahul Sharma',
                'phone' => '+91 98765 22222',
                'date_of_birth' => '2010-08-22',
                'gender' => 'male',
                'city_id' => 2,
                'age_group_id' => 4,
                'skill_level' => 'competitive',
                'position' => 'Midfielder',
                'experience' => '5 years',
            ],
            [
                'user_id' => 8,
                'full_name' => 'Priya Patel',
                'phone' => '+91 98765 33333',
                'date_of_birth' => '2013-03-10',
                'gender' => 'female',
                'city_id' => 1,
                'age_group_id' => 2,
                'skill_level' => 'advanced',
                'position' => 'Freestyle',
                'experience' => '4 years',
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
