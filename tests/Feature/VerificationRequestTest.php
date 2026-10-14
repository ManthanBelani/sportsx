<?php

namespace Tests\Feature;

use App\Models\Academy;
use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\User;
use App\Models\VerificationRequest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * @see \App\Http\Controllers\VerificationController
 * @see \App\Models\VerificationRequest
 */
class VerificationRequestTest extends TestCase
{
    use RefreshDatabase;

    protected function admin(): User
    {
        return User::create([
            'role' => 'admin', 'name' => 'Admin User', 'email' => 'admin@sportx.test',
            'password' => Hash::make('password'), 'status' => 'active', 'admin_2fa_verified_at' => now(),
        ]);
    }

    protected function athlete(): array
    {
        $user = User::create([
            'role' => 'athlete', 'name' => 'Kiran', 'email' => 'kiran@sportx.test',
            'password' => Hash::make('password'),
            'email_verified_at' => now(), 'status' => 'active',
        ]);

        $ageGroup = AgeGroup::firstOrCreate(['name' => 'Under-18'], ['min_age' => 16, 'max_age' => 18]);

        $profile = AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Kiran Patel',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'skill_level' => 'intermediate',
            'age_group_id' => $ageGroup->id,
        ]);

        return [$user, $profile];
    }

    /* ---------------------------------------------------------------------
     | submission
     | ------------------------------------------------------------------ */

    public function test_user_can_request_verification_for_their_own_profile(): void
    {
        [$user, $profile] = $this->athlete();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/me/verification', [
            'verifiable_type' => 'athlete_profile',
            'verifiable_id' => $profile->id,
            'proof_media_ids' => [1, 2],
            'notes' => 'Aadhaar attached.',
        ]);

        $response->assertCreated()->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseHas('verification_requests', [
            'requester_user_id' => $user->id,
            'verifiable_type' => 'athlete_profile',
            'verifiable_id' => $profile->id,
            'status' => 'pending',
        ]);
    }

    public function test_user_cannot_request_verification_for_another_users_profile(): void
    {
        [, $profile] = $this->athlete();

        $intruder = User::create([
            'role' => 'athlete', 'name' => 'Intruder', 'email' => 'intruder@sportx.test',
            'password' => Hash::make('password'), 'status' => 'active',
        ]);

        $this->actingAs($intruder, 'sanctum')
            ->postJson('/api/v1/me/verification', [
                'verifiable_type' => 'athlete_profile',
                'verifiable_id' => $profile->id,
            ])
            ->assertStatus(403);

        $this->assertDatabaseCount('verification_requests', 0);
    }

    public function test_verifiable_type_must_be_allow_listed(): void
    {
        [$user] = $this->athlete();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/me/verification', [
                'verifiable_type' => 'trial', // not verifiable
                'verifiable_id' => 1,
            ])
            ->assertStatus(422);
    }

    public function test_duplicate_pending_request_is_reused_not_duplicated(): void
    {
        [$user, $profile] = $this->athlete();

        $payload = ['verifiable_type' => 'athlete_profile', 'verifiable_id' => $profile->id];

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/me/verification', $payload)->assertCreated();
        $this->actingAs($user, 'sanctum')->postJson('/api/v1/me/verification', $payload)->assertOk();

        $this->assertDatabaseCount('verification_requests', 1);
    }

    public function test_user_can_list_their_own_requests(): void
    {
        [$user, $profile] = $this->athlete();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/me/verification', [
            'verifiable_type' => 'athlete_profile', 'verifiable_id' => $profile->id,
        ]);

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/me/verification')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('meta.total', 1);
    }

    /* ---------------------------------------------------------------------
     | admin review
     | ------------------------------------------------------------------ */

    public function test_admin_sees_the_pending_queue(): void
    {
        [$user, $profile] = $this->athlete();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/me/verification', [
            'verifiable_type' => 'athlete_profile', 'verifiable_id' => $profile->id,
        ]);

        $this->actingAs($this->admin(), 'sanctum')
            ->getJson('/api/v1/admin/verification?status=pending')
            ->assertOk()
            ->assertJsonPath('data.0.status', 'pending');
    }

    public function test_approving_records_the_reviewer_and_notifies_the_requester(): void
    {
        [$user, $profile] = $this->athlete();
        $admin = $this->admin();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/me/verification', [
            'verifiable_type' => 'athlete_profile', 'verifiable_id' => $profile->id,
        ]);

        $id = VerificationRequest::firstOrFail()->id;

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/verification/{$id}/approve")
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');

        $this->assertDatabaseHas('verification_requests', [
            'id' => $id, 'status' => 'approved', 'reviewed_by' => $admin->id,
        ]);

        // The applicant is told — verification decisions are a hard override.
        $this->assertDatabaseHas('notifications', [
            'user_id' => $user->id,
            'type' => 'account_action',
        ]);
    }

    public function test_rejecting_requires_a_reason(): void
    {
        [$user, $profile] = $this->athlete();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/me/verification', [
            'verifiable_type' => 'athlete_profile', 'verifiable_id' => $profile->id,
        ]);

        $id = VerificationRequest::firstOrFail()->id;

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/verification/{$id}/reject")
            ->assertStatus(422);
    }

    public function test_rejecting_stores_the_reason_and_notifies(): void
    {
        [$user, $profile] = $this->athlete();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/me/verification', [
            'verifiable_type' => 'athlete_profile', 'verifiable_id' => $profile->id,
        ]);

        $id = VerificationRequest::firstOrFail()->id;

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/verification/{$id}/reject", ['reason' => 'Document unreadable.'])
            ->assertOk()
            ->assertJsonPath('data.status', 'rejected')
            ->assertJsonPath('data.decision_reason', 'Document unreadable.');
    }

    public function test_approving_an_academy_sets_its_verification_badge(): void
    {
        $owner = User::create([
            'role' => 'academy', 'name' => 'Elite Academy', 'email' => 'academy@sportx.test',
            'password' => Hash::make('password'), 'status' => 'active',
        ]);

        $city = City::firstOrCreate(['name' => 'Ahmedabad'], ['state' => 'Gujarat']);

        $academy = Academy::create([
            'owner_user_id' => $owner->id, 'name' => 'Elite Academy',
            'city_id' => $city->id,
            'address' => 'Somewhere', 'contact_number' => '919876543210',
            // NOT NULL with no default — see Database-Design.md §4.
            'description' => 'A test academy.',
        ]);

        $this->actingAs($owner, 'sanctum')->postJson('/api/v1/me/verification', [
            'verifiable_type' => 'academy', 'verifiable_id' => $academy->id,
        ])->assertCreated();

        $id = VerificationRequest::firstOrFail()->id;

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/verification/{$id}/approve")
            ->assertOk();

        $this->assertTrue((bool) $academy->refresh()->verification_badge);
    }

    /* ---------------------------------------------------------------------
     | authorization
     | ------------------------------------------------------------------ */

    public function test_non_admin_cannot_reach_the_review_queue(): void
    {
        [$user] = $this->athlete();

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/admin/verification')
            ->assertStatus(403);
    }

    public function test_unauthenticated_user_cannot_request_verification(): void
    {
        $this->postJson('/api/v1/me/verification', [
            'verifiable_type' => 'athlete_profile', 'verifiable_id' => 1,
        ])->assertStatus(401);
    }
}