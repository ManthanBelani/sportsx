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
                'contact_number' => '+91 98765 44444',
                'sport_id' => 1,
                'city_id' => 1,
                'experience' => '10 years',
                'qualification' => 'BCCI Level 2, NCCF Certified',
                'certifications' => json_encode(['BCCI Level 2', 'NCCF Certified']),
                'languages' => json_encode(['English', 'Hindi', 'Gujarati']),
                'bio' => 'Certified cricket coach with 10 years experience',
                'fee_structure' => '₹1,500/hour',
                'listing_status' => 'published',
            ],
            [
                'user_id' => 9,
                'full_name' => 'Vikram Singh',
                'contact_number' => '+91 98765 55555',
                'sport_id' => 1,
                'city_id' => 1,
                'experience' => '8 years',
                'qualification' => 'BCCI Level 1, Sports Science Degree',
                'certifications' => json_encode(['BCCI Level 1']),
                'languages' => json_encode(['English', 'Hindi', 'Gujarati']),
                'bio' => 'Former Ranji player turned coach',
                'fee_structure' => '₹2,000/hour',
                'listing_status' => 'published',
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
