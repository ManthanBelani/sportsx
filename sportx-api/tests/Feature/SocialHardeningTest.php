<?php

namespace Tests\Feature;

use App\Models\Connection;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Hardening regressions for the social stack (feed, follow/connect, chat):
 *  - unread counts appear in /me/conversations and clear on mark-read
 *  - every chat message notifies its recipients
 *  - group conversations can't bypass the 1:1 safety gates
 *  - clients cannot forge system messages
 *  - blocked pairs can't read/comment on each other's public posts
 *  - connection requests are rate-limited per target
 *  - follows notify the followed user
 */
class SocialHardeningTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $role = 'athlete'): User
    {
        return User::factory()->create(['role' => $role, 'status' => 'active']);
    }

    private function connectedPair(): array
    {
        $a = $this->user();
        $b = $this->user('coach');
        Connection::create(['follower_user_id' => $a->id, 'followee_user_id' => $b->id, 'status' => 'accepted']);

        return [$a, $b];
    }

    public function test_unread_count_shown_and_cleared_by_mark_read(): void
    {
        [$a, $b] = $this->connectedPair();

        $conv = $this->actingAs($a, 'sanctum')
            ->postJson('/api/v1/conversations', ['participant_id' => $b->id])
            ->json('data.id');

        $this->postJson("/api/v1/conversations/{$conv}/messages", ['body' => 'one'])->assertCreated();
        $this->postJson("/api/v1/conversations/{$conv}/messages", ['body' => 'two'])->assertCreated();

        $list = $this->actingAs($b, 'sanctum')->getJson('/api/v1/me/conversations')->assertOk();
        $row = collect($list->json('data'))->firstWhere('id', (int) $conv);
        $this->assertNotNull($row);
        $this->assertSame(2, $row['unread_count']);

        $this->postJson("/api/v1/conversations/{$conv}/read")->assertOk();

        $row = collect($this->actingAs($b, 'sanctum')->getJson('/api/v1/me/conversations')->json('data'))
            ->firstWhere('id', (int) $conv);
        $this->assertSame(0, $row['unread_count']);
    }

    public function test_sending_a_message_notifies_the_recipient(): void
    {
        [$a, $b] = $this->connectedPair();

        $conv = $this->actingAs($a, 'sanctum')
            ->postJson('/api/v1/conversations', ['participant_id' => $b->id])
            ->json('data.id');

        $this->postJson("/api/v1/conversations/{$conv}/messages", ['body' => 'Hello there'])->assertCreated();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $b->id,
            'type' => 'message',
            'notifiable_type' => 'conversation',
            'notifiable_id' => $conv,
        ]);
    }

    public function test_system_message_type_cannot_be_forged(): void
    {
        [$a, $b] = $this->connectedPair();

        $conv = $this->actingAs($a, 'sanctum')
            ->postJson('/api/v1/conversations', ['participant_id' => $b->id])
            ->json('data.id');

        $this->postJson("/api/v1/conversations/{$conv}/messages", ['body' => 'fake system', 'type' => 'system'])
            ->assertStatus(422);
    }

    public function test_group_creation_requires_connection_with_every_participant(): void
    {
        $a = $this->user();
        $friend = $this->user('coach');
        $stranger = $this->user('academy');
        Connection::create(['follower_user_id' => $a->id, 'followee_user_id' => $friend->id, 'status' => 'accepted']);

        $this->actingAs($a, 'sanctum')
            ->postJson('/api/v1/conversations', ['participant_ids' => [$friend->id, $stranger->id]])
            ->assertStatus(403);
    }

    public function test_blocked_pair_cannot_read_or_comment_public_posts(): void
    {
        $author = $this->user();
        $attacker = $this->user('coach');

        $postId = $this->actingAs($author, 'sanctum')
            ->postJson('/api/v1/posts', ['body' => 'public post'])
            ->json('data.id');

        $this->actingAs($attacker, 'sanctum')
            ->postJson('/api/v1/blocks', ['user_id' => $author->id])
            ->assertSuccessful();

        $this->actingAs($attacker, 'sanctum')
            ->getJson("/api/v1/posts/{$postId}")
            ->assertNotFound();
        $this->actingAs($attacker, 'sanctum')
            ->postJson("/api/v1/posts/{$postId}/comments", ['body' => 'still stalking'])
            ->assertNotFound();
        $this->actingAs($attacker, 'sanctum')
            ->postJson("/api/v1/posts/{$postId}/like")
            ->assertNotFound();
    }

    public function test_connection_request_is_rate_limited_per_target(): void
    {
        $a = $this->user();
        $b = $this->user('coach');

        $this->actingAs($a, 'sanctum');
        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/v1/me/connections/request', ['user_id' => $b->id])->assertCreated();
            // Decline so the next request starts fresh (this is the spam loop).
            $connId = Connection::where('follower_user_id', $a->id)->where('followee_user_id', $b->id)->latest('id')->value('id');
            $this->actingAs($b, 'sanctum')
                ->patchJson("/api/v1/connections/{$connId}", ['action' => 'decline'])->assertOk();
            $this->actingAs($a, 'sanctum');
        }

        $this->postJson('/api/v1/me/connections/request', ['user_id' => $b->id])
            ->assertStatus(429);
    }

    public function test_following_notifies_the_target(): void
    {
        $a = $this->user();
        $b = $this->user('coach');

        $this->actingAs($a, 'sanctum')
            ->postJson("/api/v1/follow/user/{$b->id}")
            ->assertCreated();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $b->id,
            'title' => 'New follower',
        ]);
    }

    public function test_conversation_show_limits_messages(): void
    {
        [$a, $b] = $this->connectedPair();

        $conv = $this->actingAs($a, 'sanctum')
            ->postJson('/api/v1/conversations', ['participant_id' => $b->id])
            ->json('data.id');

        for ($i = 0; $i < 5; $i++) {
            $this->postJson("/api/v1/conversations/{$conv}/messages", ['body' => "msg {$i}"])->assertCreated();
        }

        $data = $this->actingAs($a, 'sanctum')
            ->getJson("/api/v1/conversations/{$conv}?messages_limit=3")
            ->assertOk()
            ->json('data');

        $this->assertCount(3, $data['messages']);
        $this->assertTrue($data['has_more']);
        // Oldest-first ordering within the returned window.
        $this->assertSame('msg 2', $data['messages'][0]['body']);
        $this->assertSame('msg 4', $data['messages'][2]['body']);
    }
}
