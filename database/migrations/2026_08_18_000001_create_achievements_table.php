<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('achievements')) {
            Schema::create('achievements', function (Blueprint $table) {
                $table->id();
                $table->foreignId('athlete_id')->constrained('athlete_profiles')->cascadeOnDelete();
                $table->string('text', 190);
                $table->unsignedSmallInteger('sort_order')->default(0);
                $table->timestamps();

                $table->index(['athlete_id', 'sort_order']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('achievements');
    }
};
