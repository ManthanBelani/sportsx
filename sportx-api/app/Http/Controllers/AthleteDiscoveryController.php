<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use Illuminate\Http\Request;

class AthleteDiscoveryController extends Controller
{
    public function index(Request $request)
    {
        $query = AthleteProfile::with(['user', 'sports', 'city', 'ageGroup', 'photo', 'achievements'])
            ->withCount('achievements')
            ->whereHas('sports');

        // Support aliases: q / search / query / keyword all mean text search; sport_id may be array or single; age_group_id / city_id / skill_level / has_achievements
        $search = $request->input('q') ?? $request->input('search') ?? $request->input('query') ?? $request->input('keyword');
        $sportId = $request->input('sport_id');
        $cityId = $request->input('city_id');
        $ageGroupId = $request->input('age_group_id');
        $skillLevel = $request->input('skill_level');
        $hasAchievements = $request->boolean('has_achievements') || $request->boolean('hasAchievements');

        $query->when($sportId, fn ($q) => $q->whereHas('sports', fn ($s) => $s->whereIn('sports.id', (array) $sportId)))
            ->when($ageGroupId, fn ($q) => $q->where('age_group_id', $ageGroupId))
            ->when($cityId, fn ($q) => $q->where('city_id', $cityId))
            ->when($skillLevel, fn ($q) => $q->where('skill_level', $skillLevel))
            ->when($search, fn ($q) => $q->where(function ($w) use ($search) {
                $w->where('full_name', 'like', "%{$search}%")
                  ->orWhereHas('user', fn ($u) => $u->where('name', 'like', "%{$search}%"));
            }))
            ->when($hasAchievements, fn ($q) => $q->has('achievements'));

        $perPage = min((int) ($request->input('per_page') ?? 20), 50);
        $paginator = $query->paginate($perPage);

        // Ensure achievements_count is appended (withCount) and include pagination meta compatibility for mobile DirectoryNotifier
        return response()->json($paginator);
    }

    public function show(string $id)
    {
        $athlete = AthleteProfile::with(['user', 'sports', 'city', 'ageGroup', 'photo', 'academy', 'coach', 'achievements', 'mediaItems'])
            ->withCount('achievements')
            ->findOrFail($id);

        // Append media gallery URLs via mediaItems relation mapped to expected key
        $athlete->setAttribute('media', $athlete->mediaItems->map(fn ($m) => [
            'id' => $m->id,
            'url' => $m->url,
            'media_type' => $m->media_type,
            'type' => $m->media_type,
        ]));

        return response()->json(['data' => $athlete]);
    }
}
