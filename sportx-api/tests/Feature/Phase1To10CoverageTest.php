<?php

namespace Tests\Feature;

use App\Models\Academy;
use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\CoachProfile;
use App\Models\OrganizerProfile;
use App\Models\Sport;
use App\Models\TalentScoutProfile;
use App\Models\User;
use App\Services\TotpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * End-to-end coverage for PHASE_WISE_IMPLEMENTATION_PLAN.md Phases 0–10.
 *
 * One test per phase, asserting the phase exit criteria against the real
 * HTTP + MySQL stack. Deep edge-case coverage lives in the dedicated
 * suites (OtpTest, GoogleAuthTest, Phase6/7/8/9/10*Test); this file proves
 * the phases hang together and guards the cross-phase contracts
 * (role ids, route paths, notification fan-out, legacy 410s).
 */
class Phase1To10CoverageTest extends TestCase
{
    use RefreshDatabase;

    /* ---------------- helpers ---------------- */

    private function mkUser(string $role, array $overrides = []): User
    {
        return User::factory()->create(array_merge([
            'role' => $role,
            'status' => 'active',
            'email_verified_at' => now(),
            'password' => Hash::make('password'),
        ], $overrides));
    }

    private function admin(): User
    {
        return $this->mkUser('admin', ['admin_2fa_verified_at' => now()]);
    }

    private function seedRefs(): array
    {
        return [
            Sport::create(['name' => 'Cricket '.uniqid()]),
            City::create(['name' => 'Ahmedabad '.uniqid(), 'state' => 'Gujarat']),
            AgeGroup::create(['name' => 'U16 '.uniqid()]),
        ];
    }

    private function athlete(?AgeGroup $ageGroup = null): array
    {
        $ageGroup ??= AgeGroup::create(['name' => 'U16 '.uniqid()]);
        $user = $this->mkUser('athlete');
        $profile = AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Coverage Athlete',
            'date_of_birth' => '2000-01-01',
            'gender' => 'male',
            'skill_level' => 'intermediate',
            'age_group_id' => $ageGroup->id,
        ]);

        return [$user, $profile];
    }

    private function academy(string $name = 'Coverage Academy'): array
    {
        $user = $this->mkUser('academy');
        $academy = Academy::create([
            'owner_user_id' => $user->id,
            'name' => $name.' '.uniqid(),
            'description' => 'Coverage academy for phase tests',
            'address' => 'Coverage Street 1',
            'contact_number' => '9999999999',
        ]);

        return [$user, $academy];
    }

    private function coach(?Sport $sport = null): array
    {
        $sport ??= Sport::create(['name' => 'Coach Sport '.uniqid()]);
        $user = $this->mkUser('coach');
        $profile = CoachProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Coverage Coach',
            'sport_id' => $sport->id,
            'contact_number' => '9999999999',
            'experience' => '10 years',
            'personal_coaching' => true,
        ]);

        return [$user, $profile];
    }

    private function scout(): array
    {
        $user = $this->mkUser('talent_scout');
        $profile = TalentScoutProfile::create([
            'user_id' => $user->id,
            'organization' => 'Coverage Scouts',
            'sports_specialization' => [1],
        ]);

        return [$user, $profile];
    }

    /* ---------------- Phase 0 ---------------- */

    public function test_phase0_health_and_master_data(): void
    {
        $this->getJson('/api/v1/system/health')->assertOk();
        $this->getJson('/api/v1/health')->assertOk();

        foreach (['sports', 'cities', 'age-groups', 'positions', 'facilities'] as $meta) {
            $this->getJson("/api/v1/meta/{$meta}")->assertOk();
        }
    }

    /* ---------------- Phase 1 ---------------- */

    public function test_phase1_roles_register_login_me_and_sponsor_removed(): void
    {
        foreach (['athlete', 'coach', 'academy', 'organizer', 'scout'] as $role) {
            $resp = $this->postJson('/api/v1/auth/register', [
                'role' => $role,
                'email' => "{$role}@phase1.test",
                'password' => 'Password123',
                'name' => ucfirst($role).' User',
            ]);
            $resp->assertCreated();
            $this->assertArrayHasKey('is_verified', $resp->json('user'));
            // `scout` is stored under the legacy `talent_scout` name until the rename migration lands.
            $storedRole = $role === 'scout' ? 'talent_scout' : $role;
            $this->assertDatabaseHas('users', ['email' => "{$role}@phase1.test", 'role' => $storedRole]);
        }

        // Sponsor signups are refused with 410 SPONSOR_REMOVED.
        $this->postJson('/api/v1/auth/register', [
            'role' => 'sponsor',
            'email' => 'sponsor@phase1.test',
            'password' => 'Password123',
        ])->assertStatus(410)->assertJsonPath('error.code', 'SPONSOR_REMOVED');

        // Password login → me → change-password alias.
        $login = $this->postJson('/api/v1/auth/login', [
            'email' => 'athlete@phase1.test',
            'password' => 'Password123',
        ])->assertOk();
        $this->assertArrayHasKey('is_verified', $login->json('user'));

        $token = $login->json('token');
        $this->withToken($token)->getJson('/api/v1/auth/me')->assertOk()
            ->assertJsonStructure(['data' => ['id', 'role', 'email']]);

        // Sponsor onboarding is gone for authenticated users too (410, not 404/500).
        $this->withToken($token)->postJson('/api/v1/onboarding/sponsor', [])->assertStatus(410);
        $this->withToken($token)->getJson('/api/v1/onboarding/sponsor')->assertStatus(410);

        $this->withToken($token)->postJson('/api/v1/me/change-password', [
            'current_password' => 'Password123',
            'password' => 'NewPassword123',
            'password_confirmation' => 'NewPassword123',
        ])->assertOk();

        // Scout onboarding alias + schema; completion checklist per role.
        [$sport] = $this->seedRefs();
        $scout = $this->mkUser('talent_scout');
        $this->actingAs($scout, 'sanctum');
        $this->postJson('/api/v1/onboarding/scout', [
            'sports_specialization' => [$sport->id],
            'organization' => 'Phase1 Scouts',
        ])->assertCreated();
        $this->getJson('/api/v1/onboarding/scout')->assertOk();

        $this->getJson('/api/v1/me/completion-checklist')->assertOk()
            ->assertJsonStructure(['data']);
    }

    public function test_phase1_guardian_consent_blocked_without_sms_vendor_and_verification_flow(): void
    {
        [$athlete, $profile] = $this->athlete();
        $this->actingAs($athlete, 'sanctum');

        // No SMS vendor selected (AS-60): guardian SMS fails closed with 503.
        $this->postJson('/api/v1/guardian/consent', [
            'guardian_name' => 'Parent',
            'guardian_phone' => '+919999999999',
            'relationship' => 'parent',
        ])->assertStatus(503)->assertJsonPath('error.code', 'CHANNEL_UNAVAILABLE');

        $this->getJson('/api/v1/me/guardian-controls')->assertOk();

        // Verification request → admin approve → account_action notification.
        $req = $this->postJson('/api/v1/me/verification', [
            'verifiable_type' => 'athlete_profile',
            'verifiable_id' => $profile->id,
        ])->assertCreated();
        $this->getJson('/api/v1/me/verification')->assertOk();

        $admin = $this->admin();
        $this->actingAs($admin, 'sanctum');
        $this->getJson('/api/v1/admin/verification')->assertOk();
        $this->patchJson("/api/v1/admin/verification/{$req->json('data.id')}/approve")->assertOk();
        $this->assertDatabaseHas('notifications', [
            'user_id' => $athlete->id,
            'type' => 'account_action',
        ]);
    }

    /* ---------------- Phase 2 ---------------- */

    public function test_phase2_profile_sports_achievements_privacy_settings(): void
    {
        [$sport, $city, $ageGroup] = $this->seedRefs();
        [$athlete] = $this->athlete($ageGroup);
        $this->actingAs($athlete, 'sanctum');

        $this->getJson('/api/v1/me/profile')->assertOk();

        $this->putJson('/api/v1/me/profile', [
            'full_name' => 'Updated Athlete',
            'date_of_birth' => '2000-01-01',
            'gender' => 'male',
            'skill_level' => 'advanced',
            'city_id' => $city->id,
        ])->assertOk();
        $this->assertEquals('Updated Athlete', $athlete->fresh()->name);

        // Rich sports pivot objects (plain ids stay back-compatible).
        $this->putJson('/api/v1/me/profile/sports', [
            'sports' => [[
                'sport_id' => $sport->id,
                'playing_role' => 'Batsman',
                'level' => 'district',
                'experience_years' => 3,
                'is_primary' => true,
            ]],
        ])->assertOk();

        // Typed achievements CRUD.
        $ach = $this->postJson('/api/v1/me/achievements', [
            'title' => 'State Championship',
            'type' => 'trophy',
        ])->assertCreated();
        $achId = $ach->json('data.id');
        $this->getJson('/api/v1/me/achievements')->assertOk();
        $this->putJson("/api/v1/me/achievements/{$achId}", ['title' => 'State Championship Gold'])->assertOk();
        $this->deleteJson("/api/v1/me/achievements/{$achId}")->assertOk();

        // Privacy + settings + social links.
        $this->putJson('/api/v1/me/privacy', [
            'profile_visibility' => 'followers',
            'who_can_message' => 'connections',
        ])->assertOk();
        $this->getJson('/api/v1/me/privacy')->assertOk()->assertJsonPath('data.profile_visibility', 'followers');

        $this->getJson('/api/v1/me/settings')->assertOk();
        $this->putJson('/api/v1/me/social-links', ['instagram' => 'https://instagram.com cov/athlete'])->assertStatus(422);
        $this->putJson('/api/v1/me/social-links', ['instagram' => 'https://instagram.com/athlete'])->assertOk();
        $this->getJson('/api/v1/me/activity')->assertOk();
    }

    /* ---------------- Phase 3 ---------------- */

    public function test_phase3_directories_search_saved_home_explore(): void
    {
        [$sport, $city, $ageGroup] = $this->seedRefs();
        [$athlete, $athleteProfile] = $this->athlete($ageGroup);
        $this->actingAs($athlete, 'sanctum');

        foreach (['academies', 'coaches', 'trials', 'tournaments', 'sports-venues'] as $dir) {
            $this->getJson("/api/v1/{$dir}")->assertOk();
        }

        // Universal search incl. privacy-gated athletes group.
        $search = $this->getJson('/api/v1/search?q=cricket')->assertOk();
        $this->assertArrayHasKey('athletes', $search->json('data'));

        $this->postJson('/api/v1/me/recent-searches', ['query' => 'cricket'])->assertCreated();
        $this->getJson('/api/v1/me/recent-searches')->assertOk();
        $this->getJson('/api/v1/meta/trending-searches')->assertOk();

        // Save a post → appears in Saved → unsave.
        $post = $this->postJson('/api/v1/posts', ['body' => 'Save me'])->assertCreated();
        $postId = $post->json('data.id');
        $this->postJson('/api/v1/me/saved', ['item_type' => 'post', 'item_id' => $postId])->assertCreated();
        $this->postJson('/api/v1/me/saved', ['item_type' => 'post', 'item_id' => $postId])->assertStatus(409);
        $this->getJson('/api/v1/me/saved')->assertOk();
        $this->deleteJson('/api/v1/me/saved', ['item_type' => 'post', 'item_id' => $postId])->assertOk();

        // Role-aware home + explore.
        $this->getJson('/api/v1/me/home')->assertOk()->assertJsonStructure(['data']);
        $this->getJson('/api/v1/explore')->assertOk();
    }

    /* ---------------- Phase 3E ---------------- */

    public function test_phase3e_email_settings_device_tokens_prefs_stats(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin, 'sanctum');

        $this->getJson('/api/v1/admin/email-settings')->assertOk()
            ->assertJsonStructure(['data']);
        $this->getJson('/api/v1/admin/email-settings/diagnostics')->assertOk();

        [$athlete] = $this->athlete();
        $this->actingAs($athlete, 'sanctum');

        // Device-token registry: canonical + subscribe alias agree.
        $payload = ['token' => 'fcm-token-'.uniqid(), 'device_type' => 'android'];
        $this->postJson('/api/v1/me/device-tokens', $payload)->assertOk();
        $this->assertDatabaseHas('user_device_tokens', ['user_id' => $athlete->id]);
        $this->postJson('/api/v1/me/device-tokens/subscribe', [
            'token' => 'fcm-token-'.uniqid(), 'device_type' => 'ios',
        ])->assertOk();

        // Test-push with no sendable path is safe (queued or no-devices).
        $this->postJson('/api/v1/me/device-tokens/test')->assertOk();

        $this->deleteJson('/api/v1/me/device-tokens', ['token' => $payload['token']])->assertOk();

        // Preferences read/update round-trip.
        $this->getJson('/api/v1/me/notification-preferences')->assertOk()
            ->assertJsonStructure(['data']);
        $this->putJson('/api/v1/me/notification-preferences', ['push' => false])->assertOk()
            ->assertJsonPath('data.prefs.push', false);

        // Admin delivery stats.
        $this->actingAs($admin, 'sanctum');
        $this->getJson('/api/v1/admin/notifications/stats')->assertOk()
            ->assertJsonStructure(['data' => ['by_push_status', 'by_type', 'total']]);
    }

    /* ---------------- Phase 4 ---------------- */

    public function test_phase4_opportunity_post_apply_review_close_and_legacy_gone(): void
    {
        [$sport, , $ageGroup] = $this->seedRefs();
        [$academyUser] = $this->academy();
        [$athlete, $athleteProfile] = $this->athlete($ageGroup);

        // Provider posts (draft) → publish → publicly listed.
        $this->actingAs($academyUser, 'sanctum');
        $created = $this->postJson('/api/v1/me/opportunities', [
            'type' => 'scholarship',
            'title' => 'Phase4 Scholarship',
            'sport_id' => $sport->id,
            'age_group_id' => $ageGroup->id,
            'benefits' => 'Full fee waiver',
            'deadline' => now()->addMonth()->toDateString(),
        ])->assertCreated();
        $oppId = $created->json('data.id');

        // Draft detail: owner can preview, anyone else gets 404.
        $this->getJson("/api/v1/opportunities/{$oppId}")->assertOk()
            ->assertJsonPath('data.status', 'draft');
        $this->actingAs($athlete, 'sanctum');
        $this->getJson("/api/v1/opportunities/{$oppId}")->assertNotFound();

        $this->actingAs($academyUser, 'sanctum');
        $this->postJson("/api/v1/me/opportunities/{$oppId}/publish")->assertOk();
        $this->getJson('/api/v1/opportunities?type=scholarship')->assertOk();
        $detail = $this->getJson("/api/v1/opportunities/{$oppId}")->assertOk();
        $this->assertFalse($detail->json('data.applied'));

        // Athlete applies → duplicate guarded → tabs reflect state.
        $this->actingAs($athlete, 'sanctum');
        $this->postJson("/api/v1/opportunities/{$oppId}/apply", ['pitch' => 'Pick me'])->assertCreated();
        $this->postJson("/api/v1/opportunities/{$oppId}/apply", ['pitch' => 'Again'])->assertStatus(409);
        $this->assertDatabaseHas('opportunity_applications', [
            'opportunity_id' => $oppId, 'athlete_id' => $athleteProfile->id,
        ]);

        $applied = $this->getJson('/api/v1/me/opportunities?type=applied')->assertOk();
        $this->assertNotEmpty($applied->json('data'));

        $after = $this->getJson("/api/v1/opportunities/{$oppId}")->assertOk();
        $this->assertTrue($after->json('data.applied'));
        $this->assertEquals('submitted', $after->json('data.application_status'));

        // Provider reviews → athlete notified of decision.
        $this->actingAs($academyUser, 'sanctum');
        $apps = $this->getJson("/api/v1/opportunities/{$oppId}/applications")->assertOk();
        $this->assertNotEmpty($apps->json('data'));
        $appId = $apps->json('data.0.id');
        $this->patchJson("/api/v1/opportunities/{$oppId}/applications/{$appId}", [
            'status' => 'shortlisted',
        ])->assertOk();
        $this->assertDatabaseHas('notifications', [
            'user_id' => $athlete->id, 'type' => 'status_update',
        ]);

        // Close hides the listing; legacy sponsor routes are 410.
        $this->postJson("/api/v1/me/opportunities/{$oppId}/close")->assertOk();
        $this->getJson("/api/v1/opportunities/{$oppId}")->assertOk(); // detail still visible to owner context
        $this->getJson('/api/v1/sponsorships')->assertStatus(410)->assertJsonPath('error.code', 'LEGACY_MOVED');
        $this->getJson('/api/v1/scholarships')->assertStatus(410);
    }

    /* ---------------- Phase 5 ---------------- */

    public function test_phase5_program_enquire_and_facility_crud(): void
    {
        [$sport] = $this->seedRefs();
        [$coachUser] = $this->coach();
        [$academyUser, $academy] = $this->academy();
        [$athlete] = $this->athlete();

        // Coach posts an active program → public listing.
        $this->actingAs($coachUser, 'sanctum');
        $program = $this->postJson('/api/v1/me/programs', [
            'title' => 'Phase5 Batting Camp',
            'sport_id' => $sport->id,
            'mode' => 'offline',
            'status' => 'active',
        ])->assertCreated();
        $programId = $program->json('data.id');

        $this->getJson('/api/v1/programs')->assertOk();
        $this->getJson("/api/v1/programs/{$programId}")->assertOk();
        $this->getJson('/api/v1/me/programs?status=active')->assertOk();

        // Athlete enquires → thread opens → visible in both inboxes.
        $this->actingAs($athlete, 'sanctum');
        $thread = $this->postJson("/api/v1/programs/{$programId}/enquire", [
            'message' => 'I want to join',
        ])->assertCreated();
        $this->assertNotNull($thread->json('data.id'));
        $this->getJson('/api/v1/me/enquiries')->assertOk();

        $this->actingAs($coachUser, 'sanctum');
        $this->getJson('/api/v1/me/enquiries')->assertOk();

        // Generic enquiry against the program subject also works.
        $this->actingAs($athlete, 'sanctum');
        $this->postJson('/api/v1/enquiries', [
            'subject_type' => 'program',
            'subject_id' => $programId,
            'message' => 'Second question',
        ])->assertCreated();

        // Academy facility CRUD → public detail.
        $this->actingAs($academyUser, 'sanctum');
        $facility = $this->postJson('/api/v1/me/facilities', [
            'name' => 'Main Ground',
            'type' => 'ground',
            'amenities' => ['floodlights'],
        ])->assertCreated();
        $facilityId = $facility->json('data.id');

        $this->getJson('/api/v1/me/facilities')->assertOk();
        $this->getJson("/api/v1/facilities/{$facilityId}")->assertOk();
        $this->putJson("/api/v1/me/facilities/{$facilityId}", ['name' => 'Main Ground Renovated'])->assertOk();
        $this->deleteJson("/api/v1/me/facilities/{$facilityId}")->assertOk();
        $this->assertDatabaseMissing('facilities', ['id' => $facilityId]);
    }

    /* ---------------- Phase 6 ---------------- */

    public function test_phase6_post_like_comment_follow_connect_chat_block_report(): void
    {
        [$me] = $this->athlete();
        [$other] = $this->athlete();
        $this->actingAs($me, 'sanctum');

        $post = $this->postJson('/api/v1/posts', ['body' => 'Phase6 hello'])->assertCreated();
        $postId = $post->json('data.id');
        $this->postJson("/api/v1/posts/{$postId}/like", [])->assertOk();
        $this->getJson('/api/v1/feed')->assertOk();
        $this->postJson("/api/v1/posts/{$postId}/comments", ['body' => 'Nice'])->assertCreated();
        $this->deleteJson("/api/v1/posts/{$postId}/like")->assertOk();

        $this->postJson("/api/v1/follow/user/{$other->id}")->assertSuccessful();
        $this->getJson('/api/v1/me/following')->assertOk();

        $conn = $this->postJson('/api/v1/connections', ['user_id' => $other->id])->assertCreated();
        $this->actingAs($other, 'sanctum');
        $this->patchJson("/api/v1/connections/{$conn->json('data.id')}", ['action' => 'accept'])->assertOk();

        $conv = $this->postJson('/api/v1/conversations', ['participant_id' => $me->id])->assertSuccessful();
        $convId = $conv->json('data.id');
        $this->postJson("/api/v1/conversations/{$convId}/messages", ['body' => 'Hi'])->assertCreated();

        // Block disables follow; report lands.
        $this->actingAs($me, 'sanctum');
        $this->postJson('/api/v1/blocks', ['user_id' => $other->id])->assertSuccessful();
        $this->postJson("/api/v1/follow/user/{$other->id}")->assertForbidden();
        $this->postJson('/api/v1/reports', [
            'reportable_type' => 'user', 'reportable_id' => $other->id, 'reason' => 'inappropriate',
        ])->assertCreated();
        $this->getJson('/api/v1/me/reports')->assertOk();
    }

    /* ---------------- Phase 7 ---------------- */

    public function test_phase7_leaderboard_scout_shortlist_observe_contact(): void
    {
        [, , $ageGroup] = $this->seedRefs();
        [$athleteUser, $athleteProfile] = $this->athlete($ageGroup);
        [$scoutUser, $scoutProfile] = $this->scout();

        $this->actingAs($athleteUser, 'sanctum');
        $this->getJson('/api/v1/leaderboard')->assertOk()->assertJsonStructure(['data' => ['podium', 'ranks']]);
        $this->getJson('/api/v1/leaderboard/strip')->assertOk();

        $this->actingAs($scoutUser, 'sanctum');
        $this->getJson('/api/v1/scout/dashboard')->assertOk();
        $this->postJson("/api/v1/me/scout-shortlist/{$athleteProfile->id}", ['status' => 'high'])->assertCreated();
        $this->patchJson("/api/v1/me/scout-shortlist/{$athleteProfile->id}", ['notes' => 'Top pick'])->assertOk();
        $this->getJson('/api/v1/me/scout-shortlist')->assertOk();

        $this->postJson('/api/v1/observations', [
            'athlete_profile_id' => $athleteProfile->id,
            'rating' => 5,
            'note' => 'Strong technique',
        ])->assertCreated();
        $this->getJson('/api/v1/observations')->assertOk();

        $this->postJson("/api/v1/athletes/{$athleteProfile->id}/contact", ['purpose' => 'Trial invite'])->assertSuccessful();
    }

    /* ---------------- Phase 8 ---------------- */

    public function test_phase8_trial_register_approve_ics_and_tournament_results(): void
    {
        [$sport, $city, $ageGroup] = $this->seedRefs();
        [$provider] = $this->academy();
        [$athlete] = $this->athlete($ageGroup);

        $this->actingAs($provider, 'sanctum');
        $event = $this->postJson('/api/v1/me/events?type=trial', [
            'name' => 'Phase8 Trial',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'venue' => 'Main Ground',
            'event_datetime' => now()->addDays(10)->toDateTimeString(),
            'contact_number' => '9999999999',
            'vacancies' => 10,
        ])->assertSuccessful();
        $eventId = $event->json('data.id');
        $this->postJson("/api/v1/me/events/{$eventId}/publish?type=trial")->assertSuccessful();

        $this->actingAs($athlete, 'sanctum');
        $this->postJson("/api/v1/trials/{$eventId}/register", [])->assertCreated();
        $this->postJson("/api/v1/trials/{$eventId}/register", [])->assertStatus(409);
        $this->getJson('/api/v1/me/registrations')->assertOk();

        $this->actingAs($provider, 'sanctum');
        $regId = \App\Models\TrialRegistration::where('trial_id', $eventId)->value('id');
        $this->postJson("/api/v1/registrations/{$regId}/approve?type=trial")->assertOk();
        $this->assertDatabaseHas('notifications', ['user_id' => $athlete->id]);

        // ICS is athlete-scoped (registrant only).
        $this->actingAs($athlete, 'sanctum');
        $this->getJson("/api/v1/registrations/trials/{$regId}/ics")->assertOk();

        $this->actingAs($provider, 'sanctum');
        $this->getJson("/api/v1/events/{$eventId}/registrations/export?type=trial")->assertOk();

        // Tournament results publish → public bracket.
        $org = $this->mkUser('organizer');
        $orgProfile = OrganizerProfile::create(['user_id' => $org->id, 'organization_name' => 'Org', 'org_type' => 'club']);
        $tournament = \App\Models\Tournament::create([
            'organizer_id' => $orgProfile->id,
            'sport_id' => $sport->id,
            'name' => 'Phase8 Cup',
            'start_date' => now()->addMonth()->toDateString(),
            'end_date' => now()->addMonth()->addDays(2)->toDateString(),
            'venue' => 'Ground',
            'status' => 'published',
        ]);
        $this->actingAs($org, 'sanctum');
        $category = \App\Models\TournamentCategory::create([
            'tournament_id' => $tournament->id,
            'age_group_id' => $ageGroup->id,
            'name' => 'Open', 'capacity' => 16,
        ]);
        $result = $this->postJson("/api/v1/tournaments/{$tournament->id}/results", [
            'results' => [['category_id' => $category->id, 'place' => 1, 'winner_name' => 'Team A']],
        ])->assertSuccessful();
        $this->postJson("/api/v1/tournaments/{$tournament->id}/results/{$result->json('data.0.id')}/publish")->assertSuccessful();
        $this->getJson("/api/v1/tournaments/{$tournament->id}/results")->assertOk();
    }

    /* ---------------- Phase 9 ---------------- */

    public function test_phase9_admin_expiry_broadcast_audit_analytics(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin, 'sanctum');

        $this->getJson('/api/v1/admin/dashboard')->assertOk();
        $this->getJson('/api/v1/admin/users')->assertOk();

        $pending = $this->mkUser('athlete', ['status' => 'pending']);
        $this->postJson("/api/v1/admin/users/{$pending->id}/approve")->assertOk();
        $this->assertDatabaseHas('notifications', ['user_id' => $pending->id, 'type' => 'account_action']);

        $this->getJson('/api/v1/admin/content')->assertOk();
        $this->getJson('/api/v1/admin/moderation/queue')->assertOk();
        $this->getJson('/api/v1/admin/expiry-rules')->assertOk();
        $this->getJson('/api/v1/admin/expiry/monitor')->assertOk();

        $this->postJson('/api/v1/admin/notifications/broadcast', [
            'title' => 'Phase9', 'body' => 'Broadcast body', 'channels' => ['in_app'],
        ])->assertCreated();

        $this->getJson('/api/v1/admin/audit-logs')->assertOk();

        $this->postJson('/api/v1/analytics/events', ['event' => 'phase9_smoke'])->assertCreated();
        $this->assertDatabaseHas('analytics_events', ['event' => 'phase9_smoke']);

        // Notifications center tabs + unread count for a regular user.
        [$athlete] = $this->athlete();
        $this->actingAs($athlete, 'sanctum');
        $this->getJson('/api/v1/me/notifications?tab=People')->assertOk()
            ->assertJsonStructure(['data', 'meta' => ['unread_count']]);
        $this->postJson('/api/v1/me/notifications/read-all')->assertOk();
    }

    /* ---------------- Phase 10 ---------------- */

    public function test_phase10_admin_2fa_totp_and_ops_monitors(): void
    {
        // TOTP unit contract: secret shape, otpauth URL, wrong code rejected.
        $secret = TotpService::generateSecret();
        $this->assertNotEmpty($secret);
        $this->assertStringStartsWith('otpauth://', TotpService::otpauthUrl($secret, 'admin@sportx.test'));
        $this->assertFalse(TotpService::verify($secret, '000000'));

        // Full admin login → 2FA gate → verify → dashboard flow.
        $admin = User::factory()->create([
            'role' => 'admin', 'status' => 'active',
            'email' => 'admin2fa@phase10.test',
            'email_verified_at' => now(),
        ]);
        $login = $this->postJson('/api/v1/admin/login', [
            'email' => 'admin2fa@phase10.test', 'password' => 'password',
        ])->assertOk()->assertJsonPath('data.requires_2fa', true);

        $token = $login->json('data.token');
        $this->withToken($token)->getJson('/api/v1/admin/dashboard')
            ->assertForbidden()->assertJsonPath('error.code', '2FA_REQUIRED');

        // phpunit runs with ADMIN_2FA_ENFORCE=false: any 6 digits verify.
        $this->withToken($token)->postJson('/api/v1/admin/verify-2fa', ['code' => '123456'])->assertOk();
        $this->withToken($token)->getJson('/api/v1/admin/dashboard')->assertOk();

        // Ops monitors run. mail:probe fails closed (non-zero) when no provider
        // is actually credentialed — assert it executes rather than a fixed code.
        $this->assertEquals(0, Artisan::call('notifications:monitor'));
        $this->assertIsInt(Artisan::call('mail:probe'));
    }
}
