<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coaching_enrollments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('coach_id')->constrained('coach_profiles')->cascadeOnDelete();
            $table->foreignId('athlete_id')->constrained('athlete_profiles')->cascadeOnDelete();
            $table->enum('plan_type', ['session', 'monthly', 'quarterly']);
            $table->decimal('fees_amount', 10, 2);
            $table->enum('status', ['active', 'inactive', 'cancelled', 'completed'])->default('inactive');
            $table->enum('approval_status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->string('rejection_reason')->nullable();
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->integer('sessions_remaining')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->text('notes')->nullable();
            $table->text('coach_response')->nullable();
            $table->timestamps();

            $table->unique(['coach_id', 'athlete_id', 'plan_type']);
            $table->index(['approval_status']);
            $table->index(['coach_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coaching_enrollments');
    }
};
