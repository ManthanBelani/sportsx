<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\PlatformSettings;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * JSON platform-settings API backing the mobile System Settings screen.
 */
class AdminSettingsApiTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        // PlatformSettings writes a real (git-ignored) json file — remove it
        // so one test's toggles never leak into another test's run.
        @unlink(storage_path('app/platform_settings.json'));
        parent::tearDown();
    }

    private function admin(): User
    {
        return User::factory()->create([
            'role' => 'admin', 'status' => 'active',
            'email_verified_at' => now(), 'admin_2fa_verified_at' => now(),
        ]);
    }

    public function test_admin_settings_round_trip_and_audit(): void
    {
        $this->actingAs($this->admin(), 'sanctum');

        $show = $this->getJson('/api/v1/admin/settings')->assertOk();
        $this->assertArrayHasKey('maintenance_mode', $show->json('data.settings'));
        $this->assertArrayHasKey('auto_approve_trials', $show->json('data.settings'));

        $this->putJson('/api/v1/admin/settings', [
            'maintenance_mode' => true,
            'auto_approve_trials' => true,
        ])->assertOk()
            ->assertJsonPath('data.settings.maintenance_mode', true)
            ->assertJsonPath('data.settings.auto_approve_trials', true);

        $this->assertTrue((bool) PlatformSettings::get('maintenance_mode'));
        $this->assertDatabaseHas('audit_logs', ['action' => 'settings.update']);

        // Unknown keys are ignored, never persisted.
        $this->putJson('/api/v1/admin/settings', ['nope_not_a_setting' => true])->assertOk();
        $this->assertNull(PlatformSettings::get('nope_not_a_setting'));

        // Non-admins are refused.
        $athlete = User::factory()->create(['role' => 'athlete', 'status' => 'active']);
        $this->actingAs($athlete, 'sanctum');
        $this->getJson('/api/v1/admin/settings')->assertForbidden();
    }
}
