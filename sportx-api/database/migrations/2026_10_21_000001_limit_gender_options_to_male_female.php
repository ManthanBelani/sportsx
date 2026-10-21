<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("UPDATE athlete_profiles SET gender = 'male' WHERE gender NOT IN ('male', 'female')");
        DB::statement("UPDATE tournaments SET gender = NULL WHERE gender NOT IN ('male', 'female')");

        if (Schema::hasTable('athlete_profiles')) {
            Schema::table('athlete_profiles', function (Blueprint $table) {
                $table->enum('gender', ['male', 'female'])->change();
            });
        }

        if (Schema::hasTable('tournaments')) {
            Schema::table('tournaments', function (Blueprint $table) {
                $table->enum('gender', ['male', 'female'])->nullable()->change();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('athlete_profiles')) {
            Schema::table('athlete_profiles', function (Blueprint $table) {
                $table->enum('gender', ['male', 'female', 'other', 'prefer_not_to_say'])->change();
            });
        }

        if (Schema::hasTable('tournaments')) {
            Schema::table('tournaments', function (Blueprint $table) {
                $table->enum('gender', ['male', 'female', 'mixed', 'open'])->nullable()->change();
            });
        }
    }
};
