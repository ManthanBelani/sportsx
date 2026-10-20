<?php

namespace Database\Seeders;

use App\Models\SocialAccount;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Linked Google identities.
 *
 * Only a couple of accounts have a linked identity, which is enough to
 * exercise the "Continue with Google" account-linking screen and the
 * `GET /me/social-accounts` endpoint.
 */
class SocialAccountSeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            [
                'user' => 'athlete@sportx.test',
                'provider_user_id' => '100000000000000000001',
                'name' => 'John Athlete',
                'avatar_url' => 'https://lh3.googleusercontent.com/a/seed-john',
            ],
            [
                'user' => 'coach@sportx.test',
                'provider_user_id' => '100000000000000000002',
                'name' => 'Sarah Coach',
                'avatar_url' => 'https://lh3.googleusercontent.com/a/seed-sarah',
            ],
        ];

        $created = 0;

        foreach ($rows as $row) {
            $userId = SeedLookup::userId($row['user']);

            if (! $userId) {
                continue;
            }

            SocialAccount::updateOrCreate(
                [
                    'provider' => 'google',
                    'provider_user_id' => $row['provider_user_id'],
                ],
                [
                    'user_id' => $userId,
                    'email' => $row['user'],
                    'name' => $row['name'],
                    'avatar_url' => $row['avatar_url'],
                    'scopes' => 'openid email profile',
                    'token_expires_at' => now()->addHour(),
                ]
            );

            $created++;
        }

        $this->command->info('Social accounts seeded: '.$created);
    }
}
