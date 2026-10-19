<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Closes the Academy mandatory-field gaps from
 * sportsx-design-v3/new_design_docs/SportX_Mandatory_Fields.md §3.
 *
 * Missing:
 *   #4  Academy Type       -> academy_type (enum)
 *   #7  Sports/Training Offered -> sports_offered (JSON array)
 *
 * Training Programs (#9) is served by the generic polymorphic `programs` table
 * (owner_type/owner_id), so no new column is required there.
 *
 * Both columns are nullable so existing rows survive untouched.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('academies', function (Blueprint $table) {
            // Spec §3 #4 — Private, Club, School, College, Govt.
            if (!Schema::hasColumn('academies', 'academy_type')) {
                $table->string('academy_type', 30)->nullable()->after('description');
            }
            // Spec §3 #7 — e.g. ["Batting","Bowling","Fielding"].
            if (!Schema::hasColumn('academies', 'sports_offered')) {
                $table->json('sports_offered')->nullable()->after('academy_type');
            }
        });
    }

    public function down(): void
    {
        Schema::table('academies', function (Blueprint $table) {
            foreach (['sports_offered', 'academy_type'] as $col) {
                if (Schema::hasColumn('academies', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};