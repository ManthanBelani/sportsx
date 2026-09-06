<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('scout_connections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('talent_scout_profile_id')->constrained()->cascadeOnDelete();
            $table->foreignId('athlete_profile_id')->constrained()->cascadeOnDelete();
            $table->enum('status', ['pending', 'accepted', 'rejected'])->default('pending');
            $table->text('message')->nullable();
            $table->timestamps();

            $table->unique(['talent_scout_profile_id', 'athlete_profile_id'], 'scout_connections_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('scout_connections');
    }
};
