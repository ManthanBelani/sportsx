<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Columns the FCM-backed notification system needs beyond the original
 * `notifications` table, which only tracked in-app rows.
 *
 * - channel      : how the user was reached (in_app | push | email | sms)
 * - image_url    : large image for rich push notifications
 * - priority     : FCM android.priority / APNs push priority
 * - category     : client-side routing key ("enquiry", "trial", "scout")
 * - metadata     : arbitrary payload for deep links
 * - pushed_at    : when the FCM job actually handed the message to Google
 * - push_status  : queued | sent | failed | no_devices (drives the email fallback)
 *
 * @see \App\Services\NotificationService
 * @see docs/FCM-Notification-System.md
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            if (! Schema::hasColumn('notifications', 'channel')) {
                $table->string('channel', 16)->default('in_app')->after('type');
            }

            if (! Schema::hasColumn('notifications', 'category')) {
                $table->string('category', 40)->nullable()->after('body');
            }

            if (! Schema::hasColumn('notifications', 'image_url')) {
                $table->string('image_url', 500)->nullable()->after('category');
            }

            if (! Schema::hasColumn('notifications', 'priority')) {
                $table->enum('priority', ['normal', 'high'])->default('normal')->after('image_url');
            }

            if (! Schema::hasColumn('notifications', 'metadata')) {
                $table->json('metadata')->nullable()->after('action_url');
            }

            if (! Schema::hasColumn('notifications', 'pushed_at')) {
                $table->timestamp('pushed_at')->nullable()->after('metadata');
            }

            if (! Schema::hasColumn('notifications', 'push_status')) {
                $table->string('push_status', 16)->nullable()->after('pushed_at');
            }
        });

        // The reminder sweeper polls unread rows by type; widen the index now
        // that the vocabulary has grown well past the original three values.
        Schema::table('notifications', function (Blueprint $table) {
            $table->index(['type', 'created_at'], 'notifications_type_created_index');
        });
    }

    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropIndex('notifications_type_created_index');

            $table->dropColumn([
                'channel',
                'category',
                'image_url',
                'priority',
                'metadata',
                'pushed_at',
                'push_status',
            ]);
        });
    }
};