<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\Enquiry;
use Illuminate\Database\Seeder;

class EnquirySeeder extends Seeder
{
    public function run(): void
    {
        $athlete = AthleteProfile::first();
        $academy = Academy::first();
        $coach = CoachProfile::first();

        $enquiries = [
            [
                'athlete_profile_id' => $athlete?->id ?? 1,
                'subject_type' => 'academy',
                'subject_id' => $academy?->id ?? 1,
                'message' => 'I am interested in joining your cricket academy. What are the trial dates?',
                'status' => 'open',
            ],
            [
                'athlete_profile_id' => $athlete?->id ?? 1,
                'subject_type' => 'coach_profile',
                'subject_id' => $coach?->id ?? 1,
                'message' => 'Can you provide coaching for batting techniques?',
                'status' => 'replied',
            ],
        ];

        foreach ($enquiries as $enquiry) {
            Enquiry::updateOrCreate(
                [
                    'athlete_profile_id' => $enquiry['athlete_profile_id'],
                    'subject_type' => $enquiry['subject_type'],
                    'subject_id' => $enquiry['subject_id'],
                    'message' => $enquiry['message'],
                ],
                $enquiry
            );
        }

        $this->command->info('Enquiries seeded: ' . count($enquiries));
    }
}
