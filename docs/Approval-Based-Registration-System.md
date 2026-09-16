# Approval-Based Registration System for SportX

## Overview

This document outlines the approval-based registration system to replace payment integration for trials, tournaments, and other bookable entities. Instead of processing payments via Stripe, athletes submit requests to participate, and organizers approve or reject these requests.

---

## Current State Analysis

### Existing Payment Integration
- **No Stripe/Razorpay currently implemented** - payments are display-only with manual `payment_status` flags
- Entry fees shown as text (e.g., `"₹2000–₹5000/mo"`)
- Manual payment status tracking exists: `pending`, `paid`, `waived`

### Existing Approval Workflows
| Entity | Current Status | Existing Endpoints |
|--------|---------------|-------------------|
| Trial Registration | `verification_status`: pending/verified/rejected | `POST /registrations/trials/{id}/verify`, `/reject` |
| Tournament Registration | `payment_status`: pending/paid | `PATCH /registrations/tournaments/{id}/payment` |
| Sponsorship | `status`: pending/approved/rejected | `POST /sponsorships/{id}/applications` |
| User Registration | `status`: pending/active | Admin approves coaches/sponsors |

### Roles in System
```
athlete, coach, academy, organizer, sponsor, admin, talent_scout
```

---

## Proposed Approval Workflow

### Core Concept
```
Athlete Request → Organizer Review → Approve/Reject → Athlete Notification
```

---

## 1. Tournament Registration Approval

### 1.1 Data Model Changes

**TournamentRegistration** - Add `approval_status` field:
```php
// sportx-api/app/Models/TournamentRegistration.php

class TournamentRegistration extends Model
{
    protected $fillable = [
        'tournament_id',
        'category_id',
        'athlete_id',
        'participation_type',
        'team_name',
        'payment_status',      // existing: pending/paid/waived
        'approval_status',      // NEW: pending/approved/rejected
        'status',              // existing: pending/confirmed/waitlisted/cancelled
        'rejection_reason',    // NEW: nullable string
        'reviewed_by',        // NEW: nullable foreign key to users
        'reviewed_at',        // NEW: nullable timestamp
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
    ];

    // Relationships
    public function tournament(): BelongsTo
    public function athlete(): BelongsTo
    public function reviewer(): BelongsTo(User::class, 'reviewed_by')
}
```

**Migration**:
```php
// database/migrations/xxxx_xx_xx_add_approval_to_tournament_registrations.php

public function up(): void
{
    Schema::table('tournament_registrations', function (Blueprint $table) {
        $table->string('approval_status')->default('pending')->after('payment_status');
        $table->string('rejection_reason')->nullable()->after('approval_status');
        $table->foreignId('reviewed_by')->nullable()->constrained('users')->after('rejection_reason');
        $table->timestamp('reviewed_at')->nullable()->after('reviewed_by');
    });
}
```

### 1.2 Backend API Endpoints

| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| POST | `/tournaments/{tournament}/register` | athlete | Submit registration request |
| GET | `/tournaments/{tournament}/registrations` | organizer | List all registrations for tournament |
| GET | `/tournaments/{tournament}/pending-requests` | organizer | List pending approval requests |
| PATCH | `/registrations/tournaments/{registration}/approve` | organizer | Approve a registration |
| PATCH | `/registrations/tournaments/{registration}/reject` | organizer | Reject with reason |
| GET | `/me/registrations/tournaments` | athlete | List athlete's tournament registrations with status |

### 1.3 Controller Changes

**RegistrationController.php** - Key method changes:

```php
// sportx-api/app/Http/Controllers/RegistrationController.php

public function storeTournament(Request $request, Tournament $tournament): JsonResponse
{
    // ... existing validation ...

    // Create registration with pending approval
    $registration = TournamentRegistration::create([
        'tournament_id' => $tournament->id,
        'category_id' => $validated['category_id'],
        'athlete_id' => $request->user()->athleteProfile->id,
        'participation_type' => $validated['participation_type'],
        'team_name' => $validated['team_name'] ?? null,
        'payment_status' => 'pending',      // Keep for display purposes
        'approval_status' => 'pending',      // NEW: default to pending
        'status' => 'pending',
    ]);

    // Send notification to organizer
    Notification::send(
        $tournament->organizer->user,
        new RegistrationRequestNotification($registration, 'tournament')
    );

    return response()->json([
        'message' => 'Registration request submitted successfully',
        'registration' => new TournamentRegistrationResource($registration),
    ], 201);
}

public function approveTournament(Request $request, TournamentRegistration $registration): JsonResponse
{
    $this->authorize('approve', $registration);

    $registration->update([
        'approval_status' => 'approved',
        'status' => 'confirmed',
        'reviewed_by' => $request->user()->id,
        'reviewed_at' => now(),
    ]);

    // Notify athlete
    Notification::send(
        $registration->athlete->user,
        new RegistrationApprovedNotification($registration, 'tournament')
    );

    return response()->json([
        'message' => 'Registration approved',
        'registration' => new TournamentRegistrationResource($registration),
    ]);
}

public function rejectTournament(Request $request, TournamentRegistration $registration): JsonResponse
{
    $this->authorize('approve', $registration);

    $validated = $request->validate([
        'rejection_reason' => 'required|string|max:500',
    ]);

    $registration->update([
        'approval_status' => 'rejected',
        'status' => 'cancelled',
        'rejection_reason' => $validated['rejection_reason'],
        'reviewed_by' => $request->user()->id,
        'reviewed_at' => now(),
    ]);

    // Notify athlete
    Notification::send(
        $registration->athlete->user,
        new RegistrationRejectedNotification($registration, 'tournament', $validated['rejection_reason'])
    );

    return response()->json([
        'message' => 'Registration rejected',
        'registration' => new TournamentRegistrationResource($registration),
    ]);
}
```

### 1.4 Policy Changes

```php
// sportx-api/app/Policies/TournamentRegistrationPolicy.php

class TournamentRegistrationPolicy
{
    public function approve(User $user, TournamentRegistration $registration): bool
    {
        return $user->role === 'organizer'
            && $registration->tournament->organizer_id === $user->organizerProfile->id;
    }

    public function viewOrganizer(User $user, TournamentRegistration $registration): bool
    {
        return $user->role === 'organizer'
            && $registration->tournament->organizer_id === $user->organizerProfile->id;
    }
}
```

### 1.5 Routes

```php
// sportx-api/routes/api.php

Route::middleware(['auth:sanctum', 'role:organizer'])->group(function () {
    // Tournament registrations
    Route::get('/tournaments/{tournament}/pending-requests', [RegistrationController::class, 'pendingTournamentRequests']);
    Route::patch('/registrations/tournaments/{registration}/approve', [RegistrationController::class, 'approveTournament']);
    Route::patch('/registrations/tournaments/{registration}/reject', [RegistrationController::class, 'rejectTournament']);
});
```

---

## 2. Trial Registration Approval

### 2.1 Data Model Changes

**TrialRegistration** - Enhance existing model:

```php
// sportx-api/app/Models/TrialRegistration.php

class TrialRegistration extends Model
{
    protected $fillable = [
        'trial_id',
        'athlete_id',
        'registration_ref',
        'document_status',
        'verification_status',   // existing: pending/verified/rejected
        'approval_status',       // NEW: pending/approved/rejected
        'reminder_enabled',
        'playing_role',
        'medical_conditions',
        'parental_consent',
        'rejection_reason',      // NEW
        'reviewed_by',           // NEW
        'reviewed_at',           // NEW
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
    ];
}
```

### 2.2 Backend API Endpoints

| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| POST | `/trials/{trial}/register` | athlete | Submit trial registration request |
| GET | `/trials/{trial}/registrations` | organizer/academy | List trial registrations |
| GET | `/trials/{trial}/pending-requests` | organizer/academy | List pending requests |
| PATCH | `/registrations/trials/{registration}/approve` | organizer/academy | Approve registration |
| PATCH | `/registrations/trials/{registration}/reject` | organizer/academy | Reject with reason |
| GET | `/me/registrations/trials` | athlete | List athlete's trial registrations |

### 2.3 Controller Changes

Existing `verifyTrial` and `rejectTrial` methods should be enhanced:

```php
// Rename verifyTrial to approveTrial for consistency
public function approveTrial(Request $request, TrialRegistration $registration): JsonResponse
{
    $this->authorize('approve', $registration);

    $registration->update([
        'verification_status' => 'verified',
        'approval_status' => 'approved',
        'status' => 'confirmed',
        'reviewed_by' => $request->user()->id,
        'reviewed_at' => now(),
    ]);

    Notification::send(
        $registration->athlete->user,
        new RegistrationApprovedNotification($registration, 'trial')
    );

    return response()->json([
        'message' => 'Trial registration approved',
        'registration' => new TrialRegistrationResource($registration),
    ]);
}
```

---

## 3. Other Payment-Related Entities

### 3.1 Academy Enrollment / Subscriptions

If academy subscriptions exist:

**AcademySubscription** model with `approval_status`:

```php
class AcademySubscription extends Model
{
    protected $fillable = [
        'academy_id',
        'athlete_id',
        'plan_id',
        'status',           // active/inactive/cancelled
        'approval_status',  // pending/approved/rejected
        'rejection_reason',
        'start_date',
        'end_date',
    ];
}
```

### 3.2 Equipment Booking (if exists)

```php
class EquipmentBooking extends Model
{
    protected $fillable = [
        'equipment_id',
        'athlete_id',
        'booking_date',
        'return_date',
        'status',           // reserved/confirmed/returned/cancelled
        'approval_status',  // pending/approved/rejected
    ];
}
```

### 3.3 Athlete-to-Coach Enrollment

Coaches can offer personal coaching with fee structures (per session, monthly, quarterly). Athletes request to enroll with a coach, and coaches approve/reject these requests.

**CoachingEnrollment Model**:
```php
// sportx-api/app/Models/CoachingEnrollment.php

class CoachingEnrollment extends Model
{
    protected $fillable = [
        'coach_id',
        'athlete_id',
        'plan_type',              // 'session', 'monthly', 'quarterly'
        'fees_amount',            // Amount based on plan
        'status',                 // active/inactive/cancelled/completed
        'approval_status',       // pending/approved/rejected
        'rejection_reason',
        'start_date',
        'end_date',
        'sessions_remaining',      // For session-based plans
        'reviewed_by',
        'reviewed_at',
        'notes',                  // Athlete's notes when requesting
        'coach_response',         // Coach's response when approving/rejecting
    ];

    protected $casts = [
        'fees_amount' => 'decimal:2',
        'start_date' => 'date',
        'end_date' => 'date',
        'reviewed_at' => 'datetime',
    ];

    // Relationships
    public function coach(): BelongsTo
    {
        return $this->belongsTo(CoachProfile::class, 'coach_id');
    }

    public function athlete(): BelongsTo
    {
        return $this->belongsTo(AthleteProfile::class, 'athlete_id');
    }

    public function reviewer(): BelongsTo(User::class, 'reviewed_by')
}
```

**Migration**:
```php
// database/migrations/xxxx_xx_xx_create_coaching_enrollments_table.php

public function up(): void
{
    Schema::create('coaching_enrollments', function (Blueprint $table) {
        $table->id();
        $table->foreignId('coach_id')->constrained('coach_profiles')->onDelete('cascade');
        $table->foreignId('athlete_id')->constrained('athlete_profiles')->onDelete('cascade');
        $table->enum('plan_type', ['session', 'monthly', 'quarterly']);
        $table->decimal('fees_amount', 10, 2);
        $table->enum('status', ['active', 'inactive', 'cancelled', 'completed'])->default('inactive');
        $table->enum('approval_status', ['pending', 'approved', 'rejected'])->default('pending');
        $table->string('rejection_reason')->nullable();
        $table->date('start_date')->nullable();
        $table->date('end_date')->nullable();
        $table->integer('sessions_remaining')->nullable();
        $table->foreignId('reviewed_by')->nullable()->constrained('users')->onDelete('set null');
        $table->timestamp('reviewed_at')->nullable();
        $table->text('notes')->nullable();
        $table->text('coach_response')->nullable();
        $table->timestamps();

        $table->unique(['coach_id', 'athlete_id', 'plan_type']);
        $table->index(['approval_status']);
        $table->index(['coach_id', 'status']);
    });
}
```

**Controller**:
```php
// sportx-api/app/Http/Controllers/CoachingEnrollmentController.php

class CoachingEnrollmentController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'coach_id' => 'required|exists:coach_profiles,id',
            'plan_type' => 'required|in:session,monthly,quarterly',
            'notes' => 'nullable|string|max:500',
        ]);

        $coach = CoachProfile::findOrFail($validated['coach_id']);

        if (!$coach->personal_coaching) {
            return response()->json(['message' => 'Coach does not offer personal coaching'], 400);
        }

        $feesAmount = match ($validated['plan_type']) {
            'session' => $coach->fee_per_session,
            'monthly' => $coach->fee_monthly,
            'quarterly' => $coach->fee_quarterly,
        };

        $enrollment = CoachingEnrollment::create([
            'coach_id' => $coach->id,
            'athlete_id' => $request->user()->athleteProfile->id,
            'plan_type' => $validated['plan_type'],
            'fees_amount' => $feesAmount,
            'approval_status' => 'pending',
            'status' => 'inactive',
            'notes' => $validated['notes'] ?? null,
        ]);

        Notification::send(
            $coach->user,
            new CoachingEnrollmentRequestNotification($enrollment)
        );

        return response()->json([
            'message' => 'Enrollment request submitted',
            'enrollment' => new CoachingEnrollmentResource($enrollment),
        ], 201);
    }

    public function coachEnrollments(Request $request): JsonResponse
    {
        $coach = $request->user()->coachProfile;

        $query = CoachingEnrollment::where('coach_id', $coach->id)
            ->with('athlete.user');

        if ($request->has('status')) {
            $query->where('approval_status', $request->status);
        }

        $enrollments = $query->orderByDesc('created_at')->paginate(20);

        return response()->json($enrollments);
    }

    public function myEnrollments(Request $request): JsonResponse
    {
        $athlete = $request->user()->athleteProfile;

        $enrollments = CoachingEnrollment::where('athlete_id', $athlete->id)
            ->with('coach.user')
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($enrollments);
    }

    public function approve(Request $request, CoachingEnrollment $enrollment): JsonResponse
    {
        $this->authorize('approve', $enrollment);

        $validated = $request->validate([
            'coach_response' => 'nullable|string|max:500',
            'start_date' => 'required|date',
            'end_date' => 'nullable|date|after:start_date',
        ]);

        $sessionsRemaining = match ($enrollment->plan_type) {
            'session' => $enrollment->fees_amount > 0 ? (int)($enrollment->fees_amount / $enrollment->coach->fee_per_session) : null,
            default => null,
        };

        $enrollment->update([
            'approval_status' => 'approved',
            'status' => 'active',
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
            'coach_response' => $validated['coach_response'] ?? null,
            'start_date' => $validated['start_date'],
            'end_date' => $validated['end_date'] ?? null,
            'sessions_remaining' => $sessionsRemaining,
        ]);

        Notification::send(
            $enrollment->athlete->user,
            new CoachingEnrollmentApprovedNotification($enrollment)
        );

        return response()->json([
            'message' => 'Enrollment approved',
            'enrollment' => new CoachingEnrollmentResource($enrollment),
        ]);
    }

    public function reject(Request $request, CoachingEnrollment $enrollment): JsonResponse
    {
        $this->authorize('approve', $enrollment);

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

        Notification::send(
            $enrollment->athlete->user,
            new CoachingEnrollmentRejectedNotification($enrollment, $validated['rejection_reason'])
        );

        return response()->json([
            'message' => 'Enrollment rejected',
            'enrollment' => new CoachingEnrollmentResource($enrollment),
        ]);
    }
}
```

**Policy**:
```php
// sportx-api/app/Policies/CoachingEnrollmentPolicy.php

class CoachingEnrollmentPolicy
{
    public function approve(User $user, CoachingEnrollment $enrollment): bool
    {
        return $user->role === 'coach'
            && $enrollment->coach_id === $user->coachProfile->id;
    }

    public function viewCoach(User $user, CoachingEnrollment $enrollment): bool
    {
        return $user->role === 'coach'
            && $enrollment->coach_id === $user->coachProfile->id;
    }
}
```

**Routes**:
```php
// sportx-api/routes/api.php

Route::middleware(['auth:sanctum'])->group(function () {
    // Athlete routes
    Route::post('/coaches/{coach}/enroll', [CoachingEnrollmentController::class, 'store']);
    Route::get('/me/coaching-enrollments', [CoachingEnrollmentController::class, 'myEnrollments']);
});

Route::middleware(['auth:sanctum', 'role:coach'])->group(function () {
    Route::get('/coach/enrollments', [CoachingEnrollmentController::class, 'coachEnrollments']);
    Route::patch('/coaching-enrollments/{enrollment}/approve', [CoachingEnrollmentController::class, 'approve']);
    Route::patch('/coaching-enrollments/{enrollment}/reject', [CoachingEnrollmentController::class, 'reject']);
});
```

**Notifications**:
```php
class CoachingEnrollmentRequestNotification extends Notification
{
    public function __construct(public CoachingEnrollment $enrollment) {}

    public function toOneSignal($notifiable): array
    {
        return [
            'heading' => 'New Enrollment Request',
            'body' => "{$this->enrollment->athlete->user->name} wants to enroll in your {$this->enrollment->plan_type} coaching plan",
            'data' => [
                'type' => 'coaching_enrollment_request',
                'enrollment_id' => $this->enrollment->id,
            ],
        ];
    }
}

class CoachingEnrollmentApprovedNotification extends Notification
{
    public function __construct(public CoachingEnrollment $enrollment) {}

    public function toOneSignal($notifiable): array
    {
        $planText = $this->enrollment->plan_type;
        return [
            'heading' => 'Enrollment Confirmed!',
            'body' => "Your {$planText} coaching enrollment with {$this->enrollment->coach->full_name} has been approved.",
            'data' => [
                'type' => 'coaching_enrollment_approved',
                'enrollment_id' => $this->enrollment->id,
            ],
        ];
    }
}

class CoachingEnrollmentRejectedNotification extends Notification
{
    public function __construct(public CoachingEnrollment $enrollment, public string $reason) {}

    public function toOneSignal($notifiable): array
    {
        return [
            'heading' => 'Enrollment Update',
            'body' => "Your enrollment request was not approved. Reason: {$this->reason}",
            'data' => [
                'type' => 'coaching_enrollment_rejected',
                'enrollment_id' => $this->enrollment->id,
            ],
        ];
    }
}
```

---

## 4. Role-Based Workflows

### 4.1 Athlete Workflow

```
1. Browse tournaments/trials
2. View details (entry fee shown for reference only)
3. Tap "Register" or "Request Participation"
4. Fill registration form
5. Submit → Status: "Pending Approval"
6. Receive push notification when:
   - Approved → Status: "Confirmed"
   - Rejected → Status: "Rejected" with reason
7. View all registrations in "My Registrations" screen
```

### 4.2 Organizer Workflow

```
1. View dashboard with pending approval count
2. Navigate to "Registration Requests"
3. View list of pending requests with:
   - Athlete profile
   - Registration details
   - Submission date
4. Tap to view full details
5. Choose Approve or Reject (with reason)
6. Confirmation sent to athlete
7. Registration count updates
```

### 4.3 Admin Workflow (Optional Override)

```
1. Can view all registration requests across platform
2. Can intervene if disputes arise
3. Can approve/reject on behalf of organizer
4. Audit log maintained for all actions
```

### 4.4 Academy Workflow (for Trials)

```
1. Receive trial registration notifications
2. Review athlete documents
3. Approve/Reject with feedback
4. Manage trial capacity
```

---

## 5. Notification System

### 5.1 Notification Classes

```php
// sportx-api/app/Notifications/RegistrationRequestNotification.php

class RegistrationRequestNotification extends Notification
{
    public function __construct(
        public Model $registration,
        public string $type // 'tournament' or 'trial'
    ) {}

    public function toOneSignal($notifiable): array
    {
        return [
            'heading' => 'New Registration Request',
            'body' => "{$this->registration->athlete->user->name} requested to register for {$this->registration->{$this->type}->name}",
            'data' => [
                'type' => 'registration_request',
                'registration_id' => $this->registration->id,
                'registration_type' => $this->type,
            ],
        ];
    }
}

// sportx-api/app/Notifications/RegistrationApprovedNotification.php

class RegistrationApprovedNotification extends Notification
{
    public function toOneSignal($notifiable): array
    {
        return [
            'heading' => 'Registration Confirmed!',
            'body' => "Your registration for {$this->registration->tournament->name} has been approved.",
            'data' => [
                'type' => 'registration_approved',
                'registration_id' => $this->registration->id,
            ],
        ];
    }
}

// sportx-api/app/Notifications/RegistrationRejectedNotification.php

class RegistrationRejectedNotification extends Notification
{
    public function __construct(
        public Model $registration,
        public string $type,
        public string $reason
    ) {}

    public function toOneSignal($notifiable): array
    {
        return [
            'heading' => 'Registration Update',
            'body' => "Your registration was not approved. Reason: {$this->reason}",
            'data' => [
                'type' => 'registration_rejected',
                'registration_id' => $this->registration->id,
            ],
        ];
    }
}
```

---

## 6. Flutter App Changes

### 6.1 Data Models

```dart
// sportx_app/lib/shared/models/tournament_registration.dart

enum ApprovalStatus { pending, approved, rejected }

class TournamentRegistration {
  final String id;
  final Tournament tournament;
  final TournamentCategory category;
  final AthleteProfile athlete;
  final ParticipationType participationType;
  final String? teamName;
  final String paymentStatus;    // Display only
  final ApprovalStatus approvalStatus;
  final RegistrationStatus status;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  bool get isPending => approvalStatus == ApprovalStatus.pending;
  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isRejected => approvalStatus == ApprovalStatus.rejected;
}
```

### 6.2 Registration Screen Changes

**Tournament Registration Screen**:
```dart
// Remove Stripe/payment integration
// Replace with:

class TournamentRegistrationScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Entry fee displayed as info only
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text(
                'Entry Fee: ₹${tournament.entryFee} (Approval Required)',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),

        // Registration form...

        // Replace payment button with:
        ElevatedButton(
          onPressed: () => _submitRegistrationRequest(context, ref),
          child: Text('Request to Participate'),
        ),

        // Show status after submission
        if (registration != null) ...[
          _buildStatusCard(registration),
        ],
      ],
    );
  }

  Widget _buildStatusCard(TournamentRegistration reg) {
    final statusColor = switch (reg.approvalStatus) {
      ApprovalStatus.pending => Colors.orange,
      ApprovalStatus.approved => Colors.green,
      ApprovalStatus.rejected => Colors.red,
    };

    final statusIcon = switch (reg.approvalStatus) {
      ApprovalStatus.pending => Icons.hourglass_empty,
      ApprovalStatus.approved => Icons.check_circle,
      ApprovalStatus.rejected => Icons.cancel,
    };

    final statusText = switch (reg.approvalStatus) {
      ApprovalStatus.pending => 'Pending Approval',
      ApprovalStatus.approved => 'Registration Confirmed!',
      ApprovalStatus.rejected => 'Registration Rejected: ${reg.rejectionReason}',
    };

    return Card(
      color: statusColor.withOpacity(0.1),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(statusText),
        subtitle: reg.isRejected
            ? Text(reg.rejectionReason ?? '')
            : Text('You will be notified when organizer reviews your request'),
      ),
    );
  }
}
```

### 6.3 Organizer Approval Screens

**Registration Management Screen**:
```dart
// sportx_app/lib/features/organizer/presentation/screens/registration_management_screen.dart

class RegistrationManagementScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: TabBar(
          tabs: [
            Tab(text: 'Pending (${pendingCount})'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
        body: TabBarView(
          children: [
            _RegistrationListView(status: ApprovalStatus.pending),
            _RegistrationListView(status: ApprovalStatus.approved),
            _RegistrationListView(status: ApprovalStatus.rejected),
          ],
        ),
      ),
    );
  }
}

class _RegistrationListView extends ConsumerWidget {
  final ApprovalStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrations = ref.watch(pendingRegistrationsProvider(status));

    return ListView.builder(
      itemCount: registrations.length,
      itemBuilder: (context, index) {
        final reg = registrations[index];
        return _RegistrationCard(
          registration: reg,
          onApprove: status == ApprovalStatus.pending
              ? () => _approveRegistration(context, ref, reg)
              : null,
          onReject: status == ApprovalStatus.pending
              ? () => _showRejectDialog(context, ref, reg)
              : null,
        );
      },
    );
  }

  Future<void> _approveRegistration(
    BuildContext context,
    WidgetRef ref,
    TournamentRegistration reg,
  ) async {
    await ref.read(registrationActionsProvider.notifier).approve(reg.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration approved')),
      );
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    TournamentRegistration reg,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Registration'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await ref.read(registrationActionsProvider.notifier).reject(reg.id, reason);
    }
  }
}
```

### 6.4 My Registrations Screen

```dart
// sportx_app/lib/features/athlete/presentation/screens/my_registrations_screen.dart

class MyRegistrationsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTournament_regs = ref.watch(myTournamentRegistrationsProvider);
    final myTrial_regs = ref.watch(myTrialRegistrationsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabBar(
          tabs: [
            Tab(text: 'Tournaments'),
            Tab(text: 'Trials'),
          ],
        ),
        body: TabBarView(
          children: [
            _RegistrationsListView(registrations: myTournament_regs),
            _RegistrationsListView(registrations: myTrial_regs),
          ],
        ),
      ),
    );
  }
}

class _RegistrationsListView extends StatelessWidget {
  final List<dynamic> registrations;

  @override
  Widget build(BuildContext context) {
    if (registrations.isEmpty) {
      return Center(child: Text('No registrations yet'));
    }

    return ListView.builder(
      itemCount: registrations.length,
      itemBuilder: (context, index) {
        final reg = registrations[index];
        return Card(
          child: ListTile(
            title: Text(reg.tournament.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${reg.category.name}'),
                _buildApprovalChip(reg.approvalStatus),
              ],
            ),
            trailing: reg.isApproved
                ? Icon(Icons.check_circle, color: Colors.green)
                : reg.isRejected
                    ? Icon(Icons.cancel, color: Colors.red)
                    : Icon(Icons.hourglass_empty, color: Colors.orange),
          ),
        );
      },
    );
  }

  Widget _buildApprovalChip(ApprovalStatus status) {
    return Chip(
      label: Text(
        status.label,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: switch (status) {
        ApprovalStatus.pending => Colors.orange,
        ApprovalStatus.approved => Colors.green,
        ApprovalStatus.rejected => Colors.red,
      },
    );
  }
}
```

### 6.5 Provider Changes

```dart
// sportx_app/lib/features/organizer/presentation/providers/organizer_provider.dart

class OrganizerProvider extends AsyncNotifier<List<TournamentRegistration>> {
  // Existing code...

  Future<void> approveRegistration(String registrationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await dio.patch('/registrations/tournaments/$registrationId/approve');
      return ref.read(pendingRegistrationsProvider(ApprovalStatus.pending).future);
    });
  }

  Future<void> rejectRegistration(String registrationId, String reason) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await dio.patch('/registrations/tournaments/$registrationId/reject', data: {
        'rejection_reason': reason,
      });
      return ref.read(pendingRegistrationsProvider(ApprovalStatus.pending).future);
    });
  }
}
```

### 6.6 Coach Enrollment Flutter Changes

**Data Model**:
```dart
// sportx_app/lib/shared/models/coaching_enrollment.dart

enum PlanType { session, monthly, quarterly }

class CoachingEnrollment {
  final String id;
  final Coach coach;
  final AthleteProfile athlete;
  final PlanType planType;
  final double feesAmount;
  final String approvalStatus;  // pending/approved/rejected
  final String status;          // active/inactive/cancelled
  final String? rejectionReason;
  final String? coachResponse;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? sessionsRemaining;
  final DateTime? reviewedAt;

  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';
  bool get isActive => status == 'active';
}
```

**Coach Enrollment Button on Coach Profile**:
```dart
// sportx_app/lib/features/coach/presentation/screens/coach_profile_detail_screen.dart

class CoachProfileDetailScreen extends ConsumerStatefulWidget {
  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    // ... existing scaffold and app bar ...

    return SingleChildScrollView(
      child: Column(
        children: [
          // ... existing profile header, stats, about, credentials, etc. ...

          // Add enrollment section before actions
          if (coach.personalCoaching && currentUserIsAthlete) ...[
            _buildPricingSection(context),
            _buildEnrollmentButton(context),
          ],

          // ... remaining content ...
        ],
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coaching Plans', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12),
            if (coach.feePerSession != null)
              _buildPriceRow('Per Session', '₹${coach.feePerSession!.toStringAsFixed(0)}'),
            if (coach.feeMonthly != null)
              _buildPriceRow('Monthly', '₹${coach.feeMonthly!.toStringAsFixed(0)}'),
            if (coach.feeQuarterly != null)
              _buildPriceRow('Quarterly', '₹${coach.feeQuarterly!.toStringAsFixed(0)}'),
            SizedBox(height: 8),
            Text(
              'Approval required before enrollment',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(price, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEnrollmentButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () => _showEnrollmentDialog(context),
        child: Text('Enroll with Coach'),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 48),
        ),
      ),
    );
  }

  Future<void> _showEnrollmentDialog(BuildContext context) async {
    final selectedPlan = await showModalBottomSheet<PlanType>(
      context: context,
      builder: (context) => _PlanSelectionSheet(coach: coach),
    );

    if (selectedPlan != null && context.mounted) {
      final notes = await showDialog<String>(
        context: context,
        builder: (context) => _EnrollmentNotesDialog(),
      );

      if (notes != null && context.mounted) {
        await _submitEnrollment(selectedPlan, notes);
      }
    }
  }

  Future<void> _submitEnrollment(PlanType plan, String notes) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/coaches/${coach.id}/enroll', data: {
        'plan_type': plan.name,
        'notes': notes,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrollment request submitted!')),
        );
        // Refresh coach data
        _loadCoachData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit enrollment: $e')),
        );
      }
    }
  }
}

class _PlanSelectionSheet extends StatelessWidget {
  final Coach coach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Plan', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          if (coach.feePerSession != null)
            ListTile(
              title: Text('Per Session'),
              subtitle: Text('₹${coach.feePerSession!.toStringAsFixed(0)}'),
              onTap: () => Navigator.pop(context, PlanType.session),
            ),
          if (coach.feeMonthly != null)
            ListTile(
              title: Text('Monthly'),
              subtitle: Text('₹${coach.feeMonthly!.toStringAsFixed(0)}'),
              trailing: Chip(label: Text('Popular')),
              onTap: () => Navigator.pop(context, PlanType.monthly),
            ),
          if (coach.feeQuarterly != null)
            ListTile(
              title: Text('Quarterly'),
              subtitle: Text('₹${coach.feeQuarterly!.toStringAsFixed(0)}'),
              onTap: () => Navigator.pop(context, PlanType.quarterly),
            ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _EnrollmentNotesDialog extends StatefulWidget {
  @override
  State<_EnrollmentNotesDialog> createState() => _EnrollmentNotesDialogState();
}

class _EnrollmentNotesDialogState extends State<_EnrollmentNotesDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enrollment Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add a note to your coach (optional):'),
          SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Introduce yourself and your goals...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text('Submit Request'),
        ),
      ],
    );
  }
}
```

**Coach Enrollment Management Screen**:
```dart
// sportx_app/lib/features/coach/presentation/screens/coach_enrollment_screen.dart

class CoachEnrollmentScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollments = ref.watch(coachEnrollmentsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Enrollment Requests'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Active'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EnrollmentListView(filter: 'pending'),
            _EnrollmentListView(filter: 'approved'),
            _EnrollmentListView(filter: 'rejected'),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentListView extends ConsumerWidget {
  final String filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollments = ref.watch(coachEnrollmentsProvider(filter));

    return enrollments.when(
      data: (items) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final enrollment = items[index];
          return _EnrollmentCard(
            enrollment: enrollment,
            onApprove: filter == 'pending'
                ? () => _approveEnrollment(context, ref, enrollment)
                : null,
            onReject: filter == 'pending'
                ? () => _showRejectDialog(context, ref, enrollment)
                : null,
          );
        },
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _approveEnrollment(
    BuildContext context,
    WidgetRef ref,
    CoachingEnrollment enrollment,
  ) async {
    final startDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().addYears(1),
    );

    if (startDate != null && context.mounted) {
      final response = await ref.read(coachEnrollmentActionsProvider.notifier).approve(
        enrollment.id,
        startDate: startDate,
      );

      if (context.mounted && response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrollment approved')),
        );
      }
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    CoachingEnrollment enrollment,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Enrollment'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Reason',
            hintText: 'Why are you rejecting this request?',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty && context.mounted) {
      await ref.read(coachEnrollmentActionsProvider.notifier).reject(enrollment.id, reason);
    }
  }
}

class _EnrollmentCard extends StatelessWidget {
  final CoachingEnrollment enrollment;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: enrollment.athlete.profilePhotoUrl != null
                      ? NetworkImage(enrollment.athlete.profilePhotoUrl!)
                      : null,
                  child: enrollment.athlete.profilePhotoUrl == null
                      ? Text(enrollment.athlete.user.name[0])
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enrollment.athlete.user.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        enrollment.athlete.primarySport ?? '',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(enrollment.approvalStatus),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Plan', style: TextStyle(fontSize: 12)),
                      Text(
                        enrollment.planType.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Fees', style: TextStyle(fontSize: 12)),
                      Text(
                        '₹${enrollment.feesAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (enrollment.notes != null && enrollment.notes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Note: ${enrollment.notes}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            if (enrollment.isRejected && enrollment.rejectionReason != null) ...[
              SizedBox(height: 8),
              Text(
                'Reason: ${enrollment.rejectionReason}',
                style: TextStyle(color: Colors.red),
              ),
            ],
            if (onApprove != null || onReject != null) ...[
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      child: Text('Reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  SizedBox(width: 8),
                  if (onApprove != null)
                    ElevatedButton(
                      onPressed: onApprove,
                      child: Text('Approve'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = switch (status) {
      'pending' => Colors.orange,
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };

    return Chip(
      label: Text(status, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
```

**Athlete My Enrollments Screen**:
```dart
// sportx_app/lib/features/athlete/presentation/screens/my_coaching_enrollments_screen.dart

class MyCoachingEnrollmentsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollments = ref.watch(myEnrollmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Coaching Enrollments'),
      ),
      body: enrollments.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No coaching enrollments yet'),
                  Text(
                    'Browse coaches and request enrollment',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final enrollment = items[index];
              return _MyEnrollmentCard(enrollment: enrollment);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MyEnrollmentCard extends StatelessWidget {
  final CoachingEnrollment enrollment;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: enrollment.coach.profilePhotoUrl != null
              ? NetworkImage(enrollment.coach.profilePhotoUrl!)
              : null,
          child: enrollment.coach.profilePhotoUrl == null
              ? Text(enrollment.coach.fullName[0])
              : null,
        ),
        title: Text(enrollment.coach.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${enrollment.planType.toUpperCase()} - ₹${enrollment.feesAmount.toStringAsFixed(0)}'),
            if (enrollment.isActive && enrollment.startDate != null)
              Text(
                'Started: ${enrollment.startDate!.formattedDate}',
                style: TextStyle(fontSize: 12),
              ),
            if (enrollment.sessionsRemaining != null)
              Text(
                'Sessions remaining: ${enrollment.sessionsRemaining}',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
          ],
        ),
        trailing: _buildStatusIcon(enrollment.approvalStatus),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'approved') {
      return Icon(Icons.check_circle, color: Colors.green);
    } else if (status == 'rejected') {
      return Icon(Icons.cancel, color: Colors.red);
    } else {
      return Icon(Icons.hourglass_empty, color: Colors.orange);
    }
  }
}
```

**Provider Changes**:
```dart
// sportx_app/lib/features/coach/presentation/providers/coach_enrollment_provider.dart

final coachEnrollmentsProvider = FutureProvider.family<List<CoachingEnrollment>, String>((ref, filter) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/coach/enrollments', queryParameters: {'status': filter});
  return (response.data['data'] as List)
      .map((e) => CoachingEnrollment.fromJson(e))
      .toList();
});

final myEnrollmentsProvider = FutureProvider<List<CoachingEnrollment>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/me/coaching-enrollments');
  return (response.data['data'] as List)
      .map((e) => CoachingEnrollment.fromJson(e))
      .toList();
});

class CoachEnrollmentActionsNotifier extends StateNotifier<bool> {
  final Ref ref;

  CoachEnrollmentActionsNotifier(this.ref) : super(false);

  Future<bool> approve(String enrollmentId, {required DateTime startDate, DateTime? endDate}) async {
    state = true;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/coaching-enrollments/$enrollmentId/approve', data: {
        'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });
      ref.invalidate(coachEnrollmentsProvider);
      return true;
    } catch (e) {
      return false;
    } finally {
      state = false;
    }
  }

  Future<bool> reject(String enrollmentId, String reason) async {
    state = true;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/coaching-enrollments/$enrollmentId/reject', data: {
        'rejection_reason': reason,
      });
      ref.invalidate(coachEnrollmentsProvider);
      return true;
    } catch (e) {
      return false;
    } finally {
      state = false;
    }
  }
}

final coachEnrollmentActionsProvider = StateNotifierProvider((ref) {
  return CoachEnrollmentActionsNotifier(ref);
});
```

---

## 7. Database Seeding for Testing

```php
// database/seeders/TournamentRegistrationSeeder.php

class TournamentRegistrationSeeder extends Seeder
{
    public function run(): void
    {
        // Create sample pending registrations for testing
        $registrations = [
            [
                'tournament_id' => 1,
                'category_id' => 1,
                'athlete_id' => 1,
                'participation_type' => 'individual',
                'approval_status' => 'pending',
                'status' => 'pending',
            ],
            [
                'tournament_id' => 1,
                'category_id' => 1,
                'athlete_id' => 2,
                'participation_type' => 'individual',
                'approval_status' => 'approved',
                'status' => 'confirmed',
                'reviewed_at' => now(),
            ],
        ];

        foreach ($registrations as $data) {
            TournamentRegistration::create($data);
        }
    }
}
```

---

## 8. Admin Panel Analytics & Activity Tracking

> **Note:** This section describes the **Laravel Blade-based Admin Panel** (the server-rendered web admin at `/admin`). The Flutter app does not have an admin panel—all admin functionality is accessed via the web admin panel.

### 8.1 Overview

The admin panel (web-based, Laravel Blade views) provides comprehensive visibility into all registration activities across the platform, enabling admins to monitor, analyze, and intervene when necessary.

### 8.2 Activity Log Model

```php
// sportx-api/app/Models/RegistrationActivityLog.php

class RegistrationActivityLog extends Model
{
    protected $table = 'registration_activity_logs';

    protected $fillable = [
        'registration_type',      // 'tournament' or 'trial'
        'registration_id',
        'action',                // 'submitted', 'approved', 'rejected', 'cancelled'
        'actor_type',             // 'athlete', 'organizer', 'admin'
        'actor_id',
        'metadata',               // JSON: old_values, new_values, rejection_reason
        'ip_address',
        'user_agent',
    ];

    protected $casts = [
        'metadata' => 'array',
        'created_at' => 'datetime',
    ];

    // Relationships
    public function actor(): MorphTo
    public function registration(): MorphTo
}
```

**Migration**:
```php
// database/migrations/xxxx_xx_xx_create_registration_activity_logs_table.php

public function up(): void
{
    Schema::create('registration_activity_logs', function (Blueprint $table) {
        $table->id();
        $table->string('registration_type'); // tournament, trial, academy
        $table->unsignedBigInteger('registration_id');
        $table->string('action'); // submitted, approved, rejected, cancelled
        $table->string('actor_type'); // athlete, organizer, admin
        $table->unsignedBigInteger('actor_id');
        $table->json('metadata')->nullable();
        $table->string('ip_address', 45)->nullable();
        $table->text('user_agent')->nullable();
        $table->timestamps();

        $table->index(['registration_type', 'registration_id']);
        $table->index(['actor_type', 'actor_id']);
        $table->index(['action']);
        $table->index(['created_at']);
    });
}
```

### 8.3 Activity Log Service

```php
// sportx-api/app/Services/RegistrationActivityService.php

class RegistrationActivityService
{
    public function log(
        string $registrationType,
        int $registrationId,
        string $action,
        Model $actor,
        array $metadata = []
    ): RegistrationActivityLog {
        return RegistrationActivityLog::create([
            'registration_type' => $registrationType,
            'registration_id' => $registrationId,
            'action' => $action,
            'actor_type' => $actor->getMorphClass(),
            'actor_id' => $actor->getKey(),
            'metadata' => $metadata,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]);
    }

    public function logSubmission(Model $registration, Model $athlete): RegistrationActivityLog
    {
        return $this->log(
            $this->getRegistrationType($registration),
            $registration->getKey(),
            'submitted',
            $athlete,
            [
                'tournament_id' => $registration->tournament_id ?? null,
                'trial_id' => $registration->trial_id ?? null,
                'submitted_at' => now()->toIso8601String(),
            ]
        );
    }

    public function logApproval(Model $registration, Model $approver): RegistrationActivityLog
    {
        return $this->log(
            $this->getRegistrationType($registration),
            $registration->getKey(),
            'approved',
            $approver,
            [
                'previous_status' => $registration->getOriginal('approval_status'),
                'new_status' => 'approved',
                'approved_at' => now()->toIso8601String(),
            ]
        );
    }

    public function logRejection(
        Model $registration,
        Model $rejector,
        string $reason
    ): RegistrationActivityLog {
        return $this->log(
            $this->getRegistrationType($registration),
            $registration->getKey(),
            'rejected',
            $rejector,
            [
                'previous_status' => $registration->getOriginal('approval_status'),
                'new_status' => 'rejected',
                'rejection_reason' => $reason,
                'rejected_at' => now()->toIso8601String(),
            ]
        );
    }

    private function getRegistrationType(Model $registration): string
    {
        return class_basename($registration); // TournamentRegistration or TrialRegistration
    }
}
```

### 8.4 Analytics Controller

```php
// sportx-api/app/Http/Controllers/Admin/RegistrationAnalyticsController.php

class RegistrationAnalyticsController extends Controller
{
    public function __construct(
        private RegistrationActivityService $activityService
    ) {}

    public function dashboard(): JsonResponse
    {
        $stats = [
            'total_registrations' => $this->getTotalRegistrations(),
            'pending_count' => $this->getPendingCount(),
            'approved_count' => $this->getApprovedCount(),
            'rejected_count' => $this->getRejectedCount(),
            'approval_rate' => $this->calculateApprovalRate(),
            'avg_response_time' => $this->calculateAvgResponseTime(),

            // Coaching enrollment stats
            'total_coaching_enrollments' => $this->getTotalCoachingEnrollments(),
            'pending_coaching_enrollments' => $this->getPendingCoachingEnrollments(),
            'active_coaching_enrollments' => $this->getActiveCoachingEnrollments(),
            'coaching_revenue_estimate' => $this->getCoachingRevenueEstimate(),
        ];

        return response()->json($stats);
    }

    public function chartData(Request $request): JsonResponse
    {
        $period = $request->get('period', '30_days'); // 7_days, 30_days, 90_days, 12_months

        $data = [
            'labels' => $this->getChartLabels($period),
            'datasets' => [
                [
                    'label' => 'Registrations',
                    'data' => $this->getRegistrationsByDay($period),
                    'borderColor' => '#3B82F6',
                    'backgroundColor' => 'rgba(59, 130, 246, 0.1)',
                ],
                [
                    'label' => 'Approved',
                    'data' => $this->getApprovedByDay($period),
                    'borderColor' => '#22C55E',
                    'backgroundColor' => 'rgba(34, 197, 94, 0.1)',
                ],
                [
                    'label' => 'Rejected',
                    'data' => $this->getRejectedByDay($period),
                    'borderColor' => '#EF4444',
                    'backgroundColor' => 'rgba(239, 68, 68, 0.1)',
                ],
            ],
        ];

        return response()->json($data);
    }

    public function activityLog(Request $request): JsonResponse
    {
        $query = RegistrationActivityLog::with(['actor', 'registration'])
            ->orderByDesc('created_at');

        // Filters
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

        $activities = $query->paginate(50);

        return response()->json($activities);
    }

    public function topOrganizers(Request $request): JsonResponse
    {
        $period = $request->get('period', '30_days');

        $organizers = DB::table('registration_activity_logs')
            ->join('users', 'registration_activity_logs.actor_id', '=', 'users.id')
            ->join('organizer_profiles', 'users.id', '=', 'organizer_profiles.user_id')
            ->where('registration_activity_logs.actor_type', 'organizer')
            ->where('registration_activity_logs.created_at', '>=', now()->subDays($this->getPeriodDays($period)))
            ->select(
                'organizer_profiles.id',
                'organizer_profiles.organization_name',
                DB::raw('COUNT(*) as total_actions'),
                DB::raw("SUM(CASE WHEN action = 'approved' THEN 1 ELSE 0 END) as approvals"),
                DB::raw("SUM(CASE WHEN action = 'rejected' THEN 1 ELSE 0 END) as rejections")
            )
            ->groupBy('organizer_profiles.id', 'organizer_profiles.organization_name')
            ->orderByDesc('total_actions')
            ->limit(10)
            ->get();

        return response()->json($organizers);
    }

    public function sportBreakdown(Request $request): JsonResponse
    {
        $period = $request->get('period', '30_days');

        $breakdown = TournamentRegistration::query()
            ->join('tournaments', 'tournament_registrations.tournament_id', '=', 'tournaments.id')
            ->join('sports', 'tournaments.sport_id', '=', 'sports.id')
            ->where('tournament_registrations.created_at', '>=', now()->subDays($this->getPeriodDays($period)))
            ->select(
                'sports.id',
                'sports.name',
                DB::raw('COUNT(*) as total'),
                DB::raw("SUM(CASE WHEN approval_status = 'approved' THEN 1 ELSE 0 END) as approved"),
                DB::raw("SUM(CASE WHEN approval_status = 'pending' THEN 1 ELSE 0 END) as pending"),
                DB::raw("SUM(CASE WHEN approval_status = 'rejected' THEN 1 ELSE 0 END) as rejected")
            )
            ->groupBy('sports.id', 'sports.name')
            ->get();

        return response()->json($breakdown);
    }

    public function exportActivityLog(Request $request): StreamedResponse
    {
        $query = RegistrationActivityLog::with(['actor', 'registration'])
            ->orderByDesc('created_at');

        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->get('date_from'));
        }
        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->get('date_to'));
        }

        return Excel::download(
            new ActivityLogExport($query),
            'registration_activities_' . now()->format('Y_m_d') . '.xlsx'
        );
    }

    // Private helper methods
    private function getTotalRegistrations(): int
    {
        return TournamentRegistration::count() + TrialRegistration::count();
    }

    private function getPendingCount(): int
    {
        return TournamentRegistration::where('approval_status', 'pending')->count()
             + TrialRegistration::where('approval_status', 'pending')->count();
    }

    private function getApprovedCount(): int
    {
        return TournamentRegistration::where('approval_status', 'approved')->count()
             + TrialRegistration::where('approval_status', 'approved')->count();
    }

    private function getRejectedCount(): int
    {
        return TournamentRegistration::where('approval_status', 'rejected')->count()
             + TrialRegistration::where('approval_status', 'rejected')->count();
    }

    private function calculateApprovalRate(): float
    {
        $total = $this->getApprovedCount() + $this->getRejectedCount();
        return $total > 0 ? round(($this->getApprovedCount() / $total) * 100, 2) : 0;
    }

    private function calculateAvgResponseTime(): string
    {
        $registrations = TournamentRegistration::whereNotNull('reviewed_at')
            ->selectRaw('AVG(TIMESTAMPDIFF(HOUR, created_at, reviewed_at)) as avg_hours')
            ->first();

        return $registrations->avg_hours
            ? round($registrations->avg_hours, 1) . ' hours'
            : 'N/A';
    }

    // Coaching enrollment helper methods
    private function getTotalCoachingEnrollments(): int
    {
        return CoachingEnrollment::count();
    }

    private function getPendingCoachingEnrollments(): int
    {
        return CoachingEnrollment::where('approval_status', 'pending')->count();
    }

    private function getActiveCoachingEnrollments(): int
    {
        return CoachingEnrollment::where('status', 'active')->count();
    }

    private function getCoachingRevenueEstimate(): float
    {
        return CoachingEnrollment::where('approval_status', 'approved')
            ->sum('fees_amount') ?? 0;
    }

    private function getPeriodDays(string $period): int
    {
        return match ($period) {
            '7_days' => 7,
            '30_days' => 30,
            '90_days' => 90,
            '12_months' => 365,
            default => 30,
        };
    }

    private function getChartLabels(string $period): array
    {
        $days = $this->getPeriodDays($period);
        $labels = [];

        for ($i = $days - 1; $i >= 0; $i--) {
            $date = now()->subDays($i);
            $labels[] = $date->format($period === '12_months' ? 'M Y' : 'M d');
        }

        return $labels;
    }

    private function getRegistrationsByDay(int $days): array
    {
        $data = [];
        for ($i = $days - 1; $i >= 0; $i--) {
            $date = now()->subDays($i)->format('Y-m-d');
            $count = TournamentRegistration::whereDate('created_at', $date)->count()
                   + TrialRegistration::whereDate('created_at', $date)->count();
            $data[] = $count;
        }
        return $data;
    }

    private function getApprovedByDay(int $days): array
    {
        $data = [];
        for ($i = $days - 1; $i >= 0; $i--) {
            $date = now()->subDays($i)->format('Y-m-d');
            $count = TournamentRegistration::whereDate('reviewed_at', $date)
                        ->where('approval_status', 'approved')->count()
                   + TrialRegistration::whereDate('reviewed_at', $date)
                        ->where('approval_status', 'approved')->count();
            $data[] = $count;
        }
        return $data;
    }

    private function getRejectedByDay(int $days): array
    {
        $data = [];
        for ($i = $days - 1; $i >= 0; $i--) {
            $date = now()->subDays($i)->format('Y-m-d');
            $count = TournamentRegistration::whereDate('reviewed_at', $date)
                        ->where('approval_status', 'rejected')->count()
                   + TrialRegistration::whereDate('reviewed_at', $date)
                        ->where('approval_status', 'rejected')->count();
            $data[] = $count;
        }
        return $data;
    }
}
```

### 8.5 API Routes for Admin Analytics

```php
// sportx-api/routes/api.php

Route::middleware(['auth:sanctum', 'role:admin', 'admin.2fa'])->prefix('admin')->group(function () {
    // Analytics Dashboard
    Route::get('/registrations/analytics/dashboard', [RegistrationAnalyticsController::class, 'dashboard']);
    Route::get('/registrations/analytics/chart', [RegistrationAnalyticsController::class, 'chartData']);
    Route::get('/registrations/analytics/top-organizers', [RegistrationAnalyticsController::class, 'topOrganizers']);
    Route::get('/registrations/analytics/sport-breakdown', [RegistrationAnalyticsController::class, 'sportBreakdown']);

    // Activity Log
    Route::get('/registrations/activity-log', [RegistrationAnalyticsController::class, 'activityLog']);
    Route::get('/registrations/activity-log/export', [RegistrationAnalyticsController::class, 'exportActivityLog']);

    // Admin Override Actions
    Route::patch('/registrations/tournaments/{registration}/admin-approve', [RegistrationController::class, 'adminApproveTournament']);
    Route::patch('/registrations/tournaments/{registration}/admin-reject', [RegistrationController::class, 'adminRejectTournament']);
    Route::patch('/registrations/trials/{registration}/admin-approve', [RegistrationController::class, 'adminApproveTrial']);
    Route::patch('/registrations/trials/{registration}/admin-reject', [RegistrationController::class, 'adminRejectTrial']);

    // Coaching Enrollment Analytics
    Route::get('/coaching/analytics/dashboard', [CoachingAnalyticsController::class, 'dashboard']);
    Route::get('/coaching/analytics/enrollments-by-coach', [CoachingAnalyticsController::class, 'enrollmentsByCoach']);
    Route::get('/coaching/analytics/plan-breakdown', [CoachingAnalyticsController::class, 'planBreakdown']);

    // Coaching Enrollment Admin Override
    Route::patch('/coaching-enrollments/{enrollment}/admin-approve', [CoachingEnrollmentController::class, 'adminApprove']);
    Route::patch('/coaching-enrollments/{enrollment}/admin-reject', [CoachingEnrollmentController::class, 'adminReject']);
});
```

### 8.6 Admin Panel Web Views (Blade Templates)

> **Note:** The Flutter app does not have an admin panel. Admin analytics are accessed via the web admin panel (Laravel Blade views) at `/admin`. The backend API endpoints are already implemented in `RegistrationAnalyticsController`.

**Example Blade View:**

```blade
{{-- resources/views/admin/registrations/analytics.blade.php --}}

@extends('admin.layouts.main')

@section('content')
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
    <h1 class="h2">Registration Analytics</h1>
</div>

{{-- Stats Cards --}}
<div class="row mb-4">
    @foreach(['total_registrations','pending_count','approved_count','rejected_count'] as $stat)
    <div class="col-md-3">
        <div class="card text-center">
            <div class="card-body">
                <h5>{{ $stats[$stat] }}</h5>
                <p class="text-muted">{{ ucwords(str_replace('_',' ',$stat)) }}</p>
            </div>
        </div>
    </div>
    @endforeach
</div>

{{-- Charts and Activity Log via AJAX/Chart.js --}}
@endsection
```
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(analyticsStatsProvider);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Total Registrations',
          value: stats.total.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Pending Approval',
          value: stats.pending.toString(),
          icon: Icons.hourglass_empty,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Approved',
          value: stats.approved.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Rejected',
          value: stats.rejected.toString(),
          icon: Icons.cancel,
          color: Colors.red,
        ),
        _StatCard(
          title: 'Approval Rate',
          value: '${stats.approvalRate}%',
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
        _StatCard(
          title: 'Avg Response Time',
          value: stats.avgResponseTime,
          icon: Icons.timer,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context, WidgetRef ref) {
    final chartData = ref.watch(chartDataProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Registration Trends', style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<String>(
                  value: selectedPeriod,
                  items: ['7_days', '30_days', '90_days', '12_months']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (v) => ref.read(selectedPeriodProvider.notifier).state = v!,
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.registrations.asSpots(),
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: chartData.approved.asSpots(),
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: chartData.rejected.asSpots(),
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ChartLegend(color: Colors.blue, label: 'Registrations'),
                _ChartLegend(color: Colors.green, label: 'Approved'),
                _ChartLegend(color: Colors.red, label: 'Rejected'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportBreakdown(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(sportBreakdownProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrations by Sport', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: breakdown.map((b) => b.total.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                  barGroups: breakdown.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.total.toDouble(),
                          color: Colors.blue,
                        ),
                        BarChartRodData(
                          toY: entry.value.approved.toDouble(),
                          color: Colors.green,
                        ),
                        BarChartRodData(
                          toY: entry.value.pending.toDouble(),
                          color: Colors.orange,
                        ),
                        BarChartRodData(
                          toY: entry.value.rejected.toDouble(),
                          color: Colors.red,
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < breakdown.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                breakdown[value.toInt()].name,
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOrganizers(BuildContext context, WidgetRef ref) {
    final organizers = ref.watch(topOrganizersProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Organizers by Activity', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: organizers.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final org = organizers[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(org.organizationName),
                  subtitle: Row(
                    children: [
                      Icon(Icons.check, size: 14, color: Colors.green),
                      Text('${org.approvals}'),
                      SizedBox(width: 12),
                      Icon(Icons.close, size: 14, color: Colors.red),
                      Text('${org.rejections}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text('${org.totalActions} actions'),
                    backgroundColor: Colors.blue.shade50,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityLogProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activity Log', style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    FilterChip(
                      label: Text('All'),
                      selected: ref.watch(activityFilterProvider) == null,
                      onSelected: (_) => ref.read(activityFilterProvider.notifier).state = null,
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Approved'),
                      selected: ref.watch(activityFilterProvider) == 'approved',
                      onSelected: (_) => ref.read(activityFilterProvider.notifier).state = 'approved',
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Rejected'),
                      selected: ref.watch(activityFilterProvider) == 'rejected',
                      onSelected: (_) => ref.read(activityFilterProvider.notifier).state = 'rejected',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _ActivityLogTile(activity: activity);
              },
            ),
            SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => ref.read(activityLogProvider.notifier).loadMore(),
                child: Text('Load More'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActivityLogTile extends StatelessWidget {
  final ActivityLogEntry activity;

  @override
  Widget build(BuildContext context) {
    final iconAndColor = switch (activity.action) {
      'submitted' => (Icons.person_add, Colors.blue),
      'approved' => (Icons.check_circle, Colors.green),
      'rejected' => (Icons.cancel, Colors.red),
      'cancelled' => (Icons.block, Colors.orange),
      default => (Icons.info, Colors.grey),
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: iconAndColor.$2.withOpacity(0.1),
        child: Icon(iconAndColor.$1, color: iconAndColor.$2, size: 20),
      ),
      title: Text(activity.title),
      subtitle: Text(activity.subtitle, style: TextStyle(fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxis alignment: CrossAxisAlignment.end,
        children: [
          Text(activity.formattedTime, style: TextStyle(fontSize: 11, color: Colors.grey)),
          if (activity.actorType == 'admin')
            Chip(
              label: Text('Admin', style: TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
    );
  }
}
```

### 8.7 Admin Provider

```dart
// sportx_app/lib/features/admin/presentation/providers/admin_analytics_provider.dart

class AdminAnalyticsProvider extends AsyncNotifier<AnalyticsState> {
  @override
  Future<AnalyticsState> build() async {
    final stats = await _fetchStats();
    final chartData = await _fetchChartData('30_days');
    final breakdown = await _fetchSportBreakdown('30_days');
    final organizers = await _fetchTopOrganizers('30_days');
    final activities = await _fetchActivityLog();

    return AnalyticsState(
      stats: stats,
      chartData: chartData,
      sportBreakdown: breakdown,
      topOrganizers: organizers,
      activityLog: activities,
    );
  }

  Future<AnalyticsStats> _fetchStats() async {
    final response = await dio.get('/admin/registrations/analytics/dashboard');
    return AnalyticsStats.fromJson(response.data);
  }

  Future<ChartData> _fetchChartData(String period) async {
    final response = await dio.get('/admin/registrations/analytics/chart', queryParameters: {'period': period});
    return ChartData.fromJson(response.data);
  }

  Future<List<SportBreakdown>> _fetchSportBreakdown(String period) async {
    final response = await dio.get('/admin/registrations/analytics/sport-breakdown', queryParameters: {'period': period});
    return (response.data as List).map((e) => SportBreakdown.fromJson(e)).toList();
  }

  Future<List<TopOrganizer>> _fetchTopOrganizers(String period) async {
    final response = await dio.get('/admin/registrations/analytics/top-organizers', queryParameters: {'period': period});
    return (response.data as List).map((e) => TopOrganizer.fromJson(e)).toList();
  }

  Future<PaginatedResult<ActivityLogEntry>> _fetchActivityLog({String? filter}) async {
    final params = <String, dynamic>{};
    if (filter != null) params['action'] = filter;
    final response = await dio.get('/admin/registrations/activity-log', queryParameters: params);
    return PaginatedResult.fromJson(response.data, ActivityLogEntry.fromJson);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final moreActivities = await _fetchActivityLog();
    state = AsyncValue.data(currentState.copyWith(
      activityLog: currentState.activityLog.copyWith(
        data: [...currentState.activityLog.data, ...moreActivities.data],
        hasMore: moreActivities.hasMore,
      ),
    ));
  }

  Future<void> exportLog() async {
    final response = await dio.get(
      '/admin/registrations/activity-log/export',
      options: Options(responseType: ResponseType.bytes),
    );
    // Save to file using file_picker/path_provider
    final file = File('${await getDownloadsDirectory()}/registration_activities.xlsx');
    await file.writeAsBytes(response.data);
  }

  Future<void> adminApprove(String type, String registrationId) async {
    await dio.patch('/admin/registrations/${type}s/$registrationId/admin-approve');
    ref.invalidateSelf();
  }

  Future<void> adminReject(String type, String registrationId, String reason) async {
    await dio.patch('/admin/registrations/${type}s/$registrationId/admin-reject', data: {
      'rejection_reason': reason,
    });
    ref.invalidateSelf();
  }
}

class AnalyticsState {
  final AnalyticsStats stats;
  final ChartData chartData;
  final List<SportBreakdown> sportBreakdown;
  final List<TopOrganizer> topOrganizers;
  final PaginatedResult<ActivityLogEntry> activityLog;

  AnalyticsState({
    required this.stats,
    required this.chartData,
    required this.sportBreakdown,
    required this.topOrganizers,
    required this.activityLog,
  });

  AnalyticsState copyWith({
    AnalyticsStats? stats,
    ChartData? chartData,
    List<SportBreakdown>? sportBreakdown,
    List<TopOrganizer>? topOrganizers,
    PaginatedResult<ActivityLogEntry>? activityLog,
  }) => AnalyticsState(
    stats: stats ?? this.stats,
    chartData: chartData ?? this.chartData,
    sportBreakdown: sportBreakdown ?? this.sportBreakdown,
    topOrganizers: topOrganizers ?? this.topOrganizers,
    activityLog: activityLog ?? this.activityLog,
  );
}

class AnalyticsStats {
  final int totalRegistrations;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final double approvalRate;
  final String avgResponseTime;

  AnalyticsStats.fromJson(Json json)
      : totalRegistrations = json['total_registrations'],
        pendingCount = json['pending_count'],
        approvedCount = json['approved_count'],
        rejectedCount = json['rejected_count'],
        approvalRate = (json['approval_rate'] as num).toDouble(),
        avgResponseTime = json['avg_response_time'];
}

class ChartData {
  final List<String> labels;
  final List<int> registrations;
  final List<int> approved;
  final List<int> rejected;

  ChartData.fromJson(Json json)
      : labels = List<String>.from(json['labels']),
        registrations = List<int>.from(json['datasets'][0]['data']),
        approved = List<int>.from(json['datasets'][1]['data']),
        rejected = List<int>.from(json['datasets'][2]['data']);

  List<FlSpot> get registrationsAsSpots => registrations.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
  List<FlSpot> get approvedAsSpots => approved.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
  List<FlSpot> get rejectedAsSpots => rejected.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
}
```

### 8.8 Admin Intervention Features

```php
// sportx-api/app/Http/Controllers/RegistrationController.php

// Add to existing controller:

public function adminApproveTournament(Request $request, TournamentRegistration $registration): JsonResponse
{
    $this->authorize('adminApprove', $registration);

    $registration->update([
        'approval_status' => 'approved',
        'status' => 'confirmed',
        'reviewed_by' => $request->user()->id,
        'reviewed_at' => now(),
        'admin_override' => true, // New field to track admin interventions
    ]);

    // Log admin action
    app(RegistrationActivityService::class)->logApproval($registration, $request->user());

    Notification::send(
        $registration->athlete->user,
        new RegistrationApprovedNotification($registration, 'tournament')
    );

    return response()->json([
        'message' => 'Admin approved registration',
        'registration' => new TournamentRegistrationResource($registration),
    ]);
}

public function adminRejectTournament(Request $request, TournamentRegistration $registration): JsonResponse
{
    $this->authorize('adminApprove', $registration);

    $validated = $request->validate([
        'rejection_reason' => 'required|string|max:500',
    ]);

    $registration->update([
        'approval_status' => 'rejected',
        'status' => 'cancelled',
        'rejection_reason' => $validated['rejection_reason'],
        'reviewed_by' => $request->user()->id,
        'reviewed_at' => now(),
        'admin_override' => true,
    ]);

    app(RegistrationActivityService::class)->logRejection($registration, $request->user(), $validated['rejection_reason']);

    Notification::send(
        $registration->athlete->user,
        new RegistrationRejectedNotification($registration, 'tournament', $validated['rejection_reason'])
    );

    return response()->json([
        'message' => 'Admin rejected registration',
        'registration' => new TournamentRegistrationResource($registration),
    ]);
}
```

### 8.9 Role-Based View in Admin Panel

| Role | Can View | Can Approve/Reject |
|------|----------|-------------------|
| Admin | All registrations, all organizers | Can override any registration |
| Organizer | Only their tournament/trial registrations | Can approve/reject only their registrations |
| Athlete | Only their own registrations | Cannot approve/reject |
| Academy | Only their trial registrations | Can approve/reject their trials |

### 8.10 Integration with Existing Admin Moderation

```php
// AdminModerationController.php - extend to include registrations

public function registrationStats(): JsonResponse
{
    return response()->json([
        'disputed_registrations' => $this->getDisputedCount(),
        'recent_disputes' => $this->getRecentDisputes(),
        'flagged_organizers' => $this->getFlaggedOrganizers(),
    ]);
}

private function getDisputedCount(): int
{
    return TournamentRegistration::where('dispute_status', 'open')->count()
         + TrialRegistration::where('dispute_status', 'open')->count();
}
```

---

## 9. Implementation Checklist

### Backend
- [ ] Create migration for `approval_status`, `rejection_reason`, `reviewed_by`, `reviewed_at` on tournament_registrations
- [ ] Create migration for `approval_status`, `rejection_reason`, `reviewed_by`, `reviewed_at` on trial_registrations
- [ ] Update TournamentRegistration model with new fields and relationships
- [ ] Update TrialRegistration model with new fields and relationships
- [ ] Create TournamentRegistrationPolicy with approve/viewOrganizer rules
- [ ] Update RegistrationController:
  - [ ] Modify `storeTournament()` to set `approval_status = 'pending'`
  - [ ] Add `pendingTournamentRequests()` method
  - [ ] Rename/enhance `verifyTrial()` to `approveTrial()`
  - [ ] Update `rejectTrial()` to accept reason
  - [ ] Add approve/reject for tournament registrations
- [ ] Create notification classes for approval workflow
- [ ] Add new API routes
- [ ] Update API resource classes to include approval_status
- [ ] Update database seeders for testing

### Coach Enrollment Backend
- [ ] Create `coaching_enrollments` migration with plan_type, fees_amount, approval_status
- [ ] Create CoachingEnrollment model with all fields and relationships
- [ ] Create CoachingEnrollmentPolicy with approve rules
- [ ] Create CoachingEnrollmentController with store, approve, reject, coachEnrollments, myEnrollments
- [ ] Create notification classes for coaching enrollment workflow
- [ ] Add coach enrollment API routes
- [ ] Add admin override endpoints for coaching enrollments

### Admin Analytics Backend
- [ ] Create `registration_activity_logs` migration
- [ ] Create RegistrationActivityLog model
- [ ] Create RegistrationActivityService
- [ ] Create RegistrationAnalyticsController
- [ ] Add analytics API routes
- [ ] Add admin override endpoints
- [ ] Create Excel export for activity log
- [ ] Add coaching enrollment analytics to dashboard

### Flutter App
- [ ] Update TournamentRegistration/TrialRegistration models with ApprovalStatus
- [ ] Update TournamentProvider to handle approval workflow
- [ ] Update RegistrationController storeTournament to handle approval
- [ ] Update MyRegistrationsScreen to show approval status
- [ ] Update TournamentDetailScreen to show pending status after registration
- [ ] Create Organizer Registration Approval screen
- [ ] Add pending count badge to organizer dashboard
- [ ] Update notification handling for approval/rejection
- [ ] Remove any existing payment/Stripe UI code

### Flutter Coach Enrollment
- [ ] Create CoachingEnrollment model
- [ ] Add enrollment button and pricing section to CoachProfileDetailScreen
- [ ] Create plan selection bottom sheet
- [ ] Create coach enrollment management screen
- [ ] Create athlete my enrollments screen
- [ ] Add coach enrollment providers
- [ ] Add pending enrollment badge to coach dashboard

### Laravel Admin Panel (Blade Views)
- [ ] Create `resources/views/admin/registrations/analytics.blade.php`
- [ ] Add stats cards for registrations and coaching enrollments
- [ ] Add Chart.js trend charts for registrations over time
- [ ] Add sport breakdown chart
- [ ] Add top organizers leaderboard
- [ ] Add activity log table with AJAX pagination and filters
- [ ] Add export functionality button
- [ ] Add admin override actions (approve/reject buttons in activity log)

### Testing
- [ ] Test athlete registration flow (submit → pending → notification)
- [ ] Test organizer approval flow (view pending → approve → athlete notified)
- [ ] Test organizer rejection flow (view pending → reject with reason → athlete notified)
- [ ] Test status display in My Registrations
- [ ] Test role-based access (athlete cannot approve, organizer cannot approve other's)
- [ ] Test admin analytics dashboard loads (web admin)
- [ ] Test admin can override approve/reject via web admin
- [ ] Test activity log records all actions
- [ ] Test athlete enrollment request flow (submit → coach reviews → notification)
- [ ] Test coach approval flow (view pending → approve → set start date → athlete notified)
- [ ] Test coach rejection flow (view pending → reject with reason → athlete notified)

---

## 10. Summary

| Aspect | Before | After |
|--------|--------|-------|
| Tournament Registration | Pay entry fee → instant confirm | Submit request → Organizer reviews → Approved/Rejected |
| Trial Registration | Verification-based | Approval-based with notification |
| Coach Enrollment | No enrollment system | Athlete requests → Coach approves → Active enrollment |
| Entry Fee Display | Required for payment | Shown as informational only |
| Confirmation | Payment confirmation | Approval notification |
| Cancellation | Via payment refund | Via organizer/coach/athlete request |
| Status Tracking | payment_status | approval_status + status |

### Entities Covered by Approval System

| Entity | Requester | Approver | Notes |
|--------|-----------|----------|-------|
| Tournament Registration | Athlete | Organizer | Category-based capacity |
| Trial Registration | Athlete | Organizer/Academy | Document verification |
| Coach Enrollment | Athlete | Coach | Plan types: session/monthly/quarterly |
| Academy Subscription | Athlete | Academy | Future expansion |
| Equipment Booking | Athlete | Venue Owner | Future expansion |

### Benefits
1. **No payment integration required** - works immediately
2. **Human review** - organizers/coaches can vet participants
3. **Fairness** - can implement waitlists when capacity reached
4. **Transparency** - rejection includes reason
5. **Scalable** - same system for tournaments, trials, coaching
6. **Admin visibility** - full analytics and activity tracking
7. **Audit trail** - all actions logged for compliance
