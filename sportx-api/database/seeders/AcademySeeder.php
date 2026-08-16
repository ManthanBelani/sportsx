<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\User;
use Illuminate\Database\Seeder;

class AcademySeeder extends Seeder
{
    public function run(): void
    {
        $academies = User::where('role', 'academy')->get();

        if ($academies->isEmpty()) {
            $this->command->warn('No academy users found. Run UserSeeder first.');
            return;
        }

        $profiles = [
            [
                'user_id' => 4,
                'name' => 'Elite Cricket Academy',
                'owner_name' => 'Rajesh Kumar',
                'phone' => '+91 79 2345 6789',
                'email' => 'info@elitecricket.example.com',
                'address' => 'Narendra Modi Stadium Campus, Ahmedabad',
                'city_id' => 1,
                'sport_id' => 1,
                'description' => 'Premier cricket academy in Gujarat',
                'established_year' => 2015,
                'facilities' => json_encode(['Nets', 'Ground', 'Video Analysis', 'Gym']),
                'achievements' => 'Produced 5 state-level champions',
                'website' => 'https://elitecricket.example.com',
                'social_media' => json_encode(['instagram' => '@elitecricket']),
                'listing_status' => 'published',
            ],
            [
                'user_id' => 10,
                'name' => 'Mumbai Cricket Academy',
                'owner_name' => 'Aditya Shah',
                'phone' => '+91 22 2345 6789',
                'email' => 'contact@mca.example.com',
                'address' => 'Wankhede Stadium Complex, Mumbai',
                'city_id' => 5,
                'sport_id' => 1,
                'description' => 'Historic cricket coaching center',
                'established_year' => 2010,
                'facilities' => json_encode(['Nets', 'Ground', 'Swimming Pool', 'Gym']),
                'achievements' => 'NCA affiliated',
                'website' => 'https://mca.example.com',
                'listing_status' => 'published',
            ],
        ];

        foreach ($profiles as $profile) {
            Academy::updateOrCreate(
                ['user_id' => $profile['user_id']],
                $profile
            );
        }

        $this->command->info('Academies seeded: ' . count($profiles));
    }
}
