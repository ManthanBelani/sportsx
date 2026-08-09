<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sports', function (Blueprint $table) {
            $table->id();
            $table->string('name', 60)->unique();
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('cities', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('state', 100);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            
            $table->unique(['name', 'state']);
            $table->index('state');
        });

        Schema::create('age_groups', function (Blueprint $table) {
            $table->id();
            $table->string('name', 30)->unique();
            $table->unsignedTinyInteger('min_age')->nullable();
            $table->unsignedTinyInteger('max_age')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('age_groups');
        Schema::dropIfExists('cities');
        Schema::dropIfExists('sports');
    }
};