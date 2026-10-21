<?php

namespace Database\Seeders;

use App\Models\OrganizerProfile;
use App\Models\Tournament;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

class TournamentSeeder extends Seeder
{
    public function run(): void
    {
        $cityIds = [1, 2, 3, 4, 5]; // Ahmedabad, Mumbai, Delhi, Bangalore, Chennai

        $tournaments = [
            [
                'name' => 'U-16 State Cup 2026',
                'sport' => 'Cricket',
                                'organizer_name' => 'Gujarat Cricket Federation',
                'format' => 'knockout',
                'start_date' => now()->addDays(21)->toDateString(),
                'end_date' => now()->addDays(26)->toDateString(),
                'registration_deadline' => now()->addDays(10)->toDateString(),
                'venue' => 'GMDC Ground, Ahmedabad',
                'google_maps_url' => 'https://maps.google.com/?q=GMDC+Ground',
                'city_id' => 1,
                'entry_fee' => '500',
                'contact_number' => '+91 98111 22222',
                'registration_link' => 'https://forms.example.com/u16',
                'prize_pool' => '50000',
                'rules' => 'ICC standard rules apply',
                'gender' => 'male',
                'status' => 'published',
            ],
            [
                'name' => 'Inter-City Football Championship',
                'sport' => 'Football',
                                'organizer_name' => 'Gujarat Sports Federation',
                'format' => 'league',
                'start_date' => now()->addDays(30)->toDateString(),
                'end_date' => now()->addDays(40)->toDateString(),
                'registration_deadline' => now()->addDays(15)->toDateString(),
                'venue' => 'Sports Complex, Gandhinagar',
                'city_id' => 1,
                'entry_fee' => '1000',
                'contact_number' => '+91 98111 33333',
                'prize_pool' => '100000',
                'rules' => 'FIFA rules apply',
                'gender' => 'male',
                'status' => 'published',
            ],
            [
                'name' => 'All India Badminton Open 2026',
                'sport' => 'Badminton',
                                'organizer_name' => 'Badminton Association of India',
                'format' => 'knockout',
                'start_date' => now()->addDays(45)->toDateString(),
                'end_date' => now()->addDays(50)->toDateString(),
                'registration_deadline' => now()->addDays(30)->toDateString(),
                'venue' => 'Sardar Patel Stadium, Ahmedabad',
                'google_maps_url' => 'https://maps.google.com/?q=Sardar+Patel+Stadium',
                'city_id' => 1,
                'entry_fee' => '800',
                'contact_number' => '+91 98250 11111',
                'prize_pool' => '75000',
                'rules' => 'BWF rules apply',
                'gender' => 'female',
                'status' => 'published',
            ],
            [
                'name' => 'Mumbai Junior Swimming Championship',
                'sport' => 'Swimming',
                                'organizer_name' => 'Mumbai Swimming Association',
                'format' => 'time-trial',
                'start_date' => now()->addDays(14)->toDateString(),
                'end_date' => now()->addDays(14)->toDateString(),
                'registration_deadline' => now()->addDays(7)->toDateString(),
                'venue' => 'Swimming Pool Complex, Mumbai',
                'city_id' => 2,
                'entry_fee' => '300',
                'contact_number' => '+91 98111 44444',
                'prize_pool' => '25000',
                'rules' => 'FINA rules apply',
                'gender' => 'female',
                'status' => 'published',
            ],
            [
                'name' => 'Delhi Athletics Meet 2026',
                'sport' => 'Athletics',
                                'organizer_name' => 'Delhi Athletics Federation',
                'format' => 'track-field',
                'start_date' => now()->addDays(60)->toDateString(),
                'end_date' => now()->addDays(62)->toDateString(),
                'registration_deadline' => now()->addDays(45)->toDateString(),
                'venue' => 'Jawaharlal Nehru Stadium, Delhi',
                'city_id' => 3,
                'entry_fee' => '200',
                'contact_number' => '+91 98111 55555',
                'prize_pool' => '150000',
                'rules' => 'World Athletics rules',
                'gender' => 'female',
                'status' => 'published',
            ],
            [
                'name' => 'Bangalore Basketball League',
                'sport' => 'Basketball',
                                'organizer_name' => 'Karnataka Basketball Association',
                'format' => 'league-knockout',
                'start_date' => now()->addDays(25)->toDateString(),
                'end_date' => now()->addDays(35)->toDateString(),
                'registration_deadline' => now()->addDays(12)->toDateString(),
                'venue' => 'Kanteerava Indoor Stadium, Bangalore',
                'city_id' => 4,
                'entry_fee' => '600',
                'contact_number' => '+91 98111 66666',
                'prize_pool' => '80000',
                'rules' => 'FIBA rules apply',
                'gender' => 'male',
                'status' => 'published',
            ],
            [
                'name' => 'National Tennis Open 2026',
                'sport' => 'Tennis',
                                'organizer_name' => 'All India Tennis Association',
                'format' => 'knockout',
                'start_date' => now()->addDays(90)->toDateString(),
                'end_date' => now()->addDays(97)->toDateString(),
                'registration_deadline' => now()->addDays(70)->toDateString(),
                'venue' => 'SA Tennis Centre, Chennai',
                'city_id' => 5,
                'entry_fee' => '1500',
                'contact_number' => '+91 98111 77777',
                'prize_pool' => '200000',
                'rules' => 'ITF rules apply',
                'gender' => 'female',
                'status' => 'published',
            ],
            [
                'name' => 'Women Football Cup 2026',
                'sport' => 'Football',
                                'organizer_name' => 'Women Football Association',
                'format' => 'league',
                'start_date' => now()->addDays(35)->toDateString(),
                'end_date' => now()->addDays(50)->toDateString(),
                'registration_deadline' => now()->addDays(20)->toDateString(),
                'venue' => 'DY Patil Stadium, Mumbai',
                'city_id' => 2,
                'entry_fee' => '400',
                'contact_number' => '+91 98111 88888',
                'prize_pool' => '120000',
                'rules' => 'FIFA Women rules apply',
                'gender' => 'female',
                'status' => 'published',
            ],
            [
                'name' => 'Gujarat Kabaddi Championship',
                'sport' => 'Kabaddi',
                                'organizer_name' => 'Gujarat Kabaddi Association',
                'format' => 'league-knockout',
                'start_date' => now()->addDays(18)->toDateString(),
                'end_date' => now()->addDays(25)->toDateString(),
                'registration_deadline' => now()->addDays(8)->toDateString(),
                'venue' => 'Sports Authority Ground, Rajkot',
                'city_id' => 1,
                'entry_fee' => '250',
                'contact_number' => '+91 98111 99999',
                'prize_pool' => '40000',
                'rules' => 'International Kabaddi rules',
                'gender' => 'male',
                'status' => 'published',
            ],
            [
                'name' => 'Junior Chess Tournament 2026',
                'sport' => 'Chess',
                                'organizer_name' => 'Ahmedabad Chess Association',
                'format' => 'swiss',
                'start_date' => now()->addDays(22)->toDateString(),
                'end_date' => now()->addDays(24)->toDateString(),
                'registration_deadline' => now()->addDays(15)->toDateString(),
                'venue' => 'Science City Hall, Ahmedabad',
                'city_id' => 1,
                'entry_fee' => '150',
                'contact_number' => '+91 98260 11111',
                'prize_pool' => '30000',
                'rules' => 'FIDE Swiss System',
                'gender' => 'female',
                'status' => 'published',
            ],
        ];

        foreach ($tournaments as $tournament) {
            // The tournament belongs to the organisation that actually runs
            // it — resolved by name so every organizer only sees their own
            // events in "My Events".
            $organizer = OrganizerProfile::where('organization_name', $tournament['organizer_name'])->first();
            if (! $organizer) {
                $this->command->warn("Organizer profile for {$tournament['organizer_name']} not found. Run OrganizerProfileSeeder first.");
                continue;
            }

            $sportId = SeedLookup::sportId($tournament['sport']);
            if (! $sportId) {
                $this->command->warn("Sport {$tournament['sport']} not found. Run MasterDataSeeder first.");
                continue;
            }

            $attributes = collect($tournament)->except(['sport', 'organizer_name'])->toArray();
            $attributes['sport_id'] = $sportId;
            $attributes['organizer_id'] = $organizer->id;

            Tournament::updateOrCreate(
                ['name' => $tournament['name']],
                $attributes
            );
        }

        $this->command->info('Tournaments seeded: ' . count($tournaments));
    }
}
