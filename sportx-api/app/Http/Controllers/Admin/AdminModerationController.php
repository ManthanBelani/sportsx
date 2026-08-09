<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\ListingReport;
use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\Trial;
use App\Models\Tournament;
use App\Models\Sponsorship;
use App\Models\Scholarship;
use App\Models\SportsVenue;
use App\Models\User;
use App\Events\ListingRemoved;
use App\Events\ListingWarned;

class AdminModerationController extends Controller
{
    private array $reportableTypes = [
        'academy' => Academy::class,
        'coach_profile' => CoachProfile::class,
        'trial' => Trial::class,
        'tournament' => Tournament::class,
        'sponsorship' => Sponsorship::class,
        'scholarship' => Scholarship::class,
        'sports_venue' => SportsVenue::class,
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
        $report = ListingReport::with(['reporter', 'subject'])->find($id);

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
            ->update(['status' => 'resolved']);

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
            ->update(['status' => 'resolved']);

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

        // Mark all reports as actioned
        ListingReport::where('reportable_type', $report->reportable_type)
            ->where('reportable_id', $report->reportable_id)
            ->where('status', 'pending')
            ->update(['status' => 'actioned']);

        return response()->json([
            'data' => [
                'message' => 'Owner warned.',
            ]
        ]);
    }
}
