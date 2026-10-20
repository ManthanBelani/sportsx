<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\AcademyCoach;
use App\Models\AcademySport;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Academy listings for every seeded academy.
 *
 * Also seeds the `academy_sports` and `academy_coaches` pivots, which the
 * directory filters (`?sport_id=`) and the academy profile screen rely on.
 */
class AcademySeeder extends Seeder
{
    public function run(): void
    {
        $academies = [
            [
                'email' => 'academy@sportx.test',
                'name' => 'Elite Cricket Academy',
                'address' => 'Narendra Modi Stadium Campus, Ahmedabad',
                'city' => 'Ahmedabad',
                'contact_number' => '+91 79 2345 6789',
                'email_address' => 'info@elitecricket.example.com',
                'description' => 'Premier cricket academy in Gujarat with a dedicated batting, bowling and fielding programme for ages 10-18.',
                'academy_type' => 'private',
                'sports_offered' => ['Batting', 'Bowling', 'Fielding'],
                'year_established' => 2015,
                'facilities' => ['Nets', 'Ground', 'Video Analysis', 'Gym'],
                'achievements' => ['Produced 5 state-level champions'],
                'age_groups' => ['Under-12', 'Under-14', 'Under-16', 'Under-18'],
                'fee_range' => '₹6,000 - ₹12,000 / month',
                'timings' => 'Mon-Sat 6 AM - 8 PM',
                'website' => 'https://elitecricket.example.com',
                'google_maps_url' => 'https://maps.google.com/?q=Narendra+Modi+Stadium',
                'sports' => ['Cricket'],
                'head_coach_email' => 'coach@sportx.test',
                'coaches' => [
                    ['email' => 'coach@sportx.test', 'display_name' => 'Sarah Coach'],
                    ['email' => 'vikram@sportx.test', 'display_name' => 'Vikram Singh'],
                ],
                'verification_badge' => true,
                'listing_status' => 'published',
            ],
            [
                'email' => 'mca@sportx.test',
                'name' => 'Mumbai Cricket Academy',
                'address' => 'Wankhede Stadium Complex, Mumbai',
                'city' => 'Mumbai',
                'contact_number' => '+91 22 2345 6789',
                'email_address' => 'contact@mca.example.com',
                'description' => 'Historic cricket coaching centre affiliated with the state cricket association.',
                'academy_type' => 'club',
                'sports_offered' => ['Batting', 'Bowling', 'Fitness'],
                'year_established' => 2010,
                'facilities' => ['Nets', 'Ground', 'Swimming Pool', 'Gym'],
                'achievements' => ['NCA affiliated', '12 state titles'],
                'age_groups' => ['Under-10', 'Under-12', 'Under-14'],
                'fee_range' => '₹5,000 - ₹10,000 / month',
                'timings' => 'Mon-Sat 5 AM - 9 PM',
                'website' => 'https://mca.example.com',
                'google_maps_url' => 'https://maps.google.com/?q=Wankhede+Stadium',
                'sports' => ['Cricket', 'Athletics'],
                'head_coach_email' => 'vikram@sportx.test',
                'coaches' => [
                    ['email' => 'vikram@sportx.test', 'display_name' => 'Vikram Singh'],
                ],
                'verification_badge' => true,
                'listing_status' => 'published',
            ],
            [
                'email' => 'academy2@sportx.test',
                'name' => 'Surat Sports Academy',
                'address' => 'Varachha Sports Complex, Surat',
                'city' => 'Surat',
                'contact_number' => '+91 261 2345 6789',
                'email_address' => 'hello@suratsports.example.com',
                'description' => 'Multi-sport academy running football, athletics and swimming programmes for juniors.',
                'academy_type' => 'school',
                'sports_offered' => ['Football', 'Athletics', 'Swimming'],
                'year_established' => 2018,
                'facilities' => ['Turf', 'Pool', 'Gym', 'Sports Hall'],
                'achievements' => ['3 district athletics titles'],
                'age_groups' => ['Under-10', 'Under-12', 'Under-14', 'Under-16'],
                'fee_range' => '₹3,500 - ₹8,000 / month',
                'timings' => 'Mon-Sat 7 AM - 7 PM',
                'website' => 'https://suratsports.example.com',
                'google_maps_url' => 'https://maps.google.com/?q=Varachha+Sports+Complex',
                'sports' => ['Football', 'Athletics', 'Swimming'],
                'head_coach_email' => 'coach2@sportx.test',
                'coaches' => [
                    ['email' => 'coach2@sportx.test', 'display_name' => 'Ritu Desai'],
                ],
                'verification_badge' => false,
                'listing_status' => 'published',
            ],
            [
                'email' => 'academy.pending@sportx.test',
                'name' => 'Pending Academy',
                'address' => 'Ring Road, Surat',
                'city' => 'Surat',
                'contact_number' => '+91 261 9999 8888',
                'email_address' => 'pending@academy.example.com',
                'description' => 'New academy profile awaiting admin approval.',
                'academy_type' => 'college',
                'sports_offered' => ['Kabaddi'],
                'year_established' => 2024,
                'facilities' => ['Indoor Hall'],
                'achievements' => [],
                'age_groups' => ['Under-16'],
                'fee_range' => '₹2,000 - ₹5,000 / month',
                'timings' => 'Mon-Fri 5 PM - 8 PM',
                'website' => null,
                'google_maps_url' => null,
                'sports' => ['Kabaddi'],
                'head_coach_email' => null,
                'coaches' => [],
                'verification_badge' => false,
                'listing_status' => 'draft',
            ],
        ];

        $created = 0;

        foreach ($academies as $row) {
            $ownerId = SeedLookup::userId($row['email']);

            if (! $ownerId) {
                $this->command->warn("User {$row['email']} not found. Run UserSeeder first.");
                continue;
            }

            $academy = Academy::updateOrCreate(
                ['owner_user_id' => $ownerId],
                [
                    'name' => $row['name'],
                    'description' => $row['description'],
                    'address' => $row['address'],
                    'city_id' => SeedLookup::cityId($row['city']),
                    'contact_number' => $row['contact_number'],
                    'google_maps_url' => $row['google_maps_url'],
                    'email' => $row['email_address'],
                    'website' => $row['website'],
                    'facilities' => json_encode($row['facilities']),
                    'achievements' => json_encode($row['achievements']),
                    'age_groups' => json_encode(SeedLookup::ageGroupIds($row['age_groups'])),
                    'sports_offered' => json_encode($row['sports_offered']),
                    'academy_type' => $row['academy_type'],
                    'fee_range' => $row['fee_range'],
                    'timings' => $row['timings'],
                    'year_established' => $row['year_established'],
                    'head_coach_id' => $row['head_coach_email'] ? SeedLookup::userId($row['head_coach_email']) : null,
                    'verification_badge' => $row['verification_badge'],
                    'listing_status' => $row['listing_status'],
                ]
            );

            // Pivots
            AcademySport::where('academy_id', $academy->id)->delete();
            foreach (SeedLookup::sportIds($row['sports']) as $sportId) {
                AcademySport::create(['academy_id' => $academy->id, 'sport_id' => $sportId]);
            }

            AcademyCoach::where('academy_id', $academy->id)->delete();
            foreach ($row['coaches'] as $coach) {
                $coachUserId = SeedLookup::userId($coach['email']);
                if ($coachUserId) {
                    AcademyCoach::create([
                        'academy_id' => $academy->id,
                        'coach_user_id' => $coachUserId,
                        'display_name' => $coach['display_name'],
                    ]);
                }
            }

            $created++;
        }

        $this->command->info('Academies seeded: '.$created);
    }
}
