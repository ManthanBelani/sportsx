<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sports_venues', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->foreignId('sport_id')->constrained()->restrictOnDelete();
            $table->string('address');
            $table->string('google_maps_url')->nullable();
            $table->string('contact_number', 20);
            $table->foreignId('city_id')->nullable()->constrained()->nullOnDelete();
            $table->json('photos')->nullable();
            $table->boolean('booking_available')->default(false);
            $table->string('pricing', 120)->nullable();
            $table->json('facilities')->nullable();
            $table->string('working_hours', 120)->nullable();
            $table->enum('listing_status', ['draft', 'published', 'closed', 'expired', 'removed'])->default('draft');
            $table->softDeletes();
            $table->timestamps();

            $table->index(['listing_status', 'city_id']);
            $table->index(['sport_id', 'city_id', 'listing_status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sports_venues');
    }
};
