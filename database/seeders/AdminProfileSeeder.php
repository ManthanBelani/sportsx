<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AdminProfileSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::where('role', 'admin')->first();

        if (!$admin) {
            $this->command->warn('No admin user found. Run UserSeeder first.');
            return;
        }

        DB::table('admin_profiles')->updateOrInsert(
            ['user_id' => $admin->id],
            [
                'user_id' => $admin->id,
                'is_super_admin' => true,
            ]
        );

        $this->command->info('Admin profile seeded');
    }
}
