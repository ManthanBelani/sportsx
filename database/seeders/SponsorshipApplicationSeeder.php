<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\Sponsorship;
use App\Models\SponsorshipApplication;
use Illuminate\Database\Seeder;

class SponsorshipApplicationSeeder extends Seeder
{
    public function run(): void
    {
        $sponsorship = Sponsorship::first();
        $athletes = AthleteProfile::limit(3)->get();

        if (!$sponsorship) {
            $this->command->warn('No sponsorship found. Run SponsorshipSeeder first.');
            return;
        }

        $count = 0;
        foreach ($athletes as $index => $athlete) {
            SponsorshipApplication::firstOrCreate(
                [
                    'sponsorship_id' => $sponsorship->id,
                    'athlete_id' => $athlete->id,
                ],
                [
                    'pitch_note' => 'I am very interested in this sponsorship opportunity.',
                    'status' => 'submitted',
                ]
            );
            $count++;
        }

        $this->command->info('Sponsorship applications seeded: ' . $count);
    }
}
