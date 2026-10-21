<?php

namespace Tests\Feature;

use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\OrganizerProfile;
use App\Models\Sport;
use App\Models\Tournament;
use App\Models\TournamentCategory;
use App\Models\TournamentRegistration;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * External registration links (organizers can point "Register" at their own
 * page) + the registration counters the admin dashboard shows.
 */
class TournamentExternalRegistrationTest extends TestCase
{
    use RefreshDatabase;

    private function refs(): array
    {
        $sport = Sport::create(['name' => 'Cricket']);
        $city = City::create(['name' => 'Ahmedabad', 'state' => 'Gujarat']);
        $ageGroup = AgeGroup::create(['name' => 'U16']);

        return [$sport, $city, $ageGroup];
    }

    private function organizer(string $email = 'org@test.local'): array
    {
        $user = User::factory()->create(['role' => 'organizer', 'status' => 'active', 'email' => $email]);
        $profile = OrganizerProfile::create([
            'user_id' => $user->id,
            'organization_name' => 'Test Federation',
            'org_type' => 'federation',
        ]);

        return [$user, $profile];
    }

    private function tournament(OrganizerProfile $profile, Sport $sport, City $city, AgeGroup $ageGroup, array $attrs = []): Tournament
    {
        $tournament = Tournament::create(array_merge([
            'organizer_id' => $profile->id,
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'name' => 'Test Cup',
            'venue' => 'Test Ground',
            'start_date' => now()->addMonth()->toDateString(),
            'end_date' => now()->addMonth()->addDays(2)->toDateString(),
            'status' => 'published',
        ], $attrs));

        TournamentCategory::create([
            'tournament_id' => $tournament->id,
            'age_group_id' => $ageGroup->id,
            'name' => 'U16 Boys',
            'capacity' => 16,
        ]);

        return $tournament;
    }

    public function test_organizer_can_save_an_external_registration_url(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        $this->actingAs($user, 'sanctum');

        $create = $this->postJson('/api/v1/me/tournaments', [
            'name' => 'External Cup',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'venue' => 'Test Ground',
            'start_date' => now()->addMonth()->toDateString(),
            'end_date' => now()->addMonth()->addDays(2)->toDateString(),
            'external_registration_url' => 'https://forms.example.com/my-cup',
            'categories' => [
                ['name' => 'U16 Boys', 'age_group_id' => $ageGroup->id, 'capacity' => 16],
            ],
        ]);

        $create->assertCreated();
        $this->assertSame('https://forms.example.com/my-cup', $create->json('data.external_registration_url'));
        $this->assertSame('external', $create->json('data.registration_mode'));
        $this->assertTrue($create->json('data.has_external_registration'));
    }

    public function test_invalid_external_registration_urls_are_rejected(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        $this->actingAs($user, 'sanctum');

        foreach (['javascript:alert(1)', 'not-a-url', 'ftp://example.com/form'] as $bad) {
            $this->postJson('/api/v1/me/tournaments', [
                'name' => 'Bad Link Cup',
                'sport_id' => $sport->id,
                'city_id' => $city->id,
                'venue' => 'Test Ground',
                'start_date' => now()->addMonth()->toDateString(),
                'end_date' => now()->addMonth()->addDays(2)->toDateString(),
                'external_registration_url' => $bad,
            ])->assertStatus(422)->assertJsonStructure(['error' => ['code', 'message', 'errors' => ['external_registration_url']]]);
        }
    }

    public function test_empty_external_registration_url_clears_the_link(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        $tournament = $this->tournament($profile, $sport, $city, $ageGroup, [
            'external_registration_url' => 'https://forms.example.com/my-cup',
        ]);

        $this->actingAs($user, 'sanctum');
        $this->putJson("/api/v1/me/tournaments/{$tournament->id}", [
            'external_registration_url' => '',
        ])->assertOk();

        $tournament->refresh();
        $this->assertNull($tournament->external_registration_url);
        $this->assertFalse($tournament->hasExternalRegistration());
    }

    public function test_click_is_counted_once_per_token(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        $tournament = $this->tournament($profile, $sport, $city, $ageGroup, [
            'external_registration_url' => 'https://forms.example.com/my-cup',
        ]);

        // Public endpoint — a visitor does not have to be signed in.
        $this->postJson("/api/v1/tournaments/{$tournament->id}/registration-click", [
            'click_token' => 'token-1',
        ])->assertOk()->assertJsonPath('data.external_registration_clicks', 1)
          ->assertJsonPath('data.incremented', true);

        // Same token again (retry / re-render) must not double count.
        $this->postJson("/api/v1/tournaments/{$tournament->id}/registration-click", [
            'click_token' => 'token-1',
        ])->assertOk()->assertJsonPath('data.external_registration_clicks', 1)
          ->assertJsonPath('data.incremented', false);

        // A genuinely new click is counted.
        $this->postJson("/api/v1/tournaments/{$tournament->id}/registration-click", [
            'click_token' => 'token-2',
        ])->assertOk()->assertJsonPath('data.external_registration_clicks', 2);

        $this->assertSame(2, (int) $tournament->fresh()->external_registration_clicks);
    }

    public function test_click_requires_a_token_and_an_external_tournament(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        $internal = $this->tournament($profile, $sport, $city, $ageGroup);

        $this->postJson("/api/v1/tournaments/{$internal->id}/registration-click", [])
            ->assertStatus(422);

        $this->postJson("/api/v1/tournaments/{$internal->id}/registration-click", [
            'click_token' => 'token-1',
        ])->assertStatus(422);

        $this->assertSame(0, (int) $internal->fresh()->external_registration_clicks);
    }

    public function test_stats_separate_confirmed_registrations_from_external_clicks(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        $tournament = $this->tournament($profile, $sport, $city, $ageGroup, [
            'external_registration_url' => 'https://forms.example.com/my-cup',
        ]);

        $athleteUser = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $athlete = AthleteProfile::create([
            'user_id' => $athleteUser->id,
            'full_name' => 'Test Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'age_group_id' => $ageGroup->id,
        ]);

        $category = TournamentCategory::where('tournament_id', $tournament->id)->first();
        TournamentRegistration::create([
            'tournament_id' => $tournament->id,
            'category_id' => $category->id,
            'athlete_id' => $athlete->id,
            'participation_type' => 'individual',
            'approval_status' => 'approved',
            'status' => 'confirmed',
        ]);

        $this->postJson("/api/v1/tournaments/{$tournament->id}/registration-click", [
            'click_token' => 'token-1',
        ])->assertOk();

        $this->actingAs($user, 'sanctum');
        $stats = $this->getJson("/api/v1/me/tournaments")->json('data.0');

        $this->assertSame(1, $stats['registrations_count']);
        $this->assertSame(1, $stats['confirmed_registrations_count']);
        $this->assertSame(1, $stats['external_registration_clicks']);
        $this->assertSame('external', $stats['registration_mode']);
        // Clicks are never counted as registrations.
        $this->assertSame(1, $stats['registrations_count']);
    }

    public function test_organizer_cannot_touch_another_organizers_tournament(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$owner, $ownerProfile] = $this->organizer('owner@test.local');
        [$other, $otherProfile] = $this->organizer('other@test.local');
        $tournament = $this->tournament($ownerProfile, $sport, $city, $ageGroup);

        $this->actingAs($other, 'sanctum');
        $this->putJson("/api/v1/me/tournaments/{$tournament->id}", [
            'external_registration_url' => 'https://evil.example.com',
        ])->assertStatus(403);
    }

    public function test_admin_dashboard_reports_registrations_and_external_clicks(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        $tournament = $this->tournament($profile, $sport, $city, $ageGroup, [
            'external_registration_url' => 'https://forms.example.com/my-cup',
        ]);

        $this->postJson("/api/v1/tournaments/{$tournament->id}/registration-click", [
            'click_token' => 'token-1',
        ])->assertOk();

        $admin = User::factory()->create([
            'role' => 'admin',
            'status' => 'active',
            'admin_2fa_verified_at' => now(),
        ]);
        $this->actingAs($admin, 'sanctum');

        $data = $this->getJson('/api/v1/admin/dashboard')->assertOk()->json('data');

        $this->assertSame(1, $data['external_registration_clicks']);
        $this->assertSame(1, $data['tournaments_with_external_registration']);
        $this->assertArrayHasKey('confirmed_tournament_registrations', $data);
        $this->assertArrayHasKey('total_users', $data);
    }

    public function test_admin_tournament_list_includes_registration_counters(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        $tournament = $this->tournament($profile, $sport, $city, $ageGroup, [
            'external_registration_url' => 'https://forms.example.com/my-cup',
        ]);

        $this->postJson("/api/v1/tournaments/{$tournament->id}/registration-click", [
            'click_token' => 'token-1',
        ])->assertOk();

        $admin = User::factory()->create([
            'role' => 'admin',
            'status' => 'active',
            'admin_2fa_verified_at' => now(),
        ]);
        $this->actingAs($admin, 'sanctum');

        $row = collect($this->getJson('/api/v1/admin/content/tournaments')->json('data'))
            ->firstWhere('id', $tournament->id);

        $this->assertNotNull($row);
        $this->assertSame(0, $row['confirmed_registrations_count']);
        $this->assertSame(1, $row['external_registration_clicks']);
        $this->assertSame('external', $row['registration_mode']);
    }

    public function test_public_tournament_detail_exposes_the_external_link(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        $tournament = $this->tournament($profile, $sport, $city, $ageGroup, [
            'external_registration_url' => 'https://forms.example.com/my-cup',
        ]);

        $this->getJson("/api/v1/tournaments/{$tournament->id}")
            ->assertOk()
            ->assertJsonPath('data.external_registration_url', 'https://forms.example.com/my-cup')
            ->assertJsonPath('data.has_external_registration', true);
    }
}
