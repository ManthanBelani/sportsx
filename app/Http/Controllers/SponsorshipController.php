<?php

namespace App\Http\Controllers;

use App\Models\Sponsorship;
use Illuminate\Http\Request;

class SponsorshipController extends Controller
{
    public function index(Request $request)
    {
        $query = Sponsorship::published()->with(['sport', 'sponsor', 'logo']);

        $query->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->deadline_from, fn ($q) => $q->where('deadline', '>=', $request->deadline_from))
            ->when($request->deadline_to, fn ($q) => $q->where('deadline', '<=', $request->deadline_to))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub->where('title', 'like', "%{$request->q}%")->orWhere('organization_name', 'like', "%{$request->q}%")));

        $perPage = min((int) ($request->per_page ?? 20), 50);

        return response()->json($query->paginate($perPage)->withQueryString());
    }

    public function show(string $id)
    {
        $sponsorship = Sponsorship::published()->with(['sport', 'sponsor', 'logo'])->findOrFail($id);

        return response()->json(['data' => $sponsorship]);
    }
}
