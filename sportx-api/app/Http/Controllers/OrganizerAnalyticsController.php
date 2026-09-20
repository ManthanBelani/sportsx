<?php

namespace App\Http\Controllers;

use App\Models\Tournament;
use App\Models\Trial;
use App\Models\TournamentRegistration;
use App\Models\TrialRegistration;
use Illuminate\Http\Request;

class OrganizerAnalyticsController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        abort_unless(in_array($user->role, ['organizer', 'admin']), 403, 'Organizer access required');

        // Organizer tournaments: organizer_id may be user_id (current store) or organizer_profile id (legacy).
        // Try both: where organizer_id = user->id OR where organizer_id = organizerProfile->id
        $tournamentQuery = Tournament::query();
        // Most recent stores use user id, so include both.
        $organizerProfileId = $user->organizerProfile?->id;
        if ($organizerProfileId) {
            $tournamentQuery->where(function ($q) use ($user, $organizerProfileId) {
                $q->where('organizer_id', $user->id)
                  ->orWhere('organizer_id', $organizerProfileId);
            });
        } else {
            $tournamentQuery->where('organizer_id', $user->id);
        }

        $tournaments = $tournamentQuery->with(['categories', 'sport'])->get();
        $tournamentIds = $tournaments->pluck('id');

        $trials = Trial::where('posted_by_user_id', $user->id)->get();
        $trialIds = $trials->pluck('id');

        // Tournament registrations aggregated - guard empty whereIn
        $tournamentRegs = $tournamentIds->isNotEmpty()
            ? TournamentRegistration::whereIn('tournament_id', $tournamentIds)->get()
            : collect();
        $trialRegs = $trialIds->isNotEmpty()
            ? TrialRegistration::whereIn('trial_id', $trialIds)->get()
            : collect();

        $totalRegs = $tournamentRegs->count() + $trialRegs->count();
        $pending = $tournamentRegs->where('approval_status', 'pending')->count() + $trialRegs->where('approval_status', 'pending')->count();
        $approved = $tournamentRegs->where('approval_status', 'approved')->count() + $trialRegs->where('approval_status', 'approved')->count();
        $rejected = $tournamentRegs->where('approval_status', 'rejected')->count() + $trialRegs->where('approval_status', 'rejected')->count();

        $publishedTournaments = $tournaments->where('status', 'published')->count();
        $draftTournaments = $tournaments->where('status', 'draft')->count();
        $closedTournaments = $tournaments->where('status', 'closed')->count();

        $publishedTrials = $trials->where('status', 'published')->count();
        $draftTrials = $trials->where('status', 'draft')->count();

        // Revenue: sum entry_fee * approved regs (tournament entry_fee) + trial entry fees if numeric
        $revenue = 0;
        foreach ($tournamentRegs->where('approval_status', 'approved') as $r) {
            $t = $tournaments->firstWhere('id', $r->tournament_id);
            $fee = $t ? (float) ($t->entry_fee ?? 0) : 0;
            $rev = $fee;
            // if payment_status is waived, count as 0? but keep fee for estimate
            if ($r->payment_status === 'waived') $rev = 0;
            $revenue += $rev;
        }

        // Capacity utilization
        $totalCapacity = 0;
        $totalRegistered = 0;
        foreach ($tournaments as $t) {
            foreach ($t->categories as $cat) {
                $totalCapacity += (int) ($cat->capacity ?? 0);
            }
            // count registrations for this tournament
            $totalRegistered += $tournamentRegs->where('tournament_id', $t->id)->where('approval_status', 'approved')->count();
        }

        $utilization = $totalCapacity > 0 ? round(($totalRegistered / $totalCapacity) * 100, 1) : 0;
        $decided = $approved + $rejected;
        $approvalRate = $decided > 0 ? round(($approved / $decided) * 100, 1) : 0;

        // Nearest deadline tournament
        $nearestDeadline = null;
        $nearestTournament = null;
        foreach ($tournaments->where('status', 'published') as $t) {
            if ($t->registration_deadline) {
                $daysLeft = now()->diffInDays($t->registration_deadline, false);
                if ($daysLeft >= 0 && $daysLeft <= 30) {
                    if ($nearestDeadline === null || $t->registration_deadline->lt($nearestDeadline)) {
                        $nearestDeadline = $t->registration_deadline;
                        $nearestTournament = $t;
                    }
                }
            }
        }

        // Recent pending registrations (top 5) - guard empty
        $pendingTournamentRegs = $tournamentIds->isNotEmpty()
            ? TournamentRegistration::whereIn('tournament_id', $tournamentIds)->where('approval_status', 'pending')->with(['athlete.user', 'tournament', 'category'])->orderByDesc('created_at')->limit(5)->get()
            : collect();
        $pendingTrialRegs = $trialIds->isNotEmpty()
            ? TrialRegistration::whereIn('trial_id', $trialIds)->where('approval_status', 'pending')->with(['athlete.user', 'trial'])->orderByDesc('created_at')->limit(5)->get()
            : collect();

        // Category breakdown
        $categoryStats = [];
        foreach ($tournaments as $t) {
            foreach ($t->categories as $cat) {
                $catRegs = $tournamentRegs->where('category_id', $cat->id);
                $categoryStats[] = [
                    'tournament_id' => $t->id,
                    'tournament_name' => $t->name,
                    'category_id' => $cat->id,
                    'category_name' => $cat->name,
                    'capacity' => $cat->capacity,
                    'registered' => $catRegs->where('approval_status', 'approved')->count(),
                    'pending' => $catRegs->where('approval_status', 'pending')->count(),
                    'available' => max(0, (int)$cat->capacity - $catRegs->where('approval_status', 'approved')->count()),
                ];
            }
        }

        return response()->json([
            'data' => [
                'tournaments' => [
                    'total' => $tournaments->count(),
                    'published' => $publishedTournaments,
                    'draft' => $draftTournaments,
                    'closed' => $closedTournaments,
                ],
                'trials' => [
                    'total' => $trials->count(),
                    'published' => $publishedTrials,
                    'draft' => $draftTrials,
                ],
                'registrations' => [
                    'total' => $totalRegs,
                    'pending' => $pending,
                    'approved' => $approved,
                    'rejected' => $rejected,
                    'approval_rate' => $approvalRate,
                ],
                'revenue' => [
                    'total_estimate' => round($revenue, 2),
                    'currency' => 'INR',
                ],
                'capacity' => [
                    'total_capacity' => $totalCapacity,
                    'total_registered' => $totalRegistered,
                    'utilization_percent' => $utilization,
                    'spots_left' => max(0, $totalCapacity - $totalRegistered),
                ],
                'deadline_alert' => $nearestTournament ? [
                    'tournament_id' => $nearestTournament->id,
                    'tournament_name' => $nearestTournament->name,
                    'deadline' => $nearestDeadline?->toIso8601String(),
                    'days_left' => (int) now()->diffInDays($nearestDeadline, false),
                ] : null,
                'pending_registrations' => [
                    'tournaments' => $pendingTournamentRegs,
                    'trials' => $pendingTrialRegs,
                ],
                'category_breakdown' => $categoryStats,
            ],
        ]);
    }
}
