<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            [
                'name' => 'Admin User',
                'email' => 'admin@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
            [
                'name' => 'John Athlete',
                'email' => 'athlete@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'athlete',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
            [
                'name' => 'Sarah Coach',
                'email' => 'coach@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'coach',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
            [
                'name' => 'Elite Academy',
                'email' => 'academy@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'academy',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
            [
                'name' => 'Gujarat Sports Federation',
                'email' => 'organizer@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'organizer',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
            [
                'name' => 'Decathlon India',
                'email' => 'sponsor@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'sponsor',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
            [
                'name' => 'Rahul Sharma',
                'email' => 'rahul@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'athlete',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
            [
                'name' => 'Priya Patel',
                'email' => 'priya@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'athlete',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
            [
                'name' => 'Vikram Singh',
                'email' => 'vikram@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'coach',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
            [
                'name' => 'Mumbai Cricket Academy',
                'email' => 'mca@sportx.test',
                'password' => Hash::make('password'),
                'role' => 'academy',
                'email_verified_at' => now(),
                'is_active' => true,
                'language' => 'en',
            ],
        ];

        foreach ($users as $user) {
            User::updateOrCreate(['email' => $user['email']], $user);
        }

        $this->command->info('Users seeded: ' . count($users));
    }
}
