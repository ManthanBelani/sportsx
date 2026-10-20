<?php

namespace Database\Seeders;

use App\Models\Enquiry;
use App\Models\EnquiryMessage;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Enquiry thread messages.
 *
 * Keyed on (enquiry, sender, body) so re-running the seeder does not stack
 * duplicate replies on the same thread.
 */
class EnquiryMessageSeeder extends Seeder
{
    public function run(): void
    {
        $athleteUserId = SeedLookup::userId('athlete@sportx.test');
        $coachUserId = SeedLookup::userId('coach@sportx.test');
        $academyUserId = SeedLookup::userId('academy@sportx.test');
        $organizerUserId = SeedLookup::userId('organizer@sportx.test');

        $enquiries = Enquiry::orderBy('id')->get();

        if ($enquiries->isEmpty()) {
            $this->command->warn('No enquiries found. Run EnquirySeeder first.');
            return;
        }

        $threads = [
            ['subject_type' => 'academy', 'messages' => [
                ['from' => $athleteUserId, 'body' => 'I am interested in joining your cricket academy. What are the trial dates?', 'read' => true],
                ['from' => $academyUserId, 'body' => 'Thank you for your interest! We have trials scheduled for next month.', 'read' => null],
            ]],
            ['subject_type' => 'coach_profile', 'messages' => [
                ['from' => $athleteUserId, 'body' => 'Do you have a slot for a weekday evening batch?', 'read' => true],
                ['from' => $coachUserId, 'body' => 'Yes — Mon/Wed/Fri at 4 PM works. Shall we start next week?', 'read' => null],
            ]],
            ['subject_type' => 'program', 'messages' => [
                ['from' => $athleteUserId, 'body' => 'Is the 8 week batting batch suitable for an U-16 player?', 'read' => true],
            ]],
            ['subject_type' => 'trial', 'messages' => [
                ['from' => $athleteUserId, 'body' => 'What documents do I need to bring for the trial?', 'read' => false],
                ['from' => $organizerUserId, 'body' => 'Please carry a printed birth certificate and your school ID.', 'read' => null],
            ]],
        ];

        $count = 0;

        foreach ($threads as $thread) {
            $enquiry = $enquiries->firstWhere('subject_type', $thread['subject_type']);

            if (! $enquiry) {
                continue;
            }

            foreach ($thread['messages'] as $message) {
                EnquiryMessage::updateOrCreate(
                    [
                        'enquiry_id' => $enquiry->id,
                        'sender_user_id' => $message['from'],
                        'body' => $message['body'],
                    ],
                    [
                        'read_at' => $message['read'] ? now()->subHours(4) : null,
                    ]
                );

                $count++;
            }
        }

        $this->command->info('Enquiry messages seeded: '.$count);
    }
}
