<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CoachingEnrollment;
use App\Models\RegistrationActivityLog;
use App\Models\TrialRegistration;
use App\Models\TournamentRegistration;
use Illuminate\Http\Request;

class RegistrationAnalyticsController extends Controller
{
    public function dashboard(): \Illuminate\Http\JsonResponse
    {
        $approved = TournamentRegistration::where('approval_status', 'approved')->count()
            + TrialRegistration::where('approval_status', 'approved')->count();
        $rejected = TournamentRegistration::where('approval_status', 'rejected')->count()
            + TrialRegistration::where('approval_status', 'rejected')->count();
        $total = TournamentRegistration::count() + TrialRegistration::count();
        $pending = TournamentRegistration::where('approval_status', 'pending')->count()
            + TrialRegistration::where('approval_status', 'pending')->count();

        $decided = $approved + $rejected;

        return response()->json([
            'total_registrations' => $total,
            'pending_count' => $pending,
            'approved_count' => $approved,
            'rejected_count' => $rejected,
            'approval_rate' => $decided > 0 ? round(($approved / $decided) * 100, 2) : 0,
            'total_coaching_enrollments' => CoachingEnrollment::count(),
            'pending_coaching_enrollments' => CoachingEnrollment::where('approval_status', 'pending')->count(),
            'active_coaching_enrollments' => CoachingEnrollment::where('status', 'active')->count(),
            'coaching_revenue_estimate' => (float) (CoachingEnrollment::where('approval_status', 'approved')->sum('fees_amount') ?? 0),
        ]);
    }

    public function activityLog(Request $request): \Illuminate\Http\JsonResponse
    {
        $query = RegistrationActivityLog::orderByDesc('created_at');

        if ($request->has('registration_type')) {
            $query->where('registration_type', $request->get('registration_type'));
        }
        if ($request->has('action')) {
            $query->where('action', $request->get('action'));
        }
        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->get('date_from'));
        }
        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->get('date_to'));
        }

        $logs = $query->paginate(50);

        return response()->json($logs);
    }
}
