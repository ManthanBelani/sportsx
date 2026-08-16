<?php

namespace Database\Seeders;

use App\Models\Enquiry;
use App\Models\EnquiryMessage;
use App\Models\User;
use Illuminate\Database\Seeder;

class EnquiryMessageSeeder extends Seeder
{
    public function run(): void
    {
        $enquiry = Enquiry::first();
        $users = User::limit(2)->get();

        if (!$enquiry) {
            $this->command->warn('No enquiry found. Run EnquirySeeder first.');
            return;
        }

        $messages = [
            [
                'enquiry_id' => $enquiry->id,
                'sender_id' => $users->first()?->id ?? 2,
                'message' => 'I am interested in joining your cricket academy. What are the trial dates?',
                'is_read' => true,
            ],
            [
                'enquiry_id' => $enquiry->id,
                'sender_id' => $users->last()?->id ?? 3,
                'message' => 'Thank you for your interest! We have trials scheduled for next month.',
                'is_read' => true,
            ],
        ];

        foreach ($messages as $message) {
            EnquiryMessage::updateOrCreate(
                [
                    'enquiry_id' => $message['enquiry_id'],
                    'sender_id' => $message['sender_id'],
                    'message' => $message['message'],
                ],
                $message
            );
        }

        $this->command->info('Enquiry messages seeded: ' . count($messages));
    }
}
