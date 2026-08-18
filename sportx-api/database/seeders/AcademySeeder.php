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
                'owner_user_id' => 4,
                'name' => 'Elite Cricket Academy',
                'address' => 'Narendra Modi Stadium Campus, Ahmedabad',
                'city_id' => 1,
                'contact_number' => '+91 79 2345 6789',
                'email' => 'info@elitecricket.example.com',
                'description' => 'Premier cricket academy in Gujarat',
                'year_established' => 2015,
                'facilities' => json_encode(['Nets', 'Ground', 'Video Analysis', 'Gym']),
                'achievements' => json_encode(['Produced 5 state-level champions']),
                'website' => 'https://elitecricket.example.com',
                'listing_status' => 'published',
            ],
            [
                'owner_user_id' => 10,
                'name' => 'Mumbai Cricket Academy',
                'address' => 'Wankhede Stadium Complex, Mumbai',
                'city_id' => 5,
                'contact_number' => '+91 22 2345 6789',
                'email' => 'contact@mca.example.com',
                'description' => 'Historic cricket coaching center',
                'year_established' => 2010,
                'facilities' => json_encode(['Nets', 'Ground', 'Swimming Pool', 'Gym']),
                'achievements' => json_encode(['NCA affiliated']),
                'website' => 'https://mca.example.com',
                'listing_status' => 'published',
            ],
        ];

        foreach ($profiles as $profile) {
            Academy::updateOrCreate(
                ['owner_user_id' => $profile['owner_user_id']],
                $profile
            );
        }

        $this->command->info('Academies seeded: ' . count($profiles));
    }
}
