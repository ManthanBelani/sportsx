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

        $count = 0;
        EnquiryMessage::create([
            'enquiry_id' => $enquiry->id,
            'sender_user_id' => $users->first()?->id ?? 2,
            'body' => 'I am interested in joining your cricket academy. What are the trial dates?',
        ]);
        $count++;

        EnquiryMessage::create([
            'enquiry_id' => $enquiry->id,
            'sender_user_id' => $users->last()?->id ?? 3,
            'body' => 'Thank you for your interest! We have trials scheduled for next month.',
            'read_at' => now(),
        ]);
        $count++;

        $this->command->info('Enquiry messages seeded: ' . $count);
    }
}
