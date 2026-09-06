<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('talent_scout_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('organization')->nullable();
            $table->string('affiliation')->nullable();
            $table->json('sports_specialization');
            $table->integer('experience_years')->nullable();
            $table->foreignId('city_id')->nullable()->constrained();
            $table->text('bio')->nullable();
            $table->string('photo_media_id')->nullable();
            $table->boolean('listing_status')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('talent_scout_profiles');
    }
};
