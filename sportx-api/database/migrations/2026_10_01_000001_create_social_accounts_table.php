<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Linked third-party identities ("Continue with Google").
 *
 * Kept separate from `users` so more providers can be added without another
 * users migration, and so a user can hold several identities. `users.google_id`
 * is retained for backwards compatibility with the original single-column
 * prototype and is kept in sync by SocialAuthService.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('social_accounts', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // "google" today; the column is a string so Apple/Apple-Sign-In can
            // be added without a migration.
            $table->string('provider', 32);

            // The provider's stable subject identifier (`sub` claim for Google).
            $table->string('provider_user_id', 191);

            $table->string('email')->nullable();
            $table->string('name')->nullable();
            $table->string('avatar_url', 500)->nullable();

            // Encrypted at rest by the model cast.
            $table->text('access_token')->nullable();
            $table->text('refresh_token')->nullable();
            $table->timestamp('token_expires_at')->nullable();
            $table->string('scopes')->nullable();

            $table->timestamps();

            // One provider identity maps to exactly one user.
            $table->unique(['provider', 'provider_user_id'], 'social_accounts_provider_user_unique');
            $table->index(['user_id', 'provider']);
        });

        // Drop the prototype column once the join table is authoritative.
        if (Schema::hasColumn('users', 'google_id')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropUnique('users_google_id_unique');
                $table->dropColumn('google_id');
            });
        }

        // Widen the notifications.type enum to the full vocabulary used by
        // NotificationService (see docs/FCM-Notification-System.md).
        if (DB::connection()->getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE notifications MODIFY COLUMN type VARCHAR(40) NOT NULL DEFAULT 'status_update'");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('social_accounts');

        if (! Schema::hasColumn('users', 'google_id')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('google_id')->nullable()->unique()->after('password');
            });
        }
    }
};