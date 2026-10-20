<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\Enquiry;
use App\Models\Program;
use App\Models\Trial;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Enquiries raised by athletes against providers.
 *
 * One per subject type that supports an enquiry (academy, coach profile,
 * program, trial) so the enquiry list and the provider inbox both have
 * something to show for every role.
 */
class EnquirySeeder extends Seeder
{
    public function run(): void
    {
        $athlete = AthleteProfile::where('user_id', SeedLookup::userId('athlete@sportx.test'))->first();
        $academy = Academy::where('owner_user_id', SeedLookup::userId('academy@sportx.test'))->first();
        $coach = CoachProfile::where('user_id', SeedLookup::userId('coach@sportx.test'))->first();
        $program = Program::where('title', 'Batting Technique — 8 Week Batch')->first();
        $trial = Trial::where('status', 'published')->first();

        if (! $athlete) {
            $this->command->warn('Athlete profile missing. Run AthleteProfileSeeder first.');
            return;
        }

        $rows = [
            ['subject_type' => 'academy', 'subject_id' => $academy?->id, 'days' => 7],
            ['subject_type' => 'coach_profile', 'subject_id' => $coach?->id, 'days' => 3],
            ['subject_type' => 'program', 'subject_id' => $program?->id, 'days' => 5],
            ['subject_type' => 'trial', 'subject_id' => $trial?->id, 'days' => 10],
        ];

        $created = 0;

        foreach ($rows as $row) {
            if (! $row['subject_id']) {
                continue;
            }

            Enquiry::updateOrCreate(
                [
                    'athlete_id' => $athlete->id,
                    'subject_type' => $row['subject_type'],
                    'subject_id' => $row['subject_id'],
                ],
                [
                    'preferred_datetime' => now()->addDays($row['days']),
                ]
            );

            $created++;
        }

        $this->command->info('Enquiries seeded: '.$created);
    }
}
