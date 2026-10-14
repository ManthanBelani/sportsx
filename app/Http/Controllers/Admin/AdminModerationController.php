<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\ListingReport;
use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\AuditLog;
use App\Models\CoachProfile;
use App\Models\Facility;
use App\Models\Opportunity;
use App\Models\Post;
use App\Models\Program;
use App\Models\Trial;
use App\Models\Tournament;
use App\Models\Sponsorship;
use App\Models\Scholarship;
use App\Models\SportsVenue;
use App\Models\User;
use App\Events\ListingRemoved;
use App\Events\ListingWarned;
use App\Services\NotificationService;

class AdminModerationController extends Controller
{
    private array $reportableTypes = [
        'academy' => Academy::class,
        'coach_profile' => CoachProfile::class,
        'athlete_profile' => AthleteProfile::class,
        'trial' => Trial::class,
        'tournament' => Tournament::class,
        'sponsorship' => Sponsorship::class,
        'scholarship' => Scholarship::class,
        'sports_venue' => SportsVenue::class,
        'user' => User::class,
        'post' => Post::class,
        'opportunity' => Opportunity::class,
        'program' => Program::class,
        'facility' => Facility::class,
    ];

    public function queue(Request $request): JsonResponse
    {
        $query = ListingReport::with('reporter')
            ->where('status', 'pending')
            ->orderBy('created_at', 'desc');

        if ($request->has('reason')) {
            $query->where('reason', $request->reason);
        }

        $perPage = min($request->get('per_page', 20), 50);
        $reports = $query->paginate($perPage);

        // Group by reportable for aggregation
        $grouped = ListingReport::where('status', 'pending')
            ->selectRaw('reportable_type, reportable_id, COUNT(*) as count, MIN(created_at) as first_report_at')
            ->groupBy('reportable_type', 'reportable_id')
            ->get();

        return response()->json([
            'data' => $reports->items(),
            'meta' => [
                'current_page' => $reports->currentPage(),
                'per_page' => $reports->perPage(),
                'total' => $reports->total(),
                'last_page' => $reports->lastPage(),
            ]
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $report = ListingReport::with(['reporter', 'reportable'])->find($id);

        if (!$report) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Report not found.',
                ]
            ], 404);
        }

        return response()->json([
            'data' => $report
        ]);
    }

    public function approve(int $id): JsonResponse
    {
        $report = ListingReport::find($id);

        if (!$report) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Report not found.',
                ]
            ], 404);
        }

        // Mark all reports for this item as resolved
        ListingReport::where('reportable_type', $report->reportable_type)
            ->where('reportable_id', $report->reportable_id)
            ->where('status', 'pending')
            ->update(['status' => 'approved']);

        // Reporter gets the outcome (report reviewed, content stands).
        $this->notifyReporter($report, 'Report reviewed', 'Thanks — we reviewed your report and the content stays up.');
        $this->audit(request(), 'moderation.approve', $report);

        return response()->json([
            'data' => [
                'message' => 'Listing approved. Reports resolved.',
            ]
        ]);
    }

    public function remove(int $id, Request $request): JsonResponse
    {
        $report = ListingReport::find($id);

        if (!$report) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Report not found.',
                ]
            ], 404);
        }

        $modelClass = $this->reportableTypes[$report->reportable_type] ?? null;

        if ($modelClass) {
            $item = $modelClass::find($report->reportable_id);
            if ($item) {
                $item->update(['status' => 'removed']);
                event(new ListingRemoved($item));
            }
        }

        // Mark all reports as resolved
        ListingReport::where('reportable_type', $report->reportable_type)
            ->where('reportable_id', $report->reportable_id)
            ->where('status', 'pending')
            ->update(['status' => 'approved']);

        $this->notifyReporter($report, 'Report actioned', 'Thanks — the reported content was removed.');
        $this->audit($request, 'moderation.remove', $report);

        return response()->json([
            'data' => [
                'message' => 'Listing removed.',
            ]
        ]);
    }

    public function warn(int $id, Request $request): JsonResponse
    {
        $report = ListingReport::find($id);

        if (!$report) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Report not found.',
                ]
            ], 404);
        }

        $request->validate([
            'message' => 'nullable|string|max:500',
        ]);

        $modelClass = $this->reportableTypes[$report->reportable_type] ?? null;

        if ($modelClass) {
            $item = $modelClass::find($report->reportable_id);
            if ($item) {
                event(new ListingWarned($item, $request->message));
            }
        }

        // Mark all reports as warned (enum: pending, approved, edited, removed, warned)
        ListingReport::where('reportable_type', $report->reportable_type)
            ->where('reportable_id', $report->reportable_id)
            ->where('status', 'pending')
            ->update(['status' => 'warned']);

        $this->notifyReporter($report, 'Report actioned', 'Thanks — we warned the owner based on your report.');
        $this->audit($request, 'moderation.warn', $report);

        return response()->json([
            'data' => [
                'message' => 'Owner warned.',
            ]
        ]);
    }

    /**
     * Suspend the reported content owner's account (Phase 9 suspend action).
     * Notifies reporter + reported (account_action hard override) + audit.
     */
    public function suspend(int $id, Request $request): JsonResponse
    {
        $report = ListingReport::find($id);
        if (!$report) {
            return response()->json(['error' => ['code' => 'NOT_FOUND', 'message' => 'Report not found.']], 404);
        }

        $ownerId = $this->ownerUserId($report);
        abort_if(!$ownerId, 422, 'No suspendable owner for this content.');

        $owner = User::findOrFail($ownerId);
        $owner->forceFill(['status' => 'suspended'])->save();

        try {
            NotificationService::createStatic([
                'user_id' => $owner->id,
                'type' => 'account_action',
                'title' => 'Account suspended',
                'body' => 'Your account was suspended after a moderation review. Contact support.',
                'action_url' => '/account-status',
            ]);
        } catch (\Throwable) {
        }
        $this->notifyReporter($report, 'Report actioned', 'Thanks — the reported account was suspended.');
        $this->audit($request, 'moderation.suspend', $report);

        ListingReport::where('reportable_type', $report->reportable_type)
            ->where('reportable_id', $report->reportable_id)
            ->where('status', 'pending')
            ->update(['status' => 'warned']);

        return response()->json(['data' => ['message' => 'Account suspended.']]);
    }

    /** Best-effort owner user id across profile/listing/user content. */
    protected function ownerUserId(ListingReport $report): ?int
    {
        if ($report->reportable_type === 'user') {
            return (int) $report->reportable_id;
        }
        $modelClass = $this->reportableTypes[$report->reportable_type] ?? null;
        if (!$modelClass) {
            return null;
        }
        try {
            $item = $modelClass::find($report->reportable_id);
            if (!$item) {
                return null;
            }
            foreach (['user_id', 'posted_by_user_id', 'organizer_id', 'reporter_user_id'] as $key) {
                if (!empty($item->{$key})) {
                    $candidate = User::find($item->{$key});
                    if ($candidate) {
                        return $candidate->id;
                    }
                }
            }
            foreach (['user', 'athlete', 'owner'] as $rel) {
                try {
                    $related = $item->{$rel};
                    if ($related instanceof User) {
                        return $related->id;
                    }
                    if ($related && !empty($related->user_id)) {
                        return (int) $related->user_id;
                    }
                } catch (\Throwable) {
                }
            }
        } catch (\Throwable) {
        }

        return null;
    }

    protected function notifyReporter(ListingReport $report, string $title, string $body): void
    {
        try {
            NotificationService::createStatic([
                'user_id' => $report->reporter_user_id,
                'type' => 'status_update',
                'title' => $title,
                'body' => $body,
                'notifiable_type' => 'report',
                'notifiable_id' => $report->id,
                'action_url' => '/my-reports',
            ]);
        } catch (\Throwable) {
        }
    }

    protected function audit(Request $request, string $action, ListingReport $report): void
    {
        try {
            AuditLog::create([
                'user_id' => $request->user()?->id,
                'user_name' => $request->user()?->name ?? 'System',
                'user_role' => $request->user()?->role ?? 'system',
                'action' => $action,
                'auditable_type' => 'ListingReport',
                'auditable_id' => $report->id,
                'auditable_label' => "{$report->reportable_type}#{$report->reportable_id}",
                'ip_address' => $request->ip(),
                'user_agent' => substr((string) $request->userAgent(), 0, 500),
                'route' => substr($request->path() ?? '', 0, 190),
            ]);
        } catch (\Throwable) {
        }
    }
}
