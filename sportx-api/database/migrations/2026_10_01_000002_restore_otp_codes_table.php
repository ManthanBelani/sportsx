<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Restores the OTP table with the schema App\Services\OtpService actually
 * targets.
 *
 * History: 2026_01_01_000002 created a hash-based OTP table, then
 * 2026_08_09_000003 dropped it when the flow moved to "click the emailed link".
 * That left OtpService, the OtpCode model and PurgeExpiredOtpsJob pointing at a
 * table that no longer existed. This migration brings it back for the
 * passwordless / email-OTP sign-in path and for email verification.
 *
 * @see \App\Services\OtpService
 * @see docs/Email-Provider-Architecture.md
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('otp_codes')) {
            return;
        }

        Schema::create('otp_codes', function (Blueprint $table) {
            $table->id();

            // Nullable so pre-login flows (sign-in with OTP) can issue a code
            // before the user record exists.
            $table->foreignId('user_id')
                ->nullable()
                ->constrained('users')
                ->cascadeOnDelete();

            // "email" for the MVP; kept as an enum so SMS can be added later
            // without touching every query.
            $table->enum('channel', ['email', 'phone'])->default('email');

            // The normalised address/number the code was sent to.
            $table->string('destination', 191);

            // bcrypt hash — the plaintext code exists only in the outbound email.
            $table->string('code_hash', 191);

            $table->string('purpose', 32)->default('login');

            $table->timestamp('expires_at');
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('consumed_at')->nullable();

            $table->timestamps();

            // Verification reads the newest unconsumed code for this tuple.
            $table->index(['user_id', 'channel', 'destination', 'created_at'], 'otp_codes_lookup_index');
            $table->index(['expires_at', 'consumed_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('otp_codes');
    }
};