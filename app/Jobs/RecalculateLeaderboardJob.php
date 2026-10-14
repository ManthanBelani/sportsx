<?php

namespace App\Jobs;

use App\Services\LeaderboardService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class RecalculateLeaderboardJob implements ShouldQueue
{
    use Queueable;

    public function __construct(public ?int $athleteProfileId = null) {}

    public function handle(): void
    {
        if ($this->athleteProfileId) {
            LeaderboardService::recalculateForAthlete($this->athleteProfileId);
        } else {
            LeaderboardService::rebuildAll();
        }
    }
}
