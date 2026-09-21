<?php

namespace Tests\Feature;

use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

/**
 * Social links (users.social_links) — shared by every role.
 *  - PUT /me/social-links normalizes bare domains to https URLs.
 *  - Invalid links return 422 with per-platform errors.
 *  - Links are exposed via GET /me/social-links and /auth/me.
 */
class SocialLinksTest extends TestCase
{
    use RefreshDatabase;

    public function test_athlete_can_save_and_read_social_links(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'athlete']));

        $resp = $this->putJson('/api/v1/me/social-links', [
            'social_links' => [
                'instagram' => 'instagram.com/starplayer',
                'youtube' => 'https://youtube.com/@star',
            ],
        ]);

        $resp->assertStatus(200)
            ->assertJsonPath('data.instagram', 'https://instagram.com/starplayer')
            ->assertJsonPath('data.youtube', 'https://youtube.com/@star')
            ->assertJsonPath('data.x', null);

        $this->getJson('/api/v1/me/social-links')
            ->assertStatus(200)
            ->assertJsonPath('data.instagram', 'https://instagram.com/starplayer');

        $this->getJson('/api/v1/auth/me')
            ->assertStatus(200)
            ->assertJsonPath('data.social_links.instagram', 'https://instagram.com/starplayer');
    }

    public function test_coach_can_save_social_links_with_flat_payload(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'coach']));

        $this->putJson('/api/v1/me/social-links', ['linkedin' => 'linkedin.com/in/coach'])
            ->assertStatus(200)
            ->assertJsonPath('data.linkedin', 'https://linkedin.com/in/coach');
    }

    public function test_invalid_link_returns_422(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'athlete']));

        $this->putJson('/api/v1/me/social-links', [
            'social_links' => ['x' => 'not a url at all !!!'],
        ])->assertStatus(422)->assertJsonStructure(['errors']);
    }

    public function test_unauthenticated_cannot_access_social_links(): void
    {
        $this->getJson('/api/v1/me/social-links')->assertStatus(401);
        $this->putJson('/api/v1/me/social-links', ['social_links' => []])->assertStatus(401);
    }
}
