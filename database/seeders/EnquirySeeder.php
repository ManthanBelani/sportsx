<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\Enquiry;
use Illuminate\Database\Seeder;

class EnquirySeeder extends Seeder
{
    public function run(): void
    {
        $athlete = AthleteProfile::first();
        $academy = Academy::first();

        if (!$athlete || !$academy) {
            $this->command->warn('Run AthleteProfileSeeder and AcademySeeder first.');
            return;
        }

        $enquiries = [
            [
                'athlete_id' => $athlete->id,
                'subject_type' => 'academy',
                'subject_id' => $academy->id,
                'preferred_datetime' => now()->addDays(7),
            ],
        ];

        foreach ($enquiries as $enquiry) {
            Enquiry::updateOrCreate(
                [
                    'athlete_id' => $enquiry['athlete_id'],
                    'subject_type' => $enquiry['subject_type'],
                    'subject_id' => $enquiry['subject_id'],
                ],
                $enquiry
            );
        }

        $this->command->info('Enquiries seeded: ' . count($enquiries));
    }
}
