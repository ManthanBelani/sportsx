<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * External registration links for organizers.
 *
 * A tournament can either use SportX's internal registration flow or point
 * the "Register" button at an external form (Google Forms, a third-party
 * registration system, the organizer's own site). Clicks on that button are
 * tracked separately from confirmed registrations because the external site
 * never shares its data back with us.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tournaments', function (Blueprint $table) {
            if (! Schema::hasColumn('tournaments', 'external_registration_url')) {
                $table->string('external_registration_url', 500)->nullable()->after('registration_link');
            }
            if (! Schema::hasColumn('tournaments', 'external_registration_clicks')) {
                $table->unsignedInteger('external_registration_clicks')->default(0)->after('external_registration_url');
            }
        });

        if (! Schema::hasTable('tournament_registration_clicks')) {
            Schema::create('tournament_registration_clicks', function (Blueprint $table) {
                $table->id();
                $table->foreignId('tournament_id')->constrained('tournaments')->cascadeOnDelete();
                // Guests may click the button without signing in.
                $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
                // Client supplied idempotency key — the unique index is what
                // stops duplicate API calls / re-renders from double counting.
                $table->string('click_token', 64);
                $table->timestamp('created_at')->useCurrent();

                $table->unique(['tournament_id', 'click_token']);
                $table->index(['tournament_id', 'created_at']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('tournament_registration_clicks');

        Schema::table('tournaments', function (Blueprint $table) {
            if (Schema::hasColumn('tournaments', 'external_registration_clicks')) {
                $table->dropColumn('external_registration_clicks');
            }
            if (Schema::hasColumn('tournaments', 'external_registration_url')) {
                $table->dropColumn('external_registration_url');
            }
        });
    }
};
