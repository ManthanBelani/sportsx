<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class Phase6SocialChatSafetyTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $role = 'athlete'): User
    {
        return User::factory()->create(['role' => $role, 'status' => 'active']);
    }

    public function test_post_crud_like_comment(): void
    {
        $me = $this->user();
        $this->actingAs($me, 'sanctum');

        $create = $this->postJson('/api/v1/posts', ['body' => 'Hello #sportx', 'hashtags' => ['sportx']]);
        $create->assertCreated();
        $id = $create->json('data.id');

        $this->patchJson("/api/v1/posts/{$id}", ['body' => 'Edited'])->assertOk();
        $this->postJson("/api/v1/posts/{$id}/like", [])->assertOk();
        $this->getJson("/api/v1/posts/{$id}/comments")->assertOk();
        $this->postJson("/api/v1/posts/{$id}/comments", ['body' => 'Nice!'])->assertCreated();
        $commentId = $this->postJson("/api/v1/posts/{$id}/comments", ['body' => 'Second'])->json('data.id');
        $this->deleteJson("/api/v1/comments/{$commentId}")->assertOk();
        $this->deleteJson("/api/v1/posts/{$id}/like")->assertOk();
        $this->getJson('/api/v1/feed')->assertOk();
        $this->deleteJson("/api/v1/posts/{$id}")->assertOk();
    }

    public function test_follow_and_block_flow(): void
    {
        $me = $this->user();
        $other = $this->user('coach');
        $this->actingAs($me, 'sanctum');

        $this->postJson("/api/v1/follow/user/{$other->id}")->assertSuccessful();
        $this->getJson('/api/v1/me/following')->assertOk();
        $this->postJson('/api/v1/blocks', ['user_id' => $other->id])->assertSuccessful();
        // Follow disabled once blocked.
        $this->postJson("/api/v1/follow/user/{$other->id}")->assertForbidden();
        $this->getJson('/api/v1/blocks')->assertOk();
        $this->deleteJson("/api/v1/blocks/{$other->id}")->assertOk();
    }

    public function test_connection_accept_unlocks_chat(): void
    {
        $a = $this->user();
        $b = $this->user('coach');
        $this->actingAs($a, 'sanctum');

        $req = $this->postJson('/api/v1/connections', ['user_id' => $b->id]);
        $req->assertCreated();
        $connId = $req->json('data.id');

        $this->actingAs($b, 'sanctum');
        $this->patchJson("/api/v1/connections/{$connId}", ['action' => 'accept'])->assertOk();

        $conv = $this->postJson('/api/v1/conversations', ['participant_id' => $a->id]);
        $conv->assertSuccessful();
        $convId = $conv->json('data.id');
        $this->postJson("/api/v1/conversations/{$convId}/messages", ['body' => 'Hi'])->assertCreated();
        $this->postJson("/api/v1/conversations/{$convId}/read")->assertOk();
    }

    public function test_report_and_my_reports(): void
    {
        $me = $this->user();
        $other = $this->user('coach');
        $this->actingAs($me, 'sanctum');

        $this->postJson('/api/v1/reports', [
            'reportable_type' => 'user',
            'reportable_id' => $other->id,
            'reason' => 'inappropriate',
        ])->assertCreated();
        $this->getJson('/api/v1/me/reports')->assertOk();
    }
}
