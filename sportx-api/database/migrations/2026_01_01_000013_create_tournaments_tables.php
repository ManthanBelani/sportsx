<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tournaments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organizer_id')->constrained('organizer_profiles')->cascadeOnDelete();
            $table->foreignId('sport_id')->constrained()->restrictOnDelete();
            $table->string('name', 150);
            $table->string('organizer_name', 150)->nullable();
            $table->string('format', 40)->nullable();
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->date('registration_deadline')->nullable()->index();
            $table->string('venue', 190);
            $table->string('google_maps_url')->nullable();
            $table->foreignId('city_id')->nullable()->constrained()->nullOnDelete();
            $table->string('entry_fee', 60)->nullable();
            $table->string('contact_number', 20)->nullable();
            $table->string('registration_link')->nullable();
            $table->string('prize_pool', 60)->nullable();
            $table->text('rules')->nullable();
            $table->foreignId('banner_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            $table->enum('gender', ['male', 'female', 'mixed', 'open'])->nullable();
            $table->enum('status', ['draft', 'published', 'closed', 'expired', 'removed'])->default('draft');
            $table->timestamp('expires_at')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['status', 'start_date']);
            $table->index(['sport_id', 'city_id', 'status']);
            $table->index(['organizer_id', 'status']);
        });

        Schema::create('tournament_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tournament_id')->constrained()->cascadeOnDelete();
            $table->foreignId('age_group_id')->constrained()->restrictOnDelete();
            $table->string('name', 60)->nullable();
            $table->unsignedSmallInteger('capacity');
            $table->boolean('waitlist_enabled')->default(false);
            $table->timestamps();

            $table->unique(['tournament_id', 'age_group_id']);
        });

        Schema::create('tournament_registrations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tournament_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained('tournament_categories')->cascadeOnDelete();
            $table->foreignId('athlete_id')->constrained('athlete_profiles')->cascadeOnDelete();
            $table->enum('participation_type', ['individual', 'team']);
            $table->string('team_name', 120)->nullable();
            $table->enum('payment_status', ['pending', 'paid'])->default('pending');
            $table->enum('status', ['pending', 'confirmed', 'waitlisted', 'cancelled'])->default('pending');
            $table->softDeletes();
            $table->timestamps();

            $table->unique(['tournament_id', 'category_id', 'athlete_id'], 'tour_reg_unique');
            $table->index(['category_id', 'status']);
        });

        Schema::create('tournament_results', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tournament_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained('tournament_categories')->cascadeOnDelete();
            $table->unsignedTinyInteger('place');
            $table->string('winner_name', 150);
            $table->foreignId('bracket_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->unique(['category_id', 'place']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tournament_results');
        Schema::dropIfExists('tournament_registrations');
        Schema::dropIfExists('tournament_categories');
        Schema::dropIfExists('tournaments');
    }
};
