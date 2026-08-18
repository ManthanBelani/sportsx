<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\ShortlistEntry;
use App\Models\SponsorProfile;
use Illuminate\Database\Seeder;

class ShortlistEntrySeeder extends Seeder
{
    public function run(): void
    {
        $sponsor = SponsorProfile::first();
        $athletes = AthleteProfile::limit(2)->get();

        if (!$sponsor) {
            $this->command->warn('No sponsor profile found. Run SponsorProfileSeeder first.');
            return;
        }

        $count = 0;
        foreach ($athletes as $athlete) {
            ShortlistEntry::firstOrCreate(
                [
                    'sponsor_id' => $sponsor->id,
                    'athlete_id' => $athlete->id,
                ],
                [
                    'note' => 'Promising athlete with good performance records',
                ]
            );
            $count++;
        }

        $this->command->info('Shortlist entries seeded: ' . $count);
    }
}
