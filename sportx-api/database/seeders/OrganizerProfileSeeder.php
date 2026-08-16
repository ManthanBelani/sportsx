<?php

namespace Database\Seeders;

use App\Models\OrganizerProfile;
use App\Models\User;
use Illuminate\Database\Seeder;

class OrganizerProfileSeeder extends Seeder
{
    public function run(): void
    {
        $organizers = User::where('role', 'organizer')->get();

        if ($organizers->isEmpty()) {
            $this->command->warn('No organizer users found. Run UserSeeder first.');
            return;
        }

        $profiles = [
            [
                'user_id' => 5,
                'organization_name' => 'Gujarat Sports Federation',
                'org_type' => 'federation',
                'contact_person' => 'Rohan Desai',
                'phone' => '+91 79 2345 6789',
                'email' => 'info@gsf.example.com',
                'address' => 'Sports Authority Building, Ahmedabad',
                'city_id' => 1,
                'description' => 'Official sports governing body for Gujarat',
                'website' => 'https://gsf.example.com',
                'status' => 'active',
            ],
        ];

        foreach ($profiles as $profile) {
            OrganizerProfile::updateOrCreate(
                ['user_id' => $profile['user_id']],
                $profile
            );
        }

        $this->command->info('Organizer profiles seeded: ' . count($profiles));
    }
}
