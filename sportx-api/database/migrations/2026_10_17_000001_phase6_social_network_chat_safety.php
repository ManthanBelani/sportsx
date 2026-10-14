<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── One-way follows (vs mutual connections) ──
        if (!Schema::hasTable('follows')) {
            Schema::create('follows', function (Blueprint $table) {
                $table->id();
                $table->foreignId('follower_user_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('followee_user_id')->constrained('users')->cascadeOnDelete();
                $table->timestamps();
                $table->unique(['follower_user_id', 'followee_user_id'], 'follows_unique');
                $table->index(['followee_user_id']);
                $table->index(['follower_user_id']);
            });
        }

        // ── Safety blocks (hide both ways, disable chat/follow) ──
        if (!Schema::hasTable('blocks')) {
            Schema::create('blocks', function (Blueprint $table) {
                $table->id();
                $table->foreignId('blocker_user_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('blocked_user_id')->constrained('users')->cascadeOnDelete();
                $table->timestamps();
                $table->unique(['blocker_user_id', 'blocked_user_id'], 'blocks_unique');
                $table->index(['blocked_user_id']);
            });
        }

        // ── Posts v3 columns (hashtags/sport/audience). Guarded for re-runs. ──
        if (Schema::hasTable('posts')) {
            Schema::table('posts', function (Blueprint $table) {
                if (!Schema::hasColumn('posts', 'hashtags')) {
                    $table->json('hashtags')->nullable()->after('video_url');
                }
                if (!Schema::hasColumn('posts', 'sport_id')) {
                    $table->foreignId('sport_id')->nullable()->after('hashtags')->constrained('sports')->nullOnDelete();
                }
                if (!Schema::hasColumn('posts', 'audience')) {
                    $table->string('audience', 20)->default('public')->after('sport_id');
                }
            });
        }

        // ── Chat media (P1-ready; P0 sends text only) ──
        if (Schema::hasTable('messages') && !Schema::hasColumn('messages', 'media_url')) {
            Schema::table('messages', function (Blueprint $table) {
                $table->string('media_url', 2048)->nullable()->after('body');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('messages') && Schema::hasColumn('messages', 'media_url')) {
            Schema::table('messages', function (Blueprint $table) {
                $table->dropColumn('media_url');
            });
        }
        Schema::dropIfExists('blocks');
        Schema::dropIfExists('follows');
        // posts extensions are additive; drop only audience/sport/hashtags if present
        if (Schema::hasTable('posts')) {
            Schema::table('posts', function (Blueprint $table) {
                foreach (['audience', 'sport_id', 'hashtags'] as $col) {
                    try {
                        $table->dropColumn($col);
                    } catch (\Throwable) {
                    }
                }
            });
        }
    }
};
