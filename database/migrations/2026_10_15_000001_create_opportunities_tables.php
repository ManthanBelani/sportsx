<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Unified opportunities (Phase 4): provider morph academy /
        // organizer / coach / scout; type scholarship / sponsorship / tryout /
        // camp. Replaces scholarships + sponsorships (legacy tables stay
        // readable; rows are backfilled below).
        if (! Schema::hasTable('opportunities')) {
            Schema::create('opportunities', function (Blueprint $table) {
                $table->id();
                $table->string('provider_type', 50);
                $table->unsignedBigInteger('provider_id');
                $table->foreignId('created_by_user_id')->constrained('users')->cascadeOnDelete();
                $table->enum('type', ['scholarship', 'sponsorship', 'tryout', 'camp']);
                $table->string('title', 255);
                $table->foreignId('sport_id')->nullable()->constrained('sports')->nullOnDelete();
                $table->foreignId('age_group_id')->nullable()->constrained('age_groups')->nullOnDelete();
                $table->text('eligibility')->nullable();
                $table->text('benefits')->nullable();
                $table->decimal('amount', 12, 2)->nullable();
                $table->date('deadline')->nullable();
                $table->json('documents_required')->nullable();
                $table->text('description')->nullable();
                $table->foreignId('logo_media_id')->nullable()->constrained('media_items')->nullOnDelete();
                $table->enum('status', ['draft', 'published', 'closed', 'expired'])->default('draft');
                $table->string('legacy_type', 50)->nullable();
                $table->unsignedBigInteger('legacy_id')->nullable();
                $table->timestamp('expires_at')->nullable();
                $table->timestamps();
                $table->softDeletes();

                $table->index(['provider_type', 'provider_id']);
                $table->index(['type', 'status']);
                $table->index(['sport_id', 'status']);
                $table->index('deadline');
                $table->unique(['legacy_type', 'legacy_id'], 'opportunities_legacy_unique');
            });
        }

        if (! Schema::hasTable('opportunity_applications')) {
            Schema::create('opportunity_applications', function (Blueprint $table) {
                $table->id();
                $table->foreignId('opportunity_id')->constrained('opportunities')->cascadeOnDelete();
                $table->foreignId('athlete_id')->constrained('athlete_profiles')->cascadeOnDelete();
                $table->text('pitch');
                $table->json('document_media_ids')->nullable();
                $table->json('snapshot')->nullable();
                $table->enum('status', ['submitted', 'shortlisted', 'declined'])->default('submitted');
                $table->string('decision_note', 1000)->nullable();
                $table->timestamp('replied_at')->nullable();
                $table->timestamps();

                $table->unique(['opportunity_id', 'athlete_id'], 'opp_applications_unique');
                $table->index(['athlete_id', 'status']);
            });
        }

        $this->backfillLegacy();
    }

    /**
     * One-time copy of scholarships / sponsorships (+ sponsorship
     * applications) into the unified tables. Guarded so re-running the
     * migration never duplicates rows.
     */
    protected function backfillLegacy(): void
    {
        if (! Schema::hasTable('opportunities') || ! Schema::hasTable('opportunity_applications')) {
            return;
        }

        if (Schema::hasTable('scholarships')) {
            $rows = DB::table('scholarships')->get();
            foreach ($rows as $row) {
                $exists = DB::table('opportunities')
                    ->where('legacy_type', 'scholarship')
                    ->where('legacy_id', $row->id)
                    ->exists();
                if ($exists) {
                    continue;
                }

                DB::table('opportunities')->insert([
                    'provider_type' => 'user',
                    'provider_id' => $row->created_by ?? 0,
                    'created_by_user_id' => $row->created_by ?? 1,
                    'type' => 'scholarship',
                    'title' => $row->name ?? 'Scholarship',
                    'sport_id' => $row->sport_id,
                    'age_group_id' => null,
                    'eligibility' => $row->eligibility,
                    'benefits' => $row->benefits,
                    'amount' => $row->amount,
                    'deadline' => $row->deadline,
                    'documents_required' => $row->documents_required,
                    'description' => $row->description,
                    'logo_media_id' => $row->logo_media_id,
                    'status' => in_array($row->status, ['draft', 'published', 'closed', 'expired'], true) ? $row->status : 'closed',
                    'legacy_type' => 'scholarship',
                    'legacy_id' => $row->id,
                    'created_at' => $row->created_at ?? now(),
                    'updated_at' => $row->updated_at ?? now(),
                ]);
            }
        }

        if (Schema::hasTable('sponsorships')) {
            $rows = DB::table('sponsorships')->get();
            foreach ($rows as $row) {
                $exists = DB::table('opportunities')
                    ->where('legacy_type', 'sponsorship')
                    ->where('legacy_id', $row->id)
                    ->exists();
                if ($exists) {
                    continue;
                }

                $providerId = 0;
                $createdBy = 1;
                if (isset($row->sponsor_id) && Schema::hasTable('sponsor_profiles')) {
                    $profile = DB::table('sponsor_profiles')->where('id', $row->sponsor_id)->first();
                    if ($profile) {
                        $createdBy = $profile->user_id;
                    }
                }

                DB::table('opportunities')->insert([
                    'provider_type' => 'sponsor_profile',
                    'provider_id' => $row->sponsor_id ?? $providerId,
                    'created_by_user_id' => $createdBy,
                    'type' => 'sponsorship',
                    'title' => $row->title ?? 'Sponsorship',
                    'sport_id' => $row->sport_id,
                    'age_group_id' => null,
                    'eligibility' => $row->eligibility_criteria,
                    'benefits' => $row->benefits_offered,
                    'amount' => $row->amount,
                    'deadline' => $row->deadline,
                    'documents_required' => $row->documents_required,
                    'description' => $row->description,
                    'logo_media_id' => $row->logo_media_id,
                    'status' => in_array($row->status, ['draft', 'published', 'closed', 'expired'], true) ? $row->status : 'closed',
                    'legacy_type' => 'sponsorship',
                    'legacy_id' => $row->id,
                    'expires_at' => $row->expires_at ?? null,
                    'created_at' => $row->created_at ?? now(),
                    'updated_at' => $row->updated_at ?? now(),
                ]);
            }
        }

        if (Schema::hasTable('sponsorship_applications')) {
            $rows = DB::table('sponsorship_applications')->get();
            foreach ($rows as $row) {
                $opportunityId = DB::table('opportunities')
                    ->where('legacy_type', 'sponsorship')
                    ->where('legacy_id', $row->sponsorship_id)
                    ->value('id');
                if (! $opportunityId) {
                    continue;
                }

                $exists = DB::table('opportunity_applications')
                    ->where('opportunity_id', $opportunityId)
                    ->where('athlete_id', $row->athlete_id)
                    ->exists();
                if ($exists) {
                    continue;
                }

                $status = match ($row->status ?? 'submitted') {
                    'shortlisted' => 'shortlisted',
                    'rejected' => 'declined',
                    default => 'submitted',
                };

                DB::table('opportunity_applications')->insert([
                    'opportunity_id' => $opportunityId,
                    'athlete_id' => $row->athlete_id,
                    'pitch' => $row->pitch_note ?? '',
                    'document_media_ids' => null,
                    'snapshot' => null,
                    'status' => $status,
                    'decision_note' => null,
                    'replied_at' => $row->replied_at,
                    'created_at' => $row->created_at ?? now(),
                    'updated_at' => $row->updated_at ?? now(),
                ]);
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('opportunity_applications');
        Schema::dropIfExists('opportunities');
    }
};
