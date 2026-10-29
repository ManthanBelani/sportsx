<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Community groups (coaching groups, athlete circles, trial groups …) and
 * their membership. The Flutter app consumes GET /groups, GET /me/groups,
 * POST /groups/{group}/join and DELETE /groups/{group}/leave.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('groups')) {
            Schema::create('groups', function (Blueprint $table) {
                $table->id();
                // Nullable — a group can be platform-seeded with no owner.
                $table->foreignId('created_by_user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('name', 120);
                $table->string('description', 500)->nullable();
                $table->string('image_url', 500)->nullable();
                $table->string('type', 40)->default('general'); // coaching|athletes|trials|general
                $table->string('status', 20)->default('active'); // active|archived
                $table->timestamps();

                $table->index(['status', 'type']);
            });
        }

        if (!Schema::hasTable('group_members')) {
            Schema::create('group_members', function (Blueprint $table) {
                $table->id();
                $table->foreignId('group_id')->constrained('groups')->cascadeOnDelete();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->string('role', 20)->default('member'); // member|admin
                $table->timestamp('joined_at')->nullable();
                $table->timestamps();

                $table->unique(['group_id', 'user_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('group_members');
        Schema::dropIfExists('groups');
    }
};
