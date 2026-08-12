<?php

namespace Tests\Feature;

use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\Sport;
use App\Models\Trial;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

/**
 * Trial registration regression test.
 *  - B6: athlete-submitted fields (playing_role / medical_conditions /
 *    parental_consent) must be persisted, not silently discarded.
 */
class TrialRegistrationTest extends TestCase
{
    use RefreshDatabase;

    /** @return array{0: Trial, 1: Sport, 2: City, 3: AgeGroup} */
    private function registerableTrial(): array
    {
        $sport = Sport::create(['name' => 'Cricket', 'sort_order' => 1]);
        $city = City::create(['name' => 'Ahmedabad', 'state' => 'Gujarat']);
        $ageGroup = AgeGroup::create(['name' => 'U-14', 'min_age' => 12, 'max_age' => 14]);

        $provider = User::factory()->create(['role' => 'organizer']);

        $trial = Trial::create([
            'posted_by_user_id' => $provider->id,
            'name' => 'Test Trial',
            'sport_id' => $sport->id,
            'event_datetime' => now()->addMonth(),
            'venue' => 'Test Venue',
            'contact_number' => '+919999999999',
            'registration_deadline' => now()->addWeek(),
            'status' => 'published',
        ]);

        return [$trial, $sport, $city, $ageGroup];
    }

    public function test_registration_persists_athlete_submitted_fields(): void
    {
        [$trial, $sport, $city, $ageGroup] = $this->registerableTrial();

        $athlete = User::factory()->create(['role' => 'athlete']);
        AthleteProfile::create([
            'user_id' => $athlete->id,
            'full_name' => 'Reg Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'age_group_id' => $ageGroup->id,
            'skill_level' => 'intermediate',
        ]);
        Sanctum::actingAs($athlete);

        $resp = $this->postJson("/api/v1/trials/{$trial->id}/register", [
            'playing_role' => 'Batsman',
            'medical_conditions' => 'Asthma',
            'parental_consent' => true,
        ]);

        $resp->assertStatus(201);
        $this->assertDatabaseHas('trial_registrations', [
            'trial_id' => $trial->id,
            'playing_role' => 'Batsman',
            'medical_conditions' => 'Asthma',
            'parental_consent' => 1,
        ]);
    }
}
