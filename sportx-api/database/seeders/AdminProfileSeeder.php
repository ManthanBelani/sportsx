<?php

namespace Database\Seeders;

use App\Models\AdminProfile;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Admin profile (admin_profiles) plus the 2FA material.
 *
 * The TOTP secret is a well-known test value, so a 6-digit code can be
 * generated with any standard authenticator app (or the `php artisan`
 * helper below) when testing the admin panel.
 */
class AdminProfileSeeder extends Seeder
{
    /** Shared test secret — never use this outside local development. */
    public const TOTP_SECRET = 'JBSWY3DPEHPK3PXP';

    public function run(): void
    {
        $admin = User::where('role', 'admin')->orderBy('id')->first();

        if (! $admin) {
            $this->command->warn('No admin user found. Run UserSeeder first.');
            return;
        }

        AdminProfile::updateOrCreate(
            ['user_id' => $admin->id],
            [
                'is_super_admin' => true,
                'two_factor_secret' => self::TOTP_SECRET,
            ]
        );

        // The API's admin 2FA secret lives on the user row.
        $admin->forceFill([
            'google2fa_secret' => self::TOTP_SECRET,
            'admin_2fa_verified_at' => now(),
        ])->save();

        $this->command->info('Admin profile seeded for '.$admin->email
            .' (TOTP secret: '.self::TOTP_SECRET.')');
    }
}
