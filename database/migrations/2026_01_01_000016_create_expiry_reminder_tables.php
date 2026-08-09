<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('expiry_rules', function (Blueprint $table) {
            $table->id();
            $table->enum('content_type', ['trial', 'tournament', 'sponsorship', 'scholarship'])->unique();
            $table->enum('trigger_field', ['event_date', 'final_date', 'listed_deadline']);
            $table->smallInteger('days_after')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('expiry_events', function (Blueprint $table) {
            $table->id();
            $table->enum('content_type', ['trial', 'tournament', 'sponsorship', 'scholarship']);
            $table->unsignedBigInteger('content_id');
            $table->timestamp('scheduled_at');
            $table->timestamp('executed_at')->nullable();
            $table->enum('status', ['pending', 'expired', 'overridden', 'restored'])->default('pending');
            $table->foreignId('overridden_by')->nullable()->constrained('users');
            $table->timestamps();

            $table->index(['status', 'scheduled_at']);
            $table->index(['content_type', 'content_id']);
        });

        Schema::create('reminder_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('reminderable_type');
            $table->unsignedBigInteger('reminderable_id');
            $table->timestamp('remind_at')->index();
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'reminderable_type', 'reminderable_id'], 'reminder_subs_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reminder_subscriptions');
        Schema::dropIfExists('expiry_events');
        Schema::dropIfExists('expiry_rules');
    }
};
