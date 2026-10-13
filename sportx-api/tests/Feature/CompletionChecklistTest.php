<?php

namespace Tests\Feature;

use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\MediaItem;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * @see \App\Http\Controllers\CompletionChecklistController
 */
class CompletionChecklistTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Create the FK parents (`cities`, `media_items`) the fixtures point at.
     *
     * Both `athlete_profiles.city_id` and `.photo_media_id` are constrained, so
     * referencing id 1 without creating it fails the insert.
     */
    protected function seedFkParents(): void
    {
        City::firstOrCreate(['name' => 'Test City'], ['state' => 'Gujarat']);
        MediaItem::firstOrCreate(['path' => 'test/photo.jpg'], [
            'owner_type' => 'athlete_profile',
            'owner_id' => 1,
            'media_type' => 'photo',       // enum('photo','video','document')
            // NOT NULL with no default — see Database-Design.md §3.
            'mime_type' => 'image/jpeg',
            'size_bytes' => 1024,
        ]);
    }

    protected int $seq = 0;

    protected function athlete(array $profileAttributes = [], bool $withProfile = true): User
    {
        $this->seedFkParents();

        // Some tests compare a bare profile against a filled-in one, so each
        // call needs its own account (users.email is unique).
        $user = User::create([
            'role' => 'athlete', 'name' => 'Kiran', 'email' => 'kiran'.(++$this->seq).'@sportx.test',
            'password' => Hash::make('password'),
            'email_verified_at' => now(), 'status' => 'active',
        ]);

        if ($withProfile) {
            $ageGroup = AgeGroup::firstOrCreate(['name' => 'Under-18'], ['min_age' => 16, 'max_age' => 18]);

            // Both are real FKs, so re-point them at the rows just seeded
            // rather than trusting a hard-coded id.
            if (! empty($profileAttributes['city_id'])) {
                $profileAttributes['city_id'] = City::where('name', 'Test City')->value('id');
            }

            if (! empty($profileAttributes['photo_media_id'])) {
                $profileAttributes['photo_media_id'] = MediaItem::where('path', 'test/photo.jpg')->value('id');
            }

            AthleteProfile::create(array_merge([
                'user_id' => $user->id,
                'full_name' => 'Kiran Patel',
                'gender' => 'male',
                'skill_level' => 'intermediate',
                'age_group_id' => $ageGroup->id,
                // NOT NULL with no default; individual tests override it to
                // exercise the minor gate — see Database-Design.md §4.
                'date_of_birth' => '2005-01-01',
            ], $profileAttributes));
        }

        return $user->refresh();
    }

    public function test_an_unprofiled_user_sees_everything_missing(): void
    {
        $user = $this->athlete(withProfile: false);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/v1/me/completion-checklist');

        $response->assertOk()
            ->assertJsonPath('data.role', 'athlete')
            ->assertJsonPath('data.completion', 0);

        $this->assertNotEmpty($response->json('data.missing'));
    }

    public function test_missing_entries_carry_a_label_and_a_deep_link(): void
    {
        $user = $this->athlete();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/v1/me/completion-checklist');

        $response->assertOk();

        foreach ($response->json('data.missing') as $item) {
            $this->assertArrayHasKey('key', $item);
            $this->assertArrayHasKey('label', $item);
            $this->assertArrayHasKey('deep_link', $item);
            $this->assertFalse($item['done']);
            $this->assertNotSame('', $item['deep_link']);
        }
    }

    public function test_filling_fields_raises_completion(): void
    {
        $bare = $this->athlete();
        $bareCompletion = $this->actingAs($bare, 'sanctum')
            ->getJson('/api/v1/me/completion-checklist')->json('data.completion');

        $filled = $this->athlete([
            'date_of_birth' => '2005-01-01',
            'city_id' => 1,
            'photo_media_id' => 7,
        ]);

        $filledCompletion = $this->actingAs($filled, 'sanctum')
            ->getJson('/api/v1/me/completion-checklist')->json('data.completion');

        $this->assertGreaterThan($bareCompletion, $filledCompletion);
    }

    public function test_completion_is_a_percentage_between_0_and_100(): void
    {
        $user = $this->athlete(['date_of_birth' => '2005-01-01', 'city_id' => 1, 'photo_media_id' => 7]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/v1/me/completion-checklist');

        $completion = $response->json('data.completion');

        $this->assertGreaterThanOrEqual(0, $completion);
        $this->assertLessThanOrEqual(100, $completion);
    }

    public function test_complete_and_missing_counts_agree(): void
    {
        $user = $this->athlete(['date_of_birth' => '2005-01-01']);

        $data = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/me/completion-checklist')->json('data');

        $this->assertSame(
            $data['total'],
            $data['complete'] + count($data['missing']),
            'complete + missing must equal total',
        );
    }

    public function test_a_minor_without_guardian_consent_is_flagged(): void
    {
        $minor = $this->athlete(['date_of_birth' => '2012-01-01']);

        $keys = array_column(
            $this->actingAs($minor, 'sanctum')->getJson('/api/v1/me/completion-checklist')->json('data.missing'),
            'key',
        );

        $this->assertContains('guardian_consent', $keys);
    }

    public function test_checklist_requires_authentication(): void
    {
        $this->getJson('/api/v1/me/completion-checklist')->assertStatus(401);
    }
}