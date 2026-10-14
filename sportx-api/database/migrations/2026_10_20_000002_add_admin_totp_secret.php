<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('users', 'google2fa_secret')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('google2fa_secret', 64)->nullable()->after('admin_2fa_verified_at');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'google2fa_secret')) {
            Schema::table('users', fn (Blueprint $t) => $t->dropColumn('google2fa_secret'));
        }
    }
};
