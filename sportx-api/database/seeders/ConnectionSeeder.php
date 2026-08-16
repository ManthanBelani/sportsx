<?php

namespace Database\Seeders;

use App\Models\Connection;
use App\Models\User;
use Illuminate\Database\Seeder;

class ConnectionSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::limit(5)->get();

        if ($users->count() < 3) {
            $this->command->warn('Need at least 3 users. Run UserSeeder first.');
            return;
        }

        $connections = [
            ['follower_id' => $users[1]->id, 'followee_id' => $users[2]->id, 'status' => 'accepted'],
            ['follower_id' => $users[2]->id, 'followee_id' => $users[1]->id, 'status' => 'accepted'],
            ['follower_id' => $users[1]->id, 'followee_id' => $users[3]->id, 'status' => 'accepted'],
        ];

        foreach ($connections as $connection) {
            Connection::updateOrCreate(
                [
                    'follower_id' => $connection['follower_id'],
                    'followee_id' => $connection['followee_id'],
                ],
                array_merge($connection, ['connected_at' => now()->subDays(rand(1, 10))])
            );
        }

        $this->command->info('Connections seeded: ' . count($connections));
    }
}
