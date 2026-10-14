<?php

namespace Tests\Feature;

use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\Sport;
use App\Models\TrialRegistration;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class Phase8EventsRegistrationsTest extends TestCase
{
    use RefreshDatabase;

    private function seedRefs(): array
    {
        $sport = Sport::create(['name' => 'Cricket']);
        $city = City::create(['name' => 'Ahmedabad', 'state' => 'Gujarat']);
        $ageGroup = AgeGroup::create(['name' => 'U16']);

        return [$sport, $city, $ageGroup];
    }

    private function provider(): User
    {
        return User::factory()->create(['role' => 'academy', 'status' => 'active']);
    }

    private function athlete(AgeGroup $ageGroup): array
    {
        $user = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $profile = AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Event Athlete',
            'date_of_birth' => '2000-01-01',
            'gender' => 'male',
            'skill_level' => 'intermediate',
            'age_group_id' => $ageGroup->id,
        ]);

        return [$user, $profile];
    }

    public function test_unified_event_create_list_show_publish_close(): void
    {
        [$sport, $city] = $this->seedRefs();
        $provider = $this->provider();
        $this->actingAs($provider, 'sanctum');

        $create = $this->postJson('/api/v1/me/events?type=trial', [
            'name' => 'U16 Open Trial',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'venue' => 'Motera Ground',
            'event_datetime' => now()->addDays(10)->toDateTimeString(),
            'contact_number' => '9999999999',
            'vacancies' => 50,
        ]);
        $create->assertSuccessful();
        $id = $create->json('data.id');
        $this->assertNotNull($id);

        $this->getJson('/api/v1/me/events')->assertOk()->assertJsonStructure(['data' => ['events', 'counts']]);
        $this->getJson("/api/v1/events/{$id}")->assertOk()->assertJsonPath('data.event_type', 'trial');
        $this->postJson("/api/v1/me/events/{$id}/publish?type=trial")->assertSuccessful();
        $this->postJson("/api/v1/me/events/{$id}/close?type=trial")->assertSuccessful();
    }

    public function test_register_approve_export_cancel(): void
    {
        [$sport, $city, $ageGroup] = $this->seedRefs();
        $provider = $this->provider();
        [$athlete] = $this->athlete($ageGroup);

        $this->actingAs($provider, 'sanctum');
        $create = $this->postJson('/api/v1/me/events?type=trial', [
            'name' => 'Selection Trial',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'venue' => 'Main Ground',
            'event_datetime' => now()->addDays(7)->toDateTimeString(),
            'contact_number' => '9999999999',
            'vacancies' => 2,
        ]);
        $eventId = $create->json('data.id');
        $this->postJson("/api/v1/me/events/{$eventId}/publish?type=trial")->assertSuccessful();

        $this->actingAs($athlete, 'sanctum');
        $reg = $this->postJson("/api/v1/trials/{$eventId}/register", []);
        $reg->assertCreated();
        $regId = TrialRegistration::where('trial_id', $eventId)->value('id');
        $this->assertNotNull($regId);

        // Duplicate guard.
        $this->postJson("/api/v1/trials/{$eventId}/register", [])->assertStatus(409);

        $this->getJson('/api/v1/me/registrations')->assertOk();

        $this->actingAs($provider, 'sanctum');
        $this->getJson("/api/v1/events/{$eventId}/registrations?type=trial")->assertOk();
        $this->postJson("/api/v1/registrations/{$regId}/approve?type=trial")->assertOk();
        $this->getJson("/api/v1/registrations/{$regId}?type=trial")->assertOk();
        $export = $this->getJson("/api/v1/events/{$eventId}/registrations/export?type=trial");
        $export->assertOk();
        $this->assertStringContainsString('text/csv', $export->headers->get('Content-Type'));

        // Bulk reject (idempotent) + athlete cancel path on a second registration.
        $this->postJson("/api/v1/events/{$eventId}/registrations/bulk?type=trial", [
            'action' => 'reject', 'ids' => [(int) $regId], 'reason' => 'Test bulk',
        ])->assertOk();
    }
}
