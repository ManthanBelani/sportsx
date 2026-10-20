<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Cover photo is a separate slot from the profile photo and from the
     * media gallery. Athletes/coaches get their own `cover_media_id` so an
     * uploaded gallery item never silently becomes the profile banner.
     */
    public function up(): void
    {
        if (Schema::hasColumn('athlete_profiles', 'cover_media_id')) {
            return;
        }

        Schema::table('athlete_profiles', function (Blueprint $table) {
            $table->foreignId('cover_media_id')->nullable()->constrained('media_items')->nullOnDelete();
        });

        if (Schema::hasTable('coach_profiles') && ! Schema::hasColumn('coach_profiles', 'cover_media_id')) {
            Schema::table('coach_profiles', function (Blueprint $table) {
                $table->foreignId('cover_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('athlete_profiles', 'cover_media_id')) {
            Schema::table('athlete_profiles', function (Blueprint $table) {
                $table->dropForeign(['cover_media_id']);
                $table->dropColumn('cover_media_id');
            });
        }

        if (Schema::hasTable('coach_profiles') && Schema::hasColumn('coach_profiles', 'cover_media_id')) {
            Schema::table('coach_profiles', function (Blueprint $table) {
                $table->dropForeign(['cover_media_id']);
                $table->dropColumn('cover_media_id');
            });
        }
    }
};
