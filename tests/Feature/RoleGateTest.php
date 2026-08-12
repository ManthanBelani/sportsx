<?php

namespace Tests\Feature;

use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

/**
 * Role-gate regression tests.
 *  - B9: a 403 must carry a top-level `message` so clients can render it.
 *  - B1: a missing token on a protected endpoint is 401, not 500.
 */
class RoleGateTest extends TestCase
{
    use RefreshDatabase;

    public function test_athlete_cannot_access_sponsor_endpoint_and_gets_403_message(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'athlete']));

        $resp = $this->getJson('/api/v1/athletes');

        $resp->assertStatus(403)->assertJsonPath('message', 'Insufficient permissions');
    }

    public function test_sponsor_can_access_sponsor_endpoint(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'sponsor']));

        $resp = $this->getJson('/api/v1/athletes');

        $resp->assertStatus(200);
    }

    public function test_role_gated_endpoint_without_token_returns_401(): void
    {
        $this->getJson('/api/v1/athletes')->assertStatus(401);
    }
}
