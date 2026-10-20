<?php

namespace Database\Seeders;

use App\Models\Notification;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * In-app notifications for every role.
 *
 * Covers the categories the notification centre and the push pipeline
 * understand: people, opportunities, events, mentions, reminders and
 * broadcasts — plus the hard-override account/registration types that
 * cannot be switched off.
 */
class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            ['user' => 'athlete@sportx.test', 'type' => 'reminder', 'category' => 'reminders', 'title' => 'Trial registration closes tomorrow', 'body' => 'The U-16 Cricket Trial at Ahmedabad closes in 24 hours.', 'action_url' => '/trials', 'read' => false],
            ['user' => 'athlete@sportx.test', 'type' => 'status_update', 'category' => 'opportunities', 'title' => 'Your scholarship application was shortlisted', 'body' => 'You have been shortlisted for the State Cricket Scholarship 2026.', 'action_url' => '/my-opportunities', 'read' => true],
            ['user' => 'athlete@sportx.test', 'type' => 'account_action', 'category' => 'people', 'title' => 'Welcome to SportX', 'body' => 'Your athlete account is active. Complete your profile to unlock discovery.', 'action_url' => '/profile', 'read' => false],
            ['user' => 'rahul@sportx.test', 'type' => 'connection_request', 'category' => 'people', 'title' => 'New connection request', 'body' => 'Diya Nair wants to connect with you.', 'action_url' => '/connection-requests', 'read' => false],
            ['user' => 'rahul@sportx.test', 'type' => 'registration_approved', 'category' => 'events', 'title' => 'Trial registration approved', 'body' => 'Your registration for the U-16 Cricket Trial was approved.', 'action_url' => '/my-registrations', 'read' => false],
            ['user' => 'priya@sportx.test', 'type' => 'guardian_required', 'category' => 'people', 'title' => 'Guardian consent required', 'body' => 'Ask your guardian to verify consent to enable messaging.', 'action_url' => '/guardian-consent', 'read' => false],
            ['user' => 'coach@sportx.test', 'type' => 'enquiry_reply', 'category' => 'people', 'title' => 'New programme enquiry', 'body' => 'John Athlete enquired about Batting Technique — 8 Week Batch.', 'action_url' => '/enquiries', 'read' => false],
            ['user' => 'coach@sportx.test', 'type' => 'registration_approved', 'category' => 'events', 'title' => 'Coaching request approved', 'body' => 'Kabir Khan was approved for your monthly coaching plan.', 'action_url' => '/coach/enrollments', 'read' => false],
            ['user' => 'academy@sportx.test', 'type' => 'enquiry_reply', 'category' => 'people', 'title' => 'New academy enquiry', 'body' => 'Priya Patel asked about the swimming programme timings.', 'action_url' => '/enquiries', 'read' => false],
            ['user' => 'academy@sportx.test', 'type' => 'opportunity_application', 'category' => 'opportunities', 'title' => 'New application received', 'body' => 'Rahul Sharma applied for the State Cricket Scholarship 2026.', 'action_url' => '/my-opportunities', 'read' => false],
            ['user' => 'organizer@sportx.test', 'type' => 'tournament_registration', 'category' => 'events', 'title' => 'New tournament registration', 'body' => 'Aarav Menon registered for the U-18 State Cup.', 'action_url' => '/me/events', 'read' => false],
            ['user' => 'organizer@sportx.test', 'type' => 'broadcast', 'category' => 'broadcasts', 'title' => 'Season 2026 registrations are open', 'body' => 'District leagues are now open for registration across all sports.', 'action_url' => '/me/tournaments', 'read' => false],
            ['user' => 'kiran@scout.test', 'type' => 'scout_connection_request', 'category' => 'people', 'title' => 'Athlete accepted your request', 'body' => 'Rahul Sharma accepted your scouting connection request.', 'action_url' => '/scout-connections', 'read' => false],
            ['user' => 'kiran@scout.test', 'type' => 'mention', 'category' => 'mentions', 'title' => 'You were mentioned', 'body' => 'Aarav Menon mentioned you in a post.', 'action_url' => '/feed', 'read' => false],
            ['user' => 'admin@sportx.test', 'type' => 'moderation', 'category' => 'broadcasts', 'title' => '3 listings waiting for review', 'body' => 'New coach, academy and organizer profiles are awaiting approval.', 'action_url' => '/admin/verification', 'read' => false],
            ['user' => 'admin@sportx.test', 'type' => 'account_action', 'category' => 'people', 'title' => 'New athlete sign-up', 'body' => 'Pending Athlete signed up and is awaiting approval.', 'action_url' => '/admin/users', 'read' => false],
        ];

        $created = 0;

        foreach ($rows as $row) {
            $userId = SeedLookup::userId($row['user']);

            if (! $userId) {
                continue;
            }

            $notification = Notification::firstOrNew([
                'user_id' => $userId,
                'type' => $row['type'],
                'title' => $row['title'],
            ]);

            $notification->fill([
                'channel' => 'in_app',
                'body' => $row['body'],
                'category' => $row['category'],
                'priority' => 'normal',
                'notifiable_type' => null,
                'notifiable_id' => null,
                'action_url' => $row['action_url'],
                'metadata' => null,
                'read_at' => $row['read'] ? now()->subHours(6) : null,
            ]);

            $notification->save();

            $created++;
        }

        $this->command->info('Notifications seeded: '.$created);
    }
}
