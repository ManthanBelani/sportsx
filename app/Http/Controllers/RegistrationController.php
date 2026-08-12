<?php

namespace App\Http\Controllers;

use App\Models\Trial;
use App\Models\TrialRegistration;
use App\Models\TrialRegistrationDocument;
use App\Models\Tournament;
use App\Models\TournamentRegistration;
use App\Services\IcsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class RegistrationController extends Controller
{
    // ── Trial Registrations ──────────────────────────────────────────────────

    public function storeTrial(Request $request, Trial $trial)
    {
        abort_unless($trial->isRegisterable(), 422, 'Trial is closed or expired');

        $athlete = $request->user()->athleteProfile;
        abort_unless($athlete, 403, 'Athlete profile required');

        $validated = $request->validate([
            'document_media_ids' => 'nullable|array',
            'document_media_ids.*' => 'integer|exists:media_items,id',
            'reminder_enabled' => 'boolean',
            'playing_role' => 'nullable|string|max:100',
            'medical_conditions' => 'nullable|string|max:1000',
            'parental_consent' => 'boolean',
        ]);

        abort_if(
            TrialRegistration::where('trial_id', $trial->id)->where('athlete_id', $athlete->id)->exists(),
            409, 'Already registered'
        );

        return DB::transaction(function () use ($validated, $trial, $athlete, $request) {
            $registration = TrialRegistration::create([
                'trial_id' => $trial->id,
                'athlete_id' => $athlete->id,
                'registration_ref' => $this->generateRef('TR', $trial->event_datetime),
                'playing_role' => $validated['playing_role'] ?? null,
                'medical_conditions' => $validated['medical_conditions'] ?? null,
                'parental_consent' => $validated['parental_consent'] ?? false,
                'document_status' => empty($validated['document_media_ids']) ? 'pending' : 'submitted',
                'verification_status' => 'pending',
                'reminder_enabled' => $validated['reminder_enabled'] ?? false,
            ]);

            foreach ($validated['document_media_ids'] ?? [] as $i => $mediaId) {
                TrialRegistrationDocument::create([
                    'trial_registration_id' => $registration->id,
                    'document_type' => $trial->required_documents[$i] ?? 'Document',
                    'media_item_id' => $mediaId,
                ]);
            }

            return response()->json([
                'data' => [
                    'registration_ref' => $registration->registration_ref,
                    'trial' => $trial->only(['id', 'name', 'event_datetime', 'venue']),
                    'status' => $registration->verification_status,
                    'reminder_enabled' => $registration->reminder_enabled,
                ],
            ], 201);
        });
    }

    public function trialIndex(Request $request, Trial $trial)
    {
        $this->authorizeOwner($request, $trial);

        $registrations = $trial->registrations()->with(['athlete.user', 'documents.media'])->paginate(20);

        return response()->json([
            'data' => $registrations->items(),
            'meta' => ['pagination' => [
                'total' => $registrations->total(),
                'per_page' => $registrations->perPage(),
                'current_page' => $registrations->currentPage(),
                'last_page' => $registrations->lastPage(),
            ]],
        ]);
    }

    public function trialShow(Request $request, TrialRegistration $registration)
    {
        $this->authorizeOwner($request, $registration->trial);

        return response()->json(['data' => $registration->load(['athlete.user', 'athlete.sports', 'documents.media'])]);
    }

    public function verifyTrial(Request $request, TrialRegistration $registration)
    {
        $this->authorizeOwner($request, $registration->trial);
        $registration->update(['verification_status' => 'verified']);

        return response()->json(['data' => $registration]);
    }

    public function rejectTrial(Request $request, TrialRegistration $registration)
    {
        $this->authorizeOwner($request, $registration->trial);
        $registration->update(['verification_status' => 'rejected']);

        return response()->json(['data' => $registration]);
    }

    public function toggleTrialReminder(Request $request, TrialRegistration $registration)
    {
        abort_if($registration->athlete->user_id !== $request->user()->id, 403);
        $registration->update(['reminder_enabled' => ! $registration->reminder_enabled]);

        return response()->json(['data' => ['reminder_enabled' => $registration->reminder_enabled]]);
    }

    // ── Tournament Registrations ──────────────────────────────────────────────

    public function storeTournament(Request $request, Tournament $tournament)
    {
        abort_unless($tournament->status === 'published', 422, 'Tournament is not open for registration');

        $athlete = $request->user()->athleteProfile;
        abort_unless($athlete, 403, 'Athlete profile required');

        $validated = $request->validate([
            'category_id' => 'required|integer|exists:tournament_categories,id',
            'participation_type' => 'required|in:individual,team',
            'team_name' => 'nullable|string|max:100',
            'payment_status' => 'nullable|in:pending,paid,waived',
            'reminder_enabled' => 'boolean',
        ]);

        abort_if(
            TournamentRegistration::where('tournament_id', $tournament->id)
                ->where('athlete_id', $athlete->id)
                ->where('category_id', $validated['category_id'])
                ->exists(),
            409, 'Already registered for this category'
        );

        $category = $tournament->categories()->find($validated['category_id']);
        abort_if(! $category, 422, 'Category does not belong to this tournament');

        $registration = TournamentRegistration::create([
            'tournament_id' => $tournament->id,
            'category_id' => $validated['category_id'],
            'athlete_id' => $athlete->id,
            'participation_type' => $validated['participation_type'],
            'team_name' => $validated['team_name'] ?? null,
            'payment_status' => $validated['payment_status'] ?? 'pending',
            'status' => 'registered',
            'reminder_enabled' => $validated['reminder_enabled'] ?? false,
        ]);

        return response()->json([
            'data' => $registration->load(['category', 'tournament']),
        ], 201);
    }

    public function tournamentIndex(Request $request, Tournament $tournament)
    {
        $this->authorizeTournamentOwner($request, $tournament);

        $registrations = $tournament->registrations()
            ->with(['athlete.user', 'category'])
            ->paginate(20);

        return response()->json([
            'data' => $registrations->items(),
            'meta' => ['pagination' => [
                'total' => $registrations->total(),
                'per_page' => $registrations->perPage(),
                'current_page' => $registrations->currentPage(),
                'last_page' => $registrations->lastPage(),
            ]],
        ]);
    }

    public function tournamentCapacity(Request $request, Tournament $tournament)
    {
        $this->authorizeTournamentOwner($request, $tournament);

        $caps = $tournament->categories()->withCount('registrations')->get();

        return response()->json([
            'data' => $caps->map(fn ($c) => [
                'category_id' => $c->id,
                'category_name' => $c->name,
                'max_teams' => $c->max_teams,
                'registered' => $c->registrations_count,
                'available' => max(0, ($c->max_teams ?? 0) - $c->registrations_count),
            ]),
        ]);
    }

    public function updateTournamentCapacity(Request $request, Tournament $tournament)
    {
        $this->authorizeTournamentOwner($request, $tournament);

        $validated = $request->validate([
            'categories' => 'required|array',
            'categories.*.id' => 'required|integer|exists:tournament_categories,id',
            'categories.*.max_teams' => 'nullable|integer|min:0',
        ]);

        foreach ($validated['categories'] as $catUpdate) {
            $tournament->categories()->where('id', $catUpdate['id'])
                ->update(['max_teams' => $catUpdate['max_teams']]);
        }

        return response()->json(['data' => ['message' => 'Capacity updated']]);
    }

    public function updateTournamentPayment(Request $request, TournamentRegistration $registration)
    {
        $this->authorizeTournamentOwner($request, $registration->tournament);

        $validated = $request->validate([
            'payment_status' => 'required|in:pending,paid,waived',
        ]);

        $registration->update(['payment_status' => $validated['payment_status']]);

        return response()->json(['data' => $registration]);
    }

    // ── Athlete's own registrations ──────────────────────────────────────────

    public function myRegistrations(Request $request)
    {
        $user = $request->user();
        $athlete = $user->athleteProfile;
        abort_unless($athlete, 403, 'Athlete profile required');

        $trials = TrialRegistration::with(['trial'])
            ->where('athlete_id', $athlete->id)
            ->get()
            ->map(fn ($r) => array_merge($r->toArray(), ['type' => 'trial']));

        $tournaments = TournamentRegistration::with(['tournament', 'category'])
            ->where('athlete_id', $athlete->id)
            ->get()
            ->map(fn ($r) => array_merge($r->toArray(), ['type' => 'tournament']));

        return response()->json(['data' => array_merge($trials->toArray(), $tournaments->toArray())]);
    }

    // ── Calendar Export (ICS) ─────────────────────────────────────────────────

    public function downloadTrialIcs(Request $request, TrialRegistration $registration)
    {
        abort_if($registration->athlete->user_id !== $request->user()->id, 403);

        $trial = $registration->trial;

        $ics = app(IcsService::class)->generateEventIcs(
            title: "Trial: {$trial->name}",
            description: "Registration: {$registration->registration_ref}\nVenue: {$trial->venue}",
            start: \Carbon\Carbon::parse($trial->event_datetime),
            end: \Carbon\Carbon::parse($trial->event_datetime)->addHours(3),
            location: $trial->venue_address ?? $trial->venue ?? '',
            uid: "trial-{$registration->id}@sportx.app"
        );

        return response($ics, 200, [
            'Content-Type' => 'text/calendar; charset=utf-8',
            'Content-Disposition' => "attachment; filename=\"trial-{$registration->registration_ref}.ics\"",
        ]);
    }

    public function downloadTournamentIcs(Request $request, TournamentRegistration $registration)
    {
        abort_if($registration->athlete->user_id !== $request->user()->id, 403);

        $tournament = $registration->tournament;
        $category = $registration->category;

        $startDate = \Carbon\Carbon::parse($tournament->start_date);
        $endDate = \Carbon\Carbon::parse($tournament->end_date);

        $ics = app(IcsService::class)->generateEventIcs(
            title: "Tournament: {$tournament->name}",
            description: "Registration: {$registration->id}\nCategory: {$category->name}",
            start: $startDate,
            end: $endDate,
            location: $tournament->venue_address ?? $tournament->venue ?? '',
            uid: "tournament-{$registration->id}@sportx.app"
        );

        return response($ics, 200, [
            'Content-Type' => 'text/calendar; charset=utf-8',
            'Content-Disposition' => "attachment; filename=\"tournament-{$registration->id}.ics\"",
        ]);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private function authorizeOwner(Request $request, Trial $trial): void
    {
        $user = $request->user();
        abort_unless($trial->posted_by_user_id === $user->id || $user->isAdmin(), 403);
    }

    private function authorizeTournamentOwner(Request $request, Tournament $tournament): void
    {
        $user = $request->user();
        abort_unless($tournament->organizer_id === $user->id || $user->isAdmin(), 403);
    }

    private function generateRef(string $prefix, $date): string
    {
        return '#'.$prefix.\Carbon\Carbon::parse($date)->format('Ymd').'-'.str_pad((string) random_int(1, 9999), 4, '0', STR_PAD_LEFT);
    }
}
