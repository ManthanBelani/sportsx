<?php

namespace Database\Seeders;

use App\Models\SponsorProfile;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Sponsor profiles (legacy role — the API returns 410 for new sponsor flows,
 * but the rows are still needed to exercise the legacy admin screens).
 */
class SponsorProfileSeeder extends Seeder
{
    public function run(): void
    {
        $sponsors = [
            [
                'email' => 'sponsor@sportx.test',
                'brand_name' => 'Decathlon India',
                'category' => 'Sports Retail',
                'verification_status' => 'verified',
            ],
        ];

        $created = 0;

        foreach ($sponsors as $row) {
            $userId = SeedLookup::userId($row['email']);

            if (! $userId) {
                $this->command->warn("User {$row['email']} not found. Run UserSeeder first.");
                continue;
            }

            SponsorProfile::updateOrCreate(
                ['user_id' => $userId],
                [
                    'brand_name' => $row['brand_name'],
                    'category' => $row['category'],
                    'verification_status' => $row['verification_status'],
                ]
            );

            $created++;
        }

        $this->command->info('Sponsor profiles seeded: '.$created);
    }
}
