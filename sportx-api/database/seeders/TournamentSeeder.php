<?php

namespace Database\Seeders;

use App\Models\OrganizerProfile;
use App\Models\Tournament;
use Illuminate\Database\Seeder;

class TournamentSeeder extends Seeder
{
    public function run(): void
    {
        $organizer = OrganizerProfile::first();

        $tournaments = [
            [
                'name' => 'U-16 State Cup 2026',
                'organizer_id' => $organizer?->id ?? 1,
                'sport_id' => 1,
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
                'organizer_id' => $organizer?->id ?? 1,
                'sport_id' => 2,
                'organizer_name' => 'Gujarat Sports Federation',
                'format' => 'league',
                'start_date' => now()->addDays(30)->toDateString(),
                'end_date' => now()->addDays(40)->toDateString(),
                'registration_deadline' => now()->addDays(15)->toDateString(),
                'venue' => 'Various Venues',
                'city_id' => 1,
                'entry_fee' => '1000',
                'contact_number' => '+91 98111 33333',
                'prize_pool' => '100000',
                'rules' => 'FIFA rules apply',
                'gender' => 'male',
                'status' => 'published',
            ],
        ];

        foreach ($tournaments as $tournament) {
            Tournament::updateOrCreate(
                ['name' => $tournament['name']],
                $tournament
            );
        }

        $this->command->info('Tournaments seeded: ' . count($tournaments));
    }
}
