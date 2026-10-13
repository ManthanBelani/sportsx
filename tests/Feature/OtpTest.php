<?php

namespace Tests\Feature;

use App\Mail\EmailOtpMail;
use App\Models\OtpCode;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;
use Tests\TestCase;

/**
 * @see \App\Http\Controllers\OtpController
 * @see docs/API-Specification.md §1
 */
class OtpTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        RateLimiter::clear('otp.send.'.sha1('athlete@sportx.test'));
        RateLimiter::clear('otp.verify.'.sha1('athlete@sportx.test'));
    }

    /**
     * Read the plaintext code from the queued mailable.
     *
     * The stored `code_hash` is a bcrypt hash by design, so a test that wants
     * to assert a successful round-trip has to capture the code at the point it
     * was handed to the mailer — which is exactly where the real user's code
     * would land.
     */
    protected function capturedCode(): ?string
    {
        $mailable = null;

        Mail::assertQueued(EmailOtpMail::class, function (EmailOtpMail $mail) use (&$mailable) {
            $mailable = $mail;

            return true;
        });

        return $mailable?->code;
    }

    protected function athlete(array $attributes = []): User
    {
        return User::create(array_merge([
            'role' => 'athlete',
            'name' => 'John Athlete',
            'email' => 'athlete@sportx.test',
            'password' => Hash::make('password'),
            'email_verified_at' => now(),
            'status' => 'active',
        ], $attributes));
    }

    /* ---------------------------------------------------------------------
     | send
     | ------------------------------------------------------------------ */

    public function test_send_otp_queues_an_email_and_stores_only_a_hash(): void
    {
        Mail::fake();
        $user = $this->athlete();

        $response = $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email',
            'destination' => $user->email,
            'purpose' => 'login',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.sent', true)
            ->assertJsonPath('data.channel', 'email');

        $this->assertDatabaseHas('otp_codes', [
            'user_id' => $user->id,
            'channel' => 'email',
            'destination' => $user->email,
            'purpose' => 'login',
        ]);

        // The plaintext must never be persisted.
        $row = OtpCode::query()->latest('id')->first();
        $this->assertNotSame($this->capturedCode(), $row->code_hash);
    }

    public function test_send_otp_masks_the_destination_in_the_response(): void
    {
        Mail::fake();
        $this->athlete();

        $response = $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email',
            'destination' => 'athlete@sportx.test',
            'purpose' => 'login',
        ])->assertOk();

        // Assert the property that matters rather than the exact mask shape:
        // the address comes back partially hidden, with the domain intact.
        $masked = $response->json('data.destination');

        $this->assertNotSame('athlete@sportx.test', $masked);
        $this->assertStringEndsWith('@sportx.test', $masked);
        $this->assertStringNotContainsString('athlete', $masked);
    }

    public function test_send_otp_rejects_an_unknown_purpose(): void
    {
        Mail::fake();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email',
            'destination' => 'athlete@sportx.test',
            'purpose' => 'not_a_purpose',
        ])->assertStatus(422);
    }

    public function test_send_otp_does_not_disclose_that_an_account_is_missing(): void
    {
        Mail::fake();

        // `login` for an unknown address must be indistinguishable from a bad code.
        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email',
            'destination' => 'nobody@sportx.test',
            'purpose' => 'login',
        ])->assertStatus(422);
    }

    public function test_phone_channel_reports_the_channel_as_unavailable(): void
    {
        Mail::fake();
        $this->athlete(['phone' => '919876543210']);

        // AS-60: no SMS vendor is selected, so a phone code cannot be delivered.
        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'phone',
            'destination' => '919876543210',
            'purpose' => 'login',
        ])->assertStatus(503)
            ->assertJsonPath('error.code', 'CHANNEL_UNAVAILABLE');
    }

    /* ---------------------------------------------------------------------
     | verify
     | ------------------------------------------------------------------ */

    public function test_verify_otp_issues_a_token_on_success(): void
    {
        Mail::fake();
        $user = $this->athlete();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ])->assertOk();

        $response = $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email',
            'destination' => $user->email,
            'code' => $this->capturedCode(),
            'purpose' => 'login',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['token', 'user' => ['id', 'role', 'email'], 'needs_onboarding']);

        $this->assertSame($user->id, $response->json('user.id'));
    }

    public function test_verify_otp_rejects_a_wrong_code(): void
    {
        Mail::fake();
        $user = $this->athlete();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ]);

        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email', 'destination' => $user->email, 'code' => '000000', 'purpose' => 'login',
        ])->assertStatus(422)->assertJsonPath('error.code', 'INVALID_OTP');
    }

    public function test_verify_otp_stops_accepting_after_max_attempts(): void
    {
        Mail::fake();
        config(['sportx.otp.max_attempts' => 3]);

        $user = $this->athlete();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ]);

        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/v1/auth/verify-otp', [
                'channel' => 'email', 'destination' => $user->email, 'code' => '000000', 'purpose' => 'login',
            ])->assertStatus(422);
        }

        // Even the correct code is now refused — the code is burned.
        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email', 'destination' => $user->email, 'code' => $this->capturedCode(), 'purpose' => 'login',
        ])->assertStatus(422);

        $this->assertSame(3, OtpCode::query()->latest('id')->first()->attempts);
    }

    public function test_a_code_cannot_be_used_twice(): void
    {
        Mail::fake();
        $user = $this->athlete();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ]);

        $code = $this->capturedCode();

        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email', 'destination' => $user->email, 'code' => $code, 'purpose' => 'login',
        ])->assertOk();

        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email', 'destination' => $user->email, 'code' => $code, 'purpose' => 'login',
        ])->assertStatus(422);
    }

    public function test_issuing_a_new_code_burns_the_previous_one(): void
    {
        Mail::fake();
        config(['sportx.otp.resend_cooldown_seconds' => 60]);

        $user = $this->athlete();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ]);
        $firstCode = $this->capturedCode();

        // Move past the resend cooldown rather than zeroing it — `created_at`
        // has one-second granularity, so a zero cooldown sits on a boundary.
        $this->travel(61)->seconds();

        // A fresh issue supersedes the old code even inside its expiry window.
        $this->postJson('/api/v1/auth/resend-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ])->assertOk();

        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email', 'destination' => $user->email, 'code' => $firstCode, 'purpose' => 'login',
        ])->assertStatus(422);

        // ...and the newer code still works, proving the burn is targeted
        // rather than invalidating the whole destination.
        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email', 'destination' => $user->email, 'code' => $this->capturedCode(), 'purpose' => 'login',
        ])->assertOk();
    }

    public function test_purpose_is_scoped_so_codes_are_not_interchangeable(): void
    {
        Mail::fake();
        $user = $this->athlete();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ]);
        $loginCode = $this->capturedCode();

        // A login code must not authenticate a password reset.
        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email', 'destination' => $user->email,
            'code' => $loginCode, 'purpose' => 'reset_password',
        ])->assertStatus(422);
    }

    public function test_expired_code_is_rejected(): void
    {
        Mail::fake();
        $user = $this->athlete();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ]);
        $code = $this->capturedCode();

        OtpCode::query()->latest('id')->first()->update(['expires_at' => now()->subMinute()]);

        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email', 'destination' => $user->email, 'code' => $code, 'purpose' => 'login',
        ])->assertStatus(422);
    }

    /* ---------------------------------------------------------------------
     | signup through OTP
     | ------------------------------------------------------------------ */

    public function test_signup_verification_creates_the_account(): void
    {
        Mail::fake();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => 'newcomer@sportx.test', 'purpose' => 'signup',
        ])->assertOk();

        $response = $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email',
            'destination' => 'newcomer@sportx.test',
            'code' => $this->capturedCode(),
            'purpose' => 'signup',
            'name' => 'New Comer',
            'role' => 'athlete',
            'password' => 'secret123',
        ]);

        $response->assertOk()->assertJsonPath('user.email', 'newcomer@sportx.test');

        $user = User::where('email', 'newcomer@sportx.test')->firstOrFail();

        $this->assertSame('athlete', $user->role);
        // The code proved control of the address, so it counts as verified.
        $this->assertNotNull($user->email_verified_at);
        $this->assertTrue(Hash::check('secret123', $user->password));
    }

    public function test_coach_signup_starts_pending_awaiting_approval(): void
    {
        Mail::fake();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => 'coach@sportx.test', 'purpose' => 'signup',
        ]);

        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email',
            'destination' => 'coach@sportx.test',
            'code' => $this->capturedCode(),
            'purpose' => 'signup',
            'name' => 'Sarah Coach',
            'role' => 'coach',
            'password' => 'secret123',
        ])->assertOk()->assertJsonPath('pending_approval', true);

        $this->assertSame('pending', User::where('email', 'coach@sportx.test')->firstOrFail()->status);
    }

    public function test_signup_verification_requires_name_role_and_password(): void
    {
        Mail::fake();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => 'newcomer@sportx.test', 'purpose' => 'signup',
        ]);

        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email',
            'destination' => 'newcomer@sportx.test',
            'code' => $this->capturedCode(),
            'purpose' => 'signup',
        ])->assertStatus(422);
    }

    public function test_signup_verification_rejects_a_role_outside_the_set(): void
    {
        Mail::fake();

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => 'newcomer@sportx.test', 'purpose' => 'signup',
        ]);

        $this->postJson('/api/v1/auth/verify-otp', [
            'channel' => 'email',
            'destination' => 'newcomer@sportx.test',
            'code' => $this->capturedCode(),
            'purpose' => 'signup',
            'name' => 'New Comer',
            'role' => 'superuser',
            'password' => 'secret123',
        ])->assertStatus(422);
    }

    /* ---------------------------------------------------------------------
     | throttling
     | ------------------------------------------------------------------ */

    public function test_send_otp_is_throttled_per_destination(): void
    {
        Mail::fake();
        $user = $this->athlete();
        config(['sportx.otp.resend_cooldown_seconds' => 300]);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/auth/send-otp', [
                'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
            ])->assertOk();
        }

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ])->assertStatus(429);
    }

    public function test_resend_respects_the_cooldown_window(): void
    {
        Mail::fake();
        $user = $this->athlete();
        config(['sportx.otp.resend_cooldown_seconds' => 300]);

        $this->postJson('/api/v1/auth/send-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ])->assertOk();

        $this->postJson('/api/v1/auth/resend-otp', [
            'channel' => 'email', 'destination' => $user->email, 'purpose' => 'login',
        ])->assertStatus(429);
    }
}