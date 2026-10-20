<?php

namespace Database\Seeders;

use App\Models\CoachProfile;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Coach profiles for every seeded coach.
 *
 * `listing_status` is varied on purpose: 'published' listings show up in the
 * public directory, while a 'draft' coach exercises the "own listing is not
 * published yet" path in the mobile app.
 */
class CoachProfileSeeder extends Seeder
{
    public function run(): void
    {
        $profiles = [
            [
                'email' => 'coach@sportx.test',
                'full_name' => 'Sarah Coach',
                'headline' => 'Professional Cricket Coach | BCCI Level 2 Certified',
                'contact_number' => '+91 98765 44444',
                'sport' => 'Cricket',
                'city' => 'Ahmedabad',
                'location' => 'Navrangpura, Ahmedabad',
                'experience' => '10 years',
                'qualification' => 'BCCI Level 2, NCCF Certified',
                'certifications' => ['BCCI Level 2', 'NCCF Certified', 'Sports Science Diploma'],
                'languages' => ['English', 'Hindi', 'Gujarati'],
                'bio' => 'Certified cricket coach with 10 years of experience developing district and state level players.',
                'fee_structure' => '₹1,500/hour',
                'fee_per_session' => 800,
                'fee_monthly' => 5000,
                'fee_quarterly' => 13000,
                'availability' => [
                    'Mon' => ['4-6 PM'],
                    'Tue' => ['4-6 PM'],
                    'Wed' => ['4-6 PM'],
                    'Thu' => [],
                    'Fri' => ['4-6 PM'],
                    'Sat' => ['10-12 PM', '4-6 PM'],
                    'Sun' => ['10-12 PM', '4-6 PM'],
                ],
                'achievements' => ['Coached 3 state-level selections', '200+ athletes trained'],
                'personal_coaching' => true,
                'profile_completeness' => 100,
                'listing_status' => 'published',
            ],
            [
                'email' => 'vikram@sportx.test',
                'full_name' => 'Vikram Singh',
                'headline' => 'Former Ranji Player | Cricket Coaching Expert',
                'contact_number' => '+91 98765 55555',
                'sport' => 'Cricket',
                'city' => 'Mumbai',
                'location' => 'Andheri West, Mumbai',
                'experience' => '8 years',
                'qualification' => 'BCCI Level 1, Sports Science Degree',
                'certifications' => ['BCCI Level 1', 'Sports Science Degree'],
                'languages' => ['English', 'Hindi', 'Marathi'],
                'bio' => 'Former Ranji player turned coach, specialising in batting technique for teenagers.',
                'fee_structure' => '₹2,000/hour',
                'fee_per_session' => 1000,
                'fee_monthly' => 6000,
                'fee_quarterly' => 15000,
                'availability' => [
                    'Mon' => ['6-8 AM', '4-6 PM'],
                    'Tue' => ['6-8 AM'],
                    'Wed' => ['6-8 AM', '4-6 PM'],
                    'Thu' => ['4-6 PM'],
                    'Fri' => ['6-8 AM', '4-6 PM'],
                    'Sat' => ['8-10 AM', '4-6 PM'],
                    'Sun' => ['8-10 AM', '4-6 PM'],
                ],
                'achievements' => ['12 seasons as first-class cricketer'],
                'personal_coaching' => true,
                'profile_completeness' => 95,
                'listing_status' => 'published',
            ],
            [
                'email' => 'coach2@sportx.test',
                'full_name' => 'Ritu Desai',
                'headline' => 'Badminton Coaching | National Level Referee',
                'contact_number' => '+91 98765 99999',
                'sport' => 'Badminton',
                'city' => 'Pune',
                'location' => 'Kothrud, Pune',
                'experience' => '6 years',
                'qualification' => 'National Level Referee, BWF Level 1 Coach',
                'certifications' => ['BWF Level 1', 'National Level Referee'],
                'languages' => ['English', 'Hindi', 'Marathi'],
                'bio' => 'Badminton coach focused on junior technique, footwork and match temperament.',
                'fee_structure' => '₹1,200/hour',
                'fee_per_session' => 600,
                'fee_monthly' => 4000,
                'fee_quarterly' => 10000,
                'availability' => [
                    'Mon' => ['5-7 PM'],
                    'Wed' => ['5-7 PM'],
                    'Fri' => ['5-7 PM'],
                    'Sat' => ['7-9 AM'],
                    'Sun' => ['7-9 AM'],
                ],
                'achievements' => ['Coached 2 national finalists'],
                'personal_coaching' => true,
                'profile_completeness' => 90,
                'listing_status' => 'published',
            ],
            [
                'email' => 'coach.pending@sportx.test',
                'full_name' => 'Pending Coach',
                'headline' => 'Football Coach (awaiting approval)',
                'contact_number' => '+91 98765 88888',
                'sport' => 'Football',
                'city' => 'Ahmedabad',
                'location' => 'Satellite, Ahmedabad',
                'experience' => '2 years',
                'qualification' => 'AIFF Level 1',
                'certifications' => ['AIFF Level 1'],
                'languages' => ['English', 'Hindi', 'Gujarati'],
                'bio' => 'New coach profile awaiting admin approval.',
                'fee_structure' => '₹800/hour',
                'fee_per_session' => 500,
                'fee_monthly' => 3000,
                'fee_quarterly' => 8000,
                'availability' => ['Mon' => ['6-8 PM'], 'Wed' => ['6-8 PM']],
                'achievements' => [],
                'personal_coaching' => true,
                'profile_completeness' => 60,
                'listing_status' => 'draft',
            ],
        ];

        $created = 0;

        foreach ($profiles as $profile) {
            $userId = SeedLookup::userId($profile['email']);

            if (! $userId) {
                $this->command->warn("User {$profile['email']} not found. Run UserSeeder first.");
                continue;
            }

            $data = $profile;
            unset($data['email'], $data['sport'], $data['city']);

            $data['user_id'] = $userId;
            $data['sport_id'] = SeedLookup::sportId($profile['sport']);
            $data['city_id'] = SeedLookup::cityId($profile['city']);
            $data['email'] = $profile['email'];
            $data['certifications'] = json_encode($profile['certifications']);
            $data['languages'] = json_encode($profile['languages']);
            $data['availability'] = json_encode($profile['availability']);
            $data['achievements'] = json_encode($profile['achievements']);

            CoachProfile::updateOrCreate(['user_id' => $userId], $data);

            $created++;
        }

        $this->command->info('Coach profiles seeded: '.$created);
    }
}
