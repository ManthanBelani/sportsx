<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Gap-closure (audit M-4 + Phase 1 badges):
     * - widen expiry content_type enums to include opportunity/program
     * - add verification badge columns for athlete + scout profiles
     */
    public function up(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'mysql') {
            // MySQL: alter enums in place (keeps existing rows).
            DB::statement("ALTER TABLE expiry_rules MODIFY COLUMN content_type ENUM('trial','tournament','sponsorship','scholarship','opportunity','program') NOT NULL");
            DB::statement("ALTER TABLE expiry_events MODIFY COLUMN content_type ENUM('trial','tournament','sponsorship','scholarship','opportunity','program') NOT NULL");
        }
        // sqlite/pgsql in dev/CI: enums are stored as strings — service-level
        // ExpiryService::MAP already accepts opportunity; no schema change needed.

        if (Schema::hasTable('athlete_profiles') && !Schema::hasColumn('athlete_profiles', 'verification_badge')) {
            Schema::table('athlete_profiles', function (Blueprint $table) {
                $table->string('verification_badge', 20)->nullable()->after('id');
            });
        }

        if (Schema::hasTable('talent_scout_profiles') && !Schema::hasColumn('talent_scout_profiles', 'verification_badge')) {
            Schema::table('talent_scout_profiles', function (Blueprint $table) {
                $table->string('verification_badge', 20)->nullable()->after('id');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('athlete_profiles', 'verification_badge')) {
            Schema::table('athlete_profiles', fn (Blueprint $t) => $t->dropColumn('verification_badge'));
        }
        if (Schema::hasColumn('talent_scout_profiles', 'verification_badge')) {
            Schema::table('talent_scout_profiles', fn (Blueprint $t) => $t->dropColumn('verification_badge'));
        }
        // expiry enum narrowing is intentionally not reversed (would orphan rows).
    }
};
