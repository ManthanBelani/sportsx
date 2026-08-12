<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('trial_registrations', function (Blueprint $table) {
            $table->string('playing_role', 100)->nullable()->after('registration_ref');
            $table->text('medical_conditions')->nullable()->after('playing_role');
            $table->boolean('parental_consent')->default(false)->after('medical_conditions');
        });
    }

    public function down(): void
    {
        Schema::table('trial_registrations', function (Blueprint $table) {
            $table->dropColumns(['playing_role', 'medical_conditions', 'parental_consent']);
        });
    }
};
