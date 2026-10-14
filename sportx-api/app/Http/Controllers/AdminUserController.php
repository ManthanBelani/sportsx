<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use App\Models\Sponsorship;
use App\Models\User;
use App\Services\NotificationService;
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
        $this->notifyAccountAction($user, 'approved', 'Your SportX account was approved. Welcome!');

        return response()->json(['data' => $user]);
    }

    /** Soft-delete (hide) a user. */
    public function reject(string $id)
    {
        $user = User::findOrFail($id);
        $user->forceFill(['status' => 'deleted'])->save();
        $this->notifyAccountAction($user, 'rejected', 'Your SportX account application was not approved.');

        return response()->json(['data' => $user]);
    }

    public function suspend(string $id)
    {
        $user = User::findOrFail($id);
        $user->forceFill(['status' => 'suspended'])->save();
        $this->notifyAccountAction($user, 'suspended', 'Your SportX account was suspended. Contact support.');

        return response()->json(['data' => $user]);
    }

    /**
     * account_action hard override: always in-app + email, bypasses prefs.
     * NotificationService::create handles both legs.
     */
    protected function notifyAccountAction(User $user, string $outcome, string $body): void
    {
        try {
            NotificationService::createStatic([
                'user_id' => $user->id,
                'type' => 'account_action',
                'title' => "Account {$outcome}",
                'body' => $body,
                'action_url' => '/account-status',
            ]);
        } catch (\Throwable) {
        }
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

    // ── Notification broadcast (Phase 9: channels in_app+push, chunked fan-out) ──

    public function broadcast(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:190',
            'body' => 'required|string',
            'roles' => 'nullable|array',
            'roles.*' => 'string',
            'channels' => 'nullable|array',
            'channels.*' => 'in:in_app,push',
        ]);

        $channels = $validated['channels'] ?? ['in_app', 'push'];
        $wantsInApp = in_array('in_app', $channels, true);
        $wantsPush = in_array('push', $channels, true);

        $recipients = User::query();
        if (! empty($validated['roles'])) {
            $recipients->whereIn('role', $validated['roles']);
        }
        $ids = $recipients->where('status', 'active')->pluck('id')->all();

        $created = 0;
        $pushed = 0;
        $fallback = 0;
        if ($wantsPush) {
            // Per-user create: one in-app row + chunked push fan-out each
            // (prefs gate + email fallback live inside NotificationService).
            foreach ($ids as $userId) {
                try {
                    NotificationService::createStatic([
                        'user_id' => $userId,
                        'type' => 'broadcast',
                        'title' => $validated['title'],
                        'body' => $validated['body'],
                    ]);
                    $created++;
                    $pushed++;
                } catch (\Throwable) {
                    $fallback++;
                }
            }
        } elseif ($wantsInApp) {
            // In-app only: chunked insert so a 10k broadcast never builds
            // one giant query.
            foreach (array_chunk($ids, 500) as $chunk) {
                $now = now();
                $rows = array_map(fn ($userId) => [
                    'user_id' => $userId,
                    'type' => 'broadcast',
                    'category' => 'broadcasts',
                    'title' => $validated['title'],
                    'body' => $validated['body'],
                    'push_status' => 'suppressed',
                    'created_at' => $now,
                    'updated_at' => $now,
                ], $chunk);
                DB::table('notifications')->insert($rows);
                $created += count($rows);
            }
        }

        return response()->json(['data' => [
            'recipients' => count($ids),
            'in_app_rows' => $created,
            'push_queued' => $pushed,
            'failed' => $fallback,
            'channels' => $channels,
        ]], 201);
    }
}
