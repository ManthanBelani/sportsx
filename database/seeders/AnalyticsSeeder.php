<?php

namespace Database\Seeders;

use App\Models\AnalyticsEvent;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Product analytics events (Phase 9).
 *
 * Powers the organizer/admin analytics dashboards with a realistic trail of
 * screen views, searches and list actions.
 */
class AnalyticsSeeder extends Seeder
{
    public function run(): void
    {
        $events = [
            ['user' => 'athlete@sportx.test', 'event' => 'screen_view', 'props' => ['screen' => 'home', 'role' => 'athlete']],
            ['user' => 'athlete@sportx.test', 'event' => 'screen_view', 'props' => ['screen' => 'explore', 'role' => 'athlete']],
            ['user' => 'athlete@sportx.test', 'event' => 'search', 'props' => ['query' => 'cricket trial', 'results' => 12]],
            ['user' => 'athlete@sportx.test', 'event' => 'listing_open', 'props' => ['type' => 'trial', 'id' => 1]],
            ['user' => 'rahul@sportx.test', 'event' => 'screen_view', 'props' => ['screen' => 'home', 'role' => 'athlete']],
            ['user' => 'rahul@sportx.test', 'event' => 'apply', 'props' => ['type' => 'trial', 'id' => 1]],
            ['user' => 'priya@sportx.test', 'event' => 'screen_view', 'props' => ['screen' => 'opportunities', 'role' => 'athlete']],
            ['user' => 'aarav@sportx.test', 'event' => 'search', 'props' => ['query' => 'basketball coach', 'results' => 4]],
            ['user' => 'diya@sportx.test', 'event' => 'screen_view', 'props' => ['screen' => 'leaderboard', 'role' => 'athlete']],
            ['user' => 'kabir@sportx.test', 'event' => 'save', 'props' => ['type' => 'program', 'id' => 1]],
            ['user' => 'coach@sportx.test', 'event' => 'screen_view', 'props' => ['screen' => 'coach-dashboard', 'role' => 'coach']],
            ['user' => 'coach@sportx.test', 'event' => 'profile_view', 'props' => ['profile' => 'coach', 'id' => 1]],
            ['user' => 'academy@sportx.test', 'event' => 'screen_view', 'props' => ['screen' => 'academy-dashboard', 'role' => 'academy']],
            ['user' => 'academy@sportx.test', 'event' => 'enquiry_reply', 'props' => ['enquiry_id' => 1]],
            ['user' => 'organizer@sportx.test', 'event' => 'screen_view', 'props' => ['screen' => 'organizer-dashboard', 'role' => 'organizer']],
            ['user' => 'organizer@sportx.test', 'event' => 'event_publish', 'props' => ['type' => 'tournament', 'id' => 1]],
            ['user' => 'kiran@scout.test', 'event' => 'screen_view', 'props' => ['screen' => 'scout-dashboard', 'role' => 'scout']],
            ['user' => 'kiran@scout.test', 'event' => 'shortlist_add', 'props' => ['athlete_profile_id' => 1]],
            ['user' => 'admin@sportx.test', 'event' => 'screen_view', 'props' => ['screen' => 'admin-dashboard', 'role' => 'admin']],
            ['user' => 'admin@sportx.test', 'event' => 'moderation_queue', 'props' => ['count' => 3]],
        ];

        $created = 0;

        // Analytics rows have no natural key, so previous seeded rows are
        // cleared first (identified by the `seed_ref` marker) to keep the
        // seeder idempotent.
        AnalyticsEvent::where('props', 'like', '%"seed_ref":"sportx"%')->delete();

        foreach ($events as $row) {
            $userId = SeedLookup::userId($row['user']);

            AnalyticsEvent::create([
                'user_id' => $userId,
                'event' => $row['event'],
                'props' => array_merge($row['props'], ['seed_ref' => 'sportx']),
                'created_at' => now()->subHours(random_int(1, 72)),
                'updated_at' => now()->subHours(random_int(1, 72)),
            ]);

            $created++;
        }

        $this->command->info('Analytics events seeded: '.$created);
    }
}
