<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\Sport;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Athlete profiles for every seeded athlete.
 *
 * The roster deliberately mixes adults and minors (the guardian-consent and
 * leaderboard-masking paths branch on age) and spans all skill levels so
 * filters, discovery and the leaderboard all have meaningful data.
 */
class AthleteProfileSeeder extends Seeder
{
    public function run(): void
    {
        $profiles = [
            [
                'email' => 'athlete@sportx.test',
                'full_name' => 'John Athlete',
                'phone' => '+91 98765 11111',
                'date_of_birth' => '2004-05-15',
                'gender' => 'male',
                'city' => 'Ahmedabad',
                'age_group' => 'Open',
                'skill_level' => 'intermediate',
                'position' => 'Batsman',
                'experience' => '3 years',
                'bio' => 'Right-hand batting middle-order, trains 5 days a week and plays district level cricket.',
                'academy_email' => 'academy@sportx.test',
                'coach_email' => 'coach@sportx.test',
                'sports' => ['Cricket'],
            ],
            [
                'email' => 'rahul@sportx.test',
                'full_name' => 'Rahul Sharma',
                'phone' => '+91 98765 22222',
                'date_of_birth' => '2010-08-22',
                'gender' => 'male',
                'city' => 'Surat',
                'age_group' => 'Under-18',
                'skill_level' => 'competitive',
                'position' => 'Midfielder',
                'experience' => '5 years',
                'bio' => 'Attacking midfielder, plays for the district U-17 side and trains with a licensed coach.',
                'academy_email' => 'academy2@sportx.test',
                'coach_email' => null,
                'sports' => ['Football'],
            ],
            [
                'email' => 'priya@sportx.test',
                'full_name' => 'Priya Patel',
                'phone' => '+91 98765 33333',
                'date_of_birth' => '2013-03-10',
                'gender' => 'female',
                'city' => 'Ahmedabad',
                'age_group' => 'Under-14',
                'skill_level' => 'advanced',
                'position' => 'Freestyle',
                'experience' => '4 years',
                'bio' => 'Freestyle specialist, state-level medalist and part of the academy relay squad.',
                'academy_email' => 'academy@sportx.test',
                'coach_email' => null,
                'sports' => ['Swimming'],
            ],
            [
                'email' => 'aarav@sportx.test',
                'full_name' => 'Aarav Menon',
                'phone' => '+91 98765 44444',
                'date_of_birth' => '2002-01-10',
                'gender' => 'male',
                'city' => 'Mumbai',
                'age_group' => 'Open',
                'skill_level' => 'competitive',
                'position' => 'Point Guard',
                'experience' => '7 years',
                'bio' => 'Point guard with strong court vision, plays for a city-level basketball club.',
                'academy_email' => 'mca@sportx.test',
                'coach_email' => null,
                'sports' => ['Basketball'],
            ],
            [
                'email' => 'diya@sportx.test',
                'full_name' => 'Diya Nair',
                'phone' => '+91 98765 55555',
                'date_of_birth' => '2009-07-19',
                'gender' => 'female',
                'city' => 'Bengaluru',
                'age_group' => 'Under-18',
                'skill_level' => 'intermediate',
                'position' => 'Baseline Player',
                'experience' => '2 years',
                'bio' => 'Consistent baseline player, ranked in the state junior circuit.',
                'academy_email' => null,
                'coach_email' => null,
                'sports' => ['Tennis'],
            ],
            [
                'email' => 'kabir@sportx.test',
                'full_name' => 'Kabir Khan',
                'phone' => '+91 98765 66666',
                'date_of_birth' => '2001-11-02',
                'gender' => 'male',
                'city' => 'Delhi',
                'age_group' => 'Open',
                'skill_level' => 'advanced',
                'position' => 'Raider',
                'experience' => '6 years',
                'bio' => 'Raider with a high raid success rate and a strong tackling defence.',
                'academy_email' => null,
                'coach_email' => null,
                'sports' => ['Kabaddi'],
            ],
            [
                'email' => 'athlete.pending@sportx.test',
                'full_name' => 'Pending Athlete',
                'phone' => '+91 98765 77777',
                'date_of_birth' => '2011-05-05',
                'gender' => 'male',
                'city' => 'Pune',
                'age_group' => 'Under-16',
                'skill_level' => 'beginner',
                'position' => 'Sprinter',
                'experience' => '1 year',
                'bio' => 'New athlete awaiting admin approval.',
                'academy_email' => null,
                'coach_email' => null,
                'sports' => ['Athletics'],
            ],
            [
                'email' => 'athlete.suspended@sportx.test',
                'full_name' => 'Suspended Athlete',
                'phone' => '+91 98765 88888',
                'date_of_birth' => '2000-02-14',
                'gender' => 'female',
                'city' => 'Jaipur',
                'age_group' => 'Open',
                'skill_level' => 'intermediate',
                'position' => 'Outside Hitter',
                'experience' => '3 years',
                'bio' => 'Account suspended for review — kept for admin moderation testing.',
                'academy_email' => null,
                'coach_email' => null,
                'sports' => ['Volleyball'],
            ],
        ];

        $created = 0;

        foreach ($profiles as $profile) {
            $userId = SeedLookup::userId($profile['email']);

            if (! $userId) {
                $this->command->warn("User {$profile['email']} not found. Run UserSeeder first.");
                continue;
            }

            $academyId = null;
            if (! empty($profile['academy_email'])) {
                $academyId = \App\Models\Academy::where('owner_user_id', SeedLookup::userId($profile['academy_email']))->value('id');
            }

            $coachId = null;
            if (! empty($profile['coach_email'])) {
                $coachId = CoachProfile::where('user_id', SeedLookup::userId($profile['coach_email']))->value('id');
            }

            $athlete = AthleteProfile::updateOrCreate(
                ['user_id' => $userId],
                [
                    'full_name' => $profile['full_name'],
                    'phone' => $profile['phone'],
                    'date_of_birth' => $profile['date_of_birth'],
                    'gender' => $profile['gender'],
                    'city_id' => SeedLookup::cityId($profile['city']),
                    'age_group_id' => SeedLookup::ageGroupId($profile['age_group']),
                    'skill_level' => $profile['skill_level'],
                    'position' => $profile['position'],
                    'experience' => $profile['experience'],
                    'bio' => $profile['bio'],
                    'academy_id' => $academyId,
                    'coach_id' => $coachId,
                ]
            );

            // Discovery (GET /athletes) only lists athletes with at least one
            // linked sport (whereHas('sports')), so sync sports by name.
            // The Phase 2 pivot columns carry the playing role and level, so
            // the discovery filters have something to filter on.
            $sportIds = SeedLookup::sportIds($profile['sports']);
            if ($sportIds) {
                $pivot = [];
                foreach ($sportIds as $index => $sportId) {
                    $pivot[$sportId] = [
                        'playing_role' => $profile['position'],
                        'level' => $profile['skill_level'],
                        'experience_years' => (int) filter_var($profile['experience'], FILTER_SANITIZE_NUMBER_INT),
                        'is_primary' => $index === 0,
                    ];
                }
                $athlete->sports()->sync($pivot);
            } else {
                $this->command->warn('Sports not found for '.$profile['email'].'. Run MasterDataSeeder first.');
            }

            $created++;
        }

        $this->command->info('Athlete profiles seeded: '.$created);
    }
}
