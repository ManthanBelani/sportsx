<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Verified guardian approval for an athlete under 18.
 *
 * A minor's profile must not become publicly visible, discoverable, or
 * contactable until a guardian has proven control of a phone number and
 * confirmed consent. This table records that proof.
 *
 * Consent is revocable: `consent_status` moves to `revoked` and the athlete's
 * profile visibility is restored to restricted defaults.
 *
 * @see \App\Models\GuardianConsent
 * @see \App\Http\Controllers\GuardianController
 * @see docs/Security-and-NonFunctional.md §2.2 (minors' data, India context)
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('guardian_consents', function (Blueprint $table) {
            $table->id();

            $table->foreignId('athlete_user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('guardian_name', 120);
            $table->string('guardian_phone', 20);

            // 'parent' | 'guardian' | 'sibling' | 'other'
            $table->string('relationship', 40);

            // pending → verified once the guardian's OTP is confirmed.
            $table->enum('consent_status', ['pending', 'verified', 'revoked'])
                ->default('pending')
                ->index();

            // Which of the parent's controls are in force.
            $table->boolean('allow_messages')->default(true);
            $table->boolean('allow_public_profile')->default(false);

            // 'first_name_initial' | 'hidden'
            $table->string('leaderboard_name_mode', 32)->default('first_name_initial');

            $table->timestamp('verified_at')->nullable();
            $table->timestamp('revoked_at')->nullable();

            $table->timestamps();

            // One live consent per athlete; a revoked row can be superseded.
            $table->index(['athlete_user_id', 'consent_status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('guardian_consents');
    }
};