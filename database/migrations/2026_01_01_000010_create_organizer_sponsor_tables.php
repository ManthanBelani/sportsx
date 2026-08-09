<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('organizer_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('organization_name', 150);
            $table->enum('org_type', ['federation', 'club', 'other']);
            $table->enum('verification_status', ['pending', 'verified', 'rejected'])->default('pending');
            $table->timestamps();
        });

        Schema::create('sponsor_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('brand_name', 150);
            $table->foreignId('logo_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            $table->string('category', 80)->nullable();
            $table->enum('verification_status', ['pending', 'verified', 'rejected'])->default('pending');
            $table->timestamps();
        });

        Schema::create('academy_sports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('academy_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sport_id')->constrained()->restrictOnDelete();
            $table->timestamps();

            $table->unique(['academy_id', 'sport_id']);
        });

        Schema::create('academy_coaches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('academy_id')->constrained()->cascadeOnDelete();
            $table->foreignId('coach_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('display_name', 100)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('academy_coaches');
        Schema::dropIfExists('academy_sports');
        Schema::dropIfExists('sponsor_profiles');
        Schema::dropIfExists('organizer_profiles');
    }
};
