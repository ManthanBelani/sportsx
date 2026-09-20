<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\CoachingEnrollment;
use App\Models\CoachProfile;
use Illuminate\Database\Seeder;

class CoachingEnrollmentSeeder extends Seeder
{
    public function run(): void
    {
        $coach = CoachProfile::first();
        $athlete = AthleteProfile::first();
        $athlete2 = AthleteProfile::skip(1)->first();

        if (! $coach || ! $athlete) {
            $this->command->warn('No coach or athlete found. Run CoachProfileSeeder/AthleteProfileSeeder first.');

            return;
        }

        $enrollments = [
            [
                'coach_id' => $coach->id,
                'athlete_id' => $athlete->id,
                'plan_type' => 'monthly',
                'fees_amount' => $coach->fee_monthly ?? 5000,
                'status' => 'active',
                'approval_status' => 'approved',
                'start_date' => now()->subDays(5)->toDateString(),
                'end_date' => now()->addDays(25)->toDateString(),
                'sessions_remaining' => 12,
                'reviewed_by' => $coach->user_id,
                'reviewed_at' => now()->subDays(5),
                'notes' => 'Looking to improve batting technique for U-14 trials.',
                'coach_response' => 'Accepted. See you on Monday 4 PM.',
            ],
        ];

        if ($athlete2 && $athlete2->id !== $athlete->id) {
            $enrollments[] = [
                'coach_id' => $coach->id,
                'athlete_id' => $athlete2->id,
                'plan_type' => 'session',
                'fees_amount' => $coach->fee_per_session ?? 800,
                'status' => 'inactive',
                'approval_status' => 'pending',
                'start_date' => now()->addDays(2)->toDateString(),
                'end_date' => null,
                'sessions_remaining' => 1,
                'notes' => 'Trial session request for weekend batch.',
            ];
        }

        foreach ($enrollments as $enrollment) {
            CoachingEnrollment::updateOrCreate(
                [
                    'coach_id' => $enrollment['coach_id'],
                    'athlete_id' => $enrollment['athlete_id'],
                    'plan_type' => $enrollment['plan_type'],
                ],
                $enrollment
            );
        }

        $this->command->info('Coaching enrollments seeded: '.count($enrollments));
    }
}
