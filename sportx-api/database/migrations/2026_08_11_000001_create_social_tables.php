<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Chat / Conversations ──
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->enum('type', ['private', 'group'])->default('private');
            $table->string('title')->nullable();
            $table->timestamps();
        });

        Schema::create('conversation_participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamp('last_read_at')->nullable();
            $table->timestamps();

            $table->unique(['conversation_id', 'user_id']);
            $table->index(['user_id', 'updated_at']);
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_user_id')->constrained('users')->cascadeOnDelete();
            $table->text('body');
            $table->enum('type', ['text', 'image', 'system'])->default('text');
            $table->timestamps();

            $table->index(['conversation_id', 'created_at']);
        });

        // ── Connections (follow / mutual) ──
        Schema::create('connections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('follower_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('followee_user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('status', ['pending', 'accepted', 'blocked'])->default('pending');
            $table->timestamps();

            $table->unique(['follower_user_id', 'followee_user_id'], 'connections_unique');
            $table->index(['followee_user_id', 'status']);
            $table->index(['follower_user_id', 'status']);
        });

        // ── Social posts ──
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->text('body')->nullable();
            $table->string('image_url')->nullable();
            $table->string('video_url')->nullable();
            $table->enum('visibility', ['public', 'followers'])->default('public');
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index(['visibility', 'created_at']);
        });

        Schema::create('post_likes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['post_id', 'user_id']);
        });

        Schema::create('post_comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->text('body');
            $table->foreignId('parent_id')->nullable()->constrained('post_comments')->cascadeOnDelete();
            $table->timestamps();

            $table->index(['post_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('post_comments');
        Schema::dropIfExists('post_likes');
        Schema::dropIfExists('posts');
        Schema::dropIfExists('connections');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversation_participants');
        Schema::dropIfExists('conversations');
    }
};
