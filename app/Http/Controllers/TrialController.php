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
            ->orderBy('event_datetime', 'asc');

        $perPage = min((int) ($request->per_page ?? 20), 50);

        return response()->json($query->paginate($perPage)->withQueryString());
    }

    public function show(string $id)
    {
        $trial = Trial::published()->with(['sport', 'city', 'academy', 'postedBy'])->findOrFail($id);

        return response()->json(['data' => $trial]);
    }
}
