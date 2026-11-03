<?php

namespace Tests\Feature;

use App\Mail\EmailOtpMail;
use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\GuardianConsent;
use App\Models\OtpCode;
use App\Models\User;
use App\Services\GuardianConsentService;
use App\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

/**
 * @see \App\Http\Controllers\GuardianController
 * @see \App\Services\GuardianConsentService
 */
class GuardianConsentTest extends TestCase
{
    use RefreshDatabase;

    protected function athlete(string $dob = '2012-05-01'): User
    {
        $user = User::create([
            'role' => 'athlete',
            'name' => 'Young Athlete',
            'email' => 'minor@sportx.test',
            'password' => Hash::make('password'),
            'email_verified_at' => now(),
            // Minors start gated until a guardian is verified.
            'status' => 'pending',
        ]);

        $ageGroup = AgeGroup::firstOrCreate(
            ['name' => 'Under-18', 'min_age' => 16, 'max_age' => 18],
        );

        AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Young Athlete',
            'date_of_birth' => $dob,
            'gender' => 'male',
            'skill_level' => 'intermediate',
            // NOT NULL with no default — see Database-Design.md §4.
            'age_group_id' => $ageGroup->id,
        ]);

        return $user->refresh();
    }

    /**
     * Read the plaintext code from the queued mailable — the stored hash is
     * bcrypt by design, so a round-trip test captures the code where the mailer
     * receives it (same pattern as OtpTest).
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

    /* ---------------------------------------------------------------------
     | age gate
     | ------------------------------------------------------------------ */

    public function test_under_18_is_treated_as_a_minor(): void
    {
        $service = app(GuardianConsentService::class);

        $this->assertTrue($service->isMinor('2012-05-01'));
        $this->assertFalse($service->isMinor('1995-05-01'));
        $this->assertFalse($service->isMinor(null));
    }

    public function test_a_minor_without_consent_is_not_publicly_visible(): void
    {
        $athlete = $this->athlete();
        $service = app(GuardianConsentService::class);

        $this->assertFalse($service->allowsPublicProfile($athlete));
    }

    public function test_an_adult_is_unaffected_by_the_gate(): void
    {
        $adult = $this->athlete('1995-05-01');

        $service = app(GuardianConsentService::class);

        $this->assertFalse($service->isMinor($adult->athleteProfile->date_of_birth));
        $this->assertTrue($service->allowsPublicProfile($adult));
        $this->assertTrue($service->allowsMessages($adult));
        $this->assertSame('full_name', $service->leaderboardNameMode($adult));
    }

    /* ---------------------------------------------------------------------
     | consent flow
     | ------------------------------------------------------------------ */

    public function test_requesting_consent_emails_the_guardian_and_records_a_pending_consent(): void
    {
        Mail::fake();

        $athlete = $this->athlete();

        $response = $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/consent', [
                'guardian_name' => 'Suresh Mehta',
                'guardian_email' => 'guardian@sportx.test',
                'relationship' => 'parent',
            ]);

        $response->assertCreated()
            ->assertJsonPath('data.consent_status', 'pending')
            ->assertJsonPath('data.guardian_email', 'guardian@sportx.test');

        $consent = $athlete->guardianConsents()->firstOrFail();
        $this->assertSame('pending', $consent->consent_status);
        $this->assertSame('otp', $consent->verification_method);

        // The code is emailed to the guardian, never to the athlete.
        Mail::assertQueued(EmailOtpMail::class, fn (EmailOtpMail $mail) =>
            $mail->hasTo('guardian@sportx.test'));
    }

    public function test_an_athlete_cannot_nominate_their_own_email_as_guardian(): void
    {
        Mail::fake();

        $athlete = $this->athlete();

        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/consent', [
                'guardian_name' => 'Suresh Mehta',
                'guardian_email' => 'minor@sportx.test',
                'relationship' => 'parent',
            ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'GUARDIAN_EMAIL_INVALID');

        // Fail-closed: no consent row and no email may be recorded.
        $this->assertSame(0, $athlete->guardianConsents()->count());
        Mail::assertNothingQueued();
    }

    public function test_consent_requires_a_valid_relationship(): void
    {
        $athlete = $this->athlete();

        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/consent', [
                'guardian_name' => 'Suresh Mehta',
                'guardian_email' => 'guardian@sportx.test',
                'relationship' => 'stalker',
            ])
            ->assertStatus(422);
    }

    public function test_only_athlete_accounts_can_request_consent(): void
    {
        $coach = User::create([
            'role' => 'coach', 'name' => 'Coach', 'email' => 'coach@sportx.test',
            'password' => Hash::make('password'), 'status' => 'active',
        ]);

        $this->actingAs($coach, 'sanctum')
            ->postJson('/api/v1/guardian/consent', [
                'guardian_name' => 'X', 'guardian_phone' => '919876543210', 'relationship' => 'parent',
            ])
            ->assertStatus(403);
    }

    /* ---------------------------------------------------------------------
     | verification (driven directly so the AS-60 blocker does not gate it)
     | ------------------------------------------------------------------ */

    public function test_verifying_the_guardian_code_activates_consent(): void
    {
        Mail::fake();

        $athlete = $this->athlete();

        // Request through the endpoint so the code is the one actually emailed.
        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/consent', [
                'guardian_name' => 'Suresh Mehta',
                'guardian_email' => 'guardian@sportx.test',
                'relationship' => 'parent',
            ])->assertCreated();

        $code = $this->capturedCode();

        $response = $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/verify-otp', ['code' => $code]);

        $response->assertOk()->assertJsonPath('data.consent_status', 'verified');

        $consent = $athlete->guardianConsents()->firstOrFail();
        $this->assertSame('verified', $consent->consent_status);
        $this->assertNotNull($consent->verified_at);

        // Consent activates the account.
        $this->assertSame('active', $athlete->refresh()->status);
    }

    public function test_a_wrong_guardian_code_is_rejected(): void
    {
        $athlete = $this->athlete();

        GuardianConsent::create([
            'athlete_user_id' => $athlete->id,
            'guardian_name' => 'Suresh Mehta',
            'guardian_email' => 'guardian@sportx.test',
            'relationship' => 'parent',
            'consent_status' => GuardianConsent::STATUS_PENDING,
        ]);

        OtpCode::create([
            'user_id' => $athlete->id,
            'channel' => 'email',
            'destination' => 'guardian@sportx.test',
            'code_hash' => Hash::make('482913'),
            'purpose' => OtpCode::PURPOSE_GUARDIAN_CONSENT,
            'expires_at' => now()->addMinutes(10),
        ]);

        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/verify-otp', ['code' => '000000'])
            ->assertStatus(422);

        $this->assertSame('pending', $athlete->guardianConsents()->firstOrFail()->consent_status);
    }

    public function test_verifying_without_a_pending_consent_is_refused(): void
    {
        $athlete = $this->athlete();

        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/verify-otp', ['code' => '482913'])
            ->assertStatus(422);
    }

    /* ---------------------------------------------------------------------
     | resend
     | ------------------------------------------------------------------ */

    public function test_the_confirmation_email_can_be_resent(): void
    {
        Mail::fake();

        $athlete = $this->athlete();

        GuardianConsent::create([
            'athlete_user_id' => $athlete->id,
            'guardian_name' => 'Suresh Mehta',
            'guardian_email' => 'guardian@sportx.test',
            'relationship' => 'parent',
            'consent_status' => GuardianConsent::STATUS_PENDING,
        ]);

        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/resend')
            ->assertOk()
            ->assertJsonPath('data.message', 'Confirmation email re-sent to the guardian.');

        Mail::assertQueued(EmailOtpMail::class, fn (EmailOtpMail $mail) =>
            $mail->hasTo('guardian@sportx.test'));
    }

    public function test_resend_is_rate_limited_by_the_cooldown(): void
    {
        Mail::fake();

        $athlete = $this->athlete();

        GuardianConsent::create([
            'athlete_user_id' => $athlete->id,
            'guardian_name' => 'Suresh Mehta',
            'guardian_email' => 'guardian@sportx.test',
            'relationship' => 'parent',
            'consent_status' => GuardianConsent::STATUS_PENDING,
        ]);

        $this->actingAs($athlete, 'sanctum')->postJson('/api/v1/guardian/resend')->assertOk();

        // OtpService::resend() aborts 429 inside the 60s cooldown; the
        // controller maps it to RESEND_COOLDOWN.
        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/resend')
            ->assertStatus(429)
            ->assertJsonPath('error.code', 'RESEND_COOLDOWN');
    }

    public function test_resend_requires_a_pending_consent(): void
    {
        Mail::fake();

        $athlete = $this->athlete();

        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/resend')
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'NO_PENDING_CONSENT');

        Mail::assertNothingQueued();
    }

    /* ---------------------------------------------------------------------
     | controls
     | ------------------------------------------------------------------ */

    public function test_guardian_controls_reflect_a_restricted_minor(): void
    {
        $athlete = $this->athlete();

        $response = $this->actingAs($athlete, 'sanctum')->getJson('/api/v1/me/guardian-controls');

        $response->assertOk()
            ->assertJsonPath('data.is_minor', true)
            ->assertJsonPath('data.consent_status', null)
            ->assertJsonPath('data.allow_public_profile', false)
            ->assertJsonPath('data.leaderboard_name_mode', 'first_name_initial');
    }

    public function test_consent_defaults_stay_restricted_after_verification(): void
    {
        $athlete = $this->athlete();

        GuardianConsent::create([
            'athlete_user_id' => $athlete->id,
            'guardian_name' => 'Suresh Mehta',
            'guardian_phone' => '919876543210',
            'relationship' => 'parent',
            'consent_status' => GuardianConsent::STATUS_VERIFIED,
            'verified_at' => now(),
        ]);

        $this->actingAs($athlete, 'sanctum')->getJson('/api/v1/me/guardian-controls')
            ->assertOk()
            // Verified consent must not silently expose the profile.
            ->assertJsonPath('data.allow_public_profile', false)
            ->assertJsonPath('data.consent_status', 'verified');
    }

    public function test_controls_cannot_be_changed_before_consent_is_verified(): void
    {
        $athlete = $this->athlete();

        $this->actingAs($athlete, 'sanctum')
            ->putJson('/api/v1/me/guardian-controls', ['allow_public_profile' => true])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'NO_VERIFIED_CONSENT');
    }

    public function test_controls_can_be_changed_after_verification(): void
    {
        $athlete = $this->athlete();

        GuardianConsent::create([
            'athlete_user_id' => $athlete->id,
            'guardian_name' => 'Suresh Mehta',
            'guardian_phone' => '919876543210',
            'relationship' => 'parent',
            'consent_status' => GuardianConsent::STATUS_VERIFIED,
            'verified_at' => now(),
        ]);

        $this->actingAs($athlete, 'sanctum')
            ->putJson('/api/v1/me/guardian-controls', [
                'allow_public_profile' => true,
                'leaderboard_name_mode' => 'hidden',
            ])
            ->assertOk()
            ->assertJsonPath('data.allow_public_profile', true)
            ->assertJsonPath('data.leaderboard_name_mode', 'hidden');
    }

    public function test_revoking_consent_restores_restricted_defaults(): void
    {
        $athlete = $this->athlete();

        GuardianConsent::create([
            'athlete_user_id' => $athlete->id,
            'guardian_name' => 'Suresh Mehta',
            'guardian_phone' => '919876543210',
            'relationship' => 'parent',
            'consent_status' => GuardianConsent::STATUS_VERIFIED,
            'allow_public_profile' => true,
            'verified_at' => now(),
        ]);

        $this->actingAs($athlete, 'sanctum')
            ->deleteJson('/api/v1/me/guardian-consent')
            ->assertOk();

        $service = app(GuardianConsentService::class);

        $this->assertNull($service->activeFor($athlete));
        $this->assertFalse($service->allowsPublicProfile($athlete));
    }

    public function test_guardian_controls_require_authentication(): void
    {
        $this->getJson('/api/v1/me/guardian-controls')->assertStatus(401);
    }
}