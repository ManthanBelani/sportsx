<?php

namespace Tests\Feature;

use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\Sport;
use App\Models\TalentScoutProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class Phase7LeaderboardScoutTest extends TestCase
{
    use RefreshDatabase;

    public function test_leaderboard_and_strip(): void
    {
        $athlete = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $ageGroup = AgeGroup::create(['name' => 'U18-Test']);
        AthleteProfile::create([
            'user_id' => $athlete->id,
            'full_name' => 'Rank Athlete',
            'date_of_birth' => '2000-01-01',
            'gender' => 'male',
            'skill_level' => 'intermediate',
            'age_group_id' => $ageGroup->id,
        ]);
        $this->actingAs($athlete, 'sanctum');

        $this->getJson('/api/v1/leaderboard')->assertOk()->assertJsonStructure(['data' => ['podium', 'ranks']]);
        $this->getJson('/api/v1/leaderboard/strip')->assertOk();
        $this->getJson('/api/v1/me/home')->assertOk()->assertJsonStructure(['data' => ['leaderboard_strip']]);
    }

    public function test_shortlist_pipeline_and_observations_and_contact(): void
    {
        $scout = User::factory()->create(['role' => 'talent_scout', 'status' => 'active']);
        $sp = TalentScoutProfile::create(['user_id' => $scout->id, 'organization' => 'Agency', 'sports_specialization' => [1]]);
        $athleteUser = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $ageGroup = AgeGroup::create(['name' => 'U18-Pipe']);
        $ap = AthleteProfile::create([
            'user_id' => $athleteUser->id,
            'full_name' => 'Pipe Athlete',
            'date_of_birth' => '2000-01-01',
            'gender' => 'male',
            'skill_level' => 'intermediate',
            'age_group_id' => $ageGroup->id,
        ]);

        $this->actingAs($scout, 'sanctum');

        $this->postJson("/api/v1/me/scout-shortlist/{$ap->id}", ['status' => 'high', 'tags' => ['fast']])
            ->assertCreated();
        $this->getJson('/api/v1/me/scout-shortlist?status=high')->assertOk();
        $this->patchJson("/api/v1/me/scout-shortlist/{$ap->id}", ['status' => 'final', 'notes' => 'Top pick'])
            ->assertOk();

        $this->postJson('/api/v1/observations', [
            'athlete_profile_id' => $ap->id, 'rating' => 5, 'note' => 'Great footwork',
        ])->assertCreated();
        $this->getJson('/api/v1/observations')->assertOk();

        $this->postJson("/api/v1/athletes/{$ap->id}/contact", ['purpose' => 'Trial invite'])
            ->assertSuccessful();
        $this->getJson('/api/v1/scout/dashboard')->assertOk()
            ->assertJsonStructure(['data' => ['top_talents', 'upcoming_trials', 'counts']]);
    }
}
