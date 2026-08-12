<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // AthleteProfile::sports() (belongsToMany) referenced this pivot, but no
        // migration created it — causing the /athletes discovery endpoint (and any
        // whereHas('sports') on AthleteProfile) to throw "Table athlete_sports
        // doesn't exist".
        Schema::create('athlete_sports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('athlete_id')->constrained('athlete_profiles')->cascadeOnDelete();
            $table->foreignId('sport_id')->constrained('sports')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['athlete_id', 'sport_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('athlete_sports');
    }
};
