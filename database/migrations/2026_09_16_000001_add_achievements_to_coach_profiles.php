<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('coach_profiles', 'achievements')) {
            Schema::table('coach_profiles', function (Blueprint $table) {
                $table->json('achievements')->nullable()->after('availability');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('coach_profiles', 'achievements')) {
            Schema::table('coach_profiles', function (Blueprint $table) {
                $table->dropColumn('achievements');
            });
        }
    }
};
