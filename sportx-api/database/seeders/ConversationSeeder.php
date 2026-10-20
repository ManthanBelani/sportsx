<?php

namespace Database\Seeders;

use App\Models\Conversation;
use App\Models\Message;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Chat threads (Phase 6).
 *
 * Private threads are opened between pairs that are already connected
 * (athlete <-> athlete) and between providers and athletes, plus a group
 * thread so the group-chat UI has something to render.
 */
class ConversationSeeder extends Seeder
{
    public function run(): void
    {
        $threads = [
            [
                'key' => 'john-rahul',
                'type' => 'private',
                'title' => null,
                'participants' => ['athlete@sportx.test', 'rahul@sportx.test'],
                'messages' => [
                    ['from' => 'athlete@sportx.test', 'body' => 'Hey Rahul, are you joining the U-18 state camp next month?', 'type' => 'text'],
                    ['from' => 'rahul@sportx.test', 'body' => 'Yes! Trials are on the 12th, I have already registered.', 'type' => 'text'],
                    ['from' => 'athlete@sportx.test', 'body' => 'Great, let us travel together.', 'type' => 'text'],
                ],
            ],
            [
                'key' => 'john-coach',
                'type' => 'private',
                'title' => null,
                'participants' => ['athlete@sportx.test', 'coach@sportx.test'],
                'messages' => [
                    ['from' => 'coach@sportx.test', 'body' => 'Your drill video looks good. Focus on front-foot defence this week.', 'type' => 'text'],
                    ['from' => 'athlete@sportx.test', 'body' => 'Thanks coach, I will send an update on Sunday.', 'type' => 'text'],
                ],
            ],
            [
                'key' => 'aarav-organizer',
                'type' => 'private',
                'title' => null,
                'participants' => ['aarav@sportx.test', 'organizer@sportx.test'],
                'messages' => [
                    ['from' => 'organizer@sportx.test', 'body' => 'We would like to sponsor you for the district league season.', 'type' => 'text'],
                    ['from' => 'aarav@sportx.test', 'body' => 'Thank you. Can you share the kit size and the schedule?', 'type' => 'text'],
                ],
            ],
            [
                'key' => 'academy-priya',
                'type' => 'private',
                'title' => null,
                'participants' => ['academy@sportx.test', 'priya@sportx.test'],
                'messages' => [
                    ['from' => 'academy@sportx.test', 'body' => 'Your fee instalment for this month is due on the 10th.', 'type' => 'text'],
                ],
            ],
            [
                'key' => 'u16-group',
                'type' => 'group',
                'title' => 'U-16 Cricket Batch — WhatsApp Group',
                'participants' => ['athlete@sportx.test', 'rahul@sportx.test', 'coach@sportx.test', 'academy@sportx.test'],
                'messages' => [
                    ['from' => 'coach@sportx.test', 'body' => 'Practice is moved to 5 PM tomorrow due to the heat.', 'type' => 'system'],
                    ['from' => 'rahul@sportx.test', 'body' => 'Noted, I will be there by 4:45.', 'type' => 'text'],
                    ['from' => 'athlete@sportx.test', 'body' => 'Same here. Bringing the new practice bat.', 'type' => 'text'],
                ],
            ],
        ];

        $created = 0;

        foreach ($threads as $thread) {
            $participantIds = [];
            foreach ($thread['participants'] as $email) {
                $id = SeedLookup::userId($email);
                if ($id) {
                    $participantIds[] = $id;
                }
            }

            if (count($participantIds) < 2) {
                continue;
            }

            $conversation = $this->resolveConversation($thread, $participantIds);

            $conversation->participants()->sync($participantIds);

            $existing = $conversation->messages()->count();
            if ($existing === 0) {
                foreach ($thread['messages'] as $message) {
                    Message::create([
                        'conversation_id' => $conversation->id,
                        'sender_user_id' => SeedLookup::userId($message['from']),
                        'body' => $message['body'],
                        'type' => $message['type'],
                    ]);
                }
            }

            $conversation->touch();

            $created++;
        }

        $this->command->info('Conversations seeded: '.$created);
    }

    /**
     * Private threads are identified by their participant pair (a null title
     * would otherwise match every other private thread), group threads by
     * their title.
     *
     * @param  array<int, int>  $participantIds
     */
    private function resolveConversation(array $thread, array $participantIds): Conversation
    {
        if ($thread['type'] === 'group') {
            return Conversation::firstOrCreate(
                ['type' => 'group', 'title' => $thread['title']],
                ['type' => 'group', 'title' => $thread['title']]
            );
        }

        $existing = Conversation::where('type', 'private')
            ->whereHas('participants', fn ($q) => $q->whereIn('user_id', $participantIds))
            ->get()
            ->filter(function (Conversation $conversation) use ($participantIds) {
                return $conversation->participants()->count() === count($participantIds);
            })
            ->first();

        if ($existing) {
            return $existing;
        }

        return Conversation::create(['type' => 'private']);
    }
}
