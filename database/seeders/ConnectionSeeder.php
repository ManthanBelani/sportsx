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
            ['follower_user_id' => $users[1]->id, 'followee_user_id' => $users[2]->id, 'status' => 'accepted'],
            ['follower_user_id' => $users[2]->id, 'followee_user_id' => $users[1]->id, 'status' => 'accepted'],
            ['follower_user_id' => $users[1]->id, 'followee_user_id' => $users[3]->id, 'status' => 'accepted'],
        ];

        foreach ($connections as $connection) {
            Connection::updateOrCreate(
                [
                    'follower_user_id' => $connection['follower_user_id'],
                    'followee_user_id' => $connection['followee_user_id'],
                ],
                $connection
            );
        }

        $this->command->info('Connections seeded: ' . count($connections));
    }
}
