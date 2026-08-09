<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('athlete_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('full_name');
            $table->date('date_of_birth')->index();
            $table->enum('gender', ['male', 'female', 'other', 'prefer_not_to_say']);
            $table->foreignId('age_group_id')->constrained('age_groups')->restrictOnDelete();
            $table->enum('skill_level', ['beginner', 'intermediate', 'advanced', 'competitive']);
            $table->foreignId('city_id')->nullable()->constrained()->nullOnDelete();
            $table->string('phone', 20)->nullable();
            $table->unsignedBigInteger('academy_id')->nullable();
            $table->unsignedBigInteger('coach_id')->nullable();
            $table->string('position', 100)->nullable();
            $table->string('experience')->nullable();
            $table->foreignId('photo_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('athlete_profiles');
    }
};
