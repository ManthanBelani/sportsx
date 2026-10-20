<?php

namespace Database\Seeders;

use App\Models\ExpiryEvent;
use App\Models\ExpiryRule;
use App\Models\Opportunity;
use App\Models\Tournament;
use App\Models\Trial;
use Illuminate\Database\Seeder;

/**
 * Expiry rules and the pending expiry queue (gap-closure work).
 *
 * The rules mirror the AD8 defaults, and the pending events line up with the
 * published trials / tournaments / opportunities so the expiry sweep has real
 * work to do.
 */
class ExpirySeeder extends Seeder
{
    public function run(): void
    {
        $rules = [
            ['content_type' => 'trial', 'trigger_field' => 'event_date', 'days_after' => 1],
            ['content_type' => 'tournament', 'trigger_field' => 'final_date', 'days_after' => 3],
            ['content_type' => 'sponsorship', 'trigger_field' => 'listed_deadline', 'days_after' => 0],
            ['content_type' => 'scholarship', 'trigger_field' => 'listed_deadline', 'days_after' => 0],
            ['content_type' => 'opportunity', 'trigger_field' => 'listed_deadline', 'days_after' => 0],
            ['content_type' => 'program', 'trigger_field' => 'listed_deadline', 'days_after' => 30],
        ];

        foreach ($rules as $rule) {
            ExpiryRule::updateOrCreate(
                [
                    'content_type' => $rule['content_type'],
                    'trigger_field' => $rule['trigger_field'],
                ],
                [
                    'days_after' => $rule['days_after'],
                    'is_active' => true,
                ]
            );
        }

        $events = 0;

        foreach (Trial::where('status', 'published')->get() as $trial) {
            $scheduledAt = \Carbon\Carbon::parse($trial->event_datetime)->endOfDay()->addDay();

            ExpiryEvent::updateOrCreate(
                [
                    'content_type' => 'trial',
                    'content_id' => $trial->id,
                    'status' => 'pending',
                ],
                ['scheduled_at' => $scheduledAt]
            );
            $events++;
        }

        foreach (Tournament::where('status', 'published')->get() as $tournament) {
            $scheduledAt = \Carbon\Carbon::parse($tournament->end_date ?? $tournament->start_date)
                ->endOfDay()
                ->addDays(3);

            ExpiryEvent::updateOrCreate(
                [
                    'content_type' => 'tournament',
                    'content_id' => $tournament->id,
                    'status' => 'pending',
                ],
                ['scheduled_at' => $scheduledAt]
            );
            $events++;
        }

        foreach (Opportunity::where('status', 'published')->get() as $opportunity) {
            if (! $opportunity->deadline) {
                continue;
            }

            ExpiryEvent::updateOrCreate(
                [
                    'content_type' => 'opportunity',
                    'content_id' => $opportunity->id,
                    'status' => 'pending',
                ],
                ['scheduled_at' => \Carbon\Carbon::parse($opportunity->deadline)->endOfDay()]
            );
            $events++;
        }

        $this->command->info('Expiry seeded: '.count($rules).' rules, '.$events.' pending events');
    }
}
