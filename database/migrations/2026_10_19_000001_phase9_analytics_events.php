<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('analytics_events')) {
            Schema::create('analytics_events', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
                $table->string('event', 60)->index();
                $table->json('props')->nullable();
                $table->timestamps();
                $table->index(['event', 'created_at']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('analytics_events');
    }
};
