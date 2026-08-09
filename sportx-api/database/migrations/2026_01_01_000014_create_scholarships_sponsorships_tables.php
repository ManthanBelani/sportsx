<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('scholarships', function (Blueprint $table) {
            $table->id();
            $table->string('organization_name', 150);
            $table->string('name', 150);
            $table->foreignId('sport_id')->nullable()->constrained()->restrictOnDelete();
            $table->text('eligibility');
            $table->date('deadline')->index();
            $table->string('application_link');
            $table->string('contact_email', 190)->nullable();
            $table->string('contact_phone', 20)->nullable();
            $table->decimal('amount', 12, 2)->nullable();
            $table->char('currency', 3)->default('INR');
            $table->text('benefits')->nullable();
            $table->json('documents_required')->nullable();
            $table->text('description')->nullable();
            $table->foreignId('logo_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            $table->enum('status', ['draft', 'published', 'expired', 'removed'])->default('published');
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['status', 'deadline']);
            $table->index(['sport_id', 'status']);
        });

        Schema::create('sponsorships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sponsor_id')->constrained('sponsor_profiles')->cascadeOnDelete();
            $table->string('organization_name', 150)->nullable();
            $table->foreignId('sport_id')->constrained()->restrictOnDelete();
            $table->string('title', 150);
            $table->text('eligibility_criteria');
            $table->date('deadline')->index();
            $table->string('application_link')->nullable();
            $table->string('contact_email', 190)->nullable();
            $table->string('contact_phone', 20)->nullable();
            $table->text('benefits_offered')->nullable();
            $table->decimal('amount', 12, 2)->nullable();
            $table->json('documents_required')->nullable();
            $table->text('description')->nullable();
            $table->foreignId('logo_media_id')->nullable()->constrained('media_items')->nullOnDelete();
            $table->enum('status', ['draft', 'published', 'closed', 'expired', 'removed'])->default('draft');
            $table->timestamp('expires_at')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['status', 'deadline']);
            $table->index(['sport_id', 'status']);
        });

        Schema::create('sponsorship_applications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sponsorship_id')->constrained()->cascadeOnDelete();
            $table->foreignId('athlete_id')->constrained('athlete_profiles')->cascadeOnDelete();
            $table->text('pitch_note');
            $table->enum('status', ['submitted', 'shortlisted', 'rejected'])->default('submitted');
            $table->timestamp('replied_at')->nullable();
            $table->timestamps();

            $table->unique(['sponsorship_id', 'athlete_id']);
            $table->index(['athlete_id', 'status']);
            $table->index(['sponsorship_id', 'status']);
        });

        Schema::create('shortlist_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sponsor_id')->constrained('sponsor_profiles')->cascadeOnDelete();
            $table->foreignId('athlete_id')->constrained('athlete_profiles')->cascadeOnDelete();
            $table->text('note')->nullable();
            $table->timestamps();

            $table->unique(['sponsor_id', 'athlete_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shortlist_entries');
        Schema::dropIfExists('sponsorship_applications');
        Schema::dropIfExists('sponsorships');
        Schema::dropIfExists('scholarships');
    }
};
