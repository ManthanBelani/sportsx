<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('scout_connections', function (Blueprint $table) {
            $table->foreignId('requested_by_user_id')->nullable()->after('athlete_profile_id')->constrained('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('scout_connections', function (Blueprint $table) {
            $table->dropConstrainedForeignId('requested_by_user_id');
        });
    }
};
