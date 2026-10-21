<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Organizers can run their own venues (grounds, courts, gyms) and list them
 * under "My Venues" / "Add Venue" the same way academies do.
 *
 * `academy_id` becomes nullable (a facility now has exactly one owner) and
 * `organizer_id` points at the owning organizer profile.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('facilities', function (Blueprint $table) {
            if (Schema::hasColumn('facilities', 'academy_id')) {
                // The FK stays, the column just becomes optional.
                $table->unsignedBigInteger('academy_id')->nullable()->change();
            }
            if (! Schema::hasColumn('facilities', 'organizer_id')) {
                $table->foreignId('organizer_id')->nullable()->constrained('organizer_profiles')->cascadeOnDelete()->after('academy_id');
            }
        });

        Schema::table('facilities', function (Blueprint $table) {
            $table->index('organizer_id');
        });
    }

    public function down(): void
    {
        Schema::table('facilities', function (Blueprint $table) {
            $table->dropColumn('organizer_id');
            $table->unsignedBigInteger('academy_id')->nullable(false)->change();
        });
    }
};
