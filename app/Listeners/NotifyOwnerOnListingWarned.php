<?php

namespace App\Listeners;

use App\Events\ListingWarned;
use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\Sponsorship;
use App\Models\SportsVenue;
use App\Models\Tournament;
use App\Models\Trial;
use App\Services\NotificationService;

class NotifyOwnerOnListingWarned
{
    public function handle(ListingWarned $event): void
    {
        $listing = $event->listing;
        $ownerUserId = $this->resolveOwnerUserId($listing);

        if (!$ownerUserId) {
            return;
        }

        $typeLabel = $this->getListingTypeLabel($listing);
        $name = $listing->name ?? $listing->title ?? 'Your listing';
        $body = $event->message
            ? "Warning: \"{$name}\" ({$typeLabel}) received a moderation warning: {$event->message}"
            : "Warning: \"{$name}\" ({$typeLabel}) has received a moderation warning. Please review and correct any issues.";

        NotificationService::createStatic([
            'user_id' => $ownerUserId,
            'type' => 'status_update',
            'title' => 'Listing warning',
            'body' => $body,
            'notifiable_type' => class_basename($listing),
            'notifiable_id' => $listing->id,
            'action_url' => null,
        ]);
    }

    private function resolveOwnerUserId($listing): ?int
    {
        if ($listing instanceof Trial) {
            return (int) $listing->posted_by_user_id;
        }
        if ($listing instanceof Tournament) {
            return (int) $listing->organizer?->user_id;
        }
        if ($listing instanceof Academy) {
            return (int) $listing->owner_user_id;
        }
        if ($listing instanceof CoachProfile) {
            return (int) $listing->user_id;
        }
        if ($listing instanceof Sponsorship) {
            return (int) $listing->sponsor?->user_id;
        }
        if ($listing instanceof \App\Models\Scholarship) {
            return (int) $listing->created_by;
        }
        if ($listing instanceof SportsVenue) {
            return null;
        }
        return $listing->user_id ?? $listing->owner_user_id ?? null;
    }

    private function getListingTypeLabel($listing): string
    {
        return match (true) {
            $listing instanceof Trial => 'trial',
            $listing instanceof Tournament => 'tournament',
            $listing instanceof Academy => 'academy',
            $listing instanceof CoachProfile => 'coach profile',
            $listing instanceof Sponsorship => 'sponsorship',
            $listing instanceof \App\Models\Scholarship => 'scholarship',
            $listing instanceof SportsVenue => 'sports venue',
            default => 'listing',
        };
    }
}
