<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('coach_profiles', function (Blueprint $table) {
            if (! Schema::hasColumn('coach_profiles', 'headline')) {
                $table->string('headline')->nullable()->after('profile_completeness');
            }
            if (! Schema::hasColumn('coach_profiles', 'location')) {
                $table->string('location')->nullable()->after('headline');
            }
            if (! Schema::hasColumn('coach_profiles', 'fee_per_session')) {
                $table->decimal('fee_per_session', 8, 2)->nullable()->after('location');
            }
            if (! Schema::hasColumn('coach_profiles', 'fee_monthly')) {
                $table->decimal('fee_monthly', 8, 2)->nullable()->after('fee_per_session');
            }
            if (! Schema::hasColumn('coach_profiles', 'fee_quarterly')) {
                $table->decimal('fee_quarterly', 8, 2)->nullable()->after('fee_monthly');
            }
            if (! Schema::hasColumn('coach_profiles', 'availability')) {
                $table->json('availability')->nullable()->after('fee_quarterly');
            }
        });
    }

    public function down(): void
    {
        Schema::table('coach_profiles', function (Blueprint $table) {
            foreach (['availability','fee_quarterly','fee_monthly','fee_per_session','location','headline'] as $col) {
                if (Schema::hasColumn('coach_profiles', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};