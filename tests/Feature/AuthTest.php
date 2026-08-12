<?php

namespace Tests\Feature;

use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

/**
 * Auth flow regression tests. Locks in the fixes for:
 *  - B1: unauthenticated requests must return 401 (not 500 "Route [login] not defined").
 *  - B2: /auth/me returns user fields flat inside `data` (no nested data.user).
 *  - 422 validation surfaces field-level errors.
 */
class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_returns_token_and_user(): void
    {
        $resp = $this->postJson('/api/v1/auth/register', [
            'role' => 'athlete',
            'email' => 'qa@example.com',
            'password' => 'Password123',
            'name' => 'QA User',
        ]);

        $resp->assertStatus(201)
            ->assertJsonStructure(['token', 'user' => ['id', 'role', 'email'], 'needs_onboarding']);
        $this->assertDatabaseHas('users', ['email' => 'qa@example.com', 'role' => 'athlete']);
    }

    public function test_register_rejects_duplicate_email_with_field_error(): void
    {
        User::factory()->create(['email' => 'dup@example.com', 'role' => 'athlete']);

        $resp = $this->postJson('/api/v1/auth/register', [
            'role' => 'athlete',
            'email' => 'dup@example.com',
            'password' => 'Password123',
        ]);

        $resp->assertStatus(422)->assertJsonValidationErrors('email');
    }

    public function test_register_rejects_weak_password_with_field_error(): void
    {
        $resp = $this->postJson('/api/v1/auth/register', [
            'role' => 'athlete',
            'email' => 'weak@example.com',
            'password' => '123',
        ]);

        $resp->assertStatus(422)->assertJsonValidationErrors('password');
    }

    public function test_login_invalid_credentials_returns_401(): void
    {
        User::factory()->create(['email' => 'u@example.com', 'password' => 'password']);

        $resp = $this->postJson('/api/v1/auth/login', [
            'email' => 'u@example.com',
            'password' => 'wrong-password',
        ]);

        $resp->assertStatus(401);
    }

    public function test_protected_endpoint_without_token_returns_401_not_500(): void
    {
        // Regression for the "Route [login] not defined" 500.
        $resp = $this->getJson('/api/v1/auth/me');

        $resp->assertStatus(401)->assertJson(['message' => 'Unauthenticated.']);
    }

    public function test_auth_me_returns_user_fields_flat_in_data(): void
    {
        $user = User::factory()->create(['role' => 'athlete']);
        Sanctum::actingAs($user);

        $resp = $this->getJson('/api/v1/auth/me');

        $resp->assertStatus(200)
            ->assertJsonPath('data.id', $user->id)
            ->assertJsonPath('data.role', 'athlete')
            ->assertJsonStructure(['data' => ['id', 'role', 'email', 'needs_onboarding']]);
    }

    public function test_logout_revokes_current_token(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['*']);

        $this->postJson('/api/v1/auth/logout')->assertStatus(200);
    }
}
