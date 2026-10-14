<?php

namespace Tests\Feature;

use App\Models\ListingReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class Phase10HardeningTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->create(['role' => 'admin', 'status' => 'active', 'email_verified_at' => now(), 'admin_2fa_verified_at' => now()]);
    }

    public function test_auth_throttle_returns_429_with_retry_after(): void
    {
        for ($i = 0; $i < 11; $i++) {
            $resp = $this->postJson('/api/v1/auth/login', ['email' => 'nobody@test.com', 'password' => 'wrong']);
        }
        $resp->assertStatus(429);
        $this->assertNotNull($resp->headers->get('Retry-After'));
    }

    public function test_cors_locked_down_by_default(): void
    {
        $methods = config('cors.allowed_methods');
        $this->assertNotContains('*', $methods);
        $this->assertContains('Retry-After', config('cors.exposed_headers'));
    }

    public function test_media_reorder_forbids_other_users_and_signed_url_60min(): void
    {
        $owner = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $other = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $media = \App\Models\MediaItem::create([
            'owner_type' => 'user', 'owner_id' => $owner->id, 'media_type' => 'photo',
            'disk' => 'public', 'path' => 'media/user/x.jpg',
            'original_name' => 'x.jpg', 'mime_type' => 'image/jpeg', 'size_bytes' => 10,
        ]);

        $this->actingAs($other, 'sanctum');
        $this->putJson('/api/v1/media/reorder', ['items' => [['id' => $media->id, 'sort_order' => 1]]])
            ->assertForbidden();

        $this->actingAs($owner, 'sanctum');
        $this->putJson('/api/v1/media/reorder', ['items' => [['id' => $media->id, 'sort_order' => 1]]])
            ->assertOk();
        $signed = $this->getJson("/api/v1/media/{$media->id}/signed-url")->assertOk();
        $expires = strtotime($signed->json('data.expires_at'));
        $this->assertGreaterThanOrEqual(55 * 60, $expires - time());
    }

    public function test_moderation_suspend_notifies_and_audits(): void
    {
        $admin = $this->admin();
        $reporter = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $offender = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $report = ListingReport::create([
            'reporter_user_id' => $reporter->id,
            'reportable_type' => 'user', 'reportable_id' => $offender->id,
            'reason' => 'inappropriate', 'status' => 'pending',
        ]);

        $this->actingAs($admin, 'sanctum');
        $this->postJson("/api/v1/admin/moderation/reports/{$report->id}/suspend")->assertOk();
        $this->assertEquals('suspended', $offender->fresh()->status);
        $this->assertDatabaseHas('notifications', ['user_id' => $offender->id, 'type' => 'account_action']);
        $this->assertDatabaseHas('notifications', ['user_id' => $reporter->id]);
        $this->assertDatabaseHas('audit_logs', ['action' => 'moderation.suspend']);
    }

    public function test_ops_commands_run(): void
    {
        $this->assertEquals(0, Artisan::call('notifications:monitor'));
        $this->assertContains(config('horizon.defaults.supervisor-push.queue'), [['push']]);
        $this->assertContains(config('horizon.defaults.supervisor-mail.queue'), [['mail']]);
    }
}
