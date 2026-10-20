<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\Program;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Training programs (Phase 5).
 *
 * A program is owned polymorphically by a coach profile or an academy, and
 * the "own programs" tab reads `created_by_user_id`, so both are seeded.
 */
class ProgramSeeder extends Seeder
{
    public function run(): void
    {
        $coach = CoachProfile::where('user_id', SeedLookup::userId('coach@sportx.test'))->first();
        $academy = Academy::where('owner_user_id', SeedLookup::userId('academy@sportx.test'))->first();
        $academy2 = Academy::where('owner_user_id', SeedLookup::userId('academy2@sportx.test'))->first();

        if (! $coach || ! $academy) {
            $this->command->warn('Coach/academy profiles missing. Run the profile seeders first.');
            return;
        }

        $rows = [
            [
                'owner_type' => 'coach_profile',
                'owner_id' => $coach->id,
                'created_by' => 'coach@sportx.test',
                'title' => 'Batting Technique — 8 Week Batch',
                'sport' => 'Cricket',
                'age_group' => 'Under-16',
                'duration' => '8 weeks',
                'mode' => 'offline',
                'price' => 8000,
                'schedule' => 'Mon/Wed/Fri 4:00 PM - 5:30 PM',
                'about' => 'Video-analysis driven batting drills covering grip, stance and shot selection.',
                'status' => 'active',
            ],
            [
                'owner_type' => 'coach_profile',
                'owner_id' => $coach->id,
                'created_by' => 'coach@sportx.test',
                'title' => 'Bowling Masterclass — Online',
                'sport' => 'Cricket',
                'age_group' => 'Open',
                'duration' => '4 weeks',
                'mode' => 'online',
                'price' => 3000,
                'schedule' => 'Tue/Thu 8:00 PM - 9:00 PM (live)',
                'about' => 'Live online sessions on swing, seam and yorker bowling.',
                'status' => 'active',
            ],
            [
                'owner_type' => 'academy',
                'owner_id' => $academy->id,
                'created_by' => 'academy@sportx.test',
                'title' => 'Elite Junior Cricket Residential',
                'sport' => 'Cricket',
                'age_group' => 'Under-14',
                'duration' => '12 weeks',
                'mode' => 'offline',
                'price' => 25000,
                'schedule' => 'Full-time, Mon-Sat',
                'about' => 'Residential programme with match exposure, fitness and academic support.',
                'status' => 'active',
            ],
            [
                'owner_type' => 'academy',
                'owner_id' => $academy->id,
                'created_by' => 'academy@sportx.test',
                'title' => 'Evening Fitness Foundation (Summer)',
                'sport' => 'Athletics',
                'age_group' => 'Under-16',
                'duration' => '6 weeks',
                'mode' => 'hybrid',
                'price' => 6000,
                'schedule' => 'Mon-Sat 5:30 PM - 7:00 PM',
                'about' => 'Strength, speed and agility conditioning for young athletes.',
                'status' => 'active',
            ],
            [
                'owner_type' => 'academy',
                'owner_id' => $academy2?->id,
                'created_by' => 'academy2@sportx.test',
                'title' => 'Swimming Foundation Course',
                'sport' => 'Swimming',
                'age_group' => 'Under-10',
                'duration' => '10 weeks',
                'mode' => 'offline',
                'price' => 12000,
                'schedule' => 'Tue/Fri/Sat 7:00 AM - 9:00 AM',
                'about' => 'Water confidence, four basic strokes and survival skills for young swimmers.',
                'status' => 'active',
            ],
            [
                'owner_type' => 'coach_profile',
                'owner_id' => $coach->id,
                'created_by' => 'coach@sportx.test',
                'title' => 'Winter Cricket Bootcamp (archived)',
                'sport' => 'Cricket',
                'age_group' => 'Open',
                'duration' => '2 weeks',
                'mode' => 'offline',
                'price' => 5000,
                'schedule' => 'Past season',
                'about' => 'Completed winter camp kept for the "past" tab.',
                'status' => 'past',
            ],
            [
                'owner_type' => 'coach_profile',
                'owner_id' => $coach->id,
                'created_by' => 'coach@sportx.test',
                'title' => 'Draft: Fielding Masterclass',
                'sport' => 'Cricket',
                'age_group' => 'Open',
                'duration' => '4 weeks',
                'mode' => 'offline',
                'price' => 4000,
                'schedule' => 'To be announced',
                'about' => 'Draft listing not yet published.',
                'status' => 'draft',
            ],
        ];

        $created = 0;

        foreach ($rows as $row) {
            if (! $row['owner_id']) {
                continue;
            }

            Program::updateOrCreate(
                [
                    'owner_type' => $row['owner_type'],
                    'owner_id' => $row['owner_id'],
                    'title' => $row['title'],
                ],
                [
                    'created_by_user_id' => SeedLookup::userId($row['created_by']),
                    'sport_id' => SeedLookup::sportId($row['sport']),
                    'age_group_id' => SeedLookup::ageGroupId($row['age_group']),
                    'duration' => $row['duration'],
                    'mode' => $row['mode'],
                    'price' => $row['price'],
                    'schedule' => $row['schedule'],
                    'about' => $row['about'],
                    'status' => $row['status'],
                ]
            );

            $created++;
        }

        $this->command->info('Programs seeded: '.$created);
    }
}
