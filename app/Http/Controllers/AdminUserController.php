<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use App\Models\Sponsorship;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminUserController extends Controller
{
    // ── User management ──

    /** List users with optional role / status / q filters. */
    public function index(Request $request)
    {
        $request->validate([
            'role' => 'nullable|string',
            'status' => 'nullable|string',
            'q' => 'nullable|string',
        ]);

        $query = User::query();

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }
        if ($request->filled('status')) {
            // 'pending' is a Flutter convenience meaning unverified.
            if ($request->status === 'pending') {
                $query->whereNull('email_verified_at');
            } else {
                $query->where('status', $request->status);
            }
        }
        if ($request->filled('q')) {
            $query->where(fn ($q) => $q->where('name', 'like', "%{$request->q}%")
                ->orWhere('email', 'like', "%{$request->q}%"));
        }

        return response()->json($query->latest()->paginate(20));
    }

    public function show(string $id)
    {
        return response()->json(['data' => User::findOrFail($id)]);
    }

    /** Verify + activate a user. */
    public function approve(string $id)
    {
        $user = User::findOrFail($id);
        $user->forceFill(['email_verified_at' => now(), 'status' => 'active'])->save();

        return response()->json(['data' => $user]);
    }

    /** Soft-delete (hide) a user. */
    public function reject(string $id)
    {
        $user = User::findOrFail($id);
        $user->forceFill(['status' => 'deleted'])->save();

        return response()->json(['data' => $user]);
    }

    public function suspend(string $id)
    {
        $user = User::findOrFail($id);
        $user->forceFill(['status' => 'suspended'])->save();

        return response()->json(['data' => $user]);
    }

    public function destroy(string $id)
    {
        User::findOrFail($id)->delete();

        return response()->json([], 204);
    }

    // ── Opportunity (sponsorship listing) review queue ──

    public function opportunities(Request $request)
    {
        $status = $request->input('status', 'published');
        $items = Sponsorship::with('sport', 'sponsor')
            ->where('status', $status)
            ->latest()
            ->paginate(20);

        return response()->json($items);
    }

    public function approveOpportunity(string $id)
    {
        $sponsorship = Sponsorship::findOrFail($id);
        $sponsorship->forceFill(['status' => 'published'])->save();

        return response()->json(['data' => $sponsorship]);
    }

    public function rejectOpportunity(string $id)
    {
        $sponsorship = Sponsorship::findOrFail($id);
        $sponsorship->forceFill(['status' => 'removed'])->save();

        return response()->json(['data' => $sponsorship]);
    }

    // ── Notification broadcast ──

    public function broadcast(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:190',
            'body' => 'required|string',
            'roles' => 'nullable|array',
            'roles.*' => 'string',
        ]);

        $recipients = User::query();
        if (! empty($validated['roles'])) {
            $recipients->whereIn('role', $validated['roles']);
        }
        $recipients->where('status', 'active');

        $now = now();
        $rows = $recipients->pluck('id')->map(fn ($userId) => [
            'user_id' => $userId,
            'type' => 'status_update',
            'title' => $validated['title'],
            'body' => $validated['body'],
            'created_at' => $now,
            'updated_at' => $now,
        ])->all();

        DB::table('notifications')->insert($rows);

        return response()->json(['data' => ['recipients' => count($rows)]], 201);
    }
}
