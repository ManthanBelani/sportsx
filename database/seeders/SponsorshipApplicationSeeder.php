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

        $applications = [];
        foreach ($athletes as $index => $athlete) {
            $applications[] = [
                'sponsorship_id' => $sponsorship->id,
                'athlete_profile_id' => $athlete->id,
                'status' => $index === 0 ? 'approved' : 'pending',
                'application_date' => now()->subDays(rand(1, 10))->toDateString(),
                'message' => 'I am very interested in this sponsorship opportunity.',
            ];
        }

        foreach ($applications as $application) {
            SponsorshipApplication::updateOrCreate(
                [
                    'sponsorship_id' => $application['sponsorship_id'],
                    'athlete_profile_id' => $application['athlete_profile_id'],
                ],
                $application
            );
        }

        $this->command->info('Sponsorship applications seeded: ' . count($applications));
    }
}
