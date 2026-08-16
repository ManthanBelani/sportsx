<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\Trial;
use App\Models\TrialRegistration;
use Illuminate\Database\Seeder;

class TrialRegistrationSeeder extends Seeder
{
    public function run(): void
    {
        $trial = Trial::first();
        $athletes = AthleteProfile::limit(3)->get();

        if (!$trial) {
            $this->command->warn('No trial found. Run TrialSeeder first.');
            return;
        }

        $registrations = [];
        foreach ($athletes as $index => $athlete) {
            $registrations[] = [
                'trial_id' => $trial->id,
                'athlete_profile_id' => $athlete->id,
                'status' => $index === 0 ? 'selected' : 'registered',
                'registration_date' => now()->subDays(rand(1, 5))->toDateString(),
                'playing_role' => 'Batsman',
                'medical_conditions' => null,
                'parental_consent' => true,
            ];
        }

        foreach ($registrations as $registration) {
            TrialRegistration::updateOrCreate(
                [
                    'trial_id' => $registration['trial_id'],
                    'athlete_profile_id' => $registration['athlete_profile_id'],
                ],
                $registration
            );
        }

        $this->command->info('Trial registrations seeded: ' . count($registrations));
    }
}
