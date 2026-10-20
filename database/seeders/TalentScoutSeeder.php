<?php

namespace Database\Seeders;

use App\Models\TalentScoutProfile;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Talent scout profiles for every seeded scout.
 *
 * The DB stores the role as `talent_scout` while the API canonicalises it to
 * `scout` (see App\Support\UserRoles).
 */
class TalentScoutSeeder extends Seeder
{
    public function run(): void
    {
        $scouts = [
            [
                'email' => 'kiran@scout.test',
                'organization' => 'Elite Talent Agency',
                'affiliation' => 'Gujarat Cricket Association',
                'sports_specialization' => ['Cricket', 'Badminton'],
                'experience_years' => 12,
                'city' => 'Ahmedabad',
                'bio' => 'Experienced talent scout with a passion for discovering young athletes across India.',
                'listing_status' => true,
            ],
            [
                'email' => 'scout2@sportx.test',
                'organization' => 'Metro Sports Scouting Cell',
                'affiliation' => 'Maharashtra Football Association',
                'sports_specialization' => ['Football', 'Athletics', 'Basketball'],
                'experience_years' => 7,
                'city' => 'Mumbai',
                'bio' => 'Scouts emerging multi-sport talent for city and state level academies.',
                'listing_status' => true,
            ],
            [
                'email' => 'scout.pending@sportx.test',
                'organization' => 'New Scout Agency',
                'affiliation' => null,
                'sports_specialization' => ['Swimming'],
                'experience_years' => 2,
                'city' => 'Surat',
                'bio' => 'New scout profile awaiting admin approval.',
                'listing_status' => false,
            ],
        ];

        $created = 0;

        foreach ($scouts as $row) {
            $userId = SeedLookup::userId($row['email']);

            if (! $userId) {
                $this->command->warn("User {$row['email']} not found. Run UserSeeder first.");
                continue;
            }

            TalentScoutProfile::updateOrCreate(
                ['user_id' => $userId],
                [
                    'organization' => $row['organization'],
                    'affiliation' => $row['affiliation'],
                    'sports_specialization' => SeedLookup::sportIds($row['sports_specialization']),
                    'experience_years' => $row['experience_years'],
                    'city_id' => SeedLookup::cityId($row['city']),
                    'bio' => $row['bio'],
                    'listing_status' => $row['listing_status'],
                ]
            );

            $created++;
        }

        $this->command->info('Talent scout profiles seeded: '.$created);
    }
}
