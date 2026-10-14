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
            ->when($request->facility, fn ($q) => $q->whereJsonContains('facilities', $request->facility))
            ->when($request->level, fn ($q) => $q->where('verification_badge', $request->level === 'verified'))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub->where('name', 'like', "%{$request->q}%")->orWhere('description', 'like', "%{$request->q}%")))
            ->when($request->sort, $this->sortBy($request), fn ($q) => $q->latest());

        return response()->json($this->paginate($query, $request));
    }

    public function academy(string $id)
    {
        $academy = Academy::published()->with(['city', 'logo', 'cover', 'headCoach', 'coaches', 'sports.sport', 'owner'])->findOrFail($id);
        $resource = $this->academyResource($academy);
        $resource['social_links'] = SocialLinksController::forUser($academy->owner);

        return response()->json(['data' => $resource]);
    }

    public function coaches(Request $request)
    {
        $query = CoachProfile::where('listing_status', 'published')->with(['city', 'sport', 'photo', 'academy']);

        $query->when($request->sport_id, fn ($q) => $q->where('sport_id', $request->sport_id))
            ->when($request->city_id, fn ($q) => $q->where('city_id', $request->city_id))
            ->when($request->fee_min, fn ($q) => $q->where('fee_structure', '>=', $request->fee_min))
            ->when($request->fee_max, fn ($q) => $q->where('fee_structure', '<=', $request->fee_max))
            ->when($request->age_group_id, fn ($q) => $q->whereJsonContains('age_groups', (int) $request->age_group_id))
            ->when($request->level && \Illuminate\Support\Facades\Schema::hasColumn('coach_profiles', 'skill_level'), fn ($q) => $q->where('skill_level', $request->level))
            ->when($request->experience_years && \Illuminate\Support\Facades\Schema::hasColumn('coach_profiles', 'experience_years'), fn ($q) => $q->where('experience_years', '>=', (int) $request->experience_years))
            ->when($request->rating && \Illuminate\Support\Facades\Schema::hasColumn('coach_profiles', 'avg_rating'), fn ($q) => $q->where('avg_rating', '>=', (float) $request->rating))
            ->when($request->q, fn ($q) => $q->where(fn ($sub) => $sub->where('full_name', 'like', "%{$request->q}%")->orWhere('bio', 'like', "%{$request->q}%")))
            ->when($request->sort, $this->sortBy($request), fn ($q) => $q->latest());

        return response()->json($this->paginate($query, $request));
    }

    public function coach(string $id)
    {
        $coach = CoachProfile::where('listing_status', 'published')->with(['city', 'sport', 'photo', 'academy', 'user'])->findOrFail($id);
        $coach->setAttribute('social_links', SocialLinksController::forUser($coach->user));
        $coach->unsetRelation('user');

        return response()->json(['data' => $coach]);
    }

    /** Whitelist sort columns to keep the API safe + default fallback. */
    protected function sortBy(Request $request): \Closure
    {
        $allowed = ['name', 'created_at', 'verification_badge', 'year_established'];
        $field = in_array($request->sort, $allowed, true) ? $request->sort : 'created_at';
        $dir = strtolower($request->direction ?? 'desc') === 'asc' ? 'asc' : 'desc';

        return function ($q) use ($field, $dir) {
            $q->orderBy($field, $dir);
            // Sort by experience/avg_rating only when the column exists, and
            // tie-break on name so the result is deterministic.
            if ($field === 'experience_years' && \Illuminate\Support\Facades\Schema::hasColumn($q->getModel()->getTable(), 'experience_years')) {
                $q->orderBy('experience_years', $dir)->orderBy('name', 'asc');
            } elseif (\Illuminate\Support\Facades\Schema::hasColumn($q->getModel()->getTable(), 'avg_rating')) {
                $q->orderBy('avg_rating', $dir)->orderBy('name', 'asc');
            }
        };
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
