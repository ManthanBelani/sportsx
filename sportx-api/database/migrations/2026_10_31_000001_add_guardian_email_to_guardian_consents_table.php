<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Move guardian consent verification from phone/SMS to email.
 *
 * No SMS vendor is configured (AS-60), so the phone-channel code could never
 * be delivered. The guardian email becomes the verification destination; the
 * phone stays as optional metadata for when an SMS transport lands.
 *
 * @see \App\Services\GuardianConsentService
 * @see \App\Http\Controllers\GuardianController
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('guardian_consents', function (Blueprint $table) {
            $table->string('guardian_phone', 20)->nullable()->change();
            $table->string('guardian_email')->nullable()->after('guardian_phone');

            // 'otp' | 'link' — the signed-link flow can be added later
            // without a further migration.
            $table->string('verification_method', 16)->default('otp')->after('guardian_email');
        });
    }

    public function down(): void
    {
        Schema::table('guardian_consents', function (Blueprint $table) {
            $table->dropColumn(['guardian_email', 'verification_method']);
            $table->string('guardian_phone', 20)->nullable(false)->change();
        });
    }
};
