<?php

namespace App\Http\Controllers;

use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\Block;
use App\Models\CoachProfile;
use App\Models\Follow;
use App\Models\OrganizerProfile;
use App\Models\TalentScoutProfile;
use App\Models\User;
use Illuminate\Http\Request;

class FollowController extends Controller
{
    /** Resolve a profile type+id to its owner user id. */
    public static function resolveUserId(string $type, int $id): ?int
    {
        $type = strtolower($type);
        return match ($type) {
            'user' => User::where('id', $id)->value('id'),
            'athlete', 'athlete_profile' => AthleteProfile::where('id', $id)->value('user_id'),
            'coach', 'coach_profile' => CoachProfile::where('id', $id)->value('user_id'),
            'academy' => Academy::where('id', $id)->value('user_id'),
            'organizer', 'organizer_profile' => OrganizerProfile::where('id', $id)->value('user_id'),
            'scout', 'talent_scout', 'talent_scout_profile' => TalentScoutProfile::where('id', $id)->value('user_id'),
            default => null,
        };
    }

    /** One-way follow: POST /follow/{type}/{id} */
    public function store(Request $request, string $type, int $id)
    {
        $targetUserId = static::resolveUserId($type, $id);
        abort_if(!$targetUserId, 404, 'Profile not found.');

        $me = $request->user()->id;
        abort_if($targetUserId === $me, 422, 'You cannot follow yourself.');
        if (Block::hasBlockBetween($me, $targetUserId)) {
            return response()->json(['error' => ['code' => 'BLOCKED', 'message' => 'Follow unavailable.']], 403);
        }

        $follow = Follow::firstOrCreate([
            'follower_user_id' => $me,
            'followee_user_id' => $targetUserId,
        ]);

        return response()->json(['data' => $follow], $follow->wasRecentlyCreated ? 201 : 200);
    }

    /** DELETE /follow/{type}/{id} */
    public function destroy(Request $request, string $type, int $id)
    {
        $targetUserId = static::resolveUserId($type, $id);
        abort_if(!$targetUserId, 404, 'Profile not found.');

        Follow::where('follower_user_id', $request->user()->id)
            ->where('followee_user_id', $targetUserId)
            ->delete();

        return response()->json(['data' => ['message' => 'Unfollowed']]);
    }

    /** GET /me/following */
    public function following(Request $request)
    {
        $rows = Follow::where('follower_user_id', $request->user()->id)
            ->with('followee')
            ->latest()
            ->paginate(30);

        return response()->json($rows);
    }

    /** GET /me/followers */
    public function followers(Request $request)
    {
        $rows = Follow::where('followee_user_id', $request->user()->id)
            ->with('follower')
            ->latest()
            ->paginate(30);

        return response()->json($rows);
    }
}
