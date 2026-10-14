<?php

namespace App\Jobs;

use App\Models\LeaderboardSeason;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ResetLeaderboardSeasonJob implements ShouldQueue
{
    use Queueable;

    public function __construct(public string $name = '') {}

    public function handle(): void
    {
        LeaderboardSeason::where('is_active', true)->update(['is_active' => false]);
        LeaderboardSeason::create([
            'name' => $this->name !== '' ? $this->name : now()->format('Y').' Season',
            'starts_on' => now()->toDateString(),
            'is_active' => true,
        ]);
    }
}
