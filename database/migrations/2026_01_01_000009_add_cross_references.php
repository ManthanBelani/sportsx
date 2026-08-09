<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('athlete_profiles', function (Blueprint $table) {
            $table->foreign('academy_id')->references('id')->on('academies')->nullOnDelete();
        });
        Schema::table('athlete_profiles', function (Blueprint $table) {
            $table->foreign('coach_id')->references('id')->on('coach_profiles')->nullOnDelete();
        });
        Schema::table('coach_profiles', function (Blueprint $table) {
            $table->foreign('academy_id')->references('id')->on('academies')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('athlete_profiles', function (Blueprint $table) {
            $table->dropForeign(['academy_id']);
            $table->dropForeign(['coach_id']);
        });
        Schema::table('coach_profiles', function (Blueprint $table) {
            $table->dropForeign(['academy_id']);
        });
    }
};
