<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\Trial;
use App\Models\User;
use Illuminate\Database\Seeder;

class TrialSeeder extends Seeder
{
    public function run(): void
    {
        $trials = [
            [
                'name' => 'U-14 Cricket Trials Ahmedabad',
                'posted_by_user_id' => 3,
                'academy_id' => 1,
                'organization_name' => 'Elite Cricket Academy',
                'sport_id' => 1,
                'event_datetime' => now()->addDays(14)->toDateTimeString(),
                'venue' => 'Narendra Modi Stadium',
                'google_maps_url' => 'https://maps.google.com/?q=Narendra+Modi+Stadium',
                'city_id' => 1,
                'contact_number' => '+91 98765 43210',
                'registration_deadline' => now()->addDays(7)->toDateString(),
                'eligibility' => 'Boys, Under-14, Ahmedabad residents',
                'entry_fee' => '200',
                'required_documents' => json_encode(['Aadhaar Card', 'Passport Photo']),
                'vacancies' => 30,
                'benefits' => 'Selected athletes get free academy kit',
                'status' => 'published',
            ],
            [
                'name' => 'U-16 Football Trials Mumbai',
                'posted_by_user_id' => 9,
                'academy_id' => 2,
                'organization_name' => 'Mumbai Cricket Academy',
                'sport_id' => 2,
                'event_datetime' => now()->addDays(21)->toDateTimeString(),
                'venue' => 'Cooperage Ground',
                'google_maps_url' => 'https://maps.google.com/?q=Cooperage+Ground',
                'city_id' => 5,
                'contact_number' => '+91 22 2345 6789',
                'registration_deadline' => now()->addDays(14)->toDateString(),
                'eligibility' => 'Open to all U-16 footballers',
                'entry_fee' => '300',
                'required_documents' => json_encode(['Aadhaar Card', 'School ID']),
                'vacancies' => 20,
                'benefits' => 'Trial kit provided',
                'status' => 'published',
            ],
            [
                'name' => 'Swimming Camp Registration',
                'posted_by_user_id' => 3,
                'academy_id' => 1,
                'organization_name' => 'Elite Cricket Academy',
                'sport_id' => 5,
                'event_datetime' => now()->addDays(7)->toDateTimeString(),
                'venue' => 'SGP Sports Complex',
                'google_maps_url' => 'https://maps.google.com/?q=SGP+Sports',
                'city_id' => 1,
                'contact_number' => '+91 98765 43210',
                'registration_deadline' => now()->addDays(3)->toDateString(),
                'eligibility' => 'All age groups welcome',
                'entry_fee' => '500',
                'required_documents' => json_encode(['Medical Certificate']),
                'vacancies' => 50,
                'benefits' => 'Free swimming cap and goggles',
                'status' => 'published',
            ],
        ];

        foreach ($trials as $trial) {
            Trial::updateOrCreate(
                ['name' => $trial['name']],
                $trial
            );
        }

        $this->command->info('Trials seeded: ' . count($trials));
    }
}
