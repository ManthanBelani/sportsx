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

        $resp->assertStatus(422)->assertJsonPath('error.code', 'VALIDATION_ERROR');
        $this->assertArrayHasKey('email', $resp->json('error.errors'));
    }

    public function test_register_rejects_weak_password_with_field_error(): void
    {
        $resp = $this->postJson('/api/v1/auth/register', [
            'role' => 'athlete',
            'email' => 'weak@example.com',
            'password' => '123',
        ]);

        $resp->assertStatus(422)->assertJsonPath('error.code', 'VALIDATION_ERROR');
        $this->assertArrayHasKey('password', $resp->json('error.errors'));
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

    public function test_otp_login_request_queues_email_and_verify_returns_auth_token(): void
    {
        \Illuminate\Support\Facades\Mail::fake();

        $user = User::factory()->create([
            'email' => 'otp-login@example.com',
            'role' => 'athlete',
            'status' => 'active',
        ]);

        $requestResp = $this->postJson('/api/v1/auth/otp-login/request', [
            'email' => 'otp-login@example.com',
        ]);

        $requestResp->assertStatus(200)
            ->assertJson(['message' => 'If the address is registered, a login code has been sent.']);

        \Illuminate\Support\Facades\Mail::assertQueued(\App\Mail\EmailOtpMail::class, function ($mail) {
            return $mail->hasTo('otp-login@example.com');
        });

        // Capture code
        $queued = \Illuminate\Support\Facades\Mail::queued(\App\Mail\EmailOtpMail::class);
        $this->assertNotEmpty($queued);
        $code = $queued->first()->code;

        $verifyResp = $this->postJson('/api/v1/auth/otp-login/verify', [
            'email' => 'otp-login@example.com',
            'code' => $code,
        ]);

        $verifyResp->assertStatus(200)
            ->assertJsonStructure(['token', 'user' => ['id', 'email', 'role'], 'needs_onboarding'])
            ->assertJsonPath('user.email', 'otp-login@example.com');
    }

    public function test_otp_login_verify_with_wrong_code_fails(): void
    {
        User::factory()->create([
            'email' => 'wrong-code@example.com',
            'role' => 'athlete',
            'status' => 'active',
        ]);

        $this->postJson('/api/v1/auth/otp-login/request', [
            'email' => 'wrong-code@example.com',
        ]);

        $resp = $this->postJson('/api/v1/auth/otp-login/verify', [
            'email' => 'wrong-code@example.com',
            'code' => '000000',
        ]);

        $resp->assertStatus(422)
            ->assertJson(['message' => 'That code is incorrect or has expired.']);
    }

    public function test_otp_login_request_uniform_response_for_nonexistent_email(): void
    {
        $resp = $this->postJson('/api/v1/auth/otp-login/request', [
            'email' => 'nonexistent@example.com',
        ]);

        $resp->assertStatus(200)
            ->assertJson(['message' => 'If the address is registered, a login code has been sent.']);
    }

    public function test_password_login_with_require_otp_sends_code_and_requires_otp_verification(): void
    {
        \Illuminate\Support\Facades\Mail::fake();

        $user = User::factory()->create([
            'email' => 'pass-otp@example.com',
            'password' => \Illuminate\Support\Facades\Hash::make('Secret123!'),
            'role' => 'athlete',
            'status' => 'active',
        ]);

        // Step 1: Login with credentials requesting OTP
        $resp = $this->postJson('/api/v1/auth/login', [
            'email' => 'pass-otp@example.com',
            'password' => 'Secret123!',
            'require_otp' => true,
        ]);

        $resp->assertStatus(200)
            ->assertJson(['otp_required' => true, 'email' => 'pass-otp@example.com']);
        $this->assertNull($resp->json('token'));

        \Illuminate\Support\Facades\Mail::assertQueued(\App\Mail\EmailOtpMail::class, function ($mail) {
            return $mail->hasTo('pass-otp@example.com');
        });

        $code = \Illuminate\Support\Facades\Mail::queued(\App\Mail\EmailOtpMail::class)->first()->code;

        // Step 2: Login with credentials + wrong OTP fails
        $wrongResp = $this->postJson('/api/v1/auth/login', [
            'email' => 'pass-otp@example.com',
            'password' => 'Secret123!',
            'code' => '999999',
        ]);
        $wrongResp->assertStatus(422);

        // Step 3: Login with credentials + valid OTP returns auth token
        $okResp = $this->postJson('/api/v1/auth/login', [
            'email' => 'pass-otp@example.com',
            'password' => 'Secret123!',
            'code' => $code,
        ]);
        $okResp->assertStatus(200)
            ->assertJsonStructure(['token', 'user' => ['id', 'email', 'role']])
            ->assertJsonPath('user.email', 'pass-otp@example.com');
    }
}
