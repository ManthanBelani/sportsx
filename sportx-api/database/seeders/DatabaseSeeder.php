<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;

/**
 * Default entry point for `php artisan db:seed`.
 *
 * Runs the full fixture set so a fresh checkout has every role and every
 * feature area populated.
 */
class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // The fixture set creates accounts with a known password and a shared
        // TOTP secret. Never let it run against a real environment.
        if (app()->environment('production')) {
            $this->command->error('Refusing to seed in production.');

            return;
        }

        $this->call([
            AllSeeder::class,
        ]);
    }
}
