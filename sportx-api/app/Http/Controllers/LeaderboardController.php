<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use App\Models\GuardianConsent;
use App\Models\LeaderboardScore;
use App\Services\LeaderboardService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class LeaderboardController extends Controller
{
    /**
     * GET /leaderboard?sport_id=&city_id=&age_group_id=
     * podium (top 3) + ranks 4-10. Minors anonymized: first name + initial.
     * Coach/academy/team/event tabs are P1 — athlete board only in P0.
     */
    public function index(Request $request)
    {
        $validated = $request->validate([
            'sport_id' => 'nullable|integer|exists:sports,id',
            'city_id' => 'nullable|integer|exists:cities,id',
            'age_group_id' => 'nullable|integer|exists:age_groups,id',
            'limit' => 'nullable|integer|min:1|max:50',
        ]);

        $season = LeaderboardService::activeSeason();
        $limit = $validated['limit'] ?? 10;

        $q = LeaderboardScore::with(['athlete.user', 'athlete.city', 'athlete.ageGroup', 'sport'])
            ->where('season_id', $season->id)
            ->orderByDesc('points')
            ->orderBy('updated_at');

        if (!empty($validated['sport_id'])) {
            $q->where('sport_id', $validated['sport_id']);
        }
        if (!empty($validated['city_id'])) {
            $q->whereHas('athlete', fn ($w) => $w->where('city_id', $validated['city_id']));
        }
        if (!empty($validated['age_group_id'])) {
            $q->whereHas('athlete', fn ($w) => $w->where('age_group_id', $validated['age_group_id']));
        }

        $rows = $q->limit($limit)->get();
        $ranked = $rows->values()->map(fn ($r, $i) => $this->present($r, $i + 1))->all();

        return response()->json([
            'data' => [
                'season' => ['id' => $season->id, 'name' => $season->name],
                'podium' => array_slice($ranked, 0, 3),
                'ranks' => array_slice($ranked, 3),
            ],
        ]);
    }

    /** GET /leaderboard/strip — top-5 for home (AT.1). */
    public function strip(Request $request)
    {
        $request->merge(['limit' => 5]);
        $res = $this->index($request)->getData(true);

        return response()->json(['data' => array_merge(
            $res['data']['podium'] ?? [],
            $res['data']['ranks'] ?? []
        )]);
    }

    protected function present(LeaderboardScore $row, int $rank): array
    {
        /** @var AthleteProfile|null $a */
        $a = $row->athlete;
        $name = $a?->user?->name ?? 'Athlete';
        $isMinor = false;
        if ($a?->date_of_birth) {
            try {
                $isMinor = Carbon::parse($a->date_of_birth)->age < 18;
            } catch (\Throwable) {
            }
        }
        // Minors: first name + initial unless guardian opts into full name.
        if ($isMinor && !$this->guardianOptedIn($a)) {
            $parts = preg_split('/\s+/', trim($name));
            $name = $parts[0].(isset($parts[1]) ? ' '.mb_substr($parts[1], 0, 1).'.' : '');
        }

        return [
            'rank' => $rank,
            'points' => (int) $row->points,
            'athlete_profile_id' => $row->athlete_profile_id,
            'display_name' => $name,
            'is_minor' => $isMinor,
            'sport' => $row->sport ? ['id' => $row->sport->id, 'name' => $row->sport->name] : null,
            'city' => $a?->city ? ['id' => $a->city->id, 'name' => $a->city->name] : null,
            'photo' => $a?->photo ? ['url' => $a->photo->url ?? null] : null,
        ];
    }

    protected function guardianOptedIn(?AthleteProfile $a): bool
    {
        if (!$a) {
            return false;
        }

        return GuardianConsent::where('athlete_user_id', $a->user_id)
            ->where('consent_status', GuardianConsent::STATUS_VERIFIED)
            ->where('leaderboard_name_mode', 'full')
            ->exists();
    }
}
