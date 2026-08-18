<?php

namespace Database\Seeders;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Database\Seeder;

class DeviceTokenSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::limit(3)->get();

        if ($users->isEmpty()) {
            $this->command->warn('No users found. Run UserSeeder first.');
            return;
        }

        $tokens = [];
        foreach ($users as $index => $user) {
            $tokens[] = [
                'user_id' => $user->id,
                'token' => 'fcm_token_' . $user->id . '_' . bin2hex(random_bytes(8)),
                'platform' => $index % 2 === 0 ? 'android' : 'ios',
            ];
        }

        foreach ($tokens as $token) {
            DeviceToken::updateOrCreate(
                ['user_id' => $token['user_id'], 'token' => $token['token']],
                $token
            );
        }

        $this->command->info('Device tokens seeded: ' . count($tokens));
    }
}
