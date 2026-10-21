<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Co-organizers / volunteers an organizer invites to help run their events.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('organizer_team_members')) {
            return;
        }

        Schema::create('organizer_team_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organizer_id')->constrained('organizer_profiles')->cascadeOnDelete();
            // Null until the invited person has an account (or accepts).
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('name', 120);
            $table->string('email', 150);
            $table->string('role', 40)->default('volunteer');
            $table->string('status', 20)->default('pending');
            $table->timestamp('invited_at')->nullable();
            $table->timestamp('joined_at')->nullable();
            $table->timestamps();

            $table->unique(['organizer_id', 'email']);
            $table->index(['organizer_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('organizer_team_members');
    }
};
