<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coach_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('full_name');
            $table->foreignId('sport_id')->constrained()->restrictOnDelete();
            $table->foreignId('city_id')->nullable()->constrained()->nullOnDelete();
            $table->string('contact_number', 20);
            $table->string('experience');
            $table->string('qualification')->nullable();
            $table->json('certifications')->nullable();
            $table->unsignedBigInteger('academy_id')->nullable();
            $table->json('languages')->nullable();
            $table->string('email', 190)->nullable();
            $table->boolean('personal_coaching')->default(false);
            $table->string('fee_structure', 120)->nullable();
            $table->text('bio')->nullable();
            $table->foreignId('photo_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            $table->enum('listing_status', ['draft', 'published', 'closed', 'removed'])->default('draft');
            $table->unsignedTinyInteger('profile_completeness')->default(0);
            $table->timestamps();

            $table->index(['listing_status', 'city_id']);
        });

        Schema::create('academies', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('name', 150);
            $table->text('description');
            $table->string('address');
            $table->foreignId('city_id')->nullable()->constrained()->nullOnDelete();
            $table->string('contact_number', 20);
            $table->string('google_maps_url')->nullable();
            $table->json('facilities')->nullable();
            $table->string('fee_range', 60)->nullable();
            $table->string('timings', 120)->nullable();
            $table->json('age_groups')->nullable();
            $table->unsignedSmallInteger('year_established')->nullable();
            $table->json('achievements')->nullable();
            $table->string('email', 190)->nullable();
            $table->string('website')->nullable();
            $table->foreignId('head_coach_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('logo_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            $table->foreignId('cover_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            $table->boolean('verification_badge')->default(false);
            $table->enum('listing_status', ['draft', 'published', 'closed', 'expired', 'removed'])->default('draft');
            $table->timestamps();

            $table->index(['listing_status', 'city_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('academies');
        Schema::dropIfExists('coach_profiles');
    }
};
