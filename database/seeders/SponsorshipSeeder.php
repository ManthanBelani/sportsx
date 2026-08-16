<?php

namespace Database\Seeders;

use App\Models\SponsorProfile;
use App\Models\Sponsorship;
use Illuminate\Database\Seeder;

class SponsorshipSeeder extends Seeder
{
    public function run(): void
    {
        $sponsor = SponsorProfile::first();

        $sponsorships = [
            [
                'title' => 'U-14 Cricket Kit Sponsorship',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'Decathlon India',
                'sport_id' => 1,
                'eligibility_criteria' => 'Selected U-14 trial participants from Ahmedabad',
                'deadline' => now()->addDays(20)->toDateString(),
                'application_link' => 'https://decathlon.example.com/sponsor',
                'contact_email' => 'sports@decathlon.example.com',
                'contact_phone' => '+91 80405 67890',
                'benefits_offered' => 'Full cricket kit (bat, pads, gloves) for the season',
                'amount' => 15000.00,
                'status' => 'published',
            ],
            [
                'title' => 'Football Gear Sponsorship',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'Decathlon India',
                'sport_id' => 2,
                'eligibility_criteria' => 'Registered footballers with active tournament participation',
                'deadline' => now()->addDays(25)->toDateString(),
                'application_link' => 'https://decathlon.example.com/football',
                'contact_email' => 'sports@decathlon.example.com',
                'contact_phone' => '+91 80405 67890',
                'benefits_offered' => 'Complete football kit + boots',
                'amount' => 12000.00,
                'status' => 'published',
            ],
        ];

        foreach ($sponsorships as $sponsorship) {
            Sponsorship::updateOrCreate(
                ['title' => $sponsorship['title']],
                $sponsorship
            );
        }

        $this->command->info('Sponsorships seeded: ' . count($sponsorships));
    }
}
