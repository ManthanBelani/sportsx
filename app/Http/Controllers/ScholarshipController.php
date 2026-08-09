<?php

namespace App\Http\Controllers;

use App\Models\Scholarship;
use Illuminate\Http\Request;

class ScholarshipController extends Controller
{
    public function index(Request $request)
    {
        $query = Scholarship::published()->with(['sport', 'logo']);

        $query->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->deadline_from, fn ($q) => $q->where('deadline', '>=', $request->deadline_from))
            ->when($request->deadline_to, fn ($q) => $q->where('deadline', '<=', $request->deadline_to))
            ->when($request->amount_min, fn ($q) => $q->where('amount', '>=', $request->amount_min))
            ->when($request->amount_max, fn ($q) => $q->where('amount', '<=', $request->amount_max))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub->where('name', 'like', "%{$request->q}%")->orWhere('organization_name', 'like', "%{$request->q}%")));

        $perPage = min((int) ($request->per_page ?? 20), 50);

        return response()->json($query->paginate($perPage)->withQueryString());
    }

    public function show(string $id)
    {
        $scholarship = Scholarship::published()->with(['sport', 'logo'])->findOrFail($id);

        return response()->json(['data' => $scholarship]);
    }
}
