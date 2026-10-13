<?php

namespace App\Http\Controllers;

use App\Models\VerificationRequest;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Database\Eloquent\Relations\Relational;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Blue-check verification: request submission, own-request status, and the
 * admin review queue.
 *
 * @see \App\Models\VerificationRequest
 * @see docs/API-Specification.md §1
 */
class VerificationController extends Controller
{
    /**
     * Entity types a user may request verification for, matching the morph map.
     *
     * @var array<int, string>
     */
    public const VERIFIABLE_TYPES = [
        'athlete_profile',
        'coach_profile',
        'academy',
        'organizer_profile',
        'talent_scout_profile',
    ];

    public function __construct(protected NotificationService $notifications) {}

    /**
     * POST /me/verification
     *
     * The user names which of their own entities is being verified, so the
     * request can never point at somebody else's record.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'verifiable_type' => ['required', Rule::in(self::VERIFIABLE_TYPES)],
            'verifiable_id' => 'required|integer',
            'proof_media_ids' => 'nullable|array',
            'proof_media_ids.*' => 'integer',
            'notes' => 'nullable|string|max:2000',
        ]);

        // Ownership check: the entity must belong to this user.
        $owns = $user->{$this->relationName($validated['verifiable_type'])}()
            ->whereKey($validated['verifiable_id'])
            ->exists();

        abort_unless($owns, 403, 'You can only request verification for your own profile.');

        // One live request at a time, otherwise the queue fills with duplicates.
        $existing = VerificationRequest::forRequester($user->id)
            ->pending()
            ->where('verifiable_type', $validated['verifiable_type'])
            ->where('verifiable_id', $validated['verifiable_id'])
            ->first();

        if ($existing) {
            return response()->json([
                'data' => $existing,
                'message' => 'A verification request is already pending for this profile.',
            ], 200);
        }

        $verification = VerificationRequest::create(array_merge($validated, [
            'requester_user_id' => $user->id,
            'status' => VerificationRequest::STATUS_PENDING,
        ]));

        return response()->json(['data' => $verification], 201);
    }

    /**
     * GET /me/verification
     *
     * The caller's own requests, newest first.
     */
    public function index(Request $request): JsonResponse
    {
        $requests = VerificationRequest::forRequester($request->user()->id)
            ->latest('id')
            ->paginate(20);

        return response()->json([
            'data' => $requests->items(),
            'meta' => [
                'current_page' => $requests->currentPage(),
                'per_page' => $requests->perPage(),
                'total' => $requests->total(),
                'last_page' => $requests->lastPage(),
            ],
        ]);
    }

    /**
     * GET /admin/verification
     *
     * The admin review queue.
     */
    public function queue(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['nullable', Rule::in([
                VerificationRequest::STATUS_PENDING,
                VerificationRequest::STATUS_APPROVED,
                VerificationRequest::STATUS_REJECTED,
            ])],
        ]);

        $query = VerificationRequest::query()->with(['requester', 'verifiable']);

        if (! empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }

        return response()->json($query->orderByDesc('created_at')->paginate(20));
    }

    /**
     * GET /admin/verification/{id}
     */
    public function show(string $id): JsonResponse
    {
        return response()->json([
            'data' => VerificationRequest::with(['requester', 'verifiable'])->findOrFail($id),
        ]);
    }

    /**
     * PATCH /admin/verification/{id}/approve
     */
    public function approve(Request $request, string $id): JsonResponse
    {
        $verification = VerificationRequest::findOrFail($id);
        $admin = $request->user();

        $verification->approve($admin);

        // Hard override: a user must learn that their request was decided,
        // even if they muted every optional notification.
        $this->notifications->create([
            'user_id' => $verification->requester_user_id,
            'type' => 'account_action',
            'title' => 'Your verification was approved',
            'body' => 'Your verified badge is now visible on your profile.',
            'action_url' => '/profile',
        ]);

        return response()->json(['data' => $verification->refresh()]);
    }

    /**
     * PATCH /admin/verification/{id}/reject
     *
     * A reason is mandatory — an unexplained rejection generates support load.
     */
    public function reject(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'reason' => 'required|string|max:1000',
        ]);

        $verification = VerificationRequest::findOrFail($id);
        $verification->reject($request->user(), $validated['reason']);

        $this->notifications->create([
            'user_id' => $verification->requester_user_id,
            'type' => 'account_action',
            'title' => 'Your verification was declined',
            'body' => $validated['reason'],
            'action_url' => '/profile',
        ]);

        return response()->json(['data' => $verification->refresh()]);
    }

    /**
     * Map a morph alias to the relation method on `User`.
     */
    protected function relationName(string $verifiableType): string
    {
        return match ($verifiableType) {
            'athlete_profile' => 'athleteProfile',
            'coach_profile' => 'coachProfile',
            'academy' => 'academies',
            'organizer_profile' => 'organizerProfile',
            'talent_scout_profile' => 'talentScoutProfile',
        };
    }
}