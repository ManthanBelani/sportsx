<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds the missing mandatory "Short Bio" field for the Athlete role.
 *
 * Spec: SportX_Mandatory_Fields.md §1 Athlete, mandatory #8 — Short Bio (2-3 lines).
 *
 * `bio` already exists on `coach_profiles` and `talent_scout_profiles` as a nullable
 * TEXT column; this brings `athlete_profiles` in line with them. Nullable and with
 * no default, so existing rows are untouched and no data backfill is required.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('athlete_profiles', 'bio')) {
            Schema::table('athlete_profiles', function (Blueprint $table) {
                $table->text('bio')->nullable()->after('skill_level');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('athlete_profiles', 'bio')) {
            Schema::table('athlete_profiles', fn (Blueprint $t) => $t->dropColumn('bio'));
        }
    }
};