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
        if (Auth::check() && Auth::user()->role === 'admin' && session('admin_2fa_ok')) {
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
        $request->session()->put('admin_2fa_ok', false);

        return redirect()->route('admin.2fa');
    }

    public function show2fa()
    {
        if (! Auth::check() || Auth::user()->role !== 'admin') {
            return redirect()->route('admin.login');
        }
        if (session('admin_2fa_ok')) {
            return redirect()->route('admin.dashboard');
        }

        return view('admin.twofa');
    }

    public function verify2fa(Request $request)
    {
        $request->validate(['code' => ['required', 'string', 'size:6']]);

        // MVP: accept any 6-digit code. Wire a real TOTP check before production.
        $user = Auth::user();
        $user->forceFill(['admin_2fa_verified_at' => now()])->save();
        $request->session()->put('admin_2fa_ok', true);

        return redirect()->route('admin.dashboard');
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
            $query->where('status', $request->status);
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

        $user->status = match ($data['action']) {
            'activate' => 'active',
            'suspend' => 'suspended',
            'reject' => 'rejected',
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

    // ── Moderation ─────────────────────────────────────────────────────────────

    public function moderation(Request $request)
    {
        $status = $request->get('status', 'pending');

        $query = ListingReport::query();
        if ($status !== 'all') {
            $query->where('status', $status);
        }
        $reports = $query->latest()->paginate(25)->appends(['status' => $status]);

        $counts = [
            'pending' => ListingReport::where('status', 'pending')->count(),
            'resolved' => ListingReport::where('status', 'resolved')->count(),
            'removed' => ListingReport::whereIn('status', ['removed', 'warned'])->count(),
            'all' => ListingReport::count(),
        ];

        return view('admin.moderation', ['reports' => $reports, 'status' => $status, 'counts' => $counts]);
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
            'status' => $data['action'] === 'approve' ? 'resolved' : ($data['action'] === 'remove' ? 'removed' : 'warned'),
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
            'sports' => ['name' => 'required|string|max:60', 'sort_order' => 'nullable|integer'],
            'cities' => ['name' => 'required|string|max:60', 'state' => 'nullable|string|max:60'],
            'age-groups' => ['name' => 'required|string|max:30', 'min_age' => 'nullable|integer', 'max_age' => 'nullable|integer'],
            default => abort(404),
        };

        $data = $request->validate($rules);
        $data['is_active'] = true;

        $model = self::categoryModel($type);
        $model::create($data);

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
        $reports = ListingReport::latest()->paginate(25);

        return view('admin.reports', ['reports' => $reports]);
    }

    public function reportAction(Request $request, $id)
    {
        $data = $request->validate(['action' => ['required', 'in:resolve,escalate']]);
        $report = ListingReport::findOrFail($id);

        if ($data['action'] === 'resolve') {
            $report->update([
                'status' => 'resolved',
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
        $flags = ListingReport::where('status', 'pending')->latest()->paginate(25);

        return view('admin.flags', ['flags' => $flags]);
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
            $report->update(['status' => 'resolved', 'resolved_at' => now(), 'resolved_by' => Auth::id()]);
        }

        return back()->with('success', 'Flag '.ucfirst($data['action']).'ed.');
    }

    // ── Sponsor Verification ───────────────────────────────────────────────────

    public function sponsors()
    {
        $sponsorships = Sponsorship::with('sponsor')->latest()->paginate(25);

        return view('admin.sponsors', ['sponsorships' => $sponsorships]);
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
            + Academy::where('listing_status', 'published')->count();

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

        return view('admin.analytics', compact('totalUsers', 'activeListings', 'roleDistribution', 'topSports', 'growth', 'growthMax', 'monthlySignups'));
    }

    // ── Notification Templates / Broadcast ─────────────────────────────────────

    public function notifications()
    {
        $templates = collect([
            ['type' => 'email', 'name' => 'Welcome to SportX', 'body' => 'Welcome to SportX India! Explore trials, tournaments, and scholarships near you.'],
            ['type' => 'push', 'name' => 'Trial Reminder', 'body' => 'Reminder: your trial is tomorrow. Don\'t forget your gear!'],
            ['type' => 'sms', 'name' => 'Scholarship Deadline', 'body' => 'SportX: Last day to apply for the scholarship. Apply now at sportx.in'],
        ]);

        $sent = \App\Models\Notification::select('type', \DB::raw('count(*) as cnt'))
            ->groupBy('type')->pluck('cnt', 'type');

        return view('admin.notifications', ['templates' => $templates, 'sent' => $sent]);
    }

    public function broadcast(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:120',
            'body' => 'required|string|max:500',
            'type' => 'required|in:info,success,warning',
        ]);

        // Broadcast to every user (chunked).
        User::select('id')->chunk(200, function ($users) use ($data) {
            $rows = $users->map(fn ($u) => [
                'user_id' => $u->id,
                'type' => $data['type'],
                'title' => $data['title'],
                'body' => $data['body'],
                'created_at' => now(),
                'updated_at' => now(),
            ])->all();
            \App\Models\Notification::insert($rows);
        });

        return back()->with('success', 'Broadcast sent to all users.');
    }

    // ── System Settings ────────────────────────────────────────────────────────

    private function settingsPath(): string
    {
        return storage_path('app/platform_settings.json');
    }

    private function readSettings(): array
    {
        $path = $this->settingsPath();
        if (file_exists($path)) {
            return json_decode((string) file_get_contents($path), true) ?: [];
        }
        return [
            'moderation_required' => true,
            'auto_verify_coaches' => false,
            'email_alerts' => true,
            'push_notifications' => true,
            'suspicious_login_detection' => true,
            'maintenance_mode' => false,
        ];
    }

    public function settings()
    {
        return view('admin.settings', ['settings' => $this->readSettings()]);
    }

    public function updateSettings(Request $request)
    {
        $settings = $this->readSettings();
        foreach ($settings as $key => $val) {
            $settings[$key] = $request->boolean($key);
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
            $model::create($this->extractFields($request, $model));
        } catch (\Throwable $e) {
            return back()->with('error', 'Could not create: '.$e->getMessage())->withInput();
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
            $item->update($this->extractFields($request, $model));
        } catch (\Throwable $e) {
            return back()->with('error', 'Could not update: '.$e->getMessage())->withInput();
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
        $event->update(['status' => 'overridden', 'overridden_by' => Auth::id()]);
        $this->republishContent($event);

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

        $model::findOrFail($id)->update($request->validate($rules));

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

    private function editorViewData(string $type, string $modelClass, ?object $item): array
    {
        return [
            'type' => $type,
            'item' => $item,
            'fields' => $this->editableFields($modelClass),
            'arrayFields' => $this->arrayCastFields($modelClass),
            'sports' => Sport::orderBy('name')->get(),
            'cities' => City::orderBy('name')->get(),
            'ageGroups' => AgeGroup::orderBy('min_age')->get(),
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
}
