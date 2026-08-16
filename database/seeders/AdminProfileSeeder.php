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
                'full_name' => 'Admin User',
                'phone' => '+91 98765 43210',
                'department' => 'Super Admin',
                'permissions' => json_encode(['all']),
                'is_super_admin' => true,
            ]
        );

        $this->command->info('Admin profile seeded');
    }
}
