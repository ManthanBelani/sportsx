<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Add 'pending' to users.status enum. Works on MySQL by redefining enum.
        DB::statement("ALTER TABLE users MODIFY COLUMN status ENUM('active','pending','suspended','deleted') NOT NULL DEFAULT 'active'");
    }

    public function down(): void
    {
        // Revert pending users to active before shrinking enum
        DB::table('users')->where('status', 'pending')->update(['status' => 'active']);
        DB::statement("ALTER TABLE users MODIFY COLUMN status ENUM('active','suspended','deleted') NOT NULL DEFAULT 'active'");
    }
};
