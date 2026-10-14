<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('positions')) {
            Schema::create('positions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('sport_id')->nullable()->constrained()->nullOnDelete();
                $table->string('name', 100);
                $table->timestamps();
                $table->unique(['sport_id', 'name']);
                $table->index(['sport_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('positions');
    }
};
