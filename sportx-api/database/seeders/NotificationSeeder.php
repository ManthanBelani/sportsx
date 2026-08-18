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
        $types = ['reminder', 'status_update', 'enquiry_reply'];
        $titles = [
            'New trial available in your city!',
            'Tournament registration closing soon',
            'Scholarship deadline approaching',
        ];

        $count = 0;
        foreach ($users as $index => $user) {
            if ($count < 5) {
                DB::table('notifications')->insert([
                    'user_id' => $user->id,
                    'type' => $types[$index % count($types)],
                    'title' => $titles[$index % count($titles)],
                    'body' => 'This is a test notification message.',
                    'read_at' => $index === 0 ? now() : null,
                    'created_at' => now()->subHours(rand(1, 48)),
                    'updated_at' => now()->subHours(rand(1, 48)),
                ]);
                $count++;
            }
        }

        $this->command->info('Notifications seeded: ' . $count);
    }
}
