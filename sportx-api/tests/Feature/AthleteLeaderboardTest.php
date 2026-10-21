<?php

namespace Tests\Feature;

use App\Models\Achievement;
use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\Connection;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AthleteLeaderboardTest extends TestCase
{
    use RefreshDatabase;

    protected function makeAthlete(User $user, string $name, int $ageGroupId): AthleteProfile
    {
        return AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => $name,
            'date_of_birth' => '2000-01-01',
            'gender' => 'male',
            'skill_level' => 'intermediate',
            'age_group_id' => $ageGroupId,
        ]);
    }

    public function test_leaderboard_requires_authentication(): void
    {
        $this->getJson('/api/v1/me/leaderboard')->assertStatus(401);
    }

    public function test_leaderboard_ranks_by_achievements(): void
    {
        $ageGroup = AgeGroup::create(['name' => 'U18-LB']);

        $me = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $other = User::factory()->create(['role' => 'athlete', 'status' => 'active']);

        $myProfile = $this->makeAthlete($me, 'Board Me', $ageGroup->id);
        $otherProfile = $this->makeAthlete($other, 'Board Other', $ageGroup->id);

        Achievement::create(['athlete_id' => $otherProfile->id, 'text' => 'State champion']);

        $this->actingAs($me, 'sanctum');

        $res = $this->getJson('/api/v1/me/leaderboard?period=allTime&category=achievements')
            ->assertOk()
            ->assertJsonStructure([
                'data' => ['period', 'category', 'entries', 'current_user', 'total_participants'],
            ]);

        $data = $res->json('data');
        $this->assertSame('allTime', $data['period']);
        $this->assertSame('achievements', $data['category']);
        $this->assertCount(1, $data['entries']);
        $this->assertSame(1, $data['entries'][0]['rank']);
        $this->assertSame(1, $data['entries'][0]['score']);
        $this->assertFalse($data['entries'][0]['is_current_user']);

        $this->assertNotNull($data['current_user']);
        $this->assertTrue($data['current_user']['is_current_user']);
        $this->assertSame((string) $myProfile->id, (string) $data['current_user']['id']);
    }

    public function test_leaderboard_counts_accepted_connections(): void
    {
        $ageGroup = AgeGroup::create(['name' => 'U18-LB2']);

        $me = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $other = User::factory()->create(['role' => 'athlete', 'status' => 'active']);

        $this->makeAthlete($me, 'Conn Me', $ageGroup->id);
        $this->makeAthlete($other, 'Conn Other', $ageGroup->id);

        Connection::create([
            'follower_user_id' => $me->id,
            'followee_user_id' => $other->id,
            'status' => 'accepted',
        ]);

        $this->actingAs($me, 'sanctum');

        $res = $this->getJson('/api/v1/me/leaderboard?period=allTime&category=connections')
            ->assertOk();

        $data = $res->json('data');
        $this->assertSame(1, $data['current_user']['score']);
        $this->assertSame(2, $data['total_participants']);
    }

    public function test_leaderboard_rejects_unknown_category(): void
    {
        $me = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $this->actingAs($me, 'sanctum');

        $this->getJson('/api/v1/me/leaderboard?category=bogus')->assertStatus(422);
    }
}
