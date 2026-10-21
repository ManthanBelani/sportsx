<?php

namespace App\Http\Controllers;

use App\Models\Tournament;
use App\Models\TournamentRegistrationClick;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;

/**
 * Records clicks on a tournament's "Register" button for tournaments that
 * use an external registration URL.
 *
 * A click is NOT a registration: the external site owns the actual sign-up,
 * so we only store the intent. Counting is idempotent — the client sends a
 * `click_token` and the unique (tournament_id, click_token) index makes
 * repeated API calls / UI re-renders safe.
 */
class TournamentRegistrationClickController extends Controller
{
    public function store(Request $request, string $tournamentId)
    {
        $validated = $request->validate([
            'click_token' => 'required|string|max:64',
        ]);

        $tournament = Tournament::find($tournamentId);
        abort_if(! $tournament, 404, 'Tournament not found.');

        // Only external-registration tournaments track clicks. Internal
        // tournaments use the normal registration flow.
        abort_unless($tournament->hasExternalRegistration(), 422, 'This tournament uses in-app registration.');

        $user = auth('sanctum')->user();
        $token = $validated['click_token'];

        $incremented = false;

        try {
            \Illuminate\Support\Facades\DB::transaction(function () use ($tournament, $user, $token, &$incremented) {
                TournamentRegistrationClick::create([
                    'tournament_id' => $tournament->id,
                    'user_id' => $user?->id,
                    'click_token' => $token,
                ]);

                $tournament->increment('external_registration_clicks');
                $incremented = true;
            });
        } catch (QueryException $e) {
            // Duplicate click token → this click was already counted.
            if (! $this->isDuplicateKey($e)) {
                throw $e;
            }
        }

        $tournament->refresh();

        return response()->json([
            'data' => array_merge(
                $tournament->registrationStats(),
                ['incremented' => $incremented]
            ),
        ]);
    }

    /**
     * MySQL duplicate-key (1062) / SQLite unique constraint violation.
     */
    private function isDuplicateKey(QueryException $e): bool
    {
        $sqlState = (string) $e->getCode();
        if ($sqlState === '23000' || $sqlState === '23505') {
            return true;
        }

        $info = $e->errorInfo ?? [];

        return isset($info[1]) && (int) $info[1] === 1062;
    }
}
