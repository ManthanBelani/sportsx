<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Privacy settings (Phase 2): profile_visibility + who_can_message/connect.
        if (! Schema::hasColumn('users', 'privacy_settings')) {
            Schema::table('users', function (Blueprint $table) {
                $table->json('privacy_settings')->nullable()->after('social_links');
            });
        }

        // Athlete sports pivot: playing_role / level / experience / primary flag.
        if (Schema::hasTable('athlete_sports')) {
            Schema::table('athlete_sports', function (Blueprint $table) {
                if (! Schema::hasColumn('athlete_sports', 'playing_role')) {
                    $table->string('playing_role', 100)->nullable()->after('sport_id');
                }
                if (! Schema::hasColumn('athlete_sports', 'level')) {
                    $table->string('level', 50)->nullable()->after('playing_role');
                }
                if (! Schema::hasColumn('athlete_sports', 'experience_years')) {
                    $table->unsignedSmallInteger('experience_years')->nullable()->after('level');
                }
                if (! Schema::hasColumn('athlete_sports', 'is_primary')) {
                    $table->boolean('is_primary')->default(false)->after('experience_years');
                }
            });
        }

        // Scout specialisation pivot (Phase 2).
        if (! Schema::hasTable('talent_scout_sports')) {
            Schema::create('talent_scout_sports', function (Blueprint $table) {
                $table->id();
                $table->foreignId('talent_scout_profile_id')->constrained('talent_scout_profiles')->cascadeOnDelete();
                $table->foreignId('sport_id')->constrained('sports')->cascadeOnDelete();
                $table->timestamps();

                $table->unique(['talent_scout_profile_id', 'sport_id'], 'ts_sports_unique');
            });
        }

        // Typed achievements (Phase 2): title/type/sport/level/year/certificate,
        // owned by an athlete profile OR a coach profile.
        if (Schema::hasTable('achievements')) {
            Schema::table('achievements', function (Blueprint $table) {
                if (! Schema::hasColumn('achievements', 'coach_profile_id')) {
                    $table->foreignId('coach_profile_id')->nullable()->after('athlete_id')
                        ->constrained('coach_profiles')->cascadeOnDelete();
                }
                if (! Schema::hasColumn('achievements', 'title')) {
                    $table->string('title', 190)->nullable()->after('coach_profile_id');
                }
                if (! Schema::hasColumn('achievements', 'type')) {
                    $table->string('type', 50)->nullable()->after('title');
                }
                if (! Schema::hasColumn('achievements', 'sport_id')) {
                    $table->foreignId('sport_id')->nullable()->after('type')
                        ->constrained('sports')->nullOnDelete();
                }
                if (! Schema::hasColumn('achievements', 'level')) {
                    $table->string('level', 50)->nullable()->after('sport_id');
                }
                if (! Schema::hasColumn('achievements', 'year')) {
                    $table->unsignedSmallInteger('year')->nullable()->after('level');
                }
                if (! Schema::hasColumn('achievements', 'certificate_media_id')) {
                    $table->foreignId('certificate_media_id')->nullable()->after('year')
                        ->constrained('media_items')->nullOnDelete();
                }
                if (! Schema::hasColumn('achievements', 'description')) {
                    $table->text('description')->nullable()->after('certificate_media_id');
                }
            });

            // Existing rows were athlete-owned with free-text `text`.
            // `athlete_id` stays required only when no coach owns the row; the
            // column itself is left as-is to avoid rewriting history.
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'privacy_settings')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('privacy_settings');
            });
        }

        Schema::dropIfExists('talent_scout_sports');

        if (Schema::hasTable('achievements')) {
            Schema::table('achievements', function (Blueprint $table) {
                $dropped = [];
                foreach (['description', 'certificate_media_id', 'year', 'level', 'sport_id', 'type', 'title', 'coach_profile_id'] as $column) {
                    if (Schema::hasColumn('achievements', $column)) {
                        $dropped[] = $column;
                    }
                }
                if ($dropped !== []) {
                    $table->dropColumn($dropped);
                }
            });
        }

        if (Schema::hasTable('athlete_sports')) {
            Schema::table('athlete_sports', function (Blueprint $table) {
                $dropped = [];
                foreach (['is_primary', 'experience_years', 'level', 'playing_role'] as $column) {
                    if (Schema::hasColumn('athlete_sports', $column)) {
                        $dropped[] = $column;
                    }
                }
                if ($dropped !== []) {
                    $table->dropColumn($dropped);
                }
            });
        }
    }
};
