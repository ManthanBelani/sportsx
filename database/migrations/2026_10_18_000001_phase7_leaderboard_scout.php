<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('leaderboard_seasons')) {
            Schema::create('leaderboard_seasons', function (Blueprint $table) {
                $table->id();
                $table->string('name', 60);
                $table->date('starts_on');
                $table->date('ends_on')->nullable();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
                $table->index(['is_active']);
            });
        }

        if (!Schema::hasTable('leaderboard_scores')) {
            Schema::create('leaderboard_scores', function (Blueprint $table) {
                $table->id();
                $table->foreignId('athlete_profile_id')->constrained()->cascadeOnDelete();
                $table->foreignId('sport_id')->nullable()->constrained()->nullOnDelete();
                $table->foreignId('season_id')->nullable()->constrained('leaderboard_seasons')->nullOnDelete();
                $table->unsignedInteger('points')->default(0);
                $table->timestamps();
                $table->unique(['athlete_profile_id', 'sport_id', 'season_id'], 'lb_scores_unique');
                $table->index(['sport_id', 'points']);
                $table->index(['season_id', 'points']);
            });
        }

        if (!Schema::hasTable('observations')) {
            Schema::create('observations', function (Blueprint $table) {
                $table->id();
                $table->foreignId('talent_scout_profile_id')->constrained()->cascadeOnDelete();
                $table->foreignId('athlete_profile_id')->constrained()->cascadeOnDelete();
                $table->unsignedTinyInteger('rating')->nullable();
                $table->text('note')->nullable();
                $table->foreignId('media_id')->nullable()->constrained('media_items')->nullOnDelete();
                $table->timestamps();
                $table->index(['talent_scout_profile_id', 'created_at']);
                $table->index(['athlete_profile_id', 'created_at']);
            });
        }

        // Scout shortlist pipeline (Phase 7): status + tags, private notes kept.
        if (Schema::hasTable('scout_shortlists')) {
            Schema::table('scout_shortlists', function (Blueprint $table) {
                if (!Schema::hasColumn('scout_shortlists', 'status')) {
                    $table->string('status', 20)->default('under_review')->after('athlete_profile_id');
                }
                if (!Schema::hasColumn('scout_shortlists', 'tags')) {
                    $table->json('tags')->nullable()->after('status');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('scout_shortlists')) {
            Schema::table('scout_shortlists', function (Blueprint $table) {
                foreach (['tags', 'status'] as $col) {
                    try {
                        $table->dropColumn($col);
                    } catch (\Throwable) {
                    }
                }
            });
        }
        Schema::dropIfExists('observations');
        Schema::dropIfExists('leaderboard_scores');
        Schema::dropIfExists('leaderboard_seasons');
    }
};
