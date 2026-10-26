<?php

namespace Tests\Feature;

use App\Jobs\CompressPhoto;
use App\Models\AthleteProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Photo-only uploads + per-role gallery photo quota (plan:
 * PHOTO_QUOTA_COMPRESSION_PLAN.md).
 */
class PhotoQuotaTest extends TestCase
{
    use RefreshDatabase;

    /** platform_settings.json lives on disk — snapshot/restore around tests. */
    private string $settingsFile;

    private string $settingsBackup = '';

    protected function setUp(): void
    {
        parent::setUp();
        $this->settingsFile = storage_path('app/platform_settings.json');
        $this->settingsBackup = is_file($this->settingsFile)
            ? (string) file_get_contents($this->settingsFile)
            : '';
        @unlink($this->settingsFile); // tests start from pure defaults
    }

    protected function tearDown(): void
    {
        if ($this->settingsBackup !== '') {
            @file_put_contents($this->settingsFile, $this->settingsBackup);
        } else {
            @unlink($this->settingsFile);
        }
        parent::tearDown();
    }

    private function athleteWithProfile(): array
    {
        $user = User::factory()->create(['role' => 'athlete']);
        $ageGroup = \App\Models\AgeGroup::create(['name' => 'U18-PQ']);
        $profile = AthleteProfile::create([
            'user_id' => $user->id,
            'full_name' => 'Quota Athlete',
            'date_of_birth' => '2005-01-01',
            'gender' => 'male',
            'skill_level' => 'intermediate',
            'age_group_id' => $ageGroup->id,
        ]);

        return [$user, $profile];
    }

    public function test_video_uploads_are_rejected_with_a_clear_message(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'athlete']));

        $resp = $this->postJson('/api/v1/media/upload', [
            'media_type' => 'video',
            'file' => UploadedFile::fake()->create('clip.mp4', 100, 'video/mp4'),
        ]);

        $resp->assertStatus(422);
        $this->assertStringContainsString('no longer supported', (string) $resp->json('error.message'));
    }

    public function test_photo_upload_dispatches_compression_job(): void
    {
        Queue::fake();
        [$user, $profile] = $this->athleteWithProfile();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo',
            'context' => 'gallery',
            'file' => UploadedFile::fake()->image('me.jpg'),
        ])->assertStatus(201);

        Queue::assertPushed(CompressPhoto::class);
    }

    public function test_gallery_upload_increments_counter_and_limit_blocks(): void
    {
        [$user, $profile] = $this->athleteWithProfile();
        \App\Support\PlatformSettings::update(['gallery_photo_limit_athlete' => 2]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo', 'context' => 'gallery',
            'file' => UploadedFile::fake()->image('a.jpg'),
        ])->assertStatus(201);
        $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo', 'context' => 'gallery',
            'file' => UploadedFile::fake()->image('b.jpg'),
        ])->assertStatus(201);

        $this->assertSame(2, $profile->fresh()->gallery_photo_count);

        // 3rd gallery photo — blocked.
        $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo', 'context' => 'gallery',
            'file' => UploadedFile::fake()->image('c.jpg'),
        ])->assertStatus(422)->assertJsonFragment([]);
        $this->assertStringContainsString(
            'Upload limit reached',
            (string) $this->postJson('/api/v1/media/upload', [
                'media_type' => 'photo', 'context' => 'gallery',
                'file' => UploadedFile::fake()->image('c.jpg'),
            ])->json('error.message') ?: ''
        );

        // Profile/cover/post photos are NOT counted — they still succeed.
        foreach (['profile', 'cover', 'post', 'achievement', 'credential'] as $ctx) {
            $this->postJson('/api/v1/media/upload', [
                'media_type' => 'photo', 'context' => $ctx,
                'file' => UploadedFile::fake()->image($ctx.'.jpg'),
            ])->assertStatus(201);
        }
        $this->assertSame(2, $profile->fresh()->gallery_photo_count);
    }

    public function test_quota_endpoint_reports_used_limit_remaining(): void
    {
        [$user, $profile] = $this->athleteWithProfile();
        Sanctum::actingAs($user);

        \App\Support\PlatformSettings::update(['gallery_photo_limit_athlete' => 5]);
        $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo', 'context' => 'gallery',
            'file' => UploadedFile::fake()->image('a.jpg'),
        ])->assertStatus(201);

        $resp = $this->getJson('/api/v1/me/media/quota')->assertOk();
        $this->assertSame(1, $resp->json('data.used'));
        $this->assertSame(5, $resp->json('data.limit'));
        $this->assertSame(4, $resp->json('data.remaining'));
    }

    public function test_limit_of_zero_blocks_gallery_for_the_role(): void
    {
        [$user, $profile] = $this->athleteWithProfile();
        \App\Support\PlatformSettings::update(['gallery_photo_limit_athlete' => 0]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo', 'context' => 'gallery',
            'file' => UploadedFile::fake()->image('a.jpg'),
        ])->assertStatus(422);
    }

    public function test_deleting_a_gallery_photo_releases_quota(): void
    {
        [$user, $profile] = $this->athleteWithProfile();
        Sanctum::actingAs($user);

        $created = $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo', 'context' => 'gallery',
            'file' => UploadedFile::fake()->image('a.jpg'),
        ])->assertStatus(201)->json('data.id');

        $this->assertSame(1, $profile->fresh()->gallery_photo_count);
        $this->deleteJson("/api/v1/media/{$created}")->assertOk();
        $this->assertSame(0, $profile->fresh()->gallery_photo_count);
    }

    public function test_video_posts_are_rejected_but_photo_posts_work(): void
    {
        $user = User::factory()->create(['role' => 'athlete']);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/posts', [
            'body' => 'with video', 'video_url' => '/storage/x.mp4',
        ])->assertStatus(422);

        $this->postJson('/api/v1/posts', [
            'body' => 'with photo',
            'image_media_ids' => [],
            'image_url' => '/storage/a.jpg',
        ])->assertStatus(201);
    }

    public function test_post_image_media_ids_must_be_owned_photos(): void
    {
        $user = User::factory()->create(['role' => 'athlete']);
        $profile = AthleteProfile::create([
            'user_id' => $user->id, 'full_name' => 'P', 'date_of_birth' => '2005-01-01',
            'gender' => 'male', 'skill_level' => 'intermediate',
            'age_group_id' => \App\Models\AgeGroup::create(['name' => 'U18-PQ2'])->id,
        ]);
        Sanctum::actingAs($user);

        $media = \App\Models\MediaItem::create([
            'owner_type' => 'athlete_profile', 'owner_id' => $profile->id,
            'media_type' => 'photo', 'context' => 'post', 'disk' => 'public',
            'path' => 'media/test.jpg', 'mime_type' => 'image/jpeg',
            'original_name' => 'test.jpg', 'size_bytes' => 10,
        ]);
        $foreign = \App\Models\MediaItem::create([
            'owner_type' => 'user', 'owner_id' => 999999,
            'media_type' => 'photo', 'context' => 'post', 'disk' => 'public',
            'path' => 'media/x.jpg', 'mime_type' => 'image/jpeg',
            'original_name' => 'x.jpg', 'size_bytes' => 10,
        ]);

        // Not a photo / not owned → 422.
        $this->postJson('/api/v1/posts', [
            'body' => 'hi', 'image_media_ids' => [$foreign->id],
        ])->assertStatus(422);

        // Owned photo → 201, image_url is synced from media.
        $resp = $this->postJson('/api/v1/posts', [
            'body' => 'hi', 'image_media_ids' => [$media->id],
        ])->assertStatus(201);
        $this->assertSame($media->id, $resp->json('data.image_media_ids.0'));
        $this->assertSame('/storage/media/test.jpg', $resp->json('data.image_url'));
    }

    public function test_compression_shrinks_large_images(): void
    {
        Queue::fake();
        [$user, $profile] = $this->athleteWithProfile();
        Sanctum::actingAs($user);

        $resp = $this->postJson('/api/v1/media/upload', [
            'media_type' => 'photo', 'context' => 'gallery',
            'file' => UploadedFile::fake()->image('big.jpg'),
        ]);
        $resp->assertStatus(201);

        // Swap in a oversized 3200x2000 JPEG as if a large file had landed,
        // then run the queued compression job manually.
        $img = imagecreatetruecolor(3200, 2000);
        $tmp = tmpfile();
        imagejpeg($img, $tmp, 100);
        rewind($tmp);
        $big = stream_get_contents($tmp);
        imagedestroy($img);

        $media = \App\Models\MediaItem::findOrFail($resp->json('data.id'));
        Storage::disk('public')->put($media->path, $big);

        (new CompressPhoto($media->id))->handle(new \App\Services\PhotoCompressor());
        $media->refresh();

        $this->assertNotNull($media->compressed_at);

        $compressed = imagecreatefromstring(Storage::disk('public')->get($media->path));
        $this->assertNotFalse($compressed);
        $this->assertLessThanOrEqual(1600, max(imagesx($compressed), imagesy($compressed)));

        // Counter integrity still holds post-compression.
        $this->assertSame(1, $profile->fresh()->gallery_photo_count);
    }
}
