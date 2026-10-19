<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Closes the Organizer mandatory-field gaps from
 * sportsx-design-v3/new_design_docs/SportX_Mandatory_Fields.md §5.
 *
 * `organizer_profiles` had only 3 domain columns (organization_name, org_type,
 * verification_status) against a spec of 30. This adds the missing mandatory set:
 *
 *   #2 Logo / Cover Photo  -> logo_media_id, cover_media_id
 *   #4 Primary Sport(s)    -> organizer_sports pivot
 *   #5 Event Types         -> event_types (JSON)
 *   #6 City / State        -> city_id
 *   #7 Short Description   -> description
 *
 * Also widens `org_type` to the values the API already accepts (OrganizerProfileController
 * validates 7 types and maps 4 of them down onto the old 3-value enum, so those inputs were
 * being silently collapsed to "federation"/"other"), and adds `registration_number`,
 * `website` and `verification_doc_media_id`, which the controller validates but which have
 * no column to persist to.
 *
 * Every column is nullable so existing rows survive untouched.
 */
return new class extends Migration
{
    public function up(): void
    {
        // ── Widen org_type ────────────────────────────────────────────────────
        // Old enum: federation, club, other.
        // Spec §5 #3: Event Company, Individual, Club, College, Federation, NGO.
        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE organizer_profiles MODIFY `org_type` ENUM('event_company','individual','club','college','federation','ngo','other') NOT NULL");
        }

        Schema::table('organizer_profiles', function (Blueprint $table) {
            // #2 Logo / Cover Photo
            if (!Schema::hasColumn('organizer_profiles', 'logo_media_id')) {
                $table->foreignId('logo_media_id')->nullable()->constrained('media_items')->nullOnDelete()->after('organization_name');
            }
            if (!Schema::hasColumn('organizer_profiles', 'cover_media_id')) {
                $table->foreignId('cover_media_id')->nullable()->constrained('media_items')->nullOnDelete()->after('logo_media_id');
            }

            // #6 City / State
            if (!Schema::hasColumn('organizer_profiles', 'city_id')) {
                $table->foreignId('city_id')->nullable()->constrained('cities')->nullOnDelete()->after('org_type');
            }

            // #7 Short Description (2-3 lines)
            if (!Schema::hasColumn('organizer_profiles', 'description')) {
                $table->text('description')->nullable()->after('city_id');
            }

            // #5 Event Types — JSON array of strings, e.g. ["tournament","trial","camp"]
            if (!Schema::hasColumn('organizer_profiles', 'event_types')) {
                $table->json('event_types')->nullable()->after('description');
            }

            // Already validated by OrganizerProfileController::update but had no column.
            if (!Schema::hasColumn('organizer_profiles', 'registration_number')) {
                $table->string('registration_number', 100)->nullable()->after('event_types');
            }
            if (!Schema::hasColumn('organizer_profiles', 'website')) {
                $table->string('website', 255)->nullable()->after('registration_number');
            }
            if (!Schema::hasColumn('organizer_profiles', 'verification_doc_media_id')) {
                $table->foreignId('verification_doc_media_id')->nullable()->constrained('media_items')->nullOnDelete()->after('website');
            }
        });

        // #4 Primary Sport(s) — mirrors the academy_sports pattern.
        if (!Schema::hasTable('organizer_sports')) {
            Schema::create('organizer_sports', function (Blueprint $table) {
                $table->id();
                $table->foreignId('organizer_id')->constrained('organizer_profiles')->cascadeOnDelete();
                $table->foreignId('sport_id')->constrained('sports')->restrictOnDelete();
                $table->timestamps();

                $table->unique(['organizer_id', 'sport_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('organizer_sports');

        Schema::table('organizer_profiles', function (Blueprint $table) {
            foreach ([
                'verification_doc_media_id', 'website', 'registration_number',
                'event_types', 'description', 'city_id', 'cover_media_id', 'logo_media_id',
            ] as $col) {
                if (Schema::hasColumn('organizer_profiles', $col)) {
                    $table->dropColumn($col);
                }
            }
        });

        // Collapse any values that no longer fit the 3-value enum before narrowing it.
        if (DB::getDriverName() === 'mysql') {
            DB::table('organizer_profiles')
                ->whereNotIn('org_type', ['federation', 'club', 'other'])
                ->update(['org_type' => 'other']);

            DB::statement("ALTER TABLE organizer_profiles MODIFY `org_type` ENUM('federation','club','other') NOT NULL");
        }
    }
};