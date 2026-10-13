<?php

namespace Tests\Feature;

use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\GuardianConsent;
use App\Models\OtpCode;
use App\Models\User;
use App\Services\GuardianConsentService;
use App\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
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

    public function test_requesting_consent_reports_channel_unavailable_without_an_sms_vendor(): void
    {
        // AS-60: phone OTP has no vendor, so the guardian code cannot be sent.
        // The endpoint must say so rather than record an unverifiable consent.
        $athlete = $this->athlete();

        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/consent', [
                'guardian_name' => 'Suresh Mehta',
                'guardian_phone' => '919876543210',
                'relationship' => 'parent',
            ])
            ->assertStatus(503)
            ->assertJsonPath('error.code', 'CHANNEL_UNAVAILABLE');
    }

    public function test_consent_requires_a_valid_relationship(): void
    {
        $athlete = $this->athlete();

        $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/consent', [
                'guardian_name' => 'Suresh Mehta',
                'guardian_phone' => '919876543210',
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
        $athlete = $this->athlete();

        $consent = GuardianConsent::create([
            'athlete_user_id' => $athlete->id,
            'guardian_name' => 'Suresh Mehta',
            'guardian_phone' => '919876543210',
            'relationship' => 'parent',
            'consent_status' => GuardianConsent::STATUS_PENDING,
        ]);

        // Seed a valid code directly, standing in for the SMS that AS-60 blocks.
        $code = '482913';
        $otp = OtpCode::create([
            'user_id' => $athlete->id,
            'channel' => 'phone',
            'destination' => '919876543210',
            'code_hash' => Hash::make($code),
            'purpose' => OtpCode::PURPOSE_GUARDIAN_CONSENT,
            'expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->actingAs($athlete, 'sanctum')
            ->postJson('/api/v1/guardian/verify-otp', ['code' => $code]);

        $response->assertOk()->assertJsonPath('data.consent_status', 'verified');

        $this->assertSame('verified', $consent->refresh()->consent_status);
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
            'guardian_phone' => '919876543210',
            'relationship' => 'parent',
        ]);

        OtpCode::create([
            'user_id' => $athlete->id,
            'channel' => 'phone',
            'destination' => '919876543210',
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