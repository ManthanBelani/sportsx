<?php

namespace Database\Seeders;

use App\Models\SportsVenue;
use Illuminate\Database\Seeder;

class SportsVenueSeeder extends Seeder
{
    public function run(): void
    {
        $venues = [
            [
                'name' => 'Sardar Patel Stadium',
                'sport_id' => 1,
                'address' => 'Motera, Ahmedabad',
                'google_maps_url' => 'https://maps.google.com/?q=Sardar+Patel+Stadium',
                'contact_number' => '+91 79 2345 6789',
                'city_id' => 1,
                'booking_available' => true,
                'pricing' => json_encode(['nets' => '₹2,000/hour', 'ground' => '₹5,000/day']),
                'facilities' => json_encode(['Floodlights', 'Dressing Rooms', 'Practice Nets', 'Parking']),
                'working_hours' => '6 AM - 10 PM',
                'listing_status' => 'published',
            ],
            [
                'name' => 'Cooperage Ground',
                'sport_id' => 2,
                'address' => 'Colaba, Mumbai',
                'google_maps_url' => 'https://maps.google.com/?q=Cooperage+Ground',
                'contact_number' => '+91 22 2345 6789',
                'city_id' => 5,
                'booking_available' => true,
                'pricing' => json_encode(['ground' => '₹8,000/day']),
                'facilities' => json_encode(['Floodlights', 'Dressing Rooms', 'Parking']),
                'working_hours' => '5 AM - 9 PM',
                'listing_status' => 'published',
            ],
            [
                'name' => 'SGP Sports Complex',
                'sport_id' => 5,
                'address' => 'SG Highway, Ahmedabad',
                'google_maps_url' => 'https://maps.google.com/?q=SGP+Sports+Complex',
                'contact_number' => '+91 79 2345 1234',
                'city_id' => 1,
                'booking_available' => true,
                'pricing' => json_encode(['pool' => '₹500/hour']),
                'facilities' => json_encode(['Indoor Pool', 'Changing Rooms', 'Spectator Area']),
                'working_hours' => '6 AM - 8 PM',
                'listing_status' => 'published',
            ],
        ];

        foreach ($venues as $venue) {
            SportsVenue::updateOrCreate(
                ['name' => $venue['name']],
                $venue
            );
        }

        $this->command->info('Sports venues seeded: ' . count($venues));
    }
}
