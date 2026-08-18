<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SocialSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::limit(4)->get();

        if ($users->count() < 2) {
            $this->command->warn('Need at least 2 users. Run UserSeeder first.');
            return;
        }

        $conversationId = DB::table('conversations')->insertGetId([
            'type' => 'private',
            'created_at' => now()->subDays(2),
            'updated_at' => now(),
        ]);

        foreach ($users->take(3) as $user) {
            DB::table('conversation_participants')->updateOrInsert(
                [
                    'conversation_id' => $conversationId,
                    'user_id' => $user->id,
                ],
                ['last_read_at' => now()->subDays(1), 'updated_at' => now()]
            );
        }

        $messages = [
            ['conversation_id' => $conversationId, 'sender_user_id' => $users[0]->id, 'body' => 'Hey, anyone interested in cricket trials?', 'created_at' => now()->subDays(2)],
            ['conversation_id' => $conversationId, 'sender_user_id' => $users[1]->id, 'body' => 'Yes! I saw the U-14 trials announcement.', 'created_at' => now()->subDays(2)->addMinutes(5)],
            ['conversation_id' => $conversationId, 'sender_user_id' => $users[2]->id, 'body' => 'Count me in! When is the registration deadline?', 'created_at' => now()->subDays(1)],
        ];

        foreach ($messages as $msg) {
            DB::table('messages')->updateOrInsert(
                [
                    'conversation_id' => $msg['conversation_id'],
                    'sender_user_id' => $msg['sender_user_id'],
                    'body' => $msg['body'],
                ],
                $msg
            );
        }

        $this->command->info('Social data seeded: 1 conversation, ' . count($messages) . ' messages');
    }
}
