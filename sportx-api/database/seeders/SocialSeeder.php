<?php

namespace Database\Seeders;

use App\Models\Conversation;
use App\Models\ConversationParticipant;
use App\Models\Message;
use App\Models\User;
use Illuminate\Database\Seeder;

class SocialSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::limit(4)->get();

        if ($users->count() < 2) {
            $this->command->warn('Need at least 2 users. Run UserSeeder first.');
            return;
        }

        $conversation = Conversation::updateOrCreate(
            ['id' => 1],
            ['created_at' => now()->subDays(2), 'updated_at' => now()]
        );

        foreach ($users->take(3) as $user) {
            ConversationParticipant::updateOrCreate(
                [
                    'conversation_id' => $conversation->id,
                    'user_id' => $user->id,
                ],
                ['joined_at' => now()->subDays(2)]
            );
        }

        $messages = [
            ['conversation_id' => 1, 'sender_id' => $users[0]->id, 'message' => 'Hey, anyone interested in cricket trials?', 'created_at' => now()->subDays(2)],
            ['conversation_id' => 1, 'sender_id' => $users[1]->id, 'message' => 'Yes! I saw the U-14 trials announcement.', 'created_at' => now()->subDays(2)->addMinutes(5)],
            ['conversation_id' => 1, 'sender_id' => $users[2]->id, 'message' => 'Count me in! When is the registration deadline?', 'created_at' => now()->subDays(1)],
        ];

        foreach ($messages as $msg) {
            Message::updateOrCreate(
                [
                    'conversation_id' => $msg['conversation_id'],
                    'sender_id' => $msg['sender_id'],
                    'message' => $msg['message'],
                ],
                $msg
            );
        }

        $this->command->info('Social data seeded: 1 conversation, ' . count($messages) . ' messages');
    }
}
