<?php

namespace App\Http\Controllers;

use App\Models\Achievement;
use App\Models\AthleteProfile;
use App\Models\Connection;
use App\Models\GuardianConsent;
use App\Models\TrialRegistration;
use App\Models\TournamentRegistration;
use App\Models\TournamentResult;
use App\Services\LeaderboardService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Athlete-facing leaderboard (personalised board used by the mobile app).
 *
 * GET /me/leaderboard?period=weekly|monthly|season|allTime
 *                 &category=xp|matches|wins|achievements|connections
 *                 &sport_id=&limit=
 *
 * Unlike the season board (GET /leaderboard, points per athlete x sport) this
 * board is computed live from the underlying activity rows so that weekly /
 * monthly windows are possible:
 *  - achievements: achievements.created_at
 *  - matches:      trial/tournament registrations (approved) .created_at
 *  - wins:         tournament_results (place = 1) .created_at / published_at
 *  - connections:  connections (accepted) .created_at
 *  - xp:           50 per achievement + 10 per approved match (capped at 50)
 *
 * Minors are anonymised (first name + initial) unless the guardian opted in.
 */
class AthleteLeaderboardController extends Controller
{
    public const XP_PER_ACHIEVEMENT = 50;

    public const XP_PER_MATCH = 10;

    public const XP_MATCH_CAP = 50;

    public function index(Request $request)
    {
        $validated = $request->validate([
            'period' => 'nullable|in:weekly,monthly,season,allTime,all_time',
            'category' => 'nullable|in:xp,matches,wins,achievements,connections',
            'sport_id' => 'nullable|integer|exists:sports,id',
            'limit' => 'nullable|integer|min:1|max:100',
        ]);

        $period = $validated['period'] ?? 'weekly';
        if ($period === 'all_time') {
            $period = 'allTime';
        }
        $category = $validated['category'] ?? 'xp';
        $sportId = $validated['sport_id'] ?? null;
        $limit = $validated['limit'] ?? 50;

        $season = LeaderboardService::activeSeason();
        $from = $this->periodStart($period, $season);

        $viewer = $request->user();
        $currentAthlete = $viewer?->athleteProfile;

        $athletes = AthleteProfile::with(['user', 'city', 'photo', 'sports'])
            ->when($sportId, fn ($q) => $q->whereHas('sports', fn ($s) => $s->where('sports.id', $sportId)))
            ->get();

        $scores = $this->scoresFor($category, $from, $sportId);

        // Only athletes with a score take part; the viewer always takes part.
        $rows = [];
        foreach ($athletes as $athlete) {
            $score = (int) ($scores[$athlete->id] ?? 0);
            if ($score <= 0 && $athlete->id !== $currentAthlete?->id) {
                continue;
            }
            $rows[] = ['athlete' => $athlete, 'score' => $score];
        }

        usort($rows, function ($a, $b) {
            if ($a['score'] === $b['score']) {
                return $a['athlete']->id <=> $b['athlete']->id;
            }

            return $b['score'] <=> $a['score'];
        });

        // Standard competition ranking (ties share a rank).
        $rank = 0;
        $previousScore = null;
        foreach ($rows as $i => $row) {
            if ($previousScore === null || $row['score'] !== $previousScore) {
                $rank = $i + 1;
                $previousScore = $row['score'];
            }
            $rows[$i]['rank'] = $rank;
        }

        $participants = count(array_filter($rows, fn ($r) => $r['score'] > 0));

        $entries = [];
        $currentUserEntry = null;
        foreach ($rows as $row) {
            $entry = $this->present($row['athlete'], $row['rank'], $row['score'], $currentAthlete?->id);
            if ($entry['is_current_user']) {
                $currentUserEntry = $entry;
            }
            if (count($entries) < $limit) {
                $entries[] = $entry;
            }
        }

        return response()->json([
            'data' => [
                'period' => $period,
                'category' => $category,
                'season' => ['id' => $season->id, 'name' => $season->name],
                'entries' => $entries,
                'current_user' => $currentUserEntry,
                'total_participants' => $participants,
            ],
        ]);
    }

    /**
     * Lower bound of the requested window (null = all time).
     */
    protected function periodStart(string $period, $season): ?Carbon
    {
        return match ($period) {
            'weekly' => now()->startOfWeek(),
            'monthly' => now()->startOfMonth(),
            'season' => $season?->starts_on ? Carbon::parse($season->starts_on)->startOfDay() : now()->startOfYear(),
            default => null,
        };
    }

    /**
     * Score map keyed by athlete_profile_id.
     */
    protected function scoresFor(string $category, ?Carbon $from, ?int $sportId): array
    {
        return match ($category) {
            'achievements' => $this->achievementCounts($from, $sportId),
            'matches' => $this->participationCounts($from, $sportId),
            'wins' => $this->winCounts($from, $sportId),
            'connections' => $this->connectionCounts($from),
            default => $this->xpCounts($from, $sportId),
        };
    }

    /**
     * XP = 50 per achievement + 10 per approved match (participation capped at 50).
     */
    protected function xpCounts(?Carbon $from, ?int $sportId): array
    {
        $achievements = $this->achievementCounts($from, $sportId);
        $matches = $this->participationCounts($from, $sportId);

        $scores = [];
        foreach (array_unique(array_merge(array_keys($achievements), array_keys($matches))) as $athleteId) {
            $scores[$athleteId] = ($achievements[$athleteId] ?? 0) * self::XP_PER_ACHIEVEMENT
                + min(($matches[$athleteId] ?? 0) * self::XP_PER_MATCH, self::XP_MATCH_CAP);
        }

        return $scores;
    }

    protected function achievementCounts(?Carbon $from, ?int $sportId = null): array
    {
        $rows = Achievement::query()
            ->when($from, fn ($q) => $q->where('created_at', '>=', $from))
            ->when($sportId, fn ($q) => $q->where(function ($w) use ($sportId) {
                // Untagged achievements still count for any sport.
                $w->where('sport_id', $sportId)->orWhereNull('sport_id');
            }))
            ->groupBy('athlete_id')
            ->select('athlete_id', DB::raw('count(*) as total'))
            ->pluck('total', 'athlete_id');

        return $rows->map(fn ($v) => (int) $v)->all();
    }

    protected function participationCounts(?Carbon $from, ?int $sportId = null): array
    {
        $approved = fn ($q) => $q->where(function ($w) {
            $w->whereIn('status', ['approved', 'confirmed'])
                ->orWhere('approval_status', 'approved');
        });

        $trial = TrialRegistration::query()
            ->tap($approved)
            ->when($from, fn ($q) => $q->where('created_at', '>=', $from))
            ->when($sportId, fn ($q) => $q->whereHas('trial', fn ($t) => $t->where('sport_id', $sportId)))
            ->groupBy('athlete_id')
            ->select('athlete_id', DB::raw('count(*) as total'))
            ->pluck('total', 'athlete_id');

        $tournament = TournamentRegistration::query()
            ->tap($approved)
            ->when($from, fn ($q) => $q->where('created_at', '>=', $from))
            ->when($sportId, fn ($q) => $q->whereHas('category.tournament', fn ($t) => $t->where('sport_id', $sportId)))
            ->groupBy('athlete_id')
            ->select('athlete_id', DB::raw('count(*) as total'))
            ->pluck('total', 'athlete_id');

        $counts = [];
        foreach ($trial as $athleteId => $total) {
            $counts[$athleteId] = (int) $total;
        }
        foreach ($tournament as $athleteId => $total) {
            $counts[$athleteId] = ($counts[$athleteId] ?? 0) + (int) $total;
        }

        return $counts;
    }

    /**
     * Wins are 1st places. tournament_results has no athlete FK, so the winner
     * is matched on the published name against team names / athlete names.
     */
    protected function winCounts(?Carbon $from, ?int $sportId): array
    {
        $results = TournamentResult::query()
            ->where('place', 1)
            ->when($from, fn ($q) => $q->where(function ($w) use ($from) {
                $w->where('created_at', '>=', $from)->orWhere('published_at', '>=', $from);
            }))
            ->when($sportId, fn ($q) => $q->whereHas('category.tournament', fn ($t) => $t->where('sport_id', $sportId)))
            ->get(['category_id', 'winner_name']);

        if ($results->isEmpty()) {
            return [];
        }

        $names = $results->map(fn ($r) => trim((string) $r->winner_name))
            ->filter(fn ($n) => $n !== '')
            ->unique()
            ->values()
            ->all();

        if ($names === []) {
            return [];
        }

        $nameToAthletes = [];

        $addName = function (string $name, int $athleteId) use (&$nameToAthletes) {
            $key = mb_strtolower(trim($name));
            if ($key === '') {
                return;
            }
            $nameToAthletes[$key] = array_values(array_unique(array_merge($nameToAthletes[$key] ?? [], [$athleteId])));
        };

        AthleteProfile::with('user')->whereIn('full_name', $names)->get()->each(function ($a) use ($addName) {
            $addName($a->full_name, $a->id);
            $addName((string) ($a->user?->name ?? ''), $a->id);
        });

        AthleteProfile::with('user')
            ->whereHas('user', fn ($q) => $q->whereIn('name', $names))
            ->get()
            ->each(function ($a) use ($addName) {
                $addName((string) ($a->user?->name ?? ''), $a->id);
            });

        TournamentRegistration::whereIn('team_name', $names)
            ->get(['athlete_id', 'team_name'])
            ->each(function ($r) use ($addName) {
                $addName((string) $r->team_name, (int) $r->athlete_id);
            });

        $counts = [];
        foreach ($results as $result) {
            $key = mb_strtolower(trim((string) $result->winner_name));
            foreach ($nameToAthletes[$key] ?? [] as $athleteId) {
                $counts[$athleteId] = ($counts[$athleteId] ?? 0) + 1;
            }
        }

        return $counts;
    }

    /**
     * Accepted connections per user id.
     */
    protected function connectionCounts(?Carbon $from): array
    {
        $asFollower = Connection::query()
            ->where('status', 'accepted')
            ->when($from, fn ($q) => $q->where('created_at', '>=', $from))
            ->groupBy('follower_user_id')
            ->select('follower_user_id', DB::raw('count(*) as total'))
            ->pluck('total', 'follower_user_id');

        $asFollowee = Connection::query()
            ->where('status', 'accepted')
            ->when($from, fn ($q) => $q->where('created_at', '>=', $from))
            ->groupBy('followee_user_id')
            ->select('followee_user_id', DB::raw('count(*) as total'))
            ->pluck('total', 'followee_user_id');

        $perUser = [];
        foreach ($asFollower as $userId => $total) {
            $perUser[$userId] = (int) $total;
        }
        foreach ($asFollowee as $userId => $total) {
            $perUser[$userId] = ($perUser[$userId] ?? 0) + (int) $total;
        }

        // Connections are user-scoped; the board is athlete-scoped.
        $athleteByUser = AthleteProfile::pluck('id', 'user_id');

        $counts = [];
        foreach ($perUser as $userId => $total) {
            $athleteId = $athleteByUser[$userId] ?? null;
            if ($athleteId) {
                $counts[$athleteId] = $total;
            }
        }

        return $counts;
    }

    protected function present(AthleteProfile $athlete, int $rank, int $score, ?int $currentAthleteId): array
    {
        $name = $athlete->user?->name ?: ($athlete->full_name ?: 'Athlete');
        $isMinor = false;
        if ($athlete->date_of_birth) {
            try {
                $isMinor = Carbon::parse($athlete->date_of_birth)->age < 18;
            } catch (\Throwable) {
                $isMinor = false;
            }
        }
        if ($isMinor && ! $this->guardianOptedIn($athlete)) {
            $parts = preg_split('/\s+/', trim($name));
            $name = $parts[0].(isset($parts[1]) ? ' '.mb_substr($parts[1], 0, 1).'.' : '');
        }

        return [
            'rank' => $rank,
            'id' => $athlete->id,
            'athlete_profile_id' => $athlete->id,
            'user_id' => $athlete->user_id,
            'name' => $name,
            'avatar_url' => $athlete->photo?->url,
            'score' => $score,
            'sport' => $this->sportName($athlete),
            'level' => $athlete->skill_level,
            'is_current_user' => $currentAthleteId !== null && $athlete->id === $currentAthleteId,
            'city' => $athlete->city?->name,
        ];
    }

    protected function sportName(AthleteProfile $athlete): string
    {
        $sports = $athlete->sports ?? collect();
        if ($sports->isEmpty()) {
            return 'General';
        }

        $primary = $sports->first(function ($s) {
            return (bool) ($s->pivot->is_primary ?? false);
        });

        $sport = $primary ?: $sports->first();

        return $sport->name ?? 'General';
    }

    protected function guardianOptedIn(?AthleteProfile $athlete): bool
    {
        if (! $athlete) {
            return false;
        }

        return GuardianConsent::where('athlete_user_id', $athlete->user_id)
            ->where('consent_status', GuardianConsent::STATUS_VERIFIED)
            ->where('leaderboard_name_mode', 'full')
            ->exists();
    }
}
