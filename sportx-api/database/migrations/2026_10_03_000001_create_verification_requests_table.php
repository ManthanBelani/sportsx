<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Blue-check verification requests.
 *
 * Polymorphic: an athlete, coach, academy, organizer or scout can request
 * verification against whichever entity they own. Proof documents are stored as
 * `media_items` and referenced here by id, so the documents themselves live in
 * private object storage behind signed URLs.
 *
 * @see \App\Models\VerificationRequest
 * @see \App\Http\Controllers\VerificationController
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('verification_requests', function (Blueprint $table) {
            $table->id();

            $table->foreignId('requester_user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // The entity being verified (athlete_profile, coach_profile, ...).
            // `morphs()` creates its own composite index on these two columns,
            // so no additional index is declared here.
            $table->morphs('verifiable');

            // 'pending' | 'approved' | 'rejected'
            $table->enum('status', ['pending', 'approved', 'rejected'])
                ->default('pending')
                ->index();

            // ID document + organisation proof, as media_items ids.
            $table->json('proof_media_ids')->nullable();

            $table->text('notes')->nullable();

            $table->foreignId('reviewed_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->text('decision_reason')->nullable();
            $table->timestamp('reviewed_at')->nullable();

            $table->timestamps();

            $table->index(['status', 'created_at'], 'verification_requests_status_created_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('verification_requests');
    }
};