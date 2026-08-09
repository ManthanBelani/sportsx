<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('media_items', function (Blueprint $table) {
            $table->id();
            $table->string('owner_type');
            $table->unsignedBigInteger('owner_id');
            $table->enum('media_type', ['photo', 'video', 'document']);
            $table->string('disk')->default('local');
            $table->string('path');
            $table->string('original_name', 190)->nullable();
            $table->string('mime_type', 80);
            $table->unsignedInteger('size_bytes');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->softDeletes();
            $table->timestamps();

            $table->index(['owner_type', 'owner_id', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('media_items');
    }
};
