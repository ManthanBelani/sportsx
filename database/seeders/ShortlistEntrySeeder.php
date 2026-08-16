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

        $entries = [];
        foreach ($athletes as $index => $athlete) {
            $entries[] = [
                'sponsor_id' => $sponsor->id,
                'athlete_profile_id' => $athlete->id,
                'status' => 'shortlisted',
                'notes' => 'Promising athlete with good performance records',
                'shortlisted_at' => now()->subDays(rand(1, 5))->toDateTimeString(),
            ];
        }

        foreach ($entries as $entry) {
            ShortlistEntry::updateOrCreate(
                [
                    'sponsor_id' => $entry['sponsor_id'],
                    'athlete_profile_id' => $entry['athlete_profile_id'],
                ],
                $entry
            );
        }

        $this->command->info('Shortlist entries seeded: ' . count($entries));
    }
}
