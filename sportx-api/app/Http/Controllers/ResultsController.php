<?php

namespace App\Http\Controllers;

use App\Models\Tournament;
use App\Models\TournamentResult;
use Illuminate\Http\Request;

class ResultsController extends Controller
{
    public function index(Request $request, Tournament $tournament)
    {
        $results = TournamentResult::with(['category'])
            ->where('tournament_id', $tournament->id)
            ->orderBy('place')
            ->get();

        return response()->json(['data' => $results]);
    }

    public function store(Request $request, Tournament $tournament)
    {
        $this->authorizeTournamentOwner($request, $tournament);

        $validated = $request->validate([
            'results' => 'required|array|min:1',
            'results.*.category_id' => 'required|integer|exists:tournament_categories,id',
            'results.*.place' => 'required|integer|min:1',
            'results.*.winner_name' => 'required|string|max:255',
            'results.*.bracket_media_id' => 'nullable|integer|exists:media_items,id',
        ]);

        $created = [];
        foreach ($validated['results'] as $resultData) {
            $resultData['tournament_id'] = $tournament->id;
            $resultData['published_at'] = now();
            $created[] = TournamentResult::updateOrCreate(
                [
                    'tournament_id' => $tournament->id,
                    'category_id' => $resultData['category_id'],
                    'place' => $resultData['place'],
                ],
                array_diff_key($resultData, ['category_id' => ''])
            );
        }

        return response()->json(['data' => $created], 201);
    }

    public function publish(Request $request, Tournament $tournament, TournamentResult $result)
    {
        $this->authorizeTournamentOwner($request, $tournament);
        abort_if($result->tournament_id !== $tournament->id, 403);

        $result->update(['published_at' => now()]);

        return response()->json(['data' => $result]);
    }

    public function unpublish(Request $request, Tournament $tournament, TournamentResult $result)
    {
        $this->authorizeTournamentOwner($request, $tournament);
        abort_if($result->tournament_id !== $tournament->id, 403);

        $result->update(['published_at' => null]);

        return response()->json(['data' => $result]);
    }

    private function authorizeTournamentOwner(Request $request, Tournament $tournament): void
    {
        $user = $request->user();
        abort_unless($tournament->organizer_id === $user->id || $user->isAdmin(), 403);
    }
}
