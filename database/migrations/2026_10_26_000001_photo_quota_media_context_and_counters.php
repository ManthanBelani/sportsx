<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Photo-quota groundwork (plan: PHOTO_QUOTA_COMPRESSION_PLAN.md, Step 3A–3E).
 *
 * - `media_items.context` — how a photo is used (gallery | profile | cover |
 *   logo | post | achievement | credential).Quota counts ONLY context=gallery.
 * - `*_profiles.gallery_photo_count` — maintained counter per owner row so the
 *   quota check never re-counts media_items on every upload.
 * - `posts.image_media_ids` — multi-photo posts (max from post_max_photos).
 *
 * Backfill: legacy photos (context NULL) are tagged 'gallery' unless they are
 * referenced as a profile photo / cover photo / logo or post image.
 */
return new class extends Migration
{
    /** @var array<string, string> owner_type → profile table */
    public const PROFILE_TABLES = [
        'athlete_profile' => 'athlete_profiles',
        'coach_profile' => 'coach_profiles',
        'academy' => 'academies',
        'organizer_profile' => 'organizer_profiles',
        'sponsor_profile' => 'sponsor_profiles',
        'talent_scout_profile' => 'talent_scout_profiles',
    ];

    public function up(): void
    {
        if (Schema::hasTable('media_items') && ! Schema::hasColumn('media_items', 'context')) {
            Schema::table('media_items', function ($table) {
                $table->string('context', 20)->nullable()->index()->after('media_type');
                if (! Schema::hasColumn('media_items', 'compressed_at')) {
                    $table->timestamp('compressed_at')->nullable()->after('context');
                }
            });
        }

        foreach (self::PROFILE_TABLES as $table) {
            if (Schema::hasTable($table) && ! Schema::hasColumn($table, 'gallery_photo_count')) {
                Schema::table($table, function ($table) {
                    $table->unsignedInteger('gallery_photo_count')->default(0);
                });
            }
        }

        if (Schema::hasTable('posts') && ! Schema::hasColumn('posts', 'image_media_ids')) {
            Schema::table('posts', function ($table) {
                $table->json('image_media_ids')->nullable()->after('image_url');
            });
        }

        $this->backfill();
    }

    private function backfill(): void
    {
        if (! Schema::hasTable('media_items') || ! Schema::hasColumn('media_items', 'context')) {
            return;
        }

        // Photos referenced as profile/cover/logo stay NULL-ish (not counted);
        // everything else becomes a gallery photo. Referenced ids are collected
        // so the counter starting point also matches reality.
        $referenced = [];
        foreach (self::PROFILE_TABLES as $table) {
            if (! Schema::hasTable($table)) {
                continue;
            }
            foreach (['photo_media_id', 'cover_media_id', 'logo_media_id'] as $col) {
                if (Schema::hasColumn($table, $col)) {
                    foreach (DB::table($table)->whereNotNull($col)->pluck($col) as $id) {
                        $referenced[(int) $id] = true;
                    }
                }
            }
        }

        // Tag legacy photos: 'gallery' when not referenced as an avatar/cover/logo.
        foreach (DB::table('media_items')
            ->where('media_type', 'photo')
            ->whereNull('context')
            ->orderBy('id')
            ->cursor() as $row) {
            $ctx = isset($referenced[(int) $row->id]) ? 'profile' : 'gallery';
            DB::table('media_items')->where('id', $row->id)->update(['context' => $ctx]);
        }

        // Seed the counters with the real gallery-photo tallies.
        $counts = DB::table('media_items')
            ->selectRaw("owner_type, owner_id, COUNT(*) AS n")
            ->where('media_type', 'photo')
            ->where('context', 'gallery')
            ->groupBy('owner_type', 'owner_id')
            ->get();

        foreach ($counts as $row) {
            $table = self::PROFILE_TABLES[$row->owner_type] ?? null;
            if (! $table || ! Schema::hasColumn($table, 'gallery_photo_count')) {
                continue;
            }
            DB::table($table)->where('id', $row->owner_id)
                ->update(['gallery_photo_count' => $row->n]);
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('posts')) {
            Schema::table('posts', function ($table) {
                if (Schema::hasColumn('posts', 'image_media_ids')) {
                    $table->dropColumn('image_media_ids');
                }
            });
        }
        foreach (self::PROFILE_TABLES as $table) {
            if (Schema::hasTable($table)) {
                Schema::table($table, function ($table) {
                    if (Schema::hasColumn($table, 'gallery_photo_count')) {
                        $table->dropColumn('gallery_photo_count');
                    }
                });
            }
        }
        if (Schema::hasTable('media_items')) {
            Schema::table('media_items', function ($table) {
                if (Schema::hasColumn('media_items', 'context')) {
                    $table->dropColumn('context');
                }
            });
        }
    }
};
