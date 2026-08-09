<?php

namespace App\Http\Controllers;

use App\Models\Academy;
use App\Models\CoachProfile;
use Illuminate\Http\Request;

class DirectoryController extends Controller
{
    public function academies(Request $request)
    {
        $query = Academy::published()->with(['city', 'logo', 'sports.sport']);

        $query->when($request->sport_id, fn ($q) => $q->whereHas('sports', fn ($s) => $s->whereIn('sport_id', (array) $request->sport_id)))
            ->when($request->city_id, fn ($q) => $q->where('city_id', $request->city_id))
            ->when($request->fee_min, fn ($q) => $q->where('fee_range', '>=', $request->fee_min))
            ->when($request->fee_max, fn ($q) => $q->where('fee_range', '<=', $request->fee_max))
            ->when($request->age_group_id, fn ($q) => $q->whereJsonContains('age_groups', (int) $request->age_group_id))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub->where('name', 'like', "%{$request->q}%")->orWhere('description', 'like', "%{$request->q}%")))
            ->when($request->sort, fn ($q) => $q->orderBy($request->sort, $request->direction ?? 'asc'), fn ($q) => $q->latest());

        return response()->json($this->paginate($query, $request));
    }

    public function academy(string $id)
    {
        $academy = Academy::published()->with(['city', 'logo', 'cover', 'headCoach', 'coaches', 'sports.sport'])->findOrFail($id);

        return response()->json(['data' => $this->academyResource($academy)]);
    }

    public function coaches(Request $request)
    {
        $query = CoachProfile::where('listing_status', 'published')->with(['city', 'sport', 'photo', 'academy']);

        $query->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->city_id, fn ($q) => $q->where('city_id', $request->city_id))
            ->when($request->fee_min, fn ($q) => $q->where('hourly_rate', '>=', $request->fee_min))
            ->when($request->fee_max, fn ($q) => $q->where('hourly_rate', '<=', $request->fee_max))
            ->when($request->age_group_id, fn ($q) => $q->whereJsonContains('age_groups', (int) $request->age_group_id))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub->where('full_name', 'like', "%{$request->q}%")->orWhere('bio', 'like', "%{$request->q}%")));

        return response()->json($this->paginate($query, $request));
    }

    public function coach(string $id)
    {
        $coach = CoachProfile::where('listing_status', 'published')->with(['city', 'sport', 'photo', 'academy'])->findOrFail($id);

        return response()->json(['data' => $coach]);
    }

    protected function paginate($query, Request $request)
    {
        $perPage = min((int) ($request->per_page ?? 20), 50);

        return $query->paginate($perPage)->withQueryString();
    }

    public function academyResource(Academy $academy): array
    {
        return [
            'id' => $academy->id,
            'name' => $academy->name,
            'description' => $academy->description,
            'address' => $academy->address,
            'google_maps_url' => $academy->google_maps_url,
            'contact_number' => $academy->contact_number,
            'city' => $academy->city?->only(['id', 'name', 'state']),
            'facilities' => $academy->facilities,
            'fee_range' => $academy->fee_range,
            'timings' => $academy->timings,
            'age_groups' => $academy->age_groups,
            'year_established' => $academy->year_established,
            'achievements' => $academy->achievements,
            'email' => $academy->email,
            'website' => $academy->website,
            'verification_badge' => $academy->verification_badge,
            'logo_url' => $academy->logo?->url(),
            'cover_url' => $academy->cover?->url(),
            'sports_offered' => $academy->sports->pluck('sport.name'),
            'head_coach' => $academy->headCoach?->only(['id', 'name']),
            'status' => $academy->listing_status,
        ];
    }
}
