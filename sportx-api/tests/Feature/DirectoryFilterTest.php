<?php

namespace Tests\Feature;

use App\Models\Academy;
use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\CoachProfile;
use App\Models\Sport;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DirectoryFilterTest extends TestCase
{
    use RefreshDatabase;

    public function test_academy_directory_supports_position_facility_rating_level_filters(): void
    {
        $city = City::create(['name' => 'Mumbai', 'state' => 'Maharashtra']);
        $sport = Sport::create(['name' => 'Cricket']);
        $age = AgeGroup::create(['name' => 'U-16']);
        $a = Academy::create([
            'owner_user_id' => User::factory()->create()->id,
            'name' => 'A1', 'description' => 'x', 'address' => 'Main', 'contact_number' => '9999999999',
            'city_id' => $city->id,
            'facilities' => ['Indoor Nets', 'Gym'],
            'age_groups' => [$age->id],
            'verification_badge' => true,
            'listing_status' => 'published',
        ]);
        Academy::create([
            'owner_user_id' => User::factory()->create()->id,
            'name' => 'A2', 'description' => 'x', 'address' => 'Main', 'contact_number' => '9999999999',
            'city_id' => $city->id,
            'facilities' => ['Pool'],
            'age_groups' => [],
            'verification_badge' => false,
            'listing_status' => 'published',
        ]);

        // facility + level
        $resp = $this->getJson('/api/v1/academies?facility=Indoor%20Nets&level=verified')
            ->assertOk();
        $rows = $resp->json('data');
        $this->assertCount(1, $rows ?? []);
    }

    public function test_coach_directory_supports_level_rating_experience_sort(): void
    {
        $city = City::create(['name' => 'Mumbai', 'state' => 'Maharashtra']);
        $sport = Sport::create(['name' => 'Cricket']);
        CoachProfile::create([
            'user_id' => User::factory()->create()->id,
            'full_name' => 'C1', 'city_id' => $city->id, 'sport_id' => $sport->id,
            'contact_number' => '9999999999', 'experience' => '5y', 'skill_level' => 'advanced', 'experience_years' => 10, 'avg_rating' => 4.8,
            'listing_status' => 'published',
        ]);
        CoachProfile::create([
            'user_id' => User::factory()->create()->id,
            'full_name' => 'C2', 'city_id' => $city->id, 'sport_id' => $sport->id,
            'contact_number' => '9999999999', 'experience' => '1y', 'skill_level' => 'beginner', 'experience_years' => 1, 'avg_rating' => 3.5,
            'listing_status' => 'published',
        ]);

        $this->getJson('/api/v1/coaches?sort=experience_years&direction=desc')
            ->assertOk();
        $rows = $this->getJson('/api/v1/coaches')->assertOk()->json('data');
        $this->assertCount(2, $rows ?? []);
    }

    public function test_trial_and_tournament_filters(): void
    {
        $city = City::create(['name' => 'Mumbai', 'state' => 'Maharashtra']);
        $sport = Sport::create(['name' => 'Cricket']);
        $age = AgeGroup::create(['name' => 'U-16']);
        $u = User::factory()->create(['role' => 'organizer', 'status' => 'active']);
        $orgProfile = \App\Models\OrganizerProfile::create(['user_id' => $u->id, 'organization_name' => 'Org', 'org_type' => 'club']);
        $academy = Academy::create([
            'owner_user_id' => $u->id, 'name' => 'A1', 'description' => 'x', 'address' => 'Main',
            'contact_number' => '9999999999',
            'city_id' => $city->id, 'listing_status' => 'published',
        ]);

        $trial = \App\Models\Trial::create([
            'posted_by_user_id' => $u->id, 'academy_id' => $academy->id,
            'name' => 'Trial 1', 'sport_id' => $sport->id, 'city_id' => $city->id,
            'venue' => 'Ground', 'event_datetime' => now()->addDays(10),
            'contact_number' => '9999999999', 'status' => 'published',
            'age_groups' => [$age->id], 'level' => 'intermediate',
        ]);
        $t = Tournament::create([
            'organizer_id' => $orgProfile->id, 'sport_id' => $sport->id, 'city_id' => $city->id,
            'name' => 'Cup', 'start_date' => now()->addDays(5)->toDateString(),
            'end_date' => now()->addDays(7)->toDateString(), 'venue' => 'V', 'status' => 'published',
        ]);
        \App\Models\TournamentCategory::create([
            'tournament_id' => $t->id, 'name' => 'Open', 'age_group_id' => $age->id, 'capacity' => 10,
        ]);

        $this->getJson('/api/v1/trials?level=intermediate&age_group_id='.$age->id)
            ->assertOk();
        $this->getJson('/api/v1/tournaments?level=intermediate')
            ->assertOk();
    }

    public function test_search_provider_aliases(): void
    {
        $user = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $this->actingAs($user, 'sanctum');
        $this->getJson('/api/v1/search?q=test&sport_id=1&city_id=1&sort=rating&level=advanced&facility=Indoor&position=Batsman')
            ->assertOk();
    }
}
