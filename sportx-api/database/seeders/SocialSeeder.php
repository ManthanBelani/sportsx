<?php

namespace Database\Seeders;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * A legacy group chat with the first three seeded users.
 *
 * The conversation is looked up by its participant set so re-running the
 * seeder does not create a duplicate thread.
 */
class SocialSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::limit(4)->get();

        if ($users->count() < 3) {
            $this->command->warn('Need at least 3 users. Run UserSeeder first.');
            return;
        }

        $participantIds = $users->take(3)->pluck('id')->all();

        $conversation = Conversation::where('type', 'private')
            ->whereHas('participants', fn ($q) => $q->whereIn('user_id', $participantIds))
            ->get()
            ->first(fn (Conversation $c) => $c->participants()->count() === count($participantIds));

        if (! $conversation) {
            $conversation = Conversation::create([
                'type' => 'private',
                'created_at' => now()->subDays(2),
                'updated_at' => now(),
            ]);
        }

        $conversation->participants()->syncWithoutDetaching($participantIds);

        foreach ($participantIds as $participantId) {
            $conversation->participants()->updateExistingPivot($participantId, [
                'last_read_at' => now()->subDays(1),
            ]);
        }

        $messages = [
            ['sender_user_id' => $participantIds[0], 'body' => 'Hey, anyone interested in cricket trials?', 'created_at' => now()->subDays(2)],
            ['sender_user_id' => $participantIds[1], 'body' => 'Yes! I saw the U-14 trials announcement.', 'created_at' => now()->subDays(2)->addMinutes(5)],
            ['sender_user_id' => $participantIds[2], 'body' => 'Count me in! When is the registration deadline?', 'created_at' => now()->subDays(1)],
        ];

        foreach ($messages as $msg) {
            Message::updateOrCreate(
                [
                    'conversation_id' => $conversation->id,
                    'sender_user_id' => $msg['sender_user_id'],
                    'body' => $msg['body'],
                ],
                $msg
            );
        }

        $this->command->info('Social data seeded: 1 conversation, '.count($messages).' messages');
    }
}
