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
                'headline' => 'Professional Cricket Coach | BCCI Level 2 Certified',
                'contact_number' => '+91 98765 44444',
                'sport_id' => 1,
                'city_id' => 1,
                'location' => 'Navrangpura, Ahmedabad',
                'experience' => '10 years',
                'qualification' => 'BCCI Level 2, NCCF Certified',
                'certifications' => json_encode(['BCCI Level 2', 'NCCF Certified']),
                'languages' => json_encode(['English', 'Hindi', 'Gujarati']),
                'bio' => 'Certified cricket coach with 10 years experience',
                'fee_structure' => '₹1,500/hour',
                'fee_per_session' => 800,
                'fee_monthly' => 5000,
                'fee_quarterly' => 13000,
                'availability' => json_encode([
                    'Mon' => ['4-6 PM'],
                    'Tue' => ['4-6 PM'],
                    'Wed' => ['4-6 PM'],
                    'Thu' => [],
                    'Fri' => ['4-6 PM'],
                    'Sat' => ['10-12 PM', '4-6 PM'],
                    'Sun' => ['10-12 PM', '4-6 PM'],
                ]),
                'email' => 'coach@sportx.test',
                'listing_status' => 'published',
            ],
            [
                'user_id' => 9,
                'full_name' => 'Vikram Singh',
                'headline' => 'Former Ranji Player | Cricket Coaching Expert',
                'contact_number' => '+91 98765 55555',
                'sport_id' => 1,
                'city_id' => 1,
                'location' => 'Andheri West, Mumbai',
                'experience' => '8 years',
                'qualification' => 'BCCI Level 1, Sports Science Degree',
                'certifications' => json_encode(['BCCI Level 1']),
                'languages' => json_encode(['English', 'Hindi', 'Gujarati']),
                'bio' => 'Former Ranji player turned coach',
                'fee_structure' => '₹2,000/hour',
                'fee_per_session' => 1000,
                'fee_monthly' => 6000,
                'fee_quarterly' => 15000,
                'availability' => json_encode([
                    'Mon' => ['6-8 AM', '4-6 PM'],
                    'Tue' => ['6-8 AM'],
                    'Wed' => ['6-8 AM', '4-6 PM'],
                    'Thu' => ['4-6 PM'],
                    'Fri' => ['6-8 AM', '4-6 PM'],
                    'Sat' => ['8-10 AM', '4-6 PM'],
                    'Sun' => ['8-10 AM', '4-6 PM'],
                ]),
                'email' => 'vikram@sportx.test',
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
