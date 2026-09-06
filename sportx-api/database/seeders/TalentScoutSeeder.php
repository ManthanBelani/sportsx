<?php

namespace Database\Seeders;

use App\Models\TalentScoutProfile;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class TalentScoutSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::create([
            'name' => 'Kiran Patel',
            'email' => 'kiran@scout.test',
            'password' => Hash::make('password'),
            'role' => 'talent_scout',
            'email_verified_at' => now(),
            'status' => 'active',
        ]);

        TalentScoutProfile::create([
            'user_id' => $user->id,
            'organization' => 'Elite Talent Agency',
            'affiliation' => 'Gujarat Cricket Association',
            'sports_specialization' => [1, 3],
            'experience_years' => 12,
            'city_id' => 1,
            'bio' => 'Experienced talent scout with a passion for discovering young athletes across India.',
        ]);
    }
}
