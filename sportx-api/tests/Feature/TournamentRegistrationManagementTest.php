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
use App\Models\Trial;
use App\Models\TrialRegistration;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Regressions in the tournament / registration management flow:
 *  - bulk approve used to resolve the id against the wrong table and report
 *    "processed: 0" while silently swallowing the error;
 *  - the unified /events/{id} + /registrations/{id} routes resolved trials
 *    first, so an organizer's own tournament was shadowed by a same-id trial;
 *  - per_page was ignored on the organizer registration lists (capped at 20).
 */
class TournamentRegistrationManagementTest extends TestCase
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

    private function athlete(AgeGroup $ageGroup): AthleteProfile
    {
        $user = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        return AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Test Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'age_group_id' => $ageGroup->id,
        ]);
    }

    private function tournament(OrganizerProfile $profile, Sport $sport, City $city, AgeGroup $ageGroup): array
    {
        $tournament = Tournament::create([
            'organizer_id' => $profile->id,
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'name' => 'Test Cup',
            'venue' => 'Test Ground',
            'start_date' => now()->addMonth()->toDateString(),
            'end_date' => now()->addMonth()->addDays(2)->toDateString(),
            'status' => 'published',
        ]);
        $category = TournamentCategory::create([
            'tournament_id' => $tournament->id,
            'age_group_id' => $ageGroup->id,
            'name' => 'U16 Boys',
            'capacity' => 16,
        ]);

        return [$tournament, $category];
    }

    public function test_bulk_approve_actually_approves_registrations(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        [$tournament, $category] = $this->tournament($profile, $sport, $city, $ageGroup);

        $a = $this->athlete($ageGroup);
        $b = $this->athlete($ageGroup);

        $regA = TournamentRegistration::create([
            'tournament_id' => $tournament->id,
            'category_id' => $category->id,
            'athlete_id' => $a->id,
            'participation_type' => 'individual',
        ]);
        $regB = TournamentRegistration::create([
            'tournament_id' => $tournament->id,
            'category_id' => $category->id,
            'athlete_id' => $b->id,
            'participation_type' => 'individual',
        ]);

        $this->actingAs($user, 'sanctum');

        $response = $this->postJson("/api/v1/events/{$tournament->id}/registrations/bulk?type=tournament", [
            'action' => 'approve',
            'ids' => [$regA->id, $regB->id],
        ])->assertOk();

        $this->assertSame(2, $response->json('data.processed'));
        $this->assertSame([], $response->json('data.failed'));
        $this->assertSame('approved', $regA->fresh()->approval_status);
        $this->assertSame('approved', $regB->fresh()->approval_status);
    }

    public function test_bulk_approve_does_not_touch_another_event_with_the_same_id(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        [$tournament, $category] = $this->tournament($profile, $sport, $city, $ageGroup);

        // A trial owned by somebody else that happens to share the id.
        $other = User::factory()->create(['role' => 'academy', 'status' => 'active']);
        // Force the id collision the unified routes have to survive: a trial
        // owned by somebody else that carries the tournament's id.
        \Illuminate\Support\Facades\DB::table('trials')->insert([
            'id' => $tournament->id,
            'posted_by_user_id' => $other->id,
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'name' => 'Shadow Trial',
            'venue' => 'Other Ground',
            'event_datetime' => now()->addWeek(),
            'contact_number' => '9999999999',
            'status' => 'published',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $trial = Trial::find($tournament->id);

        $athlete = $this->athlete($ageGroup);
        $tournamentReg = TournamentRegistration::create([
            'tournament_id' => $tournament->id,
            'category_id' => $category->id,
            'athlete_id' => $athlete->id,
            'participation_type' => 'individual',
        ]);
        $trialReg = TrialRegistration::create([
            'trial_id' => $trial->id,
            'athlete_id' => $athlete->id,
            'registration_ref' => 'SHADOW-1',
            'status' => 'pending',
        ]);

        $this->actingAs($user, 'sanctum');

        $response = $this->postJson("/api/v1/events/{$tournament->id}/registrations/bulk?type=tournament", [
            'action' => 'approve',
            'ids' => [$tournamentReg->id],
        ])->assertOk();

        $this->assertSame(1, $response->json('data.processed'));
        $this->assertSame('approved', $tournamentReg->fresh()->approval_status);
        // The trial registration must be untouched.
        $this->assertNotSame('approved', $trialReg->fresh()->status);
    }

    public function test_unified_event_registration_list_resolves_the_owners_event(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        [$tournament, $category] = $this->tournament($profile, $sport, $city, $ageGroup);

        $other = User::factory()->create(['role' => 'academy', 'status' => 'active']);
        $trial = Trial::create([
            'posted_by_user_id' => $other->id,
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'name' => 'Shadow Trial',
            'venue' => 'Other Ground',
            'event_datetime' => now()->addWeek(),
            'contact_number' => '9999999999',
            'status' => 'published',
        ]);
        $trial->forceFill(['id' => $tournament->id])->save();

        $athlete = $this->athlete($ageGroup);
        $tournamentReg = TournamentRegistration::create([
            'tournament_id' => $tournament->id,
            'category_id' => $category->id,
            'athlete_id' => $athlete->id,
            'participation_type' => 'individual',
        ]);

        $this->actingAs($user, 'sanctum');

        // No ?type= — the endpoint must resolve to the tournament the caller owns.
        $this->getJson("/api/v1/events/{$tournament->id}/registrations")
            ->assertOk()
            ->assertJsonPath('data.0.tournament_id', $tournament->id)
            ->assertJsonPath('data.0.id', $tournamentReg->id);
    }

    public function test_registration_list_honours_per_page(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        [$tournament, $category] = $this->tournament($profile, $sport, $city, $ageGroup);

        for ($i = 0; $i < 25; $i++) {
            $athlete = $this->athlete($ageGroup);
            TournamentRegistration::create([
                'tournament_id' => $tournament->id,
                'category_id' => $category->id,
                'athlete_id' => $athlete->id,
                'participation_type' => 'individual',
            ]);
        }

        $this->actingAs($user, 'sanctum');

        $response = $this->getJson("/api/v1/tournaments/{$tournament->id}/registrations?per_page=100")->assertOk();
        $this->assertCount(25, $response->json('data'));
        $this->assertSame(100, $response->json('meta.pagination.per_page'));
    }

    public function test_other_organizers_cannot_read_the_registration_list(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$owner, $ownerProfile] = $this->organizer('owner@test.local');
        [$other, $otherProfile] = $this->organizer('other@test.local');
        [$tournament] = $this->tournament($ownerProfile, $sport, $city, $ageGroup);

        $this->actingAs($other, 'sanctum');
        $this->getJson("/api/v1/tournaments/{$tournament->id}/registrations")->assertStatus(403);
    }

    public function test_organizer_can_export_the_registration_csv(): void
    {
        [$sport, $city, $ageGroup] = $this->refs();
        [$user, $profile] = $this->organizer();
        [$tournament, $category] = $this->tournament($profile, $sport, $city, $ageGroup);

        $athlete = $this->athlete($ageGroup);
        TournamentRegistration::create([
            'tournament_id' => $tournament->id,
            'category_id' => $category->id,
            'athlete_id' => $athlete->id,
            'participation_type' => 'individual',
        ]);

        $this->actingAs($user, 'sanctum');
        $response = $this->get("/api/v1/events/{$tournament->id}/registrations/export?type=tournament");
        $response->assertOk();
        $this->assertStringContainsString('text/csv', $response->headers->get('content-type'));
        $this->assertStringContainsString('athlete', $response->getContent());
    }
}
