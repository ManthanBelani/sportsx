<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // {instagram, facebook, youtube, x, linkedin, website} URLs (nullable json).
            // Shared by every role: athlete, coach, academy, organizer, sponsor, talent_scout, admin.
            $table->json('social_links')->nullable()->after('notification_prefs');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('social_links');
        });
    }
};
