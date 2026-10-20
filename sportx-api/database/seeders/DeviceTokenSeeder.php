<?php

namespace Database\Seeders;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Legacy FCM device tokens.
 *
 * The token is the natural key, so the fixtures use deterministic values and
 * the seeder can be re-run without piling up duplicates.
 */
class DeviceTokenSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::whereIn('role', ['athlete', 'coach', 'academy', 'organizer', 'talent_scout'])
            ->orderBy('id')
            ->limit(8)
            ->get();

        if ($users->isEmpty()) {
            $this->command->warn('No users found. Run UserSeeder first.');
            return;
        }

        $count = 0;

        foreach ($users as $index => $user) {
            $token = 'seed_legacy_fcm_'.$user->id;

            DeviceToken::updateOrCreate(
                ['token' => $token],
                [
                    'user_id' => $user->id,
                    'platform' => $index % 2 === 0 ? 'android' : 'ios',
                    'last_used_at' => now()->subHours(4),
                ]
            );

            $count++;
        }

        $this->command->info('Device tokens seeded: '.$count);
    }
}
