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

        // Peer discovery: athletes browsing other athletes should not see themselves.
        $ownAthleteId = $request->user()?->athleteProfile?->id;
        if ($ownAthleteId) {
            $query->where('id', '!=', $ownAthleteId);
        }

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

        // Privacy (Phase 2): drop `private` profiles for anyone but self/admin.
        // `followers` is treated as private until a follow graph exists.
        $viewer = $request->user();
        $visible = $paginator->getCollection()->filter(
            fn ($a) => $this->isVisibleTo($a, $viewer)
        )->values();
        $paginator->setCollection($visible);

        // Minors: strip DOB/phone for anyone but self/admin (see maskMinor).
        $visible->each(fn ($a) => $this->maskMinor($a, $viewer));

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

        $this->maskMinor($athlete, request()->user());

        abort_unless(
            $this->isVisibleTo($athlete, request()->user()),
            403,
            'This profile is private.'
        );

        return response()->json(['data' => $athlete]);
    }

    /**
     * Phase-2 visibility gate backed by `users.privacy_settings`.
     */
    public function isVisibleTo(AthleteProfile $athlete, $viewer): bool    {
        $owner = $athlete->user;

        if (! $owner) {
            return true;
        }

        $visibility = PrivacyController::settings($owner)['profile_visibility'] ?? 'public';

        if ($visibility === 'public') {
            return true;
        }

        $isSelf = $viewer && (int) $viewer->id === (int) $athlete->user_id;
        $isAdmin = $viewer && method_exists($viewer, 'isAdmin') && $viewer->isAdmin();

        return (bool) ($isSelf || $isAdmin);
    }

    /**
     * Minors (DOB < 18) expose only what discovery needs: name, sports,
     * achievements and media. Exact birth date and phone are stripped unless
     * the viewer is the athlete themselves or an admin — guardian consent
     * governs contact, never public display.
     */
    public function maskMinor(AthleteProfile $athlete, $viewer): void
    {
        try {
            $dob = $athlete->date_of_birth
                ? \Carbon\Carbon::parse($athlete->date_of_birth)
                : null;
        } catch (\Throwable) {
            $dob = null;
        }

        if ($dob === null || $dob->diffInYears(now()) >= 18) {
            return;
        }

        $isSelf = $viewer && (int) $viewer->id === (int) $athlete->user_id;
        $isAdmin = $viewer && method_exists($viewer, 'isAdmin') && $viewer->isAdmin();

        if ($isSelf || $isAdmin) {
            return;
        }

        $athlete->makeHidden(['date_of_birth', 'phone']);
        $athlete->setAttribute('is_minor', true);
    }
}
