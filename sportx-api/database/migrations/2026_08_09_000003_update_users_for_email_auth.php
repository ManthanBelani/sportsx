<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'verification_token')) {
                $table->string('verification_token', 64)->nullable()->after('email_verified_at');
            }
            if (!Schema::hasColumn('users', 'reset_password_token')) {
                $table->string('reset_password_token', 64)->nullable();
            }
            if (!Schema::hasColumn('users', 'reset_password_sent_at')) {
                $table->timestamp('reset_password_sent_at')->nullable();
            }
        });

        Schema::dropIfExists('otp_codes');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'verification_token',
                'reset_password_token',
                'reset_password_sent_at'
            ]);
        });

        Schema::create('otp_codes', function (Blueprint $table) {
            $table->id();
            $table->string('phone');
            $table->string('code');
            $table->timestamp('expires_at');
            $table->timestamps();
        });
    }
};
