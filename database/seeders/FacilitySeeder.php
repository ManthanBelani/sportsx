<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\Facility;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Academy facilities (Phase 5) — the per-academy "what we offer" list.
 */
class FacilitySeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            [
                'academy' => 'academy@sportx.test',
                'name' => 'Main Turf Ground',
                'type' => 'ground',
                'size' => 'Standard 22 yard strip, 200x90 m outfield',
                'amenities' => ['Flood lights', 'Practice wickets', 'Changing rooms', 'Drinking water'],
            ],
            [
                'academy' => 'academy@sportx.test',
                'name' => 'Batting Nets (6)',
                'type' => 'indoor',
                'size' => '6 covered net bays',
                'amenities' => ['Bowling machines', 'Video analysis bay', 'Covered roof'],
            ],
            [
                'academy' => 'academy@sportx.test',
                'name' => 'Strength & Conditioning Gym',
                'type' => 'gym',
                'size' => '1200 sq ft',
                'amenities' => ['Free weights', 'Functional training rig', 'Trainer on site'],
            ],
            [
                'academy' => 'mca@sportx.test',
                'name' => 'Cricket Academy Ground',
                'type' => 'ground',
                'size' => 'Two pitches with square boundary',
                'amenities' => ['Crane', 'Flood lights', 'Cafeteria'],
            ],
            [
                'academy' => 'mca@sportx.test',
                'name' => 'Swimming Pool',
                'type' => 'indoor',
                'size' => '25 m, 6 lanes',
                'amenities' => ['Olympic starting blocks', 'Pool-side trainer'],
            ],
            [
                'academy' => 'academy2@sportx.test',
                'name' => 'Football Turf',
                'type' => 'ground',
                'size' => '110x70 m artificial turf',
                'amenities' => ['Flood lights', 'Goal nets', 'Team benches'],
            ],
            [
                'academy' => 'academy2@sportx.test',
                'name' => 'Sports Hall',
                'type' => 'indoor',
                'size' => '30x20 m wooden floor',
                'amenities' => ['Basketball hoops', 'Volleyball nets', 'Air conditioning'],
            ],
        ];

        $created = 0;

        foreach ($rows as $row) {
            $academy = Academy::where('owner_user_id', SeedLookup::userId($row['academy']))->first();

            if (! $academy) {
                $this->command->warn('Academy not found for '.$row['academy'].'. Run AcademySeeder first.');
                continue;
            }

            Facility::updateOrCreate(
                [
                    'academy_id' => $academy->id,
                    'name' => $row['name'],
                ],
                [
                    'type' => $row['type'],
                    'size' => $row['size'],
                    'amenities' => $row['amenities'],
                    'image_media_ids' => [],
                ]
            );

            $created++;
        }

        $this->command->info('Facilities seeded: '.$created);
    }
}
