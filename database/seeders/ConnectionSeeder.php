<?php

namespace Database\Seeders;

use App\Models\Connection;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Connections (Phase 6) between seeded users.
 *
 * Covers every status the API can return: `accepted` (shows in "My
 * connections" and unlocks chat), `pending` (shows in "Connection requests")
 * and `blocked`.
 */
class ConnectionSeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            // Accepted — athlete <-> athlete (unlocks peer DM).
            ['from' => 'athlete@sportx.test', 'to' => 'rahul@sportx.test', 'status' => 'accepted'],
            ['from' => 'rahul@sportx.test', 'to' => 'athlete@sportx.test', 'status' => 'accepted'],
            // Accepted — athlete <-> coach.
            ['from' => 'athlete@sportx.test', 'to' => 'coach@sportx.test', 'status' => 'accepted'],
            // Accepted — coach <-> athlete (reverse side, for the coach inbox).
            ['from' => 'coach@sportx.test', 'to' => 'athlete@sportx.test', 'status' => 'accepted'],
            // Accepted — athlete <-> organizer.
            ['from' => 'aarav@sportx.test', 'to' => 'organizer@sportx.test', 'status' => 'accepted'],
            // Accepted — academy <-> athlete.
            ['from' => 'academy@sportx.test', 'to' => 'priya@sportx.test', 'status' => 'accepted'],
            // Accepted — coach <-> coach.
            ['from' => 'coach@sportx.test', 'to' => 'vikram@sportx.test', 'status' => 'accepted'],
            // Pending — incoming request for athlete@sportx.test.
            ['from' => 'diya@sportx.test', 'to' => 'athlete@sportx.test', 'status' => 'pending'],
            // Pending — incoming request for coach@sportx.test.
            ['from' => 'kabir@sportx.test', 'to' => 'coach@sportx.test', 'status' => 'pending'],
            // Pending — incoming request for the organizer.
            ['from' => 'priya@sportx.test', 'to' => 'organizer@sportx.test', 'status' => 'pending'],
            // Blocked.
            ['from' => 'athlete.suspended@sportx.test', 'to' => 'athlete@sportx.test', 'status' => 'blocked'],
        ];

        $created = 0;

        foreach ($rows as $row) {
            $from = SeedLookup::userId($row['from']);
            $to = SeedLookup::userId($row['to']);

            if (! $from || ! $to) {
                continue;
            }

            Connection::updateOrCreate(
                [
                    'follower_user_id' => $from,
                    'followee_user_id' => $to,
                ],
                ['status' => $row['status']]
            );

            $created++;
        }

        $this->command->info('Connections seeded: '.$created);
    }
}
