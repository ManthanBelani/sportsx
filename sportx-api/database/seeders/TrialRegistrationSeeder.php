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

        $count = 0;
        foreach ($athletes as $athlete) {
            TrialRegistration::firstOrCreate(
                [
                    'trial_id' => $trial->id,
                    'athlete_id' => $athlete->id,
                ],
                [
                    'registration_ref' => 'TR' . strtoupper(uniqid()),
                    'document_status' => 'pending',
                    'verification_status' => 'pending',
                    'reminder_enabled' => true,
                ]
            );
            $count++;
        }

        $this->command->info('Trial registrations seeded: ' . $count);
    }
}
