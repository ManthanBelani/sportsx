<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Hardening for the FCM device registry.
 *
 * The table previously had a non-unique index on `token`, so the same FCM
 * registration token could be attached to several users (or several rows for
 * one user) whenever a device re-registered after a reinstall. FCM treats a
 * token as identifying exactly one app instance, so duplicates silently steal
 * each other's notifications.
 *
 * Also adds `last_seen_at` so PruneStaleDeviceTokensJob can retire tokens for
 * devices that have not checked in for months.
 *
 * @see \App\Jobs\PruneStaleDeviceTokensJob
 * @see docs/FCM-Notification-System.md
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_device_tokens', function (Blueprint $table) {
            if (! Schema::hasColumn('user_device_tokens', 'last_seen_at')) {
                $table->timestamp('last_seen_at')->nullable()->after('is_active');
            }

            if (! Schema::hasColumn('user_device_tokens', 'failure_count')) {
                $table->unsignedSmallInteger('failure_count')->default(0)->after('last_seen_at');
            }
        });

        // Collapse duplicates: keep the row with the most recent activity.
        if (DB::connection()->getDriverName() === 'mysql') {
            DB::statement('
                DELETE t1 FROM user_device_tokens t1
                INNER JOIN user_device_tokens t2
                WHERE t1.token = t2.token
                  AND t1.id > t2.id
            ');
        }

        Schema::table('user_device_tokens', function (Blueprint $table) {
            $table->dropIndex('user_device_tokens_token_index');
            $table->unique('token', 'user_device_tokens_token_unique');
        });
    }

    public function down(): void
    {
        Schema::table('user_device_tokens', function (Blueprint $table) {
            $table->dropUnique('user_device_tokens_token_unique');
            $table->index('token');

            $table->dropColumn(['last_seen_at', 'failure_count']);
        });
    }
};