<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trials', function (Blueprint $table) {
            $table->id();
            $table->foreignId('posted_by_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('academy_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name', 150);
            $table->string('organization_name', 150)->nullable();
            $table->foreignId('sport_id')->constrained()->restrictOnDelete();
            $table->timestamp('event_datetime')->index();
            $table->string('venue', 190);
            $table->string('google_maps_url')->nullable();
            $table->foreignId('city_id')->nullable()->constrained()->nullOnDelete();
            $table->string('contact_number', 20);
            $table->timestamp('registration_deadline')->nullable()->index();
            $table->text('eligibility')->nullable();
            $table->json('required_documents')->nullable();
            $table->unsignedSmallInteger('vacancies')->nullable();
            $table->text('benefits')->nullable();
            $table->string('entry_fee', 60)->nullable();
            $table->enum('status', ['draft', 'published', 'closed', 'expired', 'removed'])->index()->default('draft');
            $table->timestamp('expires_at')->nullable()->index();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['status', 'event_datetime']);
            $table->index(['status', 'expires_at']);
            $table->index(['sport_id', 'city_id', 'status']);
            $table->index(['posted_by_user_id', 'status']);
        });

        Schema::create('trial_registrations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trial_id')->constrained()->cascadeOnDelete();
            $table->foreignId('athlete_id')->constrained('athlete_profiles')->cascadeOnDelete();
            $table->string('registration_ref', 20)->unique();
            $table->enum('document_status', ['pending', 'submitted'])->default('pending');
            $table->enum('verification_status', ['pending', 'verified', 'rejected'])->default('pending');
            $table->boolean('reminder_enabled')->default(false);
            $table->softDeletes();
            $table->timestamps();

            $table->unique(['trial_id', 'athlete_id']);
            $table->index(['athlete_id', 'verification_status']);
        });

        Schema::create('trial_registration_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trial_registration_id')->constrained()->cascadeOnDelete();
            $table->string('document_type', 60);
            $table->foreignId('media_item_id')->constrained()->cascadeOnDelete();
            $table->enum('status', ['uploaded', 'rejected'])->default('uploaded');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trial_registration_documents');
        Schema::dropIfExists('trial_registrations');
        Schema::dropIfExists('trials');
    }
};
