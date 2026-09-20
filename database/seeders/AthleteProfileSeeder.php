<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\Sport;
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
                'email' => 'athlete@sportx.test',
                'full_name' => 'John Athlete',
                'phone' => '+91 98765 11111',
                'date_of_birth' => '2012-05-15',
                'gender' => 'male',
                'city_id' => 1,
                'age_group_id' => 3,
                'skill_level' => 'intermediate',
                'position' => 'Batsman',
                'experience' => '3 years',
                'sports' => ['Cricket'],
            ],
            [
                'email' => 'rahul@sportx.test',
                'full_name' => 'Rahul Sharma',
                'phone' => '+91 98765 22222',
                'date_of_birth' => '2010-08-22',
                'gender' => 'male',
                'city_id' => 2,
                'age_group_id' => 4,
                'skill_level' => 'competitive',
                'position' => 'Midfielder',
                'experience' => '5 years',
                'sports' => ['Football'],
            ],
            [
                'email' => 'priya@sportx.test',
                'full_name' => 'Priya Patel',
                'phone' => '+91 98765 33333',
                'date_of_birth' => '2013-03-10',
                'gender' => 'female',
                'city_id' => 1,
                'age_group_id' => 2,
                'skill_level' => 'advanced',
                'position' => 'Freestyle',
                'experience' => '4 years',
                'sports' => ['Swimming'],
            ],
        ];

        foreach ($profiles as $profile) {
            $user = User::where('email', $profile['email'])->first();
            if (! $user) {
                $this->command->warn("User {$profile['email']} not found. Run UserSeeder first.");
                continue;
            }

            $sportNames = $profile['sports'];
            unset($profile['sports'], $profile['email']);

            $athlete = AthleteProfile::updateOrCreate(
                ['user_id' => $user->id],
                $profile
            );

            // Discovery (GET /athletes) only lists athletes with at least one
            // linked sport (whereHas('sports')), so sync sports by name.
            $sportIds = Sport::whereIn('name', $sportNames)->pluck('id')->all();
            if (! empty($sportIds)) {
                $athlete->sports()->sync($sportIds);
            } else {
                $this->command->warn('Sports not found for ' . $user->email . '. Run MasterDataSeeder first.');
            }
        }

        $this->command->info('Athlete profiles seeded: ' . count($profiles));
    }
}
