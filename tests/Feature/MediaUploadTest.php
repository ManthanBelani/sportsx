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

        $resp->assertStatus(422)->assertJsonValidationErrors('file');
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
