<?php

namespace App\Http\Controllers;

use App\Models\TournamentRegistration;
use App\Models\Trial;
use App\Models\TrialRegistration;
use App\Models\Tournament;
use Illuminate\Http\Request;

/**
 * Unified registrant ops (Phase 8 plan shape).
 * Existing per-type PATCH routes stay; this adds the unified layer:
 *  GET /events/{id}/registrations, GET /registrations/{id},
 *  POST …/approve|reject, bulk, CSV export, unified cancel.
 */
class EventRegistrationController extends Controller
{
    protected function eventOf(string $id, ?string $type): array
    {
        $type = strtolower($type ?? 'auto');
        if (in_array($type, ['trial', 'camp', 'auto'])) {
            $trial = Trial::find($id);
            if ($trial) {
                return ['kind' => 'trial', 'event' => $trial];
            }
            abort_if($type !== 'auto', 404);
        }

        return ['kind' => 'tournament', 'event' => Tournament::findOrFail($id)];
    }

    protected function assertOwner(Request $request, string $kind, $event): void
    {
        $user = $request->user();
        if ($user->isAdmin()) {
            return;
        }
        if ($kind === 'trial') {
            abort_unless($event->posted_by_user_id === $user->id, 403);
        } else {
            $profileId = $user->organizerProfile?->id;
            $owns = $event->organizer_id === $user->id || ($profileId && $event->organizer_id === $profileId);
            abort_unless($owns, 403);
        }
    }

    /** GET /events/{id}/registrations?status=&q= — All/Approved/Pending + search. */
    public function index(Request $request, string $id)
    {
        ['kind' => $kind, 'event' => $event] = $this->eventOf($id, $request->query('type'));
        $this->assertOwner($request, $kind, $event);

        $status = strtolower($request->query('status', 'all'));
        $q = trim($request->query('q', ''));

        if ($kind === 'trial') {
            $query = TrialRegistration::with(['athlete.user'])->where('trial_id', $event->id);
        } else {
            $query = TournamentRegistration::with(['athlete.user', 'category'])->where('tournament_id', $event->id);
        }
        if ($status !== '' && $status !== 'all') {
            $query->where('status', $status);
        }
        if ($q !== '') {
            $query->whereHas('athlete.user', fn ($w) => $w->where('name', 'like', "%{$q}%"));
        }

        return response()->json($query->orderByDesc('created_at')->paginate(30));
    }

    /** GET /registrations/{id}?type= — full submission (+docs). */
    public function show(Request $request, string $id)
    {
        $type = strtolower($request->query('type', 'auto'));
        if (in_array($type, ['trial', 'auto'])) {
            $reg = TrialRegistration::with(['athlete.user', 'trial'])->find($id);
            if ($reg) {
                $this->assertCanView($request, 'trial', $reg);
                return response()->json(['data' => array_merge($reg->toArray(), ['kind' => 'trial'])]);
            }
            abort_if($type !== 'auto', 404);
        }
        $reg = TournamentRegistration::with(['athlete.user', 'tournament', 'category'])->findOrFail($id);
        $this->assertCanView($request, 'tournament', $reg);

        return response()->json(['data' => array_merge($reg->toArray(), ['kind' => 'tournament'])]);
    }

    /** POST /registrations/{id}/approve and /reject (plan shape). */
    public function approve(Request $request, string $id)
    {
        return $this->decide($request, $id, 'approved');
    }

    public function reject(Request $request, string $id)
    {
        $request->validate(['reason' => 'nullable|string|max:500']);

        return $this->decide($request, $id, 'rejected', $request->input('reason'));
    }

    /** POST /events/{id}/registrations/bulk {action, ids[]} */
    public function bulk(Request $request, string $id)
    {
        $validated = $request->validate([
            'action' => 'required|in:approve,reject',
            'ids' => 'required|array|min:1|max:200',
            'ids.*' => 'integer',
            'reason' => 'nullable|string|max:500',
        ]);
        ['kind' => $kind, 'event' => $event] = $this->eventOf($id, $request->query('type') ?? $request->input('type'));
        $this->assertOwner($request, $kind, $event);

        $status = $validated['action'] === 'approve' ? 'approved' : 'rejected';
        $count = 0;
        foreach ($validated['ids'] as $rid) {
            $sub = Request::create("/registrations/{$rid}/{$validated['action']}", 'POST', ['reason' => $validated['reason'] ?? null]);
            $sub->setUserResolver($request->getUserResolver());
            try {
                $this->decide($sub, (string) $rid, $status, $validated['reason'] ?? null);
                $count++;
            } catch (\Throwable) {
            }
        }

        return response()->json(['data' => ['processed' => $count]]);
    }

    /** GET /events/{id}/registrations/export — CSV, role-scoped. */
    public function export(Request $request, string $id)
    {
        ['kind' => $kind, 'event' => $event] = $this->eventOf($id, $request->query('type'));
        $this->assertOwner($request, $kind, $event);

        $rows = $kind === 'trial'
            ? TrialRegistration::with(['athlete.user'])->where('trial_id', $event->id)->orderBy('id')->get()
            : TournamentRegistration::with(['athlete.user', 'category'])->where('tournament_id', $event->id)->orderBy('id')->get();

        $out = fopen('php://temp', 'r+');
        fputcsv($out, ['id', 'athlete', 'status', 'payment_status', 'created_at']);
        foreach ($rows as $r) {
            fputcsv($out, [
                $r->id,
                $r->athlete?->user?->name ?? '',
                $r->status ?? '',
                $r->payment_status ?? '',
                $r->created_at,
            ]);
        }
        rewind($out);
        $csv = stream_get_contents($out);
        fclose($out);

        return response($csv, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"event-{$id}-registrations.csv\"",
        ]);
    }

    /** DELETE /me/registrations/{id}?type= — athlete cancel. */
    public function cancel(Request $request, string $id)
    {
        $type = strtolower($request->query('type', $request->input('type', 'auto')));
        $athleteId = $request->user()->athleteProfile?->id;
        abort_unless($athleteId, 403, 'Athlete profile required.');

        if (in_array($type, ['trial', 'auto'])) {
            $reg = TrialRegistration::where('id', $id)->where('athlete_id', $athleteId)->first();
            if ($reg) {
                $reg->update(['status' => 'cancelled']);
                return response()->json(['data' => ['message' => 'Cancelled']]);
            }
            abort_if($type !== 'auto', 404);
        }
        $reg = TournamentRegistration::where('id', $id)->where('athlete_id', $athleteId)->firstOrFail();
        $reg->update(['status' => 'cancelled']);

        return response()->json(['data' => ['message' => 'Cancelled']]);
    }

    protected function decide(Request $request, string $id, string $status, ?string $reason = null)
    {
        // Reuse the existing per-type approve/reject (which notify the athlete).
        $type = strtolower($request->query('type', $request->input('type', 'auto')));
        if ($reason !== null && !$request->offsetExists('rejection_reason')) {
            $request->merge(['rejection_reason' => $reason, 'reason' => $reason]);
        }
        $rc = app(RegistrationController::class);

        if (in_array($type, ['trial', 'auto'])) {
            $reg = TrialRegistration::find($id);
            if ($reg) {
                return $status === 'approved'
                    ? $rc->approveTrial($request, $reg)
                    : $rc->rejectTrial($request, $reg);
            }
            abort_if($type !== 'auto', 404);
        }
        $reg = TournamentRegistration::findOrFail($id);

        return $status === 'approved'
            ? $rc->approveTournament($request, $reg)
            : $rc->rejectTournament($request, $reg);
    }

    protected function assertCanView(Request $request, string $kind, $reg): void
    {
        $user = $request->user();
        if ($user->isAdmin()) {
            return;
        }
        $athleteId = $user->athleteProfile?->id;
        $isMine = $athleteId && (int) $reg->athlete_id === (int) $athleteId;
        if ($isMine) {
            return;
        }
        $event = $kind === 'trial' ? $reg->trial : $reg->tournament;
        $this->assertOwner($request, $kind, $event);
    }
}
