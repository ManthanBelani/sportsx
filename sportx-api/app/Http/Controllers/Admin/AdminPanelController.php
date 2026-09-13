<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Academy;
use App\Models\AgeGroup;
use App\Models\City;
use App\Models\CoachProfile;
use App\Models\ListingReport;
use App\Models\Scholarship;
use App\Models\Sport;
use App\Models\Sponsorship;
use App\Models\SportsVenue;
use App\Models\Tournament;
use App\Models\Trial;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class AdminPanelController extends Controller
{
    // ── Auth ──────────────────────────────────────────────────────────────────

    public function showLogin()
    {
        if (Auth::check() && Auth::user()->role === 'admin') {
            return redirect()->route('admin.dashboard');
        }

        return view('admin.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', strtolower($credentials['email']))->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            return back()->with('error', 'Invalid email or password.')->withInput();
        }

        if ($user->role !== 'admin') {
            return back()->with('error', 'Admin credentials required.')->withInput();
        }

        Auth::login($user, $request->boolean('remember'));
        $request->session()->regenerate();

        return redirect()->route('admin.dashboard');
    }

    public function show2fa()
    {
        // 2FA disabled for MVP — show placeholder instead of silent redirect.
        // TODO(P0): implement TOTP (pragmarx/google2fa). Do not ship without.
        if (! Auth::check()) {
            return redirect()->route('admin.login');
        }
        return view('admin.twofa', ['error' => '2FA is not enabled. Contact engineering before production.']);
    }

    public function verify2fa(Request $request)
    {
        // 2FA disabled — stub. Replace with real TOTP verification before prod.
        return redirect()->route('admin.dashboard')->with('error', '2FA verification is disabled in this build — enable TOTP before production.');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }

    // ── Dashboard ──────────────────────────────────────────────────────────────

    public function dashboard()
    {
        $statusCol = self::statusColumnMap();

        $activeListings = Academy::where($statusCol['academies'], 'published')->count()
            + CoachProfile::where($statusCol['coaches'], 'published')->count()
            + Trial::where('status', 'published')->count()
            + Tournament::where('status', 'published')->count()
            + Sponsorship::where('status', 'published')->count();

        $stats = [
            'active_listings' => $activeListings,
            'flagged_items' => ListingReport::where('status', 'pending')->count(),
            'new_signups_30d' => User::where('created_at', '>=', now()->subDays(30))->count(),
            'total_users' => User::count(),
            'total_sports' => Sport::count(),
            'total_cities' => City::count(),
            'pending_users' => User::where('status','pending')->whereIn('role',['coach','sponsor','talent_scout'])->count(),
            'pending_trials' => Trial::where('status','draft')->count(),
            'pending_tournaments' => Tournament::where('status','draft')->count(),
        ];

        $recentUsers = User::latest()->limit(8)->get();
        $pendingReports = ListingReport::where('status', 'pending')->latest()->limit(6)->get();

        // Weekly activity: new signups per day for the last 7 days.
        $weekly = [];
        for ($i = 6; $i >= 0; $i--) {
            $day = now()->subDays($i)->startOfDay();
            $weekly[$day->format('D')] = User::whereBetween('created_at', [$day, (clone $day)->endOfDay()])->count();
        }
        $weekMax = max(1, max($weekly));
        $weekSignups = array_sum($weekly);

        return view('admin.dashboard', compact('stats', 'recentUsers', 'pendingReports', 'weekly', 'weekMax', 'weekSignups'));
    }

    // ── Users ──────────────────────────────────────────────────────────────────

    public function users(Request $request)
    {
        $query = User::query();

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }
        if ($request->filled('status')) {
            $status = $request->status === 'rejected' ? 'deleted' : $request->status;
            $query->where('status', $status);
        }
        if ($request->filled('q')) {
            $q = $request->q;
            $query->where(fn ($b) => $b->where('name', 'like', "%{$q}%")->orWhere('email', 'like', "%{$q}%"));
        }

        $users = $query->latest()->paginate(25)->appends($request->only('role', 'status', 'q'));

        return view('admin.users', ['users' => $users]);
    }

    public function userDetail($id)
    {
        $user = User::findOrFail($id);

        return view('admin.user_detail', ['u' => $user]);
    }

    public function updateUserStatus(Request $request, $id)
    {
        $data = $request->validate([
            'action' => ['required', 'in:activate,suspend,reject'],
        ]);

        $user = User::findOrFail($id);
        if ($user->role === 'admin') {
            return back()->with('error', 'Cannot modify an admin account from here.');
        }

        // users.status enum is ['active','suspended','deleted'] — map 'reject' to 'deleted'
        $user->status = match ($data['action']) {
            'activate' => 'active',
            'suspend' => 'suspended',
            'reject' => 'deleted',
        };
        $user->save();

        return back()->with('success', 'User updated.');
    }

    public function destroyUser($id)
    {
        $user = User::findOrFail($id);
        if ($user->role === 'admin') {
            return back()->with('error', 'Cannot delete an admin account.');
        }
        $user->delete();

        return redirect()->route('admin.users')->with('success', 'User deleted.');
    }

    // ── Content ────────────────────────────────────────────────────────────────

    public function content()
    {
        $map = self::contentModels();
        $statusCol = self::statusColumnMap();

        $counts = [];
        foreach ($map as $type => $model) {
            $col = $statusCol[$type];
            $counts[$type] = [
                'total' => $model::count(),
                'published' => $model::where($col, 'published')->count(),
                'draft' => $model::where($col, 'draft')->count(),
            ];
        }

        return view('admin.content', ['counts' => $counts]);
    }

    public function contentList($type)
    {
        $model = self::contentModels()[$type] ?? null;
        abort_unless($model, 404);

        $items = $model::latest()->paginate(25);

        return view('admin.content_list', [
            'type' => $type,
            'items' => $items,
            'statusCol' => self::statusColumnMap()[$type],
        ]);
    }

    public function contentDestroy($type, $id)
    {
        $model = self::contentModels()[$type] ?? null;
        abort_unless($model, 404);

        $model::findOrFail($id)->delete();

        return back()->with('success', 'Item deleted.');
    }

    public function contentPublish(Request $request, $type, $id)
    {
        $model = self::contentModels()[$type] ?? null;
        abort_unless($model, 404);

        $col = self::statusColumnMap()[$type];
        $item = $model::findOrFail($id);
        $item->{$col} = $request->boolean('publish') ? 'published' : 'draft';
        $item->save();

        return back()->with('success', 'Status updated.');
    }

    // ── Moderation (merged with Approvals) ─────────────────────────────────────

    public function moderation(Request $request)
    {
        $status = $request->get('status', 'pending');

        $query = ListingReport::query();
        if ($status !== 'all') {
            $query->where('status', $status);
        }
        $reports = $query->latest()->paginate(25, ['*'], 'reports_page')->appends(['status' => $status]);

        $counts = [
            'pending' => ListingReport::where('status', 'pending')->count(),
            'approved' => ListingReport::where('status', 'approved')->count(),
            'removed' => ListingReport::whereIn('status', ['removed', 'warned'])->count(),
            'all' => ListingReport::count(),
        ];

        // Approvals merged in
        $pendingUsers = User::where('status', 'pending')->whereIn('role', ['coach','sponsor','talent_scout'])->latest()->paginate(10, ['*'], 'users_page');
        $pendingTrials = Trial::where('status','draft')->with(['sport','city'])->latest()->paginate(10, ['*'], 'trials_page');
        $pendingTournaments = Tournament::where('status','draft')->with(['sport','city'])->latest()->paginate(10, ['*'], 'tournaments_page');
        $approvalCounts = [
            'users' => User::where('status','pending')->whereIn('role',['coach','sponsor','talent_scout'])->count(),
            'trials' => Trial::where('status','draft')->count(),
            'tournaments' => Tournament::where('status','draft')->count(),
        ];
        $settings = $this->readSettings();

        return view('admin.moderation', compact('reports','status','counts','pendingUsers','pendingTrials','pendingTournaments','approvalCounts','settings'));
    }

    public function moderationAction(Request $request, $id)
    {
        $data = $request->validate(['action' => ['required', 'in:approve,remove,warn']]);
        $report = ListingReport::findOrFail($id);

        if ($data['action'] === 'remove') {
            $reportable = $report->reportable; // morph relation
            if ($reportable) {
                $reportable->delete();
            }
        }

        $report->update([
            'status' => $data['action'] === 'approve' ? 'approved' : ($data['action'] === 'remove' ? 'removed' : 'warned'),
            'resolved_at' => now(),
            'resolved_by' => Auth::id(),
        ]);

        return back()->with('success', 'Report '.ucfirst($data['action']).'d.');
    }

    // ── Categories ─────────────────────────────────────────────────────────────

    public function categories()
    {
        return view('admin.categories', [
            'sports' => Sport::orderBy('sort_order')->get(),
            'cities' => City::orderBy('name')->get(),
            'ageGroups' => AgeGroup::orderBy('min_age')->get(),
        ]);
    }

    public function categoryStore(Request $request, $type)
    {
        $rules = match ($type) {
            'sports' => ['name' => 'required|string|max:60|unique:sports,name', 'sort_order' => 'nullable|integer'],
            'cities' => ['name' => 'required|string|max:60', 'state' => 'nullable|string|max:60'],
            'age-groups' => ['name' => 'required|string|max:30|unique:age_groups,name', 'min_age' => 'nullable|integer', 'max_age' => 'nullable|integer'],
            default => abort(404),
        };

        $messages = [
            'name.unique' => 'This name is already in use. Please choose a different name.',
        ];

        $data = $request->validate($rules, $messages);

        // Extra unique check for city (composite name+state) — validator can't express it simply.
        if ($type === 'cities') {
            $stateForCheck = $data['state'] ?? 'Unknown';
            if ($stateForCheck === '' || $stateForCheck === null) $stateForCheck = 'Unknown';
            if (City::where('name', $data['name'])->where('state', $stateForCheck)->exists()) {
                return back()->with('error', 'This city already exists for the selected state.')->withInput();
            }
        }

        $data['is_active'] = true;

        // Normalize empty values that would violate NOT NULL DB constraints.
        // ConvertEmptyStringsToNull turns "" into null; sports.sort_order and cities.state are NOT NULL.
        if ($type === 'sports') {
            $data['sort_order'] = $data['sort_order'] ?? ((int) Sport::max('sort_order') + 1);
        }
        if ($type === 'cities') {
            $data['state'] = $data['state'] ?? '';
            if ($data['state'] === null || $data['state'] === '') {
                $data['state'] = 'Unknown';
            }
        }

        $model = self::categoryModel($type);
        try {
            $model::create($data);
        } catch (\Throwable $e) {
            return back()->with('error', $this->friendlyCategoryError($e, $type, $data['name'] ?? null))->withInput();
        }

        return back()->with('success', 'Category added.');
    }

    public function categoryDestroy($type, $id)
    {
        $model = self::categoryModel($type);
        $model::findOrFail($id)->delete();

        return back()->with('success', 'Category removed.');
    }

    public function categoryToggle($type, $id)
    {
        $model = self::categoryModel($type);
        $item = $model::findOrFail($id);
        $item->is_active = ! $item->is_active;
        $item->save();

        return back()->with('success', 'Category '.($item->is_active ? 'activated' : 'deactivated').'.');
    }

    // ── Report Center ──────────────────────────────────────────────────────────

    public function reports()
    {
        $reports = ListingReport::with('reporter')->latest()->paginate(25);
        $pendingCount = ListingReport::where('status', 'pending')->count();

        return view('admin.reports', ['reports' => $reports, 'pendingCount' => $pendingCount]);
    }

    public function reportDetail($id)
    {
        $report = ListingReport::with('reporter')->findOrFail($id);

        return view('admin.report-detail', ['report' => $report]);
    }

    public function reportAction(Request $request, $id)
    {
        $data = $request->validate(['action' => ['required', 'in:resolve,escalate']]);
        $report = ListingReport::findOrFail($id);

        if ($data['action'] === 'resolve') {
            $report->update([
                'status' => 'approved',
                'resolved_at' => now(),
                'resolved_by' => Auth::id(),
            ]);
            return back()->with('success', 'Report resolved.');
        }

        // Escalate: mark as critical/pending for deeper review.
        $report->update(['status' => 'pending', 'comment' => ('[ESCALATED] ' . ($report->comment ?? ''))]);

        return back()->with('success', 'Report escalated.');
    }

    // ── Content Flagging ───────────────────────────────────────────────────────

    public function flags()
    {
        $flags = ListingReport::with(['reporter', 'reportable'])->where('status', 'pending')->latest()->paginate(25);
        $activeCount = ListingReport::where('status', 'pending')->count();

        return view('admin.flags', ['flags' => $flags, 'activeCount' => $activeCount]);
    }

    public function flagAction(Request $request, $id)
    {
        $data = $request->validate(['action' => ['required', 'in:remove,warn,dismiss']]);
        $report = ListingReport::findOrFail($id);

        if ($data['action'] === 'remove') {
            $reportable = $report->reportable;
            $reportable?->delete();
            $report->update(['status' => 'removed', 'resolved_at' => now(), 'resolved_by' => Auth::id()]);
        } elseif ($data['action'] === 'warn') {
            $report->update(['status' => 'warned', 'resolved_at' => now(), 'resolved_by' => Auth::id()]);
        } else {
            $report->update(['status' => 'approved', 'resolved_at' => now(), 'resolved_by' => Auth::id()]);
        }

        return back()->with('success', 'Flag '.ucfirst($data['action']).'ed.');
    }

    // ── Sponsor Verification ───────────────────────────────────────────────────

    public function sponsors(Request $request)
    {
        $pendingCount = Sponsorship::where('status', '!=', 'published')->count();
        $sponsorships = Sponsorship::with(['sponsor.user'])->latest()->paginate(25);

        return view('admin.sponsors', ['sponsorships' => $sponsorships, 'pendingCount' => $pendingCount]);
    }

    public function sponsorAction(Request $request, $id)
    {
        $data = $request->validate(['action' => ['required', 'in:approve,reject']]);
        $sponsorship = Sponsorship::findOrFail($id);
        $sponsorship->status = $data['action'] === 'approve' ? 'published' : 'closed';
        $sponsorship->save();

        return back()->with('success', 'Sponsorship '.($data['action'] === 'approve' ? 'approved' : 'rejected').'.');
    }

    // ── Analytics ──────────────────────────────────────────────────────────────

    public function analytics()
    {
        $totalUsers = User::count();
        $activeListings = Trial::where('status', 'published')->count()
            + Tournament::where('status', 'published')->count()
            + Sponsorship::where('status', 'published')->count()
            + Academy::where('listing_status', 'published')->count()
            + CoachProfile::where('listing_status', 'published')->count();

        $roleDistribution = User::select('role', \DB::raw('count(*) as cnt'))
            ->groupBy('role')->pluck('cnt', 'role');

        $topSports = \DB::table('sports')
            ->leftJoin('trials', 'trials.sport_id', '=', 'sports.id')
            ->select('sports.id', 'sports.name', \DB::raw('count(trials.id) as cnt'))
            ->groupBy('sports.id', 'sports.name')
            ->orderByDesc('cnt')
            ->limit(6)
            ->get();

        // Signups over the past 6 months
        $growth = [];
        for ($i = 5; $i >= 0; $i--) {
            $month = now()->subMonths($i)->startOfMonth();
            $growth[$month->format('M')] = User::whereBetween('created_at', [$month, (clone $month)->endOfMonth()])->count();
        }
        $growthMax = max(1, max($growth));

        $monthlySignups = User::where('created_at', '>=', now()->startOfMonth())->count();
        $verifiedRate = $totalUsers ? round(User::whereNotNull('email_verified_at')->count() / $totalUsers * 100) : 0;

        return view('admin.analytics', compact('totalUsers', 'activeListings', 'roleDistribution', 'topSports', 'growth', 'growthMax', 'monthlySignups', 'verifiedRate'));
    }

    // ── Notification Templates / Broadcast ─────────────────────────────────────

    public function notifications()
    {
        $templates = collect([
            // ['type' => 'email', 'name' => 'Welcome to SportX', 'body' => 'Welcome to SportX India! Explore trials, tournaments, and scholarships near you.'], // disabled: email global messaging
            ['type' => 'push', 'name' => 'Trial Reminder', 'body' => 'Reminder: your trial is tomorrow. Don\'t forget your gear!'],
            // ['type' => 'sms', 'name' => 'Scholarship Deadline', 'body' => 'SportX: Last day to apply for the scholarship. Apply now at sportx.in'], // disabled: sms global messaging
        ]);

        $typeMap = ['email' => 'status_update', 'push' => 'reminder', 'sms' => 'enquiry_reply'];
        $rawCounts = \App\Models\Notification::select('type', \DB::raw('count(*) as cnt'))
            ->groupBy('type')->pluck('cnt', 'type');
        $sent = collect($typeMap)->mapWithKeys(fn ($real, $display) => [$display => $rawCounts[$real] ?? 0]);
        $sent['_total'] = $rawCounts->sum();

        // Role counts for targeting UI
        $roleCounts = User::select('role', \DB::raw('count(*) as cnt'))->where('status','active')->groupBy('role')->pluck('cnt','role');
        $totalActive = User::where('status','active')->count();
        $fcmEnabled = app(\App\Services\FCMService::class)->isEnabled();

        return view('admin.notifications', ['templates' => $templates, 'sent' => $sent, 'roleCounts' => $roleCounts, 'totalActive' => $totalActive, 'fcmEnabled' => $fcmEnabled]);
    }

    public function broadcast(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:120',
            'body' => 'required|string|max:500',
            'type' => 'required|in:info,success,warning',
            'roles' => 'nullable|array',
            'roles.*' => 'in:athlete,coach,academy,organizer,sponsor,talent_scout,admin',
            'channels' => 'nullable|array',
            'channels.*' => 'in:in_app,push',
        ]);

        $targetRoles = $data['roles'] ?? [];
        $channels = $data['channels'] ?? ['in_app']; // default in-app only for backward compat
        // Legacy checkbox support: send_push/send_in_app booleans
        if ($request->has('send_push') || $request->has('send_in_app')) {
            $channels = [];
            if ($request->boolean('send_in_app')) $channels[] = 'in_app';
            if ($request->boolean('send_push')) $channels[] = 'push';
            if (empty($channels)) $channels = ['in_app'];
        }
        if (empty($channels)) $channels = ['in_app'];

        $sendInApp = in_array('in_app', $channels);
        $sendPush  = in_array('push', $channels);

        // Build base query for targeted users
        $userQuery = User::where('status','active');
        if (!empty($targetRoles)) {
            $userQuery->whereIn('role', $targetRoles);
        }

        $inAppCount = 0;
        $pushCount = 0;

        // 1) In-app notifications (DB)
        if ($sendInApp) {
            // Map panel type -> DB enum type
            $dbType = match($data['type']) {
                'success' => 'status_update',
                'warning' => 'reminder',
                default => 'status_update',
            };
            $userQuery->select('id')->chunk(200, function ($users) use ($data, $dbType, &$inAppCount) {
                $rows = $users->map(fn ($u) => [
                    'user_id' => $u->id,
                    'type' => $dbType,
                    'title' => $data['title'],
                    'body' => $data['body'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ])->all();
                \App\Models\Notification::insert($rows);
                $inAppCount += count($rows);
            });
        } else {
            $inAppCount = $userQuery->count();
        }

        // 2) Push via FCM
        $fcmResult = null;
        if ($sendPush) {
            $fcmService = app(\App\Services\FCMService::class);
            if (!$fcmService->isEnabled()) {
                return back()->with('error', 'FCM is not configured (FCM_PROJECT_ID / credentials missing). In-app notifications were'.($sendInApp ? " sent to {$inAppCount} users." : ' not sent.'));
            }

            $userIds = (clone $userQuery)->pluck('id')->all();
            $tokens = \App\Models\UserDeviceToken::whereIn('user_id', $userIds)->active()->pluck('token')->filter()->unique()->values()->all();

            if (empty($tokens)) {
                return back()->with('success', 'In-app sent to '.($sendInApp ? $inAppCount : 0).' users. No active device tokens found for push — recipients will see it on next app open.');
            }

            // Chunk tokens 500 per FCM multicast (FCM limit)
            foreach (array_chunk($tokens, 500) as $chunk) {
                \App\Jobs\SendPushNotification::dispatch(
                    $chunk,
                    $data['title'],
                    $data['body'],
                    [
                        'type' => $data['type'],
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'roles' => implode(',', $targetRoles),
                    ]
                );
                $pushCount += count($chunk);
            }
        }

        $roleLabel = empty($targetRoles) ? 'all users' : implode(', ', array_map(fn($r)=>ucfirst(str_replace('_',' ',$r)), $targetRoles));
        $parts = [];
        if ($sendInApp) $parts[] = "In-app to {$inAppCount} ({$roleLabel})";
        if ($sendPush) $parts[] = "Push queued to {$pushCount} devices ({$roleLabel})";
        return back()->with('success', 'Broadcast sent: '.implode(' + ', $parts).'.');
    }

    // ── Approvals (legacy — merged into Moderation) ───────────────────────────
    public function approvals(Request $request)
    {
        return redirect()->route('admin.moderation');
    }

    public function approveUser($id)
    {
        $user = User::where('status','pending')->findOrFail($id);
        $user->status = 'active';
        $user->save();
        return back()->with('success', ucfirst($user->role).' approved — login now allowed.');
    }

    public function rejectUser($id)
    {
        $user = User::where('status','pending')->findOrFail($id);
        $user->status = 'deleted';
        $user->save();
        return back()->with('success', 'Registration rejected.');
    }

    public function approveTrial($id)
    {
        $trial = Trial::where('status','draft')->findOrFail($id);
        $trial->status = 'published';
        $trial->save();
        app(\App\Services\ExpiryService::class)->onPublish($trial, 'trial');
        return back()->with('success', 'Trial approved and now visible to users.');
    }

    public function rejectTrial($id)
    {
        $trial = Trial::where('status','draft')->findOrFail($id);
        $trial->status = 'closed';
        $trial->save();
        return back()->with('success', 'Trial rejected.');
    }

    public function approveTournament($id)
    {
        $tournament = Tournament::where('status','draft')->findOrFail($id);
        $tournament->status = 'published';
        $tournament->save();
        app(\App\Services\ExpiryService::class)->onPublish($tournament, 'tournament');
        return back()->with('success', 'Tournament approved and now visible to users.');
    }

    public function rejectTournament($id)
    {
        $tournament = Tournament::where('status','draft')->findOrFail($id);
        $tournament->status = 'closed';
        $tournament->save();
        return back()->with('success', 'Tournament rejected.');
    }

    // ── System Settings ────────────────────────────────────────────────────────

    private function settingsPath(): string
    {
        return storage_path('app/platform_settings.json');
    }

    private function readSettings(): array
    {
        $defaults = [
            'moderation_required' => true,
            'auto_verify_coaches' => false,
            // Per-type auto-approve — if true, new entries go live immediately; if false, they stay pending/draft
            'auto_approve_coach' => false,
            'auto_approve_sponsor' => false,
            'auto_approve_talent_scout' => false,
            'auto_approve_trials' => false,
            'auto_approve_tournaments' => false,
            'auto_approve_scholarships' => false,
            'auto_approve_sponsorships' => false,
            'auto_approve_academies' => false,
            'auto_approve_venues' => false,
            'email_alerts' => true,
            'push_notifications' => true,
            'suspicious_login_detection' => true,
            'maintenance_mode' => false,
            // Platform access & limits
            'registrations_open' => true,
            'max_listings_per_user_per_day' => 5,
            'media_max_size_mb' => 10,
            'session_lifetime_minutes' => 30,
            'rate_limit_login_per_minute' => 10,
            'audit_log_enabled' => true,
            // Data & compliance
            'data_retention_days' => 365,
            'allow_user_data_export' => true,
            'allow_user_data_delete' => true,
        ];
        $path = $this->settingsPath();
        if (file_exists($path)) {
            $stored = json_decode((string) file_get_contents($path), true) ?: [];
            return array_merge($defaults, array_intersect_key($stored, $defaults));
        }
        return $defaults;
    }

    public function settings()
    {
        return view('admin.settings', ['settings' => $this->readSettings()]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'moderation_required' => 'nullable|boolean',
            'auto_verify_coaches' => 'nullable|boolean',
            'auto_approve_coach' => 'nullable|boolean',
            'auto_approve_sponsor' => 'nullable|boolean',
            'auto_approve_talent_scout' => 'nullable|boolean',
            'auto_approve_trials' => 'nullable|boolean',
            'auto_approve_tournaments' => 'nullable|boolean',
            'auto_approve_scholarships' => 'nullable|boolean',
            'auto_approve_sponsorships' => 'nullable|boolean',
            'auto_approve_academies' => 'nullable|boolean',
            'auto_approve_venues' => 'nullable|boolean',
            'email_alerts' => 'nullable|boolean',
            'push_notifications' => 'nullable|boolean',
            'suspicious_login_detection' => 'nullable|boolean',
            'maintenance_mode' => 'nullable|boolean',
            'registrations_open' => 'nullable|boolean',
            'audit_log_enabled' => 'nullable|boolean',
            'allow_user_data_export' => 'nullable|boolean',
            'allow_user_data_delete' => 'nullable|boolean',
            'max_listings_per_user_per_day' => 'nullable|integer|min:1|max:100',
            'media_max_size_mb' => 'nullable|integer|min:1|max:100',
            'session_lifetime_minutes' => 'nullable|integer|in:15,30,60,120,240,480',
            'rate_limit_login_per_minute' => 'nullable|integer|min:5|max:100',
            'data_retention_days' => 'nullable|integer|min:30|max:3650',
        ]);
        $defaults = $this->readSettings();
        $intKeys = ['max_listings_per_user_per_day','media_max_size_mb','session_lifetime_minutes','rate_limit_login_per_minute','data_retention_days'];
        $boolKeys = array_diff(array_keys($defaults), $intKeys);
        $settings = [];
        foreach ($boolKeys as $key) {
            $settings[$key] = $request->boolean($key);
        }
        foreach ($intKeys as $key) {
            $settings[$key] = $validated[$key] ?? $defaults[$key];
            $settings[$key] = (int) $settings[$key];
        }
        file_put_contents($this->settingsPath(), json_encode($settings, JSON_PRETTY_PRINT));

        return back()->with('success', 'Settings saved.');
    }

    // ── Content create / edit (POST + PUT endpoints) ───────────────────────────

    public function contentCreate($type)
    {
        $model = self::contentModels()[$type] ?? abort(404);

        return view('admin.content_form', $this->editorViewData($type, $model, null));
    }

    public function contentStore(Request $request, $type)
    {
        $model = self::contentModels()[$type] ?? abort(404);
        try {
            $data = $this->extractFields($request, $model);
            $data = $this->injectOwnerOnBehalf($request, $type, $data);
            $model::create($data);
        } catch (\Throwable $e) {
            return back()->with('error', $this->friendlyContentError($e, 'create'))->withInput();
        }

        return redirect()->route('admin.content.list', $type)->with('success', 'Item created.');
    }

    public function contentEdit($type, $id)
    {
        $model = self::contentModels()[$type] ?? abort(404);
        $item = $model::findOrFail($id);

        return view('admin.content_form', $this->editorViewData($type, $model, $item));
    }

    public function contentUpdate(Request $request, $type, $id)
    {
        $model = self::contentModels()[$type] ?? abort(404);
        $item = $model::findOrFail($id);
        try {
            $data = $this->extractFields($request, $model);
            $data = $this->injectOwnerOnBehalf($request, $type, $data, $item);
            $item->update($data);
        } catch (\Throwable $e) {
            return back()->with('error', $this->friendlyContentError($e, 'update'))->withInput();
        }

        return redirect()->route('admin.content.list', $type)->with('success', 'Item updated.');
    }

    // ── Expiry monitor (GET /expiry/monitor + override + restore) ──────────────

    public function expiry(Request $request)
    {
        $tab = $request->get('tab', 'pending');
        $events = \App\Models\ExpiryEvent::where('status', $tab)
            ->orderBy('scheduled_at')->paginate(25)->appends(['tab' => $tab]);

        $counts = [
            'pending' => \App\Models\ExpiryEvent::where('status', 'pending')->count(),
            'expired' => \App\Models\ExpiryEvent::where('status', 'expired')->count(),
            'overridden' => \App\Models\ExpiryEvent::where('status', 'overridden')->count(),
        ];

        $rules = \App\Models\ExpiryRule::orderBy('content_type')->get();

        return view('admin.expiry', compact('events', 'tab', 'counts', 'rules'));
    }

    public function expiryOverride($id)
    {
        $event = \App\Models\ExpiryEvent::findOrFail($id);
        $event->update(['status' => 'overridden', 'overridden_by' => Auth::id()]);
        $this->republishContent($event);

        return back()->with('success', 'Expiry overridden — listing kept live.');
    }

    public function expiryRestore($id)
    {
        $event = \App\Models\ExpiryEvent::findOrFail($id);
        $event->update(['status' => 'restored', 'overridden_by' => Auth::id()]);

        return back()->with('success', 'Listing restored.');
    }

    public function expiryRulesUpdate(Request $request)
    {
        $data = $request->validate([
            'rules' => ['required', 'array'],
            'rules.*.id' => ['required', 'integer'],
            'rules.*.days_after' => ['required', 'integer', 'min:1'],
            'rules.*.trigger_field' => ['nullable', 'string'],
            'rules.*.is_active' => ['boolean'],
        ]);

        foreach ($data['rules'] as $row) {
            \App\Models\ExpiryRule::where('id', $row['id'])->update([
                'days_after' => $row['days_after'],
                'trigger_field' => $row['trigger_field'] ?? null,
                'is_active' => $row['is_active'] ?? false,
            ]);
        }

        return back()->with('success', 'Expiry rules updated.');
    }

    // ── Category rename (PUT /categories/{type}/{id}) ──────────────────────────

    public function categoryUpdate(Request $request, $type, $id)
    {
        $model = self::categoryModel($type);
        $rules = match ($type) {
            'sports' => ['name' => ['required', 'string', 'max:60'], 'sort_order' => ['nullable', 'integer']],
            'cities' => ['name' => ['required', 'string', 'max:60'], 'state' => ['nullable', 'string', 'max:60']],
            'age-groups' => ['name' => ['required', 'string', 'max:30'], 'min_age' => ['nullable', 'integer'], 'max_age' => ['nullable', 'integer']],
            default => abort(404),
        };

        $data = $request->validate($rules, ['name.unique' => 'This name is already in use.']);
        if ($type === 'sports' && array_key_exists('sort_order', $data) && $data['sort_order'] === null) {
            unset($data['sort_order']); // keep existing value, don't set NOT NULL column to null
        }
        if ($type === 'cities' && array_key_exists('state', $data) && ($data['state'] === null || $data['state'] === '')) {
            $data['state'] = 'Unknown';
        }

        try {
            $model::findOrFail($id)->update($data);
        } catch (\Throwable $e) {
            $name = $data['name'] ?? null;
            return back()->with('error', $this->friendlyCategoryError($e, $type, $name))->withInput();
        }

        return back()->with('success', 'Category updated.');
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    public static function contentModels(): array
    {
        return [
            'academies' => Academy::class,
            'coaches' => CoachProfile::class,
            'trials' => Trial::class,
            'tournaments' => Tournament::class,
            'scholarships' => Scholarship::class,
            'sponsorships' => Sponsorship::class,
            'sports-venues' => SportsVenue::class,
        ];
    }

    public static function statusColumnMap(): array
    {
        return [
            'academies' => 'listing_status',
            'coaches' => 'listing_status',
            'trials' => 'status',
            'tournaments' => 'status',
            'scholarships' => 'status',
            'sponsorships' => 'status',
            'sports-venues' => 'listing_status',
        ];
    }

    private static function categoryModel(string $type): string
    {
        return match ($type) {
            'sports' => Sport::class,
            'cities' => City::class,
            'age-groups' => AgeGroup::class,
            default => abort(404),
        };
    }

    /** Fields the content editor should expose (fillable minus relational/system). */
    private function editableFields(string $modelClass): array
    {
        $skip = [
            'posted_by_user_id', 'owner_user_id', 'organizer_id', 'sponsor_id',
            'user_id', 'created_by', 'academy_id', 'head_coach_id',
            'logo_media_id', 'banner_media_id', 'photo_media_id', 'profile_completed_at',
        ];

        return array_values(array_filter(
            (new $modelClass)->getFillable(),
            fn ($f) => ! in_array($f, $skip)
        ));
    }

    private function ownerConfigForType(string $type): ?array
    {
        return match ($type) {
            'trials' => ['column' => 'posted_by_user_id', 'label' => 'Owner (posting user)', 'roles' => ['organizer','academy','coach','admin']],
            'tournaments' => ['column' => 'organizer_id', 'label' => 'Organizer (on behalf of)', 'roles' => ['organizer','admin']],
            'academies' => ['column' => 'owner_user_id', 'label' => 'Owner (academy user)', 'roles' => ['academy','admin']],
            'coaches' => ['column' => 'user_id', 'label' => 'Coach user', 'roles' => ['coach','admin']],
            'scholarships' => ['column' => 'created_by', 'label' => 'Created by (user)', 'roles' => null],
            'sponsorships' => ['column' => 'sponsor_id', 'label' => 'Sponsor (on behalf of)', 'roles' => ['sponsor','admin']],
            default => null, // sports-venues has no owner column
        };
    }

    private function ownerOptionsForType(string $type): array
    {
        $cfg = $this->ownerConfigForType($type);
        if (! $cfg) return [];
        // sponsorships & tournaments need profile-aware resolution, but options are still users
        $q = User::orderBy('name');
        if (! empty($cfg['roles'])) {
            $q->whereIn('role', $cfg['roles']);
        }
        return $q->limit(200)->get(['id','name','email','role'])->all();
    }

    private function editorViewData(string $type, string $modelClass, ?object $item): array
    {
        $ownerConfig = $this->ownerConfigForType($type);
        $ownerOptions = $this->ownerOptionsForType($type);
        // Resolve current owner user id for edit pre-select
        $currentOwnerUserId = null;
        if ($item && $ownerConfig) {
            $col = $ownerConfig['column'];
            $raw = $item->{$col} ?? null;
            if ($type === 'tournaments' && $raw) {
                $currentOwnerUserId = \App\Models\OrganizerProfile::where('id', $raw)->value('user_id');
            } elseif ($type === 'sponsorships' && $raw) {
                $currentOwnerUserId = \App\Models\SponsorProfile::where('id', $raw)->value('user_id');
            } else {
                $currentOwnerUserId = $raw;
            }
        }
        return [
            'type' => $type,
            'item' => $item,
            'fields' => $this->editableFields($modelClass),
            'arrayFields' => $this->arrayCastFields($modelClass),
            'sports' => Sport::orderBy('name')->get(),
            'cities' => City::orderBy('name')->get(),
            'ageGroups' => AgeGroup::orderBy('min_age')->get(),
            'ownerConfig' => $ownerConfig,
            'ownerOptions' => $ownerOptions,
            'currentOwnerUserId' => $currentOwnerUserId,
        ];
    }

    /** Fields whose values are JSON/array-cast and must be edited as lists. */
    private function arrayCastFields(string $modelClass): array
    {
        $casts = (new $modelClass)->getCasts();

        return collect($casts)
            ->filter(fn ($cast) => in_array($cast, ['array', 'json', 'AsArrayObject', 'collection']) || str_contains((string) $cast, 'ArrayObject'))
            ->keys()
            ->all();
    }

    private function extractFields(Request $request, string $modelClass): array
    {
        $fillable = (new $modelClass)->getFillable();
        $data = $request->only($fillable);
        $arrayFields = $this->arrayCastFields($modelClass);

        foreach ($fillable as $f) {
            if (in_array($f, ['booking_available', 'personal_coaching', 'is_active', 'profile_completed'])) {
                $data[$f] = $request->boolean($f);
            }
            // Convert edited list text (one item per line) back into an array.
            if (in_array($f, $arrayFields) && isset($data[$f]) && is_string($data[$f])) {
                $data[$f] = array_values(array_filter(array_map('trim', preg_split('/\r\n|\r|\n/', $data[$f])), fn ($v) => $v !== ''));
            }
        }

        return $data;
    }

    private function injectOwnerOnBehalf(Request $request, string $type, array $data, ?object $existing = null): array
    {
        $cfg = $this->ownerConfigForType($type);
        if (! $cfg) return $data;
        $col = $cfg['column'];
        // Panel sends `owner_user_id` select — empty means fallback to admin (or keep existing on update)
        $selectedUserId = $request->input('owner_user_id');
        if ($selectedUserId === '' || $selectedUserId === null) {
            if ($existing && isset($existing->{$col}) && $existing->{$col}) {
                return $data; // keep existing owner on edit when no selection
            }
            $selectedUserId = $request->user()?->id ?? auth()->id();
        }
        $selectedUserId = $selectedUserId ? (int) $selectedUserId : null;
        if (! $selectedUserId) return $data;

        if ($type === 'tournaments') {
            // organizer_id is FK to organizer_profiles.id — resolve or create profile for selected user
            $profile = \App\Models\OrganizerProfile::firstOrCreate(
                ['user_id' => $selectedUserId],
                ['organization_name' => User::find($selectedUserId)?->name ?? 'Admin Organization', 'org_type' => 'other', 'verification_status' => 'verified']
            );
            $data[$col] = $profile->id;
        } elseif ($type === 'sponsorships') {
            $profile = \App\Models\SponsorProfile::firstOrCreate(
                ['user_id' => $selectedUserId],
                ['brand_name' => User::find($selectedUserId)?->name ?? 'Admin Sponsor']
            );
            $data[$col] = $profile->id;
        } else {
            $data[$col] = $selectedUserId;
        }
        return $data;
    }

    private function republishContent(\App\Models\ExpiryEvent $event): void
    {
        try {
            $map = [
                'academy' => Academy::class, 'coach' => CoachProfile::class, 'coach_profile' => CoachProfile::class,
                'trial' => Trial::class, 'tournament' => Tournament::class,
                'sponsorship' => Sponsorship::class, 'scholarship' => Scholarship::class,
                'sports_venue' => SportsVenue::class, 'sports-venue' => SportsVenue::class,
            ];
            $model = $map[strtolower((string) $event->content_type)] ?? null;
            if ($model && $event->content_id) {
                $row = $model::find($event->content_id);
                if ($row) {
                    $col = self::statusColumnMap()[self::typeKeyFor($model)] ?? 'status';
                    $row->{$col} = 'published';
                    $row->save();
                }
            }
        } catch (\Throwable $e) {
            // Best-effort republish; never fail the override/restore action.
        }
    }

    private static function typeKeyFor(string $modelClass): string
    {
        return match ($modelClass) {
            Academy::class => 'academies',
            CoachProfile::class => 'coaches',
            Trial::class => 'trials',
            Tournament::class => 'tournaments',
            Scholarship::class => 'scholarships',
            Sponsorship::class => 'sponsorships',
            SportsVenue::class => 'sports-venues',
            default => 'trials',
        };
    }

    private function friendlyCategoryError(\Throwable $e, string $type, ?string $name): string
    {
        $msg = $e->getMessage();
        $quoted = $name ? " '{$name}'" : '';

        if (str_contains($msg, '1062') || str_contains($msg, 'Duplicate entry')) {
            return match ($type) {
                'sports' => "Sport{$quoted} already exists. Please use a different name.",
                'cities' => "City{$quoted} already exists for this state. Try a different name or state.",
                'age-groups' => "Age group{$quoted} already exists.",
                default => "This{$quoted} already exists. Please use a different name.",
            };
        }
        if (str_contains($msg, '1048') || str_contains($msg, 'cannot be null')) {
            if (preg_match("/Column '([^']+)' cannot be null/", $msg, $m)) {
                $col = str_replace('_', ' ', $m[1]);
                return "Missing required field: {$col}. Please fill it in.";
            }
            return "Missing required field. Please check your input.";
        }
        // Don't leak raw SQL in production — log it, show friendly.
        \Illuminate\Support\Facades\Log::warning('Admin category error', ['type' => $type, 'error' => $msg]);
        return "Could not save category{$quoted}. Please check your input and try again.";
    }

    private function friendlyContentError(\Throwable $e, string $action): string
    {
        $msg = $e->getMessage();
        if (str_contains($msg, '1062') || str_contains($msg, 'Duplicate entry')) {
            return "An entry with this name already exists. Please use a different title.";
        }
        if (str_contains($msg, '1048') || str_contains($msg, 'cannot be null')) {
            if (preg_match("/Column '([^']+)' cannot be null/", $msg, $m)) {
                $col = str_replace('_', ' ', $m[1]);
                return "Missing required field: {$col}. Please fill it in and try again.";
            }
            return "Missing required information. Please fill in all required fields.";
        }
        \Illuminate\Support\Facades\Log::warning('Admin content error', ['action' => $action, 'error' => $msg]);
        return "Could not {$action} this item. Please check your input and try again.";
    }
}
