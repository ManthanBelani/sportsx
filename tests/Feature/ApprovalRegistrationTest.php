<?php

namespace Tests\Feature;

use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\CoachProfile;
use App\Models\OrganizerProfile;
use App\Models\Sport;
use App\Models\Tournament;
use App\Models\Trial;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

/**
 * Approval-based registration system (docs/Approval-Based-Registration-System.md).
 *
 * Covers: tournament approval flow, trial approval flow, coaching enrollment
 * flow, role-based access, admin overrides, activity log + analytics.
 */
class ApprovalRegistrationTest extends TestCase
{
    use RefreshDatabase;

    private function makeSport(): Sport
    {
        return Sport::create(['name' => 'Cricket '.uniqid(), 'sort_order' => 1]);
    }

    private function makeAthlete(Sport $sport): User
    {
        $user = User::factory()->create(['role' => 'athlete']);
        AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Test Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'sport_id' => $sport->id,
            'skill_level' => 'intermediate',
        ]);

        return $user->fresh();
    }

    private function makeOrganizerWithTournament(Sport $sport): array
    {
        $user = User::factory()->create(['role' => 'organizer']);
        $profile = OrganizerProfile::create([
            'user_id' => $user->id,
            'organization_name' => 'Test Org',
            'org_type' => 'club',
        ]);
        $ageGroup = AgeGroup::create(['name' => 'U-16 '.uniqid(), 'min_age' => 14, 'max_age' => 16]);

        $tournament = Tournament::create([
            'organizer_id' => $profile->id,
            'sport_id' => $sport->id,
            'name' => 'Test Cup',
            'start_date' => now()->addMonth()->toDateString(),
            'end_date' => now()->addMonth()->addDays(5)->toDateString(),
            'venue' => 'Test Ground',
            'status' => 'published',
        ]);
        $category = $tournament->categories()->create([
            'age_group_id' => $ageGroup->id,
            'name' => 'U-16',
            'capacity' => 16,
        ]);

        return [$user->fresh(), $tournament, $category];
    }

    private function makeTrial(User $provider): Trial
    {
        return Trial::create([
            'posted_by_user_id' => $provider->id,
            'name' => 'Test Trial',
            'sport_id' => $this->makeSport()->id,
            'event_datetime' => now()->addMonth(),
            'venue' => 'Test Venue',
            'contact_number' => '+919999999999',
            'registration_deadline' => now()->addWeek(),
            'status' => 'published',
        ]);
    }

    // ── Tournament approval flow ──────────────────────────────────────────

    public function test_tournament_registration_submits_as_pending(): void
    {
        $sport = $this->makeSport();
        [$organizer, $tournament, $category] = $this->makeOrganizerWithTournament($sport);
        $athlete = $this->makeAthlete($sport);
        Sanctum::actingAs($athlete);

        $resp = $this->postJson("/api/v1/tournaments/{$tournament->id}/register", [
            'category_id' => $category->id,
            'participation_type' => 'individual',
        ]);

        $resp->assertStatus(201);
        $resp->assertJsonPath('data.approval_status', 'pending');
        $this->assertDatabaseHas('tournament_registrations', [
            'tournament_id' => $tournament->id,
            'approval_status' => 'pending',
            'status' => 'pending',
        ]);
        $this->assertDatabaseHas('registration_activity_logs', [
            'registration_type' => 'tournament',
            'action' => 'submitted',
        ]);
        // Organizer gets a notification
        $this->assertDatabaseHas('notifications', [
            'user_id' => $organizer->id,
            'type' => 'status_update',
        ]);
    }

    public function test_organizer_can_approve_tournament_registration(): void
    {
        $sport = $this->makeSport();
        [$organizer, $tournament, $category] = $this->makeOrganizerWithTournament($sport);
        $athlete = $this->makeAthlete($sport);

        Sanctum::actingAs($athlete);
        $resp = $this->postJson("/api/v1/tournaments/{$tournament->id}/register", [
            'category_id' => $category->id,
            'participation_type' => 'individual',
        ]);
        $registrationId = $resp->json('data.id');

        Sanctum::actingAs($organizer);
        $approve = $this->patchJson("/api/v1/registrations/tournaments/{$registrationId}/approve");
        $approve->assertStatus(200);
        $approve->assertJsonPath('data.approval_status', 'approved');

        $this->assertDatabaseHas('tournament_registrations', [
            'id' => $registrationId,
            'approval_status' => 'approved',
            'status' => 'confirmed',
        ]);
        $this->assertDatabaseHas('registration_activity_logs', ['action' => 'approved']);
        $this->assertDatabaseHas('notifications', [
            'user_id' => $athlete->id,
            'type' => 'status_update',
        ]);
    }

    public function test_organizer_reject_requires_reason(): void
    {
        $sport = $this->makeSport();
        [$organizer, $tournament, $category] = $this->makeOrganizerWithTournament($sport);
        $athlete = $this->makeAthlete($sport);

        Sanctum::actingAs($athlete);
        $resp = $this->postJson("/api/v1/tournaments/{$tournament->id}/register", [
            'category_id' => $category->id,
            'participation_type' => 'individual',
        ]);
        $registrationId = $resp->json('data.id');

        Sanctum::actingAs($organizer);
        $this->patchJson("/api/v1/registrations/tournaments/{$registrationId}/reject", [])
            ->assertStatus(422);

        $this->patchJson("/api/v1/registrations/tournaments/{$registrationId}/reject", [
            'rejection_reason' => 'Category is full',
        ])->assertStatus(200);

        $this->assertDatabaseHas('tournament_registrations', [
            'id' => $registrationId,
            'approval_status' => 'rejected',
            'status' => 'cancelled',
            'rejection_reason' => 'Category is full',
        ]);
    }

    public function test_athlete_cannot_approve_and_organizer_cannot_approve_others(): void
    {
        $sport = $this->makeSport();
        [$organizer, $tournament, $category] = $this->makeOrganizerWithTournament($sport);
        $athlete = $this->makeAthlete($sport);

        Sanctum::actingAs($athlete);
        $resp = $this->postJson("/api/v1/tournaments/{$tournament->id}/register", [
            'category_id' => $category->id,
            'participation_type' => 'individual',
        ]);
        $registrationId = $resp->json('data.id');

        // Athlete tries to approve own registration
        $this->patchJson("/api/v1/registrations/tournaments/{$registrationId}/approve")
            ->assertStatus(403);

        // Another organizer tries to approve
        $other = User::factory()->create(['role' => 'organizer']);
        OrganizerProfile::create(['user_id' => $other->id, 'organization_name' => 'Other']);
        Sanctum::actingAs($other->fresh());
        $this->patchJson("/api/v1/registrations/tournaments/{$registrationId}/approve")
            ->assertStatus(403);
    }

    public function test_pending_requests_and_my_registrations_endpoints(): void
    {
        $sport = $this->makeSport();
        [$organizer, $tournament, $category] = $this->makeOrganizerWithTournament($sport);
        $athlete = $this->makeAthlete($sport);

        Sanctum::actingAs($athlete);
        $this->postJson("/api/v1/tournaments/{$tournament->id}/register", [
            'category_id' => $category->id,
            'participation_type' => 'individual',
        ])->assertStatus(201);

        Sanctum::actingAs($organizer);
        $this->getJson("/api/v1/tournaments/{$tournament->id}/pending-requests")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data');

        Sanctum::actingAs($athlete);
        $this->getJson('/api/v1/me/registrations/tournaments')
            ->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_admin_can_override_tournament_registration(): void
    {
        $sport = $this->makeSport();
        [$organizer, $tournament, $category] = $this->makeOrganizerWithTournament($sport);
        $athlete = $this->makeAthlete($sport);
        $admin = User::factory()->create(['role' => 'admin']);

        Sanctum::actingAs($athlete);
        $resp = $this->postJson("/api/v1/tournaments/{$tournament->id}/register", [
            'category_id' => $category->id,
            'participation_type' => 'individual',
        ]);
        $registrationId = $resp->json('data.id');

        Sanctum::actingAs($admin);
        $this->patchJson("/api/v1/admin/registrations/tournaments/{$registrationId}/admin-approve")
            ->assertStatus(200);
        $this->assertDatabaseHas('tournament_registrations', [
            'id' => $registrationId,
            'approval_status' => 'approved',
            'admin_override' => 1,
        ]);
    }

    // ── Trial approval flow ───────────────────────────────────────────────

    public function test_trial_approve_and_reject_flow(): void
    {
        $provider = User::factory()->create(['role' => 'organizer']);
        $trial = $this->makeTrial($provider);
        $athlete = $this->makeAthlete($this->makeSport());

        Sanctum::actingAs($athlete);
        $resp = $this->postJson("/api/v1/trials/{$trial->id}/register", [
            'playing_role' => 'Bowler',
        ]);
        $resp->assertStatus(201);
        $resp->assertJsonPath('data.approval_status', 'pending');

        $registrationId = \App\Models\TrialRegistration::latest('id')->first()->id;

        Sanctum::actingAs($provider);
        $this->patchJson("/api/v1/registrations/trials/{$registrationId}/approve")
            ->assertStatus(200)
            ->assertJsonPath('data.approval_status', 'approved');

        $this->assertDatabaseHas('trial_registrations', [
            'id' => $registrationId,
            'verification_status' => 'verified',
            'approval_status' => 'approved',
        ]);

        // Second athlete → reject path
        $athlete2 = $this->makeAthlete($this->makeSport());
        Sanctum::actingAs($athlete2);
        $this->postJson("/api/v1/trials/{$trial->id}/register", [])->assertStatus(201);
        $reg2 = \App\Models\TrialRegistration::latest('id')->first()->id;

        Sanctum::actingAs($provider);
        $this->patchJson("/api/v1/registrations/trials/{$reg2}/reject", [
            'rejection_reason' => 'No vacancies',
        ])->assertStatus(200);
        $this->assertDatabaseHas('trial_registrations', [
            'id' => $reg2,
            'approval_status' => 'rejected',
            'rejection_reason' => 'No vacancies',
        ]);
    }

    // ── Coaching enrollment flow ──────────────────────────────────────────

    private function makeCoach(): array
    {
        $sport = $this->makeSport();
        $user = User::factory()->create(['role' => 'coach']);
        $coach = CoachProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Coach Test',
            'sport_id' => $sport->id,
            'contact_number' => '+911234567890',
            'experience' => '10 years',
            'personal_coaching' => true,
            'fee_per_session' => 500,
            'fee_monthly' => 5000,
            'fee_quarterly' => 12000,
            'listing_status' => 'published',
        ]);

        return [$user->fresh(), $coach];
    }

    public function test_coaching_enrollment_request_approve_reject(): void
    {
        [$coachUser, $coach] = $this->makeCoach();
        $athlete = $this->makeAthlete($this->makeSport());

        Sanctum::actingAs($athlete);
        $resp = $this->postJson("/api/v1/coaches/{$coach->id}/enroll", [
            'plan_type' => 'monthly',
            'notes' => 'Want to improve batting',
        ]);
        $resp->assertStatus(201);
        $resp->assertJsonPath('data.approval_status', 'pending');
        $enrollmentId = $resp->json('data.id');

        $this->assertDatabaseHas('coaching_enrollments', [
            'id' => $enrollmentId,
            'plan_type' => 'monthly',
            'approval_status' => 'pending',
        ]);

        // Duplicate request blocked
        $this->postJson("/api/v1/coaches/{$coach->id}/enroll", [
            'plan_type' => 'monthly',
        ])->assertStatus(409);

        // Coach approves
        Sanctum::actingAs($coachUser);
        $this->patchJson("/api/v1/coaching-enrollments/{$enrollmentId}/approve", [
            'start_date' => now()->toDateString(),
        ])->assertStatus(200);
        $this->assertDatabaseHas('coaching_enrollments', [
            'id' => $enrollmentId,
            'approval_status' => 'approved',
            'status' => 'active',
        ]);

        // Athlete can list own enrollments
        Sanctum::actingAs($athlete);
        $this->getJson('/api/v1/me/coaching-enrollments')
            ->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_coach_without_personal_coaching_rejects_enrollment(): void
    {
        $sport = $this->makeSport();
        $user = User::factory()->create(['role' => 'coach']);
        $coach = CoachProfile::create([
            'user_id' => $user->id,
            'full_name' => 'No Coaching',
            'sport_id' => $sport->id,
            'contact_number' => '+911234567890',
            'experience' => '5 years',
            'personal_coaching' => false,
            'listing_status' => 'published',
        ]);
        $athlete = $this->makeAthlete($sport);

        Sanctum::actingAs($athlete);
        $this->postJson("/api/v1/coaches/{$coach->id}/enroll", [
            'plan_type' => 'session',
        ])->assertStatus(400);
    }

    // ── Admin analytics ───────────────────────────────────────────────────

    public function test_admin_analytics_dashboard_and_activity_log(): void
    {
        $sport = $this->makeSport();
        [$organizer, $tournament, $category] = $this->makeOrganizerWithTournament($sport);
        $athlete = $this->makeAthlete($sport);
        $admin = User::factory()->create(['role' => 'admin']);

        Sanctum::actingAs($athlete);
        $this->postJson("/api/v1/tournaments/{$tournament->id}/register", [
            'category_id' => $category->id,
            'participation_type' => 'individual',
        ])->assertStatus(201);

        Sanctum::actingAs($admin);

        $this->getJson('/api/v1/admin/registrations/analytics/dashboard')
            ->assertStatus(200)
            ->assertJsonPath('pending_count', 1);

        $this->getJson('/api/v1/admin/registrations/activity-log')
            ->assertStatus(200);
    }
}
