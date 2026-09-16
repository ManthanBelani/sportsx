<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // NOTE: guards below make the migration re-runnable — MySQL DDL
        // auto-commits, so a failed run can leave earlier steps applied.

        // ── Tournament registrations: approval workflow ──
        Schema::table('tournament_registrations', function (Blueprint $table) {
            if (! Schema::hasColumn('tournament_registrations', 'approval_status')) {
                $table->string('approval_status', 20)->default('pending')->after('payment_status');
            }
            if (! Schema::hasColumn('tournament_registrations', 'rejection_reason')) {
                $table->string('rejection_reason', 500)->nullable()->after('approval_status');
            }
            if (! Schema::hasColumn('tournament_registrations', 'reviewed_by')) {
                $table->foreignId('reviewed_by')->nullable()->after('rejection_reason')
                    ->constrained('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('tournament_registrations', 'reviewed_at')) {
                $table->timestamp('reviewed_at')->nullable()->after('reviewed_by');
            }
            if (! Schema::hasColumn('tournament_registrations', 'reminder_enabled')) {
                $table->boolean('reminder_enabled')->default(false)->after('reviewed_at');
            }
            if (! Schema::hasColumn('tournament_registrations', 'admin_override')) {
                $table->boolean('admin_override')->default(false)->after('reminder_enabled');
            }
        });
        $this->addIndexIfMissing(
            'tournament_registrations',
            'tournament_registrations_approval_status_index',
            'approval_status'
        );

        // ── Trial registrations: approval workflow ──
        Schema::table('trial_registrations', function (Blueprint $table) {
            if (! Schema::hasColumn('trial_registrations', 'approval_status')) {
                $table->string('approval_status', 20)->default('pending')->after('verification_status');
            }
            if (! Schema::hasColumn('trial_registrations', 'rejection_reason')) {
                $table->string('rejection_reason', 500)->nullable()->after('approval_status');
            }
            if (! Schema::hasColumn('trial_registrations', 'reviewed_by')) {
                $table->foreignId('reviewed_by')->nullable()->after('rejection_reason')
                    ->constrained('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('trial_registrations', 'reviewed_at')) {
                $table->timestamp('reviewed_at')->nullable()->after('reviewed_by');
            }
            if (! Schema::hasColumn('trial_registrations', 'admin_override')) {
                $table->boolean('admin_override')->default(false)->after('reviewed_at');
            }
        });
        $this->addIndexIfMissing(
            'trial_registrations',
            'trial_registrations_approval_status_index',
            'approval_status'
        );

        if (Schema::getConnection()->getDriverName() === 'mysql') {
            \Illuminate\Support\Facades\DB::statement(
                "ALTER TABLE tournament_registrations MODIFY payment_status ENUM('pending','paid','waived') NOT NULL DEFAULT 'pending'"
            );
        }

        // ── Coaching enrollments (athlete requests → coach approves) ──
        if (! Schema::hasTable('coaching_enrollments')) {
            Schema::create('coaching_enrollments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('coach_id')->constrained('coach_profiles')->cascadeOnDelete();
            $table->foreignId('athlete_id')->constrained('athlete_profiles')->cascadeOnDelete();
            $table->enum('plan_type', ['session', 'monthly', 'quarterly']);
            $table->decimal('fees_amount', 10, 2)->default(0);
            $table->enum('status', ['active', 'inactive', 'cancelled', 'completed'])->default('inactive');
            $table->enum('approval_status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->string('rejection_reason', 500)->nullable();
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->integer('sessions_remaining')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->text('notes')->nullable();
            $table->text('coach_response')->nullable();
            $table->boolean('admin_override')->default(false);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['coach_id', 'athlete_id', 'plan_type'], 'coach_enroll_unique');
            $table->index(['approval_status']);
            $table->index(['coach_id', 'status']);
            });
        }

        // ── Activity log (audit trail for all approval actions) ──
        if (! Schema::hasTable('registration_activity_logs')) {
            Schema::create('registration_activity_logs', function (Blueprint $table) {
                $table->id();
                $table->string('registration_type', 40); // tournament, trial, coaching
                $table->unsignedBigInteger('registration_id');
                $table->string('action', 20); // submitted, approved, rejected, cancelled
                $table->string('actor_type', 20); // athlete, organizer, coach, admin, academy
                $table->unsignedBigInteger('actor_id');
                $table->json('metadata')->nullable();
                $table->string('ip_address', 45)->nullable();
                $table->text('user_agent')->nullable();
                $table->timestamps();

                // NOTE: explicit short names — the auto-generated MySQL index
                // names for this table exceed the 64-char identifier limit.
                $table->index(['registration_type', 'registration_id'], 'reg_logs_type_reg_idx');
                $table->index(['actor_type', 'actor_id'], 'reg_logs_actor_idx');
                $table->index(['action'], 'reg_logs_action_idx');
            });
        }
    }

    /**
     * Add an index only if it does not already exist (re-runnable
     * migrations after a partial failure on MySQL, where DDL commits).
     */
    private function addIndexIfMissing(string $table, string $index, string $column): void
    {
        $connection = Schema::getConnection();

        if ($connection->getDriverName() === 'mysql') {
            $exists = $connection->table('information_schema.statistics')
                ->where('table_schema', $connection->getDatabaseName())
                ->where('table_name', $table)
                ->where('index_name', $index)
                ->exists();

            if ($exists) {
                return;
            }
        }

        Schema::table($table, function (Blueprint $table) use ($column) {
            $table->index([$column]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('registration_activity_logs');
        Schema::dropIfExists('coaching_enrollments');

        if (Schema::getConnection()->getDriverName() === 'mysql') {
            \Illuminate\Support\Facades\DB::statement(
                "ALTER TABLE tournament_registrations MODIFY payment_status ENUM('pending','paid') NOT NULL DEFAULT 'pending'"
            );
        }

        Schema::table('trial_registrations', function (Blueprint $table) {
            $table->dropIndex(['approval_status']);
            $table->dropConstrainedForeignId('reviewed_by');
            $table->dropColumn(['approval_status', 'rejection_reason', 'reviewed_at', 'admin_override']);
        });

        Schema::table('tournament_registrations', function (Blueprint $table) {
            $table->dropIndex(['approval_status']);
            $table->dropConstrainedForeignId('reviewed_by');
            $table->dropColumn(['approval_status', 'rejection_reason', 'reviewed_at', 'reminder_enabled', 'admin_override']);
        });
    }
};
