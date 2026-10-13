<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Media caption + sport tag (Phase 2: `POST /media/upload` extras).
        if (Schema::hasTable('media_items')) {
            Schema::table('media_items', function (Blueprint $table) {
                if (! Schema::hasColumn('media_items', 'caption')) {
                    $table->string('caption', 280)->nullable()->after('original_name');
                }
                if (! Schema::hasColumn('media_items', 'sport_id')) {
                    $table->foreignId('sport_id')->nullable()->after('caption')
                        ->constrained('sports')->nullOnDelete();
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('media_items')) {
            Schema::table('media_items', function (Blueprint $table) {
                $dropped = [];
                foreach (['sport_id', 'caption'] as $column) {
                    if (Schema::hasColumn('media_items', $column)) {
                        $dropped[] = $column;
                    }
                }
                if ($dropped !== []) {
                    $table->dropColumn($dropped);
                }
            });
        }
    }
};
