<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Full role roster for local/manual testing.
 *
 * Every role the product supports gets at least one ACTIVE account, plus a
 * second account so that social features (connections, chat, follow, feed)
 * have two distinct parties on each side.
 *
 * Additionally, one PENDING and one SUSPENDED account per approval-gated role
 * so the admin panel's approve / reject / suspend flows have something to act
 * on.
 *
 * Every seeded account uses the password `password` and a verified email, so
 * `POST /auth/login` works out of the box for all of them.
 */
class UserSeeder extends Seeder
{
    public const PASSWORD = 'password';

    /**
     * Shared notification preferences so the toggles in Settings have a value.
     *
     * @var array<string, mixed>
     */
    private const NOTIFICATION_PREFS = [
        'push' => true,
        'in_app' => true,
        'categories' => [
            'people' => true,
            'opportunities' => true,
            'events' => true,
            'mentions' => true,
            'reminders' => true,
            'broadcasts' => true,
        ],
    ];

    /**
     * @var array<string, mixed>
     */
    private const PRIVACY_SETTINGS = [
        'profile_visibility' => 'public',
        'who_can_message' => 'everyone',
        'who_can_connect' => 'everyone',
    ];

    public function run(): void
    {
        $users = [
            /* ── Admins ─────────────────────────────────────────────── */
            [
                'name' => 'Admin User',
                'email' => 'admin@sportx.test',
                'role' => 'admin',
                'phone' => '+91 90000 00001',
            ],
            [
                'name' => 'Meera Admin',
                'email' => 'admin2@sportx.test',
                'role' => 'admin',
                'phone' => '+91 90000 00002',
            ],

            /* ── Athletes ───────────────────────────────────────────── */
            [
                'name' => 'John Athlete',
                'email' => 'athlete@sportx.test',
                'role' => 'athlete',
                'phone' => '+91 98765 11111',
            ],
            [
                'name' => 'Rahul Sharma',
                'email' => 'rahul@sportx.test',
                'role' => 'athlete',
                'phone' => '+91 98765 22222',
            ],
            [
                'name' => 'Priya Patel',
                'email' => 'priya@sportx.test',
                'role' => 'athlete',
                'phone' => '+91 98765 33333',
            ],
            [
                'name' => 'Aarav Menon',
                'email' => 'aarav@sportx.test',
                'role' => 'athlete',
                'phone' => '+91 98765 44444',
            ],
            [
                'name' => 'Diya Nair',
                'email' => 'diya@sportx.test',
                'role' => 'athlete',
                'phone' => '+91 98765 55555',
            ],
            [
                'name' => 'Kabir Khan',
                'email' => 'kabir@sportx.test',
                'role' => 'athlete',
                'phone' => '+91 98765 66666',
            ],
            [
                'name' => 'Pending Athlete',
                'email' => 'athlete.pending@sportx.test',
                'role' => 'athlete',
                'phone' => '+91 98765 77777',
                'status' => 'pending',
            ],
            [
                'name' => 'Suspended Athlete',
                'email' => 'athlete.suspended@sportx.test',
                'role' => 'athlete',
                'phone' => '+91 98765 88888',
                'status' => 'suspended',
            ],

            /* ── Coaches ────────────────────────────────────────────── */
            [
                'name' => 'Sarah Coach',
                'email' => 'coach@sportx.test',
                'role' => 'coach',
                'phone' => '+91 98765 44444',
            ],
            [
                'name' => 'Vikram Singh',
                'email' => 'vikram@sportx.test',
                'role' => 'coach',
                'phone' => '+91 98765 55555',
            ],
            [
                'name' => 'Ritu Desai',
                'email' => 'coach2@sportx.test',
                'role' => 'coach',
                'phone' => '+91 98765 99999',
            ],
            [
                'name' => 'Pending Coach',
                'email' => 'coach.pending@sportx.test',
                'role' => 'coach',
                'phone' => '+91 98765 88888',
                'status' => 'pending',
            ],

            /* ── Academies ──────────────────────────────────────────── */
            [
                'name' => 'Elite Academy',
                'email' => 'academy@sportx.test',
                'role' => 'academy',
                'phone' => '+91 79 2345 6789',
            ],
            [
                'name' => 'Mumbai Cricket Academy',
                'email' => 'mca@sportx.test',
                'role' => 'academy',
                'phone' => '+91 22 2345 6789',
            ],
            [
                'name' => 'Surat Sports Academy',
                'email' => 'academy2@sportx.test',
                'role' => 'academy',
                'phone' => '+91 261 2345 6789',
            ],
            [
                'name' => 'Pending Academy',
                'email' => 'academy.pending@sportx.test',
                'role' => 'academy',
                'phone' => '+91 261 9999 8888',
                'status' => 'pending',
            ],

            /* ── Organizers ─────────────────────────────────────────── */
            [
                'name' => 'Gujarat Sports Federation',
                'email' => 'organizer@sportx.test',
                'role' => 'organizer',
                'phone' => '+91 79 2657 8800',
            ],
            [
                'name' => 'Mumbai District Sports Council',
                'email' => 'organizer2@sportx.test',
                'role' => 'organizer',
                'phone' => '+91 22 2657 8800',
            ],
            [
                'name' => 'Pending Organizer',
                'email' => 'organizer.pending@sportx.test',
                'role' => 'organizer',
                'phone' => '+91 79 2657 8811',
                'status' => 'pending',
            ],

            /* ── Talent scouts ──────────────────────────────────────── */
            [
                'name' => 'Kiran Patel',
                'email' => 'kiran@scout.test',
                'role' => 'talent_scout',
                'phone' => '+91 98250 11111',
            ],
            [
                'name' => 'Anita Fernandes',
                'email' => 'scout2@sportx.test',
                'role' => 'talent_scout',
                'phone' => '+91 98250 22222',
            ],
            [
                'name' => 'Pending Scout',
                'email' => 'scout.pending@sportx.test',
                'role' => 'talent_scout',
                'phone' => '+91 98250 33333',
                'status' => 'pending',
            ],

            /* ── Sponsor (legacy role, API returns 410) ─────────────── */
            [
                'name' => 'Decathlon India',
                'email' => 'sponsor@sportx.test',
                'role' => 'sponsor',
                'phone' => '+91 22 4040 8080',
            ],
        ];

        foreach ($users as $user) {
            $attributes = [
                'name' => $user['name'],
                'email' => $user['email'],
                'role' => $user['role'],
                'phone' => $user['phone'] ?? null,
                'password' => Hash::make(self::PASSWORD),
                'status' => $user['status'] ?? 'active',
                'email_verified_at' => now(),
                // Admins are pre-verified for 2FA so the admin API (which is
                // gated behind `admin.2fa`) is reachable straight after a seed.
                'admin_2fa_verified_at' => $user['role'] === 'admin' ? now() : null,
                'language' => 'en',
                'notification_prefs' => self::NOTIFICATION_PREFS,
                'privacy_settings' => self::PRIVACY_SETTINGS,
                'social_links' => [
                    'instagram' => 'https://instagram.com/'.strtolower(str_replace(' ', '.', $user['name'])),
                    'linkedin' => 'https://linkedin.com/in/'.strtolower(str_replace(' ', '-', $user['name'])),
                ],
            ];

            User::updateOrCreate(['email' => $user['email']], $attributes);
        }

        $this->command->info('Users seeded: '.count($users)
            .' (roles: '.implode(', ', array_unique(array_column($users, 'role'))).')');
    }
}
