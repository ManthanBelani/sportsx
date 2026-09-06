<?php

namespace Tests\Feature;

use App\Models\TalentScoutProfile;
use App\Models\ScoutShortlist;
use App\Models\ScoutConnection;
use App\Models\AthleteProfile;
use App\Models\User;
use App\Models\Sport;
use App\Models\City;
use App\Models\AgeGroup;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

class TalentScoutTest extends TestCase
{
    use RefreshDatabase;

    protected User $scoutUser;
    protected TalentScoutProfile $scoutProfile;
    protected User $athleteUser;
    protected AthleteProfile $athleteProfile;

    protected function setUp(): void
    {
        parent::setUp();

        // Create required reference data
        Sport::create(['id' => 1, 'name' => 'Cricket']);
        Sport::create(['id' => 2, 'name' => 'Football']);
        City::create(['id' => 1, 'name' => 'Mumbai']);
        AgeGroup::create(['id' => 1, 'name' => 'Under 18']);

        // Create scout user and profile
        $this->scoutUser = User::create([
            'name' => 'Test Scout',
            'email' => 'scout@test.com',
            'password' => 'password',
            'role' => 'talent_scout',
            'email_verified_at' => now(),
            'status' => 'active',
        ]);

        $this->scoutProfile = TalentScoutProfile::create([
            'user_id' => $this->scoutUser->id,
            'organization' => 'Test Agency',
            'affiliation' => 'Test Association',
            'sports_specialization' => [1, 2],
            'experience_years' => 5,
            'city_id' => 1,
            'bio' => 'Test bio',
        ]);

        // Create athlete user and profile
        $this->athleteUser = User::create([
            'name' => 'Test Athlete',
            'email' => 'athlete@test.com',
            'password' => 'password',
            'role' => 'athlete',
            'email_verified_at' => now(),
            'status' => 'active',
        ]);

        $this->athleteProfile = AthleteProfile::create([
            'user_id' => $this->athleteUser->id,
            'full_name' => 'Test Athlete',
            'date_of_birth' => '2000-01-01',
            'gender' => 'male',
            'age_group_id' => 1,
            'skill_level' => 'advanced',
            'city_id' => 1,
        ]);
    }

    // ==================== Onboarding Tests ====================

    public function test_talent_scout_can_complete_onboarding(): void
    {
        $newUser = User::create([
            'name' => 'New Scout',
            'email' => 'newscout@test.com',
            'password' => 'password',
            'role' => 'talent_scout',
            'email_verified_at' => now(),
            'status' => 'active',
        ]);

        Sanctum::actingAs($newUser);

        $resp = $this->postJson('/api/v1/onboarding/talent-scout', [
            'organization' => 'New Agency',
            'affiliation' => 'New Association',
            'sports_specialization' => [1],
            'experience_years' => 3,
            'city_id' => 1,
            'bio' => 'New scout bio',
        ]);

        $resp->assertStatus(201)
            ->assertJsonStructure(['data' => ['id', 'organization', 'sports_specialization']]);

        $this->assertDatabaseHas('talent_scout_profiles', [
            'user_id' => $newUser->id,
            'organization' => 'New Agency',
        ]);
    }

    public function test_non_talent_scout_cannot_complete_scout_onboarding(): void
    {
        $athlete = User::create([
            'name' => 'Athlete',
            'email' => 'athlete2@test.com',
            'password' => 'password',
            'role' => 'athlete',
            'email_verified_at' => now(),
            'status' => 'active',
        ]);

        Sanctum::actingAs($athlete);

        $resp = $this->postJson('/api/v1/onboarding/talent-scout', [
            'sports_specialization' => [1],
        ]);

        $resp->assertStatus(403);
    }

    public function test_onboarding_requires_sports_specialization(): void
    {
        Sanctum::actingAs($this->scoutUser);

        $resp = $this->postJson('/api/v1/onboarding/talent-scout', [
            'organization' => 'Test',
        ]);

        $resp->assertStatus(422)->assertJsonValidationErrors('sports_specialization');
    }

    // ==================== Profile Tests ====================

    public function test_scout_can_get_own_profile(): void
    {
        Sanctum::actingAs($this->scoutUser);

        $resp = $this->getJson('/api/v1/me/scout-profile');

        $resp->assertStatus(200)
            ->assertJsonPath('data.organization', 'Test Agency')
            ->assertJsonPath('data.sports_specialization', [1, 2]);
    }

    public function test_scout_can_update_profile(): void
    {
        Sanctum::actingAs($this->scoutUser);

        $resp = $this->putJson('/api/v1/me/scout-profile', [
            'organization' => 'Updated Agency',
            'bio' => 'Updated bio',
        ]);

        $resp->assertStatus(200)
            ->assertJsonPath('data.organization', 'Updated Agency')
            ->assertJsonPath('data.bio', 'Updated bio');
    }

    public function test_user_without_scout_profile_gets_404(): void
    {
        $newUser = User::create([
            'name' => 'No Profile',
            'email' => 'noprofile@test.com',
            'password' => 'password',
            'role' => 'talent_scout',
            'email_verified_at' => now(),
            'status' => 'active',
        ]);

        Sanctum::actingAs($newUser);

        $resp = $this->getJson('/api/v1/me/scout-profile');

        $resp->assertStatus(404);
    }

    // ==================== Shortlist Tests ====================

    public function test_scout_can_add_athlete_to_shortlist(): void
    {
        Sanctum::actingAs($this->scoutUser);

        $resp = $this->postJson("/api/v1/me/shortlist/{$this->athleteProfile->id}", [
            'notes' => 'Promising athlete',
        ]);

        $resp->assertStatus(201);

        $this->assertDatabaseHas('scout_shortlists', [
            'talent_scout_profile_id' => $this->scoutProfile->id,
            'athlete_profile_id' => $this->athleteProfile->id,
            'notes' => 'Promising athlete',
        ]);
    }

    public function test_scout_cannot_duplicate_shortlist_entry(): void
    {
        Sanctum::actingAs($this->scoutUser);

        $this->postJson("/api/v1/me/shortlist/{$this->athleteProfile->id}");

        $resp = $this->postJson("/api/v1/me/shortlist/{$this->athleteProfile->id}");

        $resp->assertStatus(409);
    }

    public function test_scout_can_list_shortlist(): void
    {
        ScoutShortlist::create([
            'talent_scout_profile_id' => $this->scoutProfile->id,
            'athlete_profile_id' => $this->athleteProfile->id,
            'notes' => 'Test note',
        ]);

        Sanctum::actingAs($this->scoutUser);

        $resp = $this->getJson('/api/v1/me/shortlist');

        $resp->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_scout_can_remove_from_shortlist(): void
    {
        ScoutShortlist::create([
            'talent_scout_profile_id' => $this->scoutProfile->id,
            'athlete_profile_id' => $this->athleteProfile->id,
        ]);

        Sanctum::actingAs($this->scoutUser);

        $resp = $this->deleteJson("/api/v1/me/shortlist/{$this->athleteProfile->id}");

        $resp->assertStatus(200);

        $this->assertDatabaseMissing('scout_shortlists', [
            'talent_scout_profile_id' => $this->scoutProfile->id,
            'athlete_profile_id' => $this->athleteProfile->id,
        ]);
    }

    public function test_scout_can_update_shortlist_notes(): void
    {
        ScoutShortlist::create([
            'talent_scout_profile_id' => $this->scoutProfile->id,
            'athlete_profile_id' => $this->athleteProfile->id,
            'notes' => 'Old notes',
        ]);

        Sanctum::actingAs($this->scoutUser);

        $resp = $this->patchJson("/api/v1/me/shortlist/{$this->athleteProfile->id}", [
            'notes' => 'New notes',
        ]);

        $resp->assertStatus(200)
            ->assertJsonPath('data.notes', 'New notes');
    }

    // ==================== Connection Tests ====================

    public function test_scout_can_send_connection_request(): void
    {
        Sanctum::actingAs($this->scoutUser);

        $resp = $this->postJson("/api/v1/athletes/{$this->athleteProfile->id}/connect", [
            'message' => 'I would like to connect',
        ]);

        $resp->assertStatus(201);

        $this->assertDatabaseHas('scout_connections', [
            'talent_scout_profile_id' => $this->scoutProfile->id,
            'athlete_profile_id' => $this->athleteProfile->id,
            'status' => 'pending',
            'message' => 'I would like to connect',
        ]);
    }

    public function test_scout_cannot_duplicate_connection_request(): void
    {
        Sanctum::actingAs($this->scoutUser);

        $this->postJson("/api/v1/athletes/{$this->athleteProfile->id}/connect");

        $resp = $this->postJson("/api/v1/athletes/{$this->athleteProfile->id}/connect");

        $resp->assertStatus(409);
    }

    public function test_scout_can_list_connections(): void
    {
        ScoutConnection::create([
            'talent_scout_profile_id' => $this->scoutProfile->id,
            'athlete_profile_id' => $this->athleteProfile->id,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->scoutUser);

        $resp = $this->getJson('/api/v1/me/connections');

        $resp->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_scout_can_cancel_pending_connection(): void
    {
        $connection = ScoutConnection::create([
            'talent_scout_profile_id' => $this->scoutProfile->id,
            'athlete_profile_id' => $this->athleteProfile->id,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->scoutUser);

        $resp = $this->deleteJson("/api/v1/me/connections/{$connection->id}");

        $resp->assertStatus(200);

        $this->assertDatabaseMissing('scout_connections', [
            'id' => $connection->id,
        ]);
    }

    public function test_scout_cannot_cancel_accepted_connection(): void
    {
        $connection = ScoutConnection::create([
            'talent_scout_profile_id' => $this->scoutProfile->id,
            'athlete_profile_id' => $this->athleteProfile->id,
            'status' => 'accepted',
        ]);

        Sanctum::actingAs($this->scoutUser);

        $resp = $this->deleteJson("/api/v1/me/connections/{$connection->id}");

        $resp->assertStatus(404);
    }

    // ==================== Authorization Tests ====================

    public function test_non_scout_cannot_access_scout_routes(): void
    {
        Sanctum::actingAs($this->athleteUser);

        $this->getJson('/api/v1/me/scout-profile')->assertStatus(403);
        $this->putJson('/api/v1/me/scout-profile', [])->assertStatus(403);
        $this->getJson('/api/v1/me/shortlist')->assertStatus(403);
        $this->getJson('/api/v1/me/connections')->assertStatus(403);
    }

    public function test_unauthenticated_user_cannot_access_scout_routes(): void
    {
        $this->getJson('/api/v1/me/scout-profile')->assertStatus(401);
        $this->postJson('/api/v1/me/shortlist/1')->assertStatus(401);
        $this->postJson('/api/v1/athletes/1/connect')->assertStatus(401);
    }

    // ==================== Athlete Discovery Tests ====================

    public function test_scout_can_discover_athletes(): void
    {
        Sanctum::actingAs($this->scoutUser);

        $resp = $this->getJson('/api/v1/athletes');

        $resp->assertStatus(200)
            ->assertJsonStructure(['data']);
    }
}
