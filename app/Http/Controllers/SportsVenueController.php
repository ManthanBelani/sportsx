<?php

namespace App\Http\Controllers;

use App\Models\SportsVenue;
use Illuminate\Http\Request;

class SportsVenueController extends Controller
{
    public function index(Request $request)
    {
        $query = SportsVenue::published()->with(['sport', 'city']);

        $query->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->city_id, fn ($q) => $q->where('city_id', $request->city_id))
            ->when($request->booking_available, fn ($q) => $q->where('booking_available', filter_var($request->booking_available, FILTER_VALIDATE_BOOLEAN)))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub->where('name', 'like', "%{$request->q}%")->orWhere('address', 'like', "%{$request->q}%")));

        $perPage = min((int) ($request->per_page ?? 20), 50);

        return response()->json($query->paginate($perPage)->withQueryString());
    }

    public function show(string $id)
    {
        $venue = SportsVenue::published()->with(['sport', 'city'])->findOrFail($id);

        return response()->json(['data' => $venue]);
    }
}
