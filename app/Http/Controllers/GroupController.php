<?php

namespace App\Http\Controllers;

use App\Models\Group;
use App\Models\GroupMember;
use Illuminate\Http\Request;

/**
 * Community groups — GET /groups, GET /me/groups, POST /groups/{group}/join,
 * DELETE /groups/{group}/leave. Every payload is shaped for the Flutter
 * `Group` model (member_count / is_member are resolved for the caller).
 */
class GroupController extends Controller
{
    /** GET /groups — popular groups the caller can discover. */
    public function index(Request $request)
    {
        $limit = min((int) $request->query('limit', 20), 50);
        $type = $request->query('type');
        $me = $request->user()?->id;

        $query = Group::where('status', 'active')
            ->withCount('members')
            ->orderByDesc('members_count')
            ->orderByDesc('id');

        if ($type && $type !== 'popular' && in_array($type, Group::TYPES, true)) {
            $query->where('type', $type);
        }

        $groups = $query->get()
            ->map(fn ($g) => $this->shape($g, $me))
            ->values();

        return response()->json(['data' => $groups]);
    }

    /** GET /me/groups — groups the caller has joined. */
    public function mine(Request $request)
    {
        $me = $request->user()->id;

        $groups = Group::where('status', 'active')
            ->whereHas('members', fn ($q) => $q->where('user_id', $me))
            ->withCount('members')
            ->orderBy('name')
            ->get()
            ->map(fn ($g) => $this->shape($g, $me))
            ->values();

        return response()->json(['data' => $groups]);
    }

    /** POST /groups/{group}/join — idempotent membership. */
    public function join(Request $request, Group $group)
    {
        $me = $request->user()->id;

        GroupMember::firstOrCreate(
            ['group_id' => $group->id, 'user_id' => $me],
            ['role' => 'member', 'joined_at' => now()]
        );

        return response()->json(['data' => $this->shape($group->loadCount('members'), $me)]);
    }

    /** DELETE /groups/{group}/leave — idempotent removal. */
    public function leave(Request $request, Group $group)
    {
        GroupMember::where('group_id', $group->id)
            ->where('user_id', $request->user()->id)
            ->delete();

        return response()->json(['data' => ['message' => 'Left group']]);
    }

    /** Shape a group row for the Flutter `Group.fromJson` parser. */
    private function shape(Group $group, ?int $viewerId): array
    {
        $memberCount = $group->members_count ?? $group->members()->count();
        $isMember = $viewerId !== null
            && $group->members()->where('user_id', $viewerId)->exists();

        return [
            'id' => $group->id,
            'name' => $group->name,
            'description' => $group->description,
            'image_url' => $group->image_url,
            'member_count' => (int) $memberCount,
            'is_member' => $isMember,
            'type' => $group->type,
            'created_at' => $group->created_at?->toIso8601String(),
        ];
    }
}
