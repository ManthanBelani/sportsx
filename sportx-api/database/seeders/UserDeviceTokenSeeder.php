<?php

namespace Database\Seeders;

use App\Models\UserDeviceToken;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * FCM device registrations (Phase 2 push hardening).
 *
 * The `token` column is UNIQUE, so the fixtures use deterministic tokens that
 * survive a re-seed.
 */
class UserDeviceTokenSeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            ['user' => 'athlete@sportx.test', 'device_type' => 'android', 'device_id' => 'pixel-8-emulator', 'is_active' => true, 'failure_count' => 0],
            ['user' => 'athlete@sportx.test', 'device_type' => 'ios', 'device_id' => 'iphone-15-simulator', 'is_active' => true, 'failure_count' => 0],
            ['user' => 'rahul@sportx.test', 'device_type' => 'android', 'device_id' => 'pixel-7a-device', 'is_active' => true, 'failure_count' => 0],
            ['user' => 'priya@sportx.test', 'device_type' => 'android', 'device_id' => 'samsung-a54-device', 'is_active' => true, 'failure_count' => 1],
            ['user' => 'coach@sportx.test', 'device_type' => 'web', 'device_id' => 'chrome-desktop', 'is_active' => true, 'failure_count' => 0],
            ['user' => 'academy@sportx.test', 'device_type' => 'web', 'device_id' => 'chrome-office', 'is_active' => true, 'failure_count' => 0],
            ['user' => 'organizer@sportx.test', 'device_type' => 'ios', 'device_id' => 'iphone-14-device', 'is_active' => false, 'failure_count' => 5],
            ['user' => 'kiran@scout.test', 'device_type' => 'android', 'device_id' => 'oneplus-device', 'is_active' => true, 'failure_count' => 0],
            ['user' => 'admin@sportx.test', 'device_type' => 'web', 'device_id' => 'chrome-admin', 'is_active' => true, 'failure_count' => 0],
        ];

        $created = 0;

        foreach ($rows as $row) {
            $userId = SeedLookup::userId($row['user']);

            if (! $userId) {
                continue;
            }

            $token = 'seed_fcm_'.strtolower(str_replace(['@', '.'], '_', $row['user'])).'_'.$row['device_id'];

            UserDeviceToken::updateOrCreate(
                ['token' => $token],
                [
                    'user_id' => $userId,
                    'device_type' => $row['device_type'],
                    'device_id' => $row['device_id'],
                    'is_active' => $row['is_active'],
                    'failure_count' => $row['failure_count'],
                    'last_seen_at' => now()->subHours(6),
                ]
            );

            $created++;
        }

        $this->command->info('User device tokens seeded: '.$created);
    }
}
