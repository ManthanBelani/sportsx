<?php

namespace Tests\Feature;

use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\OrganizerProfile;
use App\Models\Post;
use App\Models\Sport;
use App\Models\Trial;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Organizer tooling that used to be mocked in the app:
 *  - venues (facilities) an organizer runs;
 *  - the organizer team (co-organizers / volunteers);
 *  - role-scoped feeds;
 *  - trial registration counters;
 *  - a consistent error envelope for API errors.
 */
class OrganizerToolsTest extends TestCase
{
    use RefreshDatabase;

    private function organizer(string $email = 'org@test.local'): array
    {
        $user = User::factory()->create(['role' => 'organizer', 'status' => 'active', 'email' => $email]);
        $profile = OrganizerProfile::create([
            'user_id' => $user->id,
            'organization_name' => 'Test Federation',
            'org_type' => 'federation',
        ]);

        return [$user, $profile];
    }

    public function test_organizer_can_manage_their_own_venues(): void
    {
        [$user] = $this->organizer();
        $this->actingAs($user, 'sanctum');

        $create = $this->postJson('/api/v1/me/facilities', [
            'name' => 'Sardar Patel Stadium',
            'type' => 'ground',
            'size' => '100 x 70 m',
            'amenities' => ['Floodlights', 'Changing Room'],
        ]);
        $create->assertCreated();
        $this->assertNotNull($create->json('data.organizer_id'));
        $this->assertNull($create->json('data.academy_id'));

        $list = $this->getJson('/api/v1/me/facilities')->assertOk();
        $this->assertCount(1, $list->json('data'));
        $this->assertSame('Sardar Patel Stadium', $list->json('data.0.name'));

        $id = $create->json('data.id');
        $this->putJson("/api/v1/me/facilities/$id", ['name' => 'Sardar Patel Stadium (Renamed)'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Sardar Patel Stadium (Renamed)')
            // A partial update must not reset the type.
            ->assertJsonPath('data.type', 'ground');

        $this->deleteJson("/api/v1/me/facilities/$id")->assertOk();
        $this->getJson('/api/v1/me/facilities')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_venues_are_scoped_to_their_owner(): void
    {
        [$owner] = $this->organizer('owner@test.local');
        [$other] = $this->organizer('other@test.local');

        $this->actingAs($owner, 'sanctum');
        $this->postJson('/api/v1/me/facilities', ['name' => 'Owner Ground'])->assertCreated();

        $this->actingAs($other, 'sanctum');
        $this->getJson('/api/v1/me/facilities')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_organizer_team_can_be_managed(): void
    {
        [$user] = $this->organizer();
        $this->actingAs($user, 'sanctum');

        $invite = $this->postJson('/api/v1/me/organizer/team', [
            'name' => 'Aisha Verma',
            'email' => 'aisha@test.local',
            'role' => 'co_organizer',
        ]);
        $invite->assertCreated();
        $this->assertSame('pending', $invite->json('data.status'));
        $this->assertSame('co_organizer', $invite->json('data.role'));

        // The same person cannot be invited twice.
        $this->postJson('/api/v1/me/organizer/team', [
            'name' => 'Aisha Verma',
            'email' => 'aisha@test.local',
        ])->assertStatus(422);

        $list = $this->getJson('/api/v1/me/organizer/team')->assertOk();
        $this->assertCount(1, $list->json('data'));

        $id = $invite->json('data.id');
        $this->patchJson("/api/v1/me/organizer/team/$id", ['role' => 'volunteer'])
            ->assertOk()
            ->assertJsonPath('data.role', 'volunteer');

        $this->deleteJson("/api/v1/me/organizer/team/$id")->assertOk();
        $this->getJson('/api/v1/me/organizer/team')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_organizer_team_is_organizer_only(): void
    {
        $athlete = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $this->actingAs($athlete, 'sanctum');

        $this->getJson('/api/v1/me/organizer/team')->assertStatus(403);
        $this->postJson('/api/v1/me/organizer/team', [
            'name' => 'X', 'email' => 'x@test.local',
        ])->assertStatus(403);
    }

    public function test_feed_can_be_scoped_to_an_author_role(): void
    {
        $athlete = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $coach = User::factory()->create(['role' => 'coach', 'status' => 'active']);
        $organizer = User::factory()->create(['role' => 'organizer', 'status' => 'active']);

        Post::create(['user_id' => $athlete->id, 'body' => 'athlete post', 'visibility' => 'public']);
        Post::create(['user_id' => $coach->id, 'body' => 'coach post', 'visibility' => 'public']);
        Post::create(['user_id' => $organizer->id, 'body' => 'event announcement', 'visibility' => 'public']);

        $this->actingAs($athlete, 'sanctum');

        $coachPosts = $this->getJson('/api/v1/posts?author_role=coach')->assertOk();
        $this->assertCount(1, $coachPosts->json('data'));
        $this->assertSame('coach post', $coachPosts->json('data.0.body'));

        $all = $this->getJson('/api/v1/posts')->assertOk();
        $this->assertCount(3, $all->json('data'));
    }

    public function test_trial_payload_carries_registration_counters(): void
    {
        $sport = Sport::create(['name' => 'Cricket']);
        $city = City::create(['name' => 'Ahmedabad', 'state' => 'Gujarat']);
        $owner = User::factory()->create(['role' => 'academy', 'status' => 'active']);

        $trial = Trial::create([
            'posted_by_user_id' => $owner->id,
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'name' => 'Open Trial',
            'venue' => 'Test Ground',
            'event_datetime' => now()->addWeek(),
            'contact_number' => '9999999999',
            'vacancies' => 20,
            'status' => 'published',
        ]);

        $this->actingAs($owner, 'sanctum');
        $data = $this->getJson('/api/v1/me/trials')->assertOk()->json('data.0');

        $this->assertSame(20, $data['total_spots']);
        $this->assertSame(0, $data['filled_spots']);
        $this->assertSame(20, $data['spots_left']);
        $this->assertSame(0, $data['registrations_count']);
    }

    public function test_api_errors_use_the_structured_envelope(): void
    {
        [$user] = $this->organizer();
        $this->actingAs($user, 'sanctum');

        // A wrong method is reported with the structured envelope too (and
        // without any server paths / stack trace).
        $response = $this->getJson('/api/v1/me/facilities/999999');
        $response->assertStatus(405);
        $this->assertArrayHasKey('error', $response->json());
        $this->assertArrayHasKey('code', $response->json('error'));
        $this->assertArrayNotHasKey('file', $response->json());
        $this->assertArrayNotHasKey('trace', $response->json());
        $this->assertArrayNotHasKey('exception', $response->json());
    }

    public function test_athlete_cannot_read_organizer_facilities(): void
    {
        $athlete = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $this->actingAs($athlete, 'sanctum');

        $this->getJson('/api/v1/me/facilities')->assertStatus(403);
    }
}
