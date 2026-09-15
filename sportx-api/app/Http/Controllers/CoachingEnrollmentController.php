<?php

namespace App\Http\Controllers;

use App\Models\CoachProfile;
use App\Models\CoachingEnrollment;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class CoachingEnrollmentController extends Controller
{
    public function store(Request $request, $coach = null)
    {
        // Support both /coaches/{coach}/enroll (route param) and body coach_id
        $routeCoachId = $request->route('coach');
        if ($routeCoachId !== null) {
            $request->merge(['coach_id' => $routeCoachId]);
        }

        $validated = $request->validate([
            'coach_id' => 'required|exists:coach_profiles,id',
            'plan_type' => 'required|in:session,monthly,quarterly',
            'notes' => 'nullable|string|max:500',
        ]);

        $athlete = $request->user()->athleteProfile;
        abort_unless($athlete, 403, 'Athlete profile required');

        $coach = CoachProfile::findOrFail($validated['coach_id']);

        if (! $coach->personal_coaching) {
            return response()->json(['message' => 'Coach does not offer personal coaching'], 400);
        }

        abort_if(
            CoachingEnrollment::where('coach_id', $coach->id)
                ->where('athlete_id', $athlete->id)
                ->where('plan_type', $validated['plan_type'])
                ->exists(),
            409, 'Already enrolled or pending for this plan'
        );

        $feesAmount = match ($validated['plan_type']) {
            'session' => $coach->fee_per_session ?? 0,
            'monthly' => $coach->fee_monthly ?? 0,
            'quarterly' => $coach->fee_quarterly ?? 0,
        };

        $enrollment = CoachingEnrollment::create([
            'coach_id' => $coach->id,
            'athlete_id' => $athlete->id,
            'plan_type' => $validated['plan_type'],
            'fees_amount' => $feesAmount,
            'approval_status' => 'pending',
            'status' => 'inactive',
            'notes' => $validated['notes'] ?? null,
        ]);

        $enrollment->load(['coach.user', 'athlete.user']);

        try {
            if ($coach->user_id !== $request->user()->id) {
                NotificationService::createStatic([
                    'user_id' => $coach->user_id,
                    'type' => 'status_update',
                    'title' => 'New Enrollment Request',
                    'body' => $request->user()->name . ' wants to enroll in your ' . $validated['plan_type'] . ' coaching plan',
                    'notifiable_type' => 'coaching_enrollment',
                    'notifiable_id' => $enrollment->id,
                    'action_url' => "/coaching-enrollments/{$enrollment->id}",
                ]);
            }
        } catch (\Throwable $e) {}

        return response()->json([
            'message' => 'Enrollment request submitted',
            'data' => $enrollment,
        ], 201);
    }

    public function coachEnrollments(Request $request)
    {
        $coach = $request->user()->coachProfile;
        abort_unless($coach, 403, 'Coach profile required');

        $query = CoachingEnrollment::where('coach_id', $coach->id)->with(['athlete.user', 'coach.user']);

        if ($request->has('status')) {
            $query->where('approval_status', $request->query('status'));
        }
        if ($request->has('approval_status')) {
            $query->where('approval_status', $request->query('approval_status'));
        }

        $enrollments = $query->orderByDesc('created_at')->paginate(20);

        return response()->json([
            'data' => $enrollments->items(),
            'meta' => ['pagination' => [
                'total' => $enrollments->total(),
                'per_page' => $enrollments->perPage(),
                'current_page' => $enrollments->currentPage(),
                'last_page' => $enrollments->lastPage(),
            ]],
        ]);
    }

    public function myEnrollments(Request $request)
    {
        $athlete = $request->user()->athleteProfile;
        abort_unless($athlete, 403, 'Athlete profile required');

        $enrollments = CoachingEnrollment::where('athlete_id', $athlete->id)
            ->with(['coach.user', 'athlete.user'])
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json([
            'data' => $enrollments->items(),
            'meta' => ['pagination' => [
                'total' => $enrollments->total(),
                'per_page' => $enrollments->perPage(),
                'current_page' => $enrollments->currentPage(),
                'last_page' => $enrollments->lastPage(),
            ]],
        ]);
    }

    public function approve(Request $request, CoachingEnrollment $enrollment)
    {
        $this->authorizeCoach($request, $enrollment);

        $validated = $request->validate([
            'coach_response' => 'nullable|string|max:500',
            'start_date' => 'required|date',
            'end_date' => 'nullable|date|after:start_date',
        ]);

        $enrollment->update([
            'approval_status' => 'approved',
            'status' => 'active',
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
            'coach_response' => $validated['coach_response'] ?? null,
            'start_date' => $validated['start_date'],
            'end_date' => $validated['end_date'] ?? null,
            'rejection_reason' => null,
        ]);

        $enrollment->load(['athlete.user', 'coach']);
        try {
            NotificationService::createStatic([
                'user_id' => $enrollment->athlete->user_id,
                'type' => 'status_update',
                'title' => 'Enrollment Confirmed!',
                'body' => "Your {$enrollment->plan_type} coaching enrollment with {$enrollment->coach->full_name} has been approved.",
                'notifiable_type' => 'coaching_enrollment',
                'notifiable_id' => $enrollment->id,
                'action_url' => "/coaching-enrollments/{$enrollment->id}",
            ]);
        } catch (\Throwable $e) {}

        return response()->json(['message' => 'Enrollment approved', 'data' => $enrollment]);
    }

    public function reject(Request $request, CoachingEnrollment $enrollment)
    {
        $this->authorizeCoach($request, $enrollment);

        $validated = $request->validate([
            'rejection_reason' => 'required|string|max:500',
        ]);

        $enrollment->update([
            'approval_status' => 'rejected',
            'status' => 'cancelled',
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
            'rejection_reason' => $validated['rejection_reason'],
        ]);

        $enrollment->load(['athlete.user']);
        try {
            NotificationService::createStatic([
                'user_id' => $enrollment->athlete->user_id,
                'type' => 'status_update',
                'title' => 'Enrollment Update',
                'body' => "Your enrollment request was not approved. Reason: {$validated['rejection_reason']}",
                'notifiable_type' => 'coaching_enrollment',
                'notifiable_id' => $enrollment->id,
                'action_url' => "/coaching-enrollments/{$enrollment->id}",
            ]);
        } catch (\Throwable $e) {}

        return response()->json(['message' => 'Enrollment rejected', 'data' => $enrollment]);
    }

    public function show(Request $request, CoachingEnrollment $enrollment)
    {
        $user = $request->user();
        $isAthlete = $user->athleteProfile && $enrollment->athlete_id === $user->athleteProfile->id;
        $isCoach = $user->coachProfile && $enrollment->coach_id === $user->coachProfile->id;
        abort_unless($isAthlete || $isCoach || $user->isAdmin(), 403);
        $enrollment->load(['coach.user', 'athlete.user']);
        return response()->json(['data' => $enrollment]);
    }

    private function authorizeCoach(Request $request, CoachingEnrollment $enrollment): void
    {
        $user = $request->user();
        if ($user->isAdmin()) return;
        $coach = $user->coachProfile;
        abort_unless($coach && (int) $enrollment->coach_id === (int) $coach->id, 403);
    }
}
