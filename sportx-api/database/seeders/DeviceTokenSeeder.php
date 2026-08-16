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
                'device_token' => 'fcm_token_' . $user->id . '_' . bin2hex(random_bytes(8)),
                'device_type' => $index % 2 === 0 ? 'android' : 'ios',
                'device_name' => 'Device ' . ($index + 1),
                'is_active' => true,
            ];
        }

        foreach ($tokens as $token) {
            DeviceToken::updateOrCreate(
                ['user_id' => $token['user_id'], 'device_token' => $token['device_token']],
                $token
            );
        }

        $this->command->info('Device tokens seeded: ' . count($tokens));
    }
}
