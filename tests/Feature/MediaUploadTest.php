<?php

namespace Tests\Feature;

use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\Sport;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

/**
 * Media upload regression tests.
 *  - B1: requires auth (401 without token).
 *  - B5: owner is inferred from the authenticated athlete profile when not
 *    provided, so mobile clients can upload without knowing their profile id.
 *  - B13: spoofed/invalid content is rejected by the real (content-derived)
 *    mime check, not just the client-supplied extension.
 */
class MediaUploadTest extends TestCase
{
    use RefreshDatabase;

    public function test_upload_without_token_returns_401(): void
    {
        $this->postJson('/api/v1/media/upload')->assertStatus(401);
    }

    public function test_upload_without_file_returns_422(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'athlete']));

        $resp = $this->postJson('/api/v1/media/upload', ['media_type' => 'photo']);

        $resp->assertStatus(422)->assertJsonPath('error.code', 'VALIDATION_ERROR');
        $this->assertArrayHasKey('file', $resp->json('error.errors'));
    }

    public function test_upload_infers_owner_from_athlete_profile(): void
    {
        [$sport, $city, $ageGroup] = $this->masterRows();

        $user = User::factory()->create(['role' => 'athlete']);
        $profile = AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Media Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'age_group_id' => $ageGroup->id,
            'skill_level' => 'intermediate',
        ]);
        Sanctum::actingAs($user);

        $resp = $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo',
            'file' => UploadedFile::fake()->image('pic.jpg'),
        ]);

        $resp->assertStatus(201)
            ->assertJsonStructure(['data' => ['id', 'url', 'media_type']]);
        $this->assertDatabaseHas('media_items', [
            'owner_type' => 'athlete_profile',
            'owner_id' => $profile->id,
        ]);
    }

    public function test_upload_rejects_wrong_mime_for_media_type(): void
    {
        [$sport, $city, $ageGroup] = $this->masterRows();

        $user = User::factory()->create(['role' => 'athlete']);
        AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Media Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'age_group_id' => $ageGroup->id,
            'skill_level' => 'intermediate',
        ]);
        Sanctum::actingAs($user);

        // A valid JPEG claimed as a video — must be rejected by the real mime check.
        $resp = $this->postJson('/api/v1/media/upload', [
            'media_type' => 'video',
            'file' => UploadedFile::fake()->image('pic.jpg'),
        ]);

        $resp->assertStatus(422);
    }

    public function test_upload_accepts_client_owned_owner(): void
    {
        [$sport, $city, $ageGroup] = $this->masterRows();

        $user = User::factory()->create(['role' => 'athlete']);
        $profile = AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Owner Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'age_group_id' => $ageGroup->id,
            'skill_level' => 'intermediate',
        ]);
        Sanctum::actingAs($user);

        $resp = $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo',
            'owner_type' => 'athlete_profile',
            'owner_id' => $profile->id,
            'file' => UploadedFile::fake()->image('pic.jpg'),
        ]);

        $resp->assertStatus(201);
        $this->assertDatabaseHas('media_items', [
            'owner_type' => 'athlete_profile',
            'owner_id' => $profile->id,
        ]);
    }

    public function test_upload_rejects_spoofed_owner(): void
    {
        [$sport, $city, $ageGroup] = $this->masterRows();

        // Victim: another athlete whose profile the attacker targets.
        $victim = User::factory()->create(['role' => 'athlete']);
        $victimProfile = AthleteProfile::create([
            'user_id' => $victim->id,
            'full_name' => 'Victim Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'age_group_id' => $ageGroup->id,
            'skill_level' => 'intermediate',
        ]);

        // Attacker: any other authenticated user.
        Sanctum::actingAs(User::factory()->create(['role' => 'athlete']));

        $resp = $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo',
            'owner_type' => 'athlete_profile',
            'owner_id' => $victimProfile->id,
            'file' => UploadedFile::fake()->image('pic.jpg'),
        ]);

        $resp->assertStatus(403);
        $this->assertDatabaseMissing('media_items', [
            'owner_type' => 'athlete_profile',
            'owner_id' => $victimProfile->id,
        ]);
    }

    public function test_profile_cover_and_credential_media_are_hidden_from_gallery_and_quota(): void
    {
        [$sport, $city, $ageGroup] = $this->masterRows();

        $user = User::factory()->create(['role' => 'athlete']);
        AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Gallery Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'sport_id' => $sport->id,
            'city_id' => $city->id,
            'age_group_id' => $ageGroup->id,
            'skill_level' => 'intermediate',
        ]);
        Sanctum::actingAs($user);

        foreach (['profile', 'cover', 'credential', 'gallery'] as $context) {
            $this->postJson('/api/v1/media/upload', [
                'media_type' => 'photo',
                'context' => $context,
                'file' => UploadedFile::fake()->image("$context.jpg"),
            ])->assertStatus(201);
        }

        // GET /me/media lists gallery photos only.
        $list = $this->getJson('/api/v1/me/media')->assertOk()->json('data.data');
        $this->assertCount(1, $list['data'] ?? $list);
        $rows = $list['data'] ?? $list;
        $this->assertSame('gallery', $rows[0]['context']);

        // The profile payload's media_items also excludes profile/cover/credential.
        $profile = $this->getJson('/api/v1/me/profile')->assertOk()->json('data');
        $profileMedia = $profile['media_items'] ?? $profile['athlete']['media_items'] ?? null;
        $this->assertNotNull($profileMedia);
        $this->assertCount(1, $profileMedia);
        $this->assertSame('gallery', $profileMedia[0]['context']);

        // Quota counts gallery photos only: used = 1 of 100.
        $quota = $this->getJson('/api/v1/me/media/quota')->assertOk()->json('data');
        $this->assertSame(1, $quota['used']);
        $this->assertSame(99, $quota['remaining']);
    }

    /** @return array{0: Sport, 1: City, 2: AgeGroup} */
    private function masterRows(): array
    {
        return [
            Sport::create(['name' => 'Cricket', 'sort_order' => 1]),
            City::create(['name' => 'Ahmedabad', 'state' => 'Gujarat']),
            AgeGroup::create(['name' => 'U-14', 'min_age' => 12, 'max_age' => 14]),
        ];
    }
}
