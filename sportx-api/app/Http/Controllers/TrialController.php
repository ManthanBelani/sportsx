<?php

namespace App\Http\Controllers;

use App\Models\Trial;
use Illuminate\Http\Request;

class TrialController extends Controller
{
    public function index(Request $request)
    {
        $query = Trial::published()->with(['sport', 'city', 'academy', 'postedBy']);

        $query->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->city_id, fn ($q) => $q->where('city_id', $request->city_id))
            ->when($request->fee_min, fn ($q) => $q->where('entry_fee', '>=', $request->fee_min))
            ->when($request->fee_max, fn ($q) => $q->where('entry_fee', '<=', $request->fee_max))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub->where('name', 'like', "%{$request->q}%")->orWhere('organization_name', 'like', "%{$request->q}%")))
            ->when($request->date_from, fn ($q) => $q->where('event_datetime', '>=', $request->date_from))
            ->when($request->date_to, fn ($q) => $q->where('event_datetime', '<=', $request->date_to))
            ->when($request->age_group_id && \Illuminate\Support\Facades\Schema::hasColumn('trials', 'age_groups'),
                fn ($q) => $q->whereJsonContains('age_groups', (int) $request->age_group_id))
            ->when($request->level && \Illuminate\Support\Facades\Schema::hasColumn('trials', 'level'),
                fn ($q) => $q->where('level', $request->level))
            ->when($request->facility, fn ($q) => $q->whereJsonContains('required_documents', $request->facility))
            ->orderBy('event_datetime', 'asc');

        $perPage = min((int) ($request->per_page ?? 20), 50);

        return response()->json($query->paginate($perPage)->withQueryString());
    }

    public function show(Request $request, string $id)
    {
        $trial = Trial::published()->with(['sport', 'city', 'academy', 'postedBy'])->findOrFail($id);

        $data = $trial->toArray();
        $data['registration_status'] = $this->registrationStatus($trial, $request->user());

        return response()->json(['data' => $data]);
    }

    /**
     * Registration status for the viewer (Phase 3): own registration state +
     * seats remaining. Guests get `registered: false` with seat counts.
     *
     * @return array{registered: bool, approval_status: ?string, seats_total: ?int, seats_taken: int, seats_left: ?int, is_registerable: bool}
     */
    protected function registrationStatus(\App\Models\Trial $trial, $viewer): array
    {
        $taken = $trial->registrations()->where('approval_status', 'approved')->count();

        $status = [
            'registered' => false,
            'approval_status' => null,
            'seats_total' => $trial->vacancies,
            'seats_taken' => $taken,
            'seats_left' => $trial->vacancies !== null ? max(0, $trial->vacancies - $taken) : null,
            'is_registerable' => $trial->isRegisterable(),
        ];

        $athleteId = $viewer?->athleteProfile?->id;
        if ($athleteId) {
            $mine = $trial->registrations()->where('athlete_id', $athleteId)->latest('id')->first();
            if ($mine) {
                $status['registered'] = true;
                $status['approval_status'] = $mine->approval_status;
            }
        }

        return $status;
    }
}
