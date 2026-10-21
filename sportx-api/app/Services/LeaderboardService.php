<?php

namespace App\Services;

use App\Models\Achievement;
use App\Models\AthleteProfile;
use App\Models\LeaderboardScore;
use App\Models\LeaderboardSeason;
use App\Models\TrialRegistration;
use App\Models\TournamentRegistration;
use Illuminate\Support\Facades\Schema;

/**
 * Credibility engine (Phase 7).
 * Points (active season, per athlete x sport):
 *  - verified achievement: 50 (only verified achievements count)
 *  - profile completion milestone (>=80%): 20
 *  - event participation (approved registration): 10 each, capped at 50
 * Minors are anonymized at presentation (first name + initial), never here.
 */
class LeaderboardService
{
    public const POINTS_VERIFIED_ACHIEVEMENT = 50;

    public const POINTS_COMPLETION_MILESTONE = 20;

    public const POINTS_PARTICIPATION = 10;

    public const PARTICIPATION_CAP = 50;

    public static function activeSeason(): LeaderboardSeason
    {
        return LeaderboardSeason::where('is_active', true)->latest('id')->first()
            ?? LeaderboardSeason::create([
                'name' => now()->format('Y').' Season',
                'starts_on' => now()->startOfYear()->toDateString(),
                'is_active' => true,
            ]);
    }

    public static function recalculateForAthlete(int $athleteProfileId): void
    {
        $athlete = AthleteProfile::find($athleteProfileId);
        if (!$athlete) {
            return;
        }
        $season = static::activeSeason();
        $sportIds = static::sportIdsFor($athlete);

        foreach ($sportIds as $sportId) {
            $points = 0;

            // Verified achievements only.
            $achQ = Achievement::where('athlete_id', $athlete->id);
            if (Schema::hasColumn('achievements', 'sport_id')) {
                $achQ->where('sport_id', $sportId);
            }
            if (Schema::hasColumn('achievements', 'is_verified')) {
                $achQ->where('is_verified', true);
            } elseif (Schema::hasColumn('achievements', 'verification_status')) {
                $achQ->where('verification_status', 'verified');
            }
            $points += $achQ->count() * static::POINTS_VERIFIED_ACHIEVEMENT;

            // Completion milestone.
            try {
                $percent = \App\Http\Controllers\CompletionChecklistController::completionFor($athlete->user);
                if ($percent >= 80) {
                    $points += static::POINTS_COMPLETION_MILESTONE;
                }
            } catch (\Throwable) {
            }

            // Participation (approved regs), capped.
            $parts = 0;
            try {
                $parts += TrialRegistration::where('athlete_id', $athlete->id)
                    ->whereIn('status', ['approved', 'confirmed'])->count();
            } catch (\Throwable) {
            }
            try {
                $parts += TournamentRegistration::where('athlete_id', $athlete->id)
                    ->whereIn('status', ['approved', 'confirmed'])->count();
            } catch (\Throwable) {
            }
            $points += min($parts * static::POINTS_PARTICIPATION, static::PARTICIPATION_CAP);

            LeaderboardScore::updateOrCreate(
                ['athlete_profile_id' => $athlete->id, 'sport_id' => $sportId, 'season_id' => $season->id],
                ['points' => $points]
            );
        }
    }

    public static function rebuildAll(): int
    {
        $n = 0;
        AthleteProfile::query()->select('id')->chunkById(200, function ($rows) use (&$n) {
            foreach ($rows as $row) {
                static::recalculateForAthlete($row->id);
                $n++;
            }
        });

        return $n;
    }

    /** Sports to score this athlete under (primary sport at minimum). */
    protected static function sportIdsFor(AthleteProfile $athlete): array
    {
        $ids = [];
        if (!empty($athlete->primary_sport_id)) {
            $ids[] = (int) $athlete->primary_sport_id;
        }
        try {
            foreach ($athlete->sports ?? [] as $s) {
                $sid = is_array($s) ? ($s['id'] ?? $s['sport_id'] ?? null) : ($s->id ?? null);
                if ($sid) {
                    $ids[] = (int) $sid;
                }
            }
        } catch (\Throwable) {
        }
        $ids = array_values(array_unique(array_filter($ids)));

        return $ids !== [] ? $ids : [null];
    }
}
