<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class Phase9AdminNotificationsTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->create(['role' => 'admin', 'status' => 'active', 'email_verified_at' => now(), 'admin_2fa_verified_at' => now()]);
    }

    public function test_notification_tabs_and_unread_count(): void
    {
        $user = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/v1/me/notifications?tab=People')->assertOk()
            ->assertJsonStructure(['data', 'meta' => ['unread_count']]);
        $this->getJson('/api/v1/me/notifications?tab=Events')->assertOk();
        $this->getJson('/api/v1/me/notifications?tab=Opportunities')->assertOk();
        $this->getJson('/api/v1/me/notifications?tab=Mentions')->assertOk();
    }

    public function test_prefs_show_update_and_hard_override_note(): void
    {
        $user = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $this->actingAs($user, 'sanctum');

        $show = $this->getJson('/api/v1/me/notification-preferences')->assertOk();
        $this->assertContains('account_action', $show->json('data.hard_overrides'));

        $this->putJson('/api/v1/me/notification-preferences', [
            'push' => false, 'categories' => ['mentions' => false],
        ])->assertOk()->assertJsonPath('data.prefs.push', false)
            ->assertJsonPath('data.prefs.categories.mentions', false);
    }

    public function test_prefs_suppress_push_but_keep_row_and_admin_notify_bypasses(): void
    {
        Queue::fake();
        $user = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $user->forceFill(['notification_prefs' => ['push' => true, 'categories' => [
            'people' => true, 'opportunities' => true, 'events' => true,
            'mentions' => false, 'reminders' => true, 'broadcasts' => true,
        ]]])->save();

        $this->actingAs($user, 'sanctum');
        // mentions-gated type still stored in-app, push suppressed.
        \App\Services\NotificationService::createStatic([
            'user_id' => $user->id, 'type' => 'mention',
            'title' => 'Mention', 'body' => 'You were mentioned',
        ]);
        $this->assertDatabaseHas('notifications', ['user_id' => $user->id, 'push_status' => 'suppressed']);

        // Hard override bypasses prefs (admin approve path).
        $admin = $this->admin();
        $this->actingAs($admin, 'sanctum');
        $target = User::factory()->create(['role' => 'athlete', 'status' => 'pending']);
        $this->postJson("/api/v1/admin/users/{$target->id}/approve")->assertOk();
        $this->assertDatabaseHas('notifications', ['user_id' => $target->id, 'type' => 'account_action']);
    }

    public function test_broadcast_channels_and_analytics_and_positions(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin, 'sanctum');

        $this->postJson('/api/v1/admin/notifications/broadcast', [
            'title' => 'Hello', 'body' => 'World', 'channels' => ['in_app'],
        ])->assertCreated()->assertJsonPath('data.channels', ['in_app']);

        $this->postJson('/api/v1/analytics/events', ['event' => 'signup'])->assertCreated();
        $this->assertDatabaseHas('analytics_events', ['event' => 'signup']);

        $this->postJson('/api/v1/admin/categories/positions', ['name' => 'Striker'])->assertCreated();
        $this->getJson('/api/v1/meta/positions')->assertOk();
        $this->getJson('/api/v1/admin/content/opportunities')->assertOk();
    }
}
