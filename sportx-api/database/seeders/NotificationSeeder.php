<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::limit(5)->get();

        if ($users->isEmpty()) {
            $this->command->warn('No users found. Run UserSeeder first.');
            return;
        }

        $notifications = [];
        $types = ['trial', 'tournament', 'scholarship', 'sponsorship', 'system'];
        $titles = [
            'New trial available in your city!',
            'Tournament registration closing soon',
            'Scholarship deadline approaching',
            'Your sponsorship application was approved',
            'Welcome to SportX!',
        ];

        foreach ($users as $index => $user) {
            $notifications[] = [
                'user_id' => $user->id,
                'type' => $types[$index % count($types)],
                'title' => $titles[$index % count($titles)],
                'message' => 'This is a test notification message.',
                'data' => json_encode(['item_id' => $index + 1]),
                'is_read' => $index === 0,
                'created_at' => now()->subHours(rand(1, 48)),
            ];
        }

        foreach ($notifications as $notification) {
            DB::table('notifications')->updateOrInsert(
                [
                    'user_id' => $notification['user_id'],
                    'type' => $notification['type'],
                    'title' => $notification['title'],
                ],
                $notification
            );
        }

        $this->command->info('Notifications seeded: ' . count($notifications));
    }
}
