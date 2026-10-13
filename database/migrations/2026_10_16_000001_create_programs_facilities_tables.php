<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Training programs (Phase 5): owner morph coach / academy.
        if (! Schema::hasTable('programs')) {
            Schema::create('programs', function (Blueprint $table) {
                $table->id();
                $table->string('owner_type', 50);
                $table->unsignedBigInteger('owner_id');
                $table->foreignId('created_by_user_id')->constrained('users')->cascadeOnDelete();
                $table->string('title', 255);
                $table->foreignId('sport_id')->nullable()->constrained('sports')->nullOnDelete();
                $table->foreignId('age_group_id')->nullable()->constrained('age_groups')->nullOnDelete();
                $table->string('duration', 120)->nullable();
                $table->string('mode', 20)->default('offline');
                $table->decimal('price', 12, 2)->nullable();
                $table->text('schedule')->nullable();
                $table->text('about')->nullable();
                $table->enum('status', ['draft', 'active', 'past'])->default('draft');
                $table->timestamps();
                $table->softDeletes();

                $table->index(['owner_type', 'owner_id']);
                $table->index(['status', 'sport_id']);
            });
        }

        // Academy facilities (Phase 5): structured rows replacing the
        // free-form `academies.facilities` JSON (backfilled below).
        if (! Schema::hasTable('facilities')) {
            Schema::create('facilities', function (Blueprint $table) {
                $table->id();
                $table->foreignId('academy_id')->constrained('academies')->cascadeOnDelete();
                $table->string('name', 150);
                $table->string('type', 30)->default('other');
                $table->string('size', 120)->nullable();
                $table->json('amenities')->nullable();
                $table->json('image_media_ids')->nullable();
                $table->timestamps();

                $table->index('academy_id');
            });
        }

        $this->backfillAcademyFacilities();
    }

    /**
     * Copy each academy's JSON `facilities` list into structured rows.
     * Guarded — re-running never duplicates.
     */
    protected function backfillAcademyFacilities(): void
    {
        if (! Schema::hasTable('facilities') || ! Schema::hasTable('academies')) {
            return;
        }

        if (! Schema::hasColumn('academies', 'facilities')) {
            return;
        }

        $academies = DB::table('academies')->select('id', 'facilities')->get();

        foreach ($academies as $academy) {
            $raw = $academy->facilities;
            if (is_string($raw)) {
                $decoded = json_decode($raw, true);
                $items = is_array($decoded) ? $decoded : [$raw];
            } elseif (is_array($raw)) {
                $items = $raw;
            } else {
                continue;
            }

            foreach ($items as $entry) {
                $name = is_array($entry) ? ($entry['name'] ?? null) : $entry;
                if (! is_string($name) || trim($name) === '') {
                    continue;
                }

                $exists = DB::table('facilities')
                    ->where('academy_id', $academy->id)
                    ->where('name', trim($name))
                    ->exists();
                if ($exists) {
                    continue;
                }

                DB::table('facilities')->insert([
                    'academy_id' => $academy->id,
                    'name' => trim($name),
                    'type' => is_array($entry) ? strtolower($entry['type'] ?? 'other') : 'other',
                    'size' => is_array($entry) ? ($entry['size'] ?? null) : null,
                    'amenities' => is_array($entry) && isset($entry['amenities']) ? json_encode($entry['amenities']) : null,
                    'image_media_ids' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('facilities');
        Schema::dropIfExists('programs');
    }
};
