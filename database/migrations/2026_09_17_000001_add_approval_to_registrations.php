<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // NOTE: superseded by 2026_09_17_000001_add_approval_workflow_to_registrations
        // which has hasColumn guards. Guards added here too so this stays
        // re-runnable on databases where the workflow migration already ran.
        Schema::table('tournament_registrations', function (Blueprint $table) {
            if (! Schema::hasColumn('tournament_registrations', 'approval_status')) {
                $table->string('approval_status')->default('pending')->after('payment_status');
            }
            if (! Schema::hasColumn('tournament_registrations', 'rejection_reason')) {
                $table->string('rejection_reason')->nullable()->after('approval_status');
            }
            if (! Schema::hasColumn('tournament_registrations', 'reviewed_by')) {
                $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete()->after('rejection_reason');
            }
            if (! Schema::hasColumn('tournament_registrations', 'reviewed_at')) {
                $table->timestamp('reviewed_at')->nullable()->after('reviewed_by');
            }
            if (! Schema::hasColumn('tournament_registrations', 'reminder_enabled')) {
                $table->boolean('reminder_enabled')->default(false)->after('reviewed_at');
            }
        });

        // SQLite does not support dropping enum checks easily, so we handle payment_status expansion via raw if needed.
        // Keep existing enum but add 'waived' handling at app level; no DB change needed for SQLite.

        Schema::table('trial_registrations', function (Blueprint $table) {
            if (! Schema::hasColumn('trial_registrations', 'approval_status')) {
                $table->string('approval_status')->default('pending')->after('verification_status');
            }
            if (! Schema::hasColumn('trial_registrations', 'rejection_reason')) {
                $table->string('rejection_reason')->nullable()->after('approval_status');
            }
            if (! Schema::hasColumn('trial_registrations', 'reviewed_by')) {
                $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete()->after('rejection_reason');
            }
            if (! Schema::hasColumn('trial_registrations', 'reviewed_at')) {
                $table->timestamp('reviewed_at')->nullable()->after('reviewed_by');
            }
            if (! Schema::hasColumn('trial_registrations', 'status')) {
                $table->string('status')->default('pending')->after('reviewed_at');
            }
        });

        // Add indexes
        try {
            Schema::table('tournament_registrations', function (Blueprint $table) {
                $table->index('approval_status');
            });
        } catch (\Throwable $e) {}

        try {
            Schema::table('trial_registrations', function (Blueprint $table) {
                $table->index('approval_status');
            });
        } catch (\Throwable $e) {}
    }

    public function down(): void
    {
        Schema::table('tournament_registrations', function (Blueprint $table) {
            $table->dropColumn(['approval_status', 'rejection_reason', 'reviewed_by', 'reviewed_at', 'reminder_enabled']);
        });

        Schema::table('trial_registrations', function (Blueprint $table) {
            $table->dropColumn(['approval_status', 'rejection_reason', 'reviewed_by', 'reviewed_at', 'status']);
        });
    }
};
