<?php

namespace Database\Seeders;

use App\Models\Block;
use App\Models\Follow;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * One-way follows and safety blocks (Phase 6).
 *
 * Follows power the "followers / following" screens and the `followers`
 * post visibility, blocks power the safety and reporting flows.
 */
class SocialGraphSeeder extends Seeder
{
    public function run(): void
    {
        $follows = [
            ['from' => 'athlete@sportx.test', 'to' => 'coach@sportx.test'],
            ['from' => 'athlete@sportx.test', 'to' => 'academy@sportx.test'],
            ['from' => 'athlete@sportx.test', 'to' => 'kiran@scout.test'],
            ['from' => 'rahul@sportx.test', 'to' => 'athlete@sportx.test'],
            ['from' => 'rahul@sportx.test', 'to' => 'academy2@sportx.test'],
            ['from' => 'priya@sportx.test', 'to' => 'coach@sportx.test'],
            ['from' => 'aarav@sportx.test', 'to' => 'organizer2@sportx.test'],
            ['from' => 'diya@sportx.test', 'to' => 'coach2@sportx.test'],
            ['from' => 'kabir@sportx.test', 'to' => 'coach@sportx.test'],
            ['from' => 'coach@sportx.test', 'to' => 'athlete@sportx.test'],
            ['from' => 'kiran@scout.test', 'to' => 'rahul@sportx.test'],
            ['from' => 'organizer@sportx.test', 'to' => 'aarav@sportx.test'],
        ];

        $followCount = 0;

        foreach ($follows as $row) {
            $from = SeedLookup::userId($row['from']);
            $to = SeedLookup::userId($row['to']);

            if (! $from || ! $to || $from === $to) {
                continue;
            }

            Follow::firstOrCreate([
                'follower_user_id' => $from,
                'followee_user_id' => $to,
            ]);

            $followCount++;
        }

        $blocks = [
            ['from' => 'athlete.suspended@sportx.test', 'to' => 'athlete@sportx.test'],
            ['from' => 'diya@sportx.test', 'to' => 'coach2@sportx.test'],
        ];

        $blockCount = 0;

        foreach ($blocks as $row) {
            $from = SeedLookup::userId($row['from']);
            $to = SeedLookup::userId($row['to']);

            if (! $from || ! $to || $from === $to) {
                continue;
            }

            Block::firstOrCreate([
                'blocker_user_id' => $from,
                'blocked_user_id' => $to,
            ]);

            $blockCount++;
        }

        $this->command->info('Follows seeded: '.$followCount.' (blocks: '.$blockCount.')');
    }
}
