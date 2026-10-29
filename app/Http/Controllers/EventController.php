<?php

namespace App\Http\Controllers;

use App\Models\Tournament;
use App\Models\Trial;
use Illuminate\Http\Request;

/**
 * Unified events API (Phase 8).
 * Tables stay split (trials/tournaments); unification lives here.
 * type=camp maps to the trials table (camps are trial-shaped in P0).
 */
class EventController extends Controller
{
    /** POST /me/events?type=trial|tournament|camp */
    public function store(Request $request)
    {
        $type = strtolower($request->query('type', $request->input('type', 'trial')));
        abort_unless(in_array($type, ['trial', 'tournament', 'camp']), 422, 'Unknown event type.');

        if ($type === 'tournament') {
            return app(ProviderTournamentController::class)->store($request);
        }

        return app(ProviderTrialController::class)->store($request);
    }

    /** GET /me/events?type=&filter=upcoming|past — merged, with counts. */
    public function mine(Request $request)
    {
        $user = $request->user();
        $type = strtolower($request->query('type', 'all'));
        $filter = strtolower($request->query('filter', 'upcoming'));
        $now = now();

        $trials = collect();
        $tournaments = collect();
        if (in_array($type, ['all', 'trial', 'camp'])) {
            $trials = Trial::where('posted_by_user_id', $user->id)
                ->with(['sport', 'city'])
                ->withCount([
                    'registrations',
                    'registrations as confirmed_registrations_count' => fn ($q) => $q->where('approval_status', 'approved'),
                ])
                ->orderBy('event_datetime', 'desc')
                ->get()
                ->map(fn ($t) => array_merge($t->toArray(), ['event_type' => 'trial'], $this->trialStats($t)));
        }
        if (in_array($type, ['all', 'tournament'])) {
            $profileId = $user->organizerProfile?->id;
            $q = Tournament::with(['sport', 'city', 'bannerMedia'])->withRegistrationCounts()->orderBy('start_date', 'desc');
            if ($profileId) {
                $q->where(fn ($w) => $w->where('organizer_id', $user->id)->orWhere('organizer_id', $profileId));
            } else {
                $q->where('organizer_id', $user->id);
            }
            $tournaments = $q->get()->map(fn ($t) => array_merge($t->toArray(), ['event_type' => 'tournament'], $t->registrationStats(), ['banner_url' => $t->bannerUrl()]));
        }

        $all = $trials->concat($tournaments);
        $dateOf = fn (array $e) => $e['event_datetime'] ?? $e['start_date'] ?? null;
        $upcoming = $all->filter(fn ($e) => !$dateOf($e) || $dateOf($e) >= $now->toDateTimeString())->values();
        $past = $all->filter(fn ($e) => $dateOf($e) && $dateOf($e) < $now->toDateTimeString())->values();

        $list = $filter === 'past' ? $past : ($request->query('filter') ? $upcoming : $all);

        return response()->json(['data' => [
            'events' => $list->values()->all(),
            'counts' => ['upcoming' => $upcoming->count(), 'past' => $past->count(), 'total' => $all->count()],
        ]]);
    }

    /**
     * Registration counters for a trial (spots come from `vacancies`).
     */
    private function trialStats(Trial $trial): array
    {
        $confirmed = (int) ($trial->confirmed_registrations_count ?? 0);
        $total = (int) ($trial->registrations_count ?? 0);
        $spots = (int) ($trial->vacancies ?? 0);

        return [
            'total_spots' => $spots,
            'filled_spots' => $confirmed,
            'spots_left' => max(0, $spots - $confirmed),
            'registrations_count' => $total,
            'confirmed_registrations_count' => $confirmed,
            'utilization_percent' => $spots > 0 ? round(($confirmed / $spots) * 100, 1) : 0.0,
        ];
    }

    /** GET /events/{id}?type= — auto-detects trial vs tournament. */    public function show(Request $request, string $id)
    {
        $type = strtolower($request->query('type', 'auto'));
        if (in_array($type, ['trial', 'camp', 'auto'])) {
            $trial = Trial::with(['sport', 'city'])->find($id);
            if ($trial) {
                return response()->json(['data' => array_merge($trial->toArray(), ['event_type' => 'trial'])]);
            }
            abort_if($type !== 'auto', 404);
        }
        $tournament = Tournament::with(['sport', 'city', 'categories'])->findOrFail($id);

        return response()->json(['data' => array_merge($tournament->toArray(), ['event_type' => 'tournament'])]);
    }

    /** PUT/PATCH /me/events/{id}?type= (+ publish/close via status). */
    public function update(Request $request, string $id)
    {
        $type = strtolower($request->query('type', $request->input('type', 'auto')));
        $trial = in_array($type, ['auto', 'trial', 'camp']) ? Trial::find($id) : null;
        if ($trial) {
            abort_unless($trial->posted_by_user_id === $request->user()->id || $request->user()->isAdmin(), 403);
            $c = new ProviderTrialController(app(\App\Services\ExpiryService::class));

            return $c->update($this->subRequest($request, $trial->id, 'trial'), $trial);
        }
        $tournament = Tournament::findOrFail($id);
        $this->assertTournamentOwner($request, $tournament);
        $c = new ProviderTournamentController(app(\App\Services\ExpiryService::class));

        return $c->update($this->subRequest($request, $tournament->id, 'tournament'), $tournament);
    }

    /** POST /me/events/{id}/publish and /close */
    public function publish(Request $request, string $id)
    {
        return $this->transition($request, $id, 'publish');
    }

    public function close(Request $request, string $id)
    {
        return $this->transition($request, $id, 'close');
    }

    protected function transition(Request $request, string $id, string $action)
    {
        $type = strtolower($request->query('type', 'auto'));
        $trial = in_array($type, ['auto', 'trial', 'camp']) ? Trial::find($id) : null;
        if ($trial) {
            abort_unless($trial->posted_by_user_id === $request->user()->id || $request->user()->isAdmin(), 403);
            $c = new ProviderTrialController(app(\App\Services\ExpiryService::class));

            return $action === 'publish' ? $c->publish($request, $trial) : $c->close($request, $trial);
        }
        $tournament = Tournament::findOrFail($id);
        $this->assertTournamentOwner($request, $tournament);
        $c = new ProviderTournamentController(app(\App\Services\ExpiryService::class));

        return $action === 'publish' ? $c->publish($request, $tournament) : $c->close($request, $tournament);
    }

    protected function subRequest(Request $request, int|string $id, string $type): Request
    {
        $sub = Request::create("/me/events/{$id}", $request->method(), $request->all());
        $sub->setUserResolver($request->getUserResolver());
        $sub->query->set('type', $type);

        return $sub;
    }

    protected function assertTournamentOwner(Request $request, Tournament $t): void
    {
        $user = $request->user();
        $profileId = $user->organizerProfile?->id;
        $owns = $t->organizer_id === $user->id || ($profileId && $t->organizer_id === $profileId);
        abort_unless($owns || $user->isAdmin(), 403);
    }
}
