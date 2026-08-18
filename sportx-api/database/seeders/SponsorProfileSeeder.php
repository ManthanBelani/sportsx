<?php

namespace Database\Seeders;

use App\Models\SponsorProfile;
use App\Models\User;
use Illuminate\Database\Seeder;

class SponsorProfileSeeder extends Seeder
{
    public function run(): void
    {
        $sponsors = User::where('role', 'sponsor')->get();

        if ($sponsors->isEmpty()) {
            $this->command->warn('No sponsor users found. Run UserSeeder first.');
            return;
        }

        $profiles = [
            [
                'user_id' => 6,
                'brand_name' => 'Decathlon India',
                'category' => 'Sports Retail',
                'verification_status' => 'verified',
            ],
        ];

        foreach ($profiles as $profile) {
            SponsorProfile::updateOrCreate(
                ['user_id' => $profile['user_id']],
                $profile
            );
        }

        $this->command->info('Sponsor profiles seeded: ' . count($profiles));
    }
}
