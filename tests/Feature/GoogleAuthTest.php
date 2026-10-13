<?php

namespace Tests\Feature;

use App\Exceptions\GoogleAuthException;
use App\Models\SocialAccount;
use App\Models\User;
use App\Services\GoogleAuthService;
use App\Services\Support\GoogleKeySet;
use Firebase\JWT\JWT;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * Google sign-in.
 *
 * The verified-claims boundary is faked for the endpoint tests — minting real
 * RS256 tokens would need a real key pair and Google's JWKS on every run. The
 * signature/JWKS path itself is covered separately in
 * `GoogleAuthServiceVerificationTest`, which generates a local RSA key pair and
 * stubs the key-set endpoint.
 *
 * @see \App\Services\GoogleAuthService
 * @see docs/Google-Authentication.md
 */
class GoogleAuthTest extends TestCase
{
    use RefreshDatabase;

    /** A structurally realistic stand-in for a Google ID token (real ones are ~1KB). */
    private const FAKE_ID_TOKEN = 'eyJhbGciOiJSUzI1NiIsImtpZCI6ImFiYzEyMyJ9.e30.c2lnbmF0dXJlLXN0dWIifQ';

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'sportx.google.client_id' => 'test-client-id.apps.googleusercontent.com',
            'sportx.google.client_secret' => 'test-secret',
            'sportx.google.allow_signup' => true,
            'sportx.google.default_role' => 'athlete',
            'sportx.google.restrict_roles' => ['athlete', 'coach', 'academy', 'organizer', 'sponsor', 'talent_scout'],
            'sportx.google.hd' => null,
        ]);
    }

    /**
     * Stub the service so it returns a fixed verified profile.
     *
     * @param  array<string, mixed>  $profile
     */
    protected function fakeVerifiedProfile(array $profile = [], ?\Closure $onResolve = null): void
    {
        $profile = array_merge([
            'sub' => '100948372948372948',
            'email' => 'kiran@example.com',
            'email_verified' => true,
            'name' => 'Kiran Patel',
            'picture' => 'https://lh3.googleusercontent.com/a/default',
        ], $profile);

        $service = \Mockery::mock(GoogleAuthService::class)->makePartial();

        $service->shouldReceive('verifyIdToken')->andReturn($profile);

        if ($onResolve) {
            $service->shouldReceive('resolveAccount')->andReturnUsing($onResolve);
        }

        $this->app->instance(GoogleAuthService::class, $service);
    }

    /* ---------------------------------------------------------------------
     | happy paths
     | ------------------------------------------------------------------ */

    public function test_unknown_google_identity_creates_an_account_and_returns_a_token(): void
    {
        $this->fakeVerifiedProfile();

        $response = $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN]);

        $response->assertOk()
            ->assertJsonPath('created', true)
            ->assertJsonPath('linked', false)
            ->assertJsonPath('user.email', 'kiran@example.com')
            ->assertJsonStructure(['token', 'user' => ['id', 'role', 'email'], 'needs_onboarding']);

        $this->assertDatabaseHas('users', ['email' => 'kiran@example.com']);
        $this->assertDatabaseHas('social_accounts', [
            'provider' => 'google',
            'provider_user_id' => '100948372948372948',
        ]);
    }

    public function test_google_verified_email_marks_the_sportx_email_verified(): void
    {
        $this->fakeVerifiedProfile();

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])->assertOk();

        $user = User::where('email', 'kiran@example.com')->firstOrFail();
        $this->assertNotNull($user->email_verified_at);
    }

    public function test_returning_user_is_signed_in_without_creating_a_duplicate(): void
    {
        $user = User::create([
            'role' => 'athlete', 'name' => 'Kiran', 'email' => 'kiran@example.com',
            'password' => Hash::make('password'), 'email_verified_at' => now(), 'status' => 'active',
        ]);
        SocialAccount::create([
            'user_id' => $user->id, 'provider' => 'google',
            'provider_user_id' => '100948372948372948', 'email' => 'kiran@example.com',
        ]);

        $this->fakeVerifiedProfile();

        $response = $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN]);

        $response->assertOk()->assertJsonPath('created', false)->assertJsonPath('user.id', $user->id);

        $this->assertSame(1, User::where('email', 'kiran@example.com')->count());
    }

    /* ---------------------------------------------------------------------
     | account linking
     | ------------------------------------------------------------------ */

    public function test_verified_email_is_linked_to_an_existing_account(): void
    {
        $user = User::create([
            'role' => 'athlete', 'name' => 'Kiran', 'email' => 'kiran@example.com',
            'password' => Hash::make('password'), 'email_verified_at' => now(), 'status' => 'active',
        ]);

        $this->fakeVerifiedProfile();

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])
            ->assertOk()
            ->assertJsonPath('linked', true)
            ->assertJsonPath('created', false)
            ->assertJsonPath('user.id', $user->id);

        $this->assertDatabaseHas('social_accounts', [
            'user_id' => $user->id,
            'provider' => 'google',
        ]);
    }

    public function test_unverified_existing_account_is_refused_linking(): void
    {
        User::create([
            'role' => 'athlete', 'name' => 'Squatter', 'email' => 'kiran@example.com',
            'password' => Hash::make('password'),
            // Never verified the address.
            'email_verified_at' => null, 'status' => 'active',
        ]);

        $this->fakeVerifiedProfile();

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'EMAIL_UNVERIFIED');

        // Critically: no identity was linked, so the squatter gained nothing.
        $this->assertDatabaseCount('social_accounts', 0);
    }

    /* ---------------------------------------------------------------------
     | approval gate — the security-critical case
     | ------------------------------------------------------------------ */

public function test_pending_account_cannot_use_google_to_bypass_approval(): void
    {
        $this->fakeVerifiedProfile();

        // A coach signup starts pending. The applicant still gets a session —
        // matching `/auth/register` — so they can see the pending screen.
        $this->postJson('/api/v1/auth/google', [
            'id_token' => self::FAKE_ID_TOKEN,
            'role' => 'coach',
        ])->assertOk()
            ->assertJsonPath('created', true)
            ->assertJsonPath('pending_approval', true)
            ->assertJsonPath('user.status', 'pending');

        $user = User::where('email', 'kiran@example.com')->firstOrFail();
        $this->assertSame('pending', $user->status);

        // Signing in again must be refused — the token from signup does not
        // entitle the applicant to a session on a *later* attempt.
        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])
            ->assertStatus(403)
            ->assertJsonPath('error.code', 'PENDING_APPROVAL');
    }

    public function test_approving_the_account_lets_google_sign_in_proceed(): void
    {
        $this->fakeVerifiedProfile();

        $this->postJson('/api/v1/auth/google', [
            'id_token' => self::FAKE_ID_TOKEN, 'role' => 'coach',
        ])->assertOk()->assertJsonPath('user.status', 'pending');

        User::where('email', 'kiran@example.com')->firstOrFail()->update(['status' => 'active']);

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])
            ->assertOk()
            ->assertJsonPath('created', false)
            ->assertJsonPath('user.status', 'active');
    }

    public function test_suspended_account_cannot_sign_in_with_google(): void
    {
        $this->fakeVerifiedProfile();

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])->assertOk();

        User::where('email', 'kiran@example.com')->firstOrFail()->update(['status' => 'suspended']);

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])
            ->assertStatus(403)
            ->assertJsonPath('error.code', 'ACCOUNT_DISABLED');
    }

    /* ---------------------------------------------------------------------
     | role validation
     | ------------------------------------------------------------------ */

    public function test_role_outside_the_allow_list_is_rejected(): void
    {
        $this->fakeVerifiedProfile();

        $this->postJson('/api/v1/auth/google', [
            'id_token' => self::FAKE_ID_TOKEN,
            'role' => 'admin', // never permitted for self sign-up
        ])->assertStatus(422)->assertJsonPath('error.code', 'INVALID_ROLE');

        $this->assertDatabaseCount('users', 0);
    }

    public function test_allow_listed_role_is_applied(): void
    {
        $this->fakeVerifiedProfile();

        $this->postJson('/api/v1/auth/google', [
            'id_token' => self::FAKE_ID_TOKEN,
            'role' => 'organizer',
        ])->assertOk()->assertJsonPath('user.role', 'organizer');
    }

    /* ---------------------------------------------------------------------
     | signup toggle
     | ------------------------------------------------------------------ */

    public function test_unknown_identity_is_refused_when_signup_is_disabled(): void
    {
        config(['sportx.google.allow_signup' => false]);

        $this->fakeVerifiedProfile();

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])
            ->assertStatus(403)
            ->assertJsonPath('error.code', 'SIGNUP_DISABLED');

        $this->assertDatabaseCount('users', 0);
    }

    /* ---------------------------------------------------------------------
     | verification failures
     | ------------------------------------------------------------------ */

    public function test_invalid_token_is_rejected(): void
    {
        $service = \Mockery::mock(GoogleAuthService::class);
        $service->shouldReceive('verifyIdToken')
            ->andThrow(GoogleAuthException::make('Signature verification failed'));
        $this->app->instance(GoogleAuthService::class, $service);

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])
            ->assertStatus(401)
            ->assertJsonPath('error.code', 'INVALID_ID_TOKEN');
    }

    public function test_unverified_google_email_is_rejected(): void
    {
        $service = \Mockery::mock(GoogleAuthService::class);
        $service->shouldReceive('verifyIdToken')
            ->andThrow(GoogleAuthException::make('Google has not verified this email address.'));
        $this->app->instance(GoogleAuthService::class, $service);

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])
            ->assertStatus(401)
            ->assertJsonPath('error.code', 'INVALID_ID_TOKEN');
    }

    public function test_google_outage_returns_503_not_401(): void
    {
        $service = \Mockery::mock(GoogleAuthService::class);
        $service->shouldReceive('verifyIdToken')
            ->andThrow(GoogleAuthException::make('Unable to reach Google.', 503));
        $this->app->instance(GoogleAuthService::class, $service);

        $this->postJson('/api/v1/auth/google', ['id_token' => self::FAKE_ID_TOKEN])
            ->assertStatus(503)
            ->assertJsonPath('error.code', 'GOOGLE_UNAVAILABLE');
    }

    public function test_id_token_is_required(): void
    {
        $this->postJson('/api/v1/auth/google', [])->assertStatus(422);
    }

    /* ---------------------------------------------------------------------
     | linked-account management
     | ------------------------------------------------------------------ */

    public function test_user_can_list_linked_accounts_without_secrets(): void
    {
        $user = User::create([
            'role' => 'athlete', 'name' => 'Kiran', 'email' => 'kiran@example.com',
            'password' => Hash::make('password'), 'email_verified_at' => now(), 'status' => 'active',
        ]);
        SocialAccount::create([
            'user_id' => $user->id, 'provider' => 'google',
            'provider_user_id' => '100948', 'email' => 'kiran@example.com',
            'access_token' => 'super-secret-token',
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/v1/me/social-accounts');

        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.provider', 'google');

        $body = $response->getContent();
        $this->assertStringNotContainsString('super-secret-token', $body);
        $this->assertStringNotContainsString('access_token', $body);
    }

    public function test_last_credential_cannot_be_unlinked_without_a_password(): void
    {
        $user = User::create([
            'role' => 'athlete', 'name' => 'Kiran', 'email' => 'kiran@example.com',
            'password' => null, // Google-only account
            'email_verified_at' => now(), 'status' => 'active',
        ]);
        SocialAccount::create([
            'user_id' => $user->id, 'provider' => 'google', 'provider_user_id' => '100948',
        ]);

        $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/me/social-accounts/google')
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'LAST_CREDENTIAL');

        $this->assertDatabaseCount('social_accounts', 1);
    }

    public function test_credential_can_be_unlinked_when_a_password_exists(): void
    {
        $user = User::create([
            'role' => 'athlete', 'name' => 'Kiran', 'email' => 'kiran@example.com',
            'password' => Hash::make('password'),
            'email_verified_at' => now(), 'status' => 'active',
        ]);
        SocialAccount::create([
            'user_id' => $user->id, 'provider' => 'google', 'provider_user_id' => '100948',
        ]);

        $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/me/social-accounts/google')
            ->assertOk();

        $this->assertDatabaseCount('social_accounts', 0);
    }

    public function test_unauthenticated_user_cannot_list_linked_accounts(): void
    {
        $this->getJson('/api/v1/me/social-accounts')->assertStatus(401);
    }
}