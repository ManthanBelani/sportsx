<?php

namespace App\Services;

use App\Models\ExpiryEvent;
use App\Models\ExpiryRule;
use App\Models\Scholarship;
use App\Models\Sponsorship;
use App\Models\Tournament;
use App\Models\Trial;

class ExpiryService
{
    /**
     * Map content_type => [model class, trigger column holding the relevant date]
     * Trigger fields per AD8 defaults: trial = event_date, tournament = final_date,
     * sponsorship/scholarship = listed_deadline.
     */
    private const MAP = [
        'trial' => [Trial::class, 'event_datetime', 'event_date'],
        'tournament' => [Tournament::class, 'end_date', 'final_date'],
        'sponsorship' => [Sponsorship::class, 'deadline', 'listed_deadline'],
        'scholarship' => [Scholarship::class, 'deadline', 'listed_deadline'],
    ];

    /**
     * Compute expires_at for a freshly published listing from the active rule.
     * Also registers a pending expiry event for the monitor (AD9).
     */
    public function onPublish(object $listing, string $contentType): void
    {
        [$modelClass, $dateColumn, $triggerField] = self::MAP[$contentType];

        $rule = ExpiryRule::where('content_type', $contentType)->where('is_active', true)->first();

        // Default offsets per AD8 if no rule row exists
        $daysAfter = $rule?->days_after ?? match ($contentType) {
            'trial' => 1,
            'tournament' => 3,
            default => 0,
        };

        $baseDate = $listing->{$dateColumn};
        if (! $baseDate) {
            return;
        }

        $expiresAt = \Carbon\Carbon::parse($baseDate)->endOfDay()->addDays($daysAfter);

        $listing->update(['expires_at' => $expiresAt]);

        // One pending expiry event per listing (replace any existing pending)
        ExpiryEvent::where('content_type', $contentType)
            ->where('content_id', $listing->id)
            ->where('status', 'pending')
            ->delete();

        ExpiryEvent::create([
            'content_type' => $contentType,
            'content_id' => $listing->id,
            'scheduled_at' => $expiresAt,
            'status' => 'pending',
        ]);
    }

    /**
     * Sweep: execute all due pending expiry events.
     * Returns count of listings expired.
     */
    public function sweep(): int
    {
        $due = ExpiryEvent::where('status', 'pending')
            ->where('scheduled_at', '<=', now())
            ->get();

        $count = 0;
        foreach ($due as $event) {
            [$modelClass] = [self::MAP[$event->content_type][0]];
            $listing = $modelClass::find($event->content_id);

            if ($listing && in_array($listing->status ?? '', ['published'])) {
                $listing->update(['status' => 'expired']);
            }

            $event->update(['status' => 'expired', 'executed_at' => now()]);
            $count++;
        }

        return $count;
    }
}
