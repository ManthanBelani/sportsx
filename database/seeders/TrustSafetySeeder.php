<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\GuardianConsent;
use App\Models\OrganizerProfile;
use App\Models\TalentScoutProfile;
use App\Models\VerificationRequest;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Trust & safety: blue-check verification requests and guardian consents.
 *
 * Verification requests cover all three states so the admin panel's
 * approve / reject queue is populated. Guardian consents cover verified,
 * pending and revoked, and drive the minor-chat and leaderboard masking
 * behaviour.
 */
class TrustSafetySeeder extends Seeder
{
    public function run(): void
    {
        /* ── Verification requests ────────────────────────────────── */
        $academy = Academy::where('owner_user_id', SeedLookup::userId('academy@sportx.test'))->first();
        $coach = CoachProfile::where('user_id', SeedLookup::userId('coach@sportx.test'))->first();
        $organizer = OrganizerProfile::where('user_id', SeedLookup::userId('organizer@sportx.test'))->first();
        $adminId = SeedLookup::userId('admin@sportx.test');

        $requests = [
            [
                'requester' => 'academy2@sportx.test',
                'type' => 'academy',
                'id' => Academy::where('owner_user_id', SeedLookup::userId('academy2@sportx.test'))->value('id'),
                'status' => 'pending',
                'notes' => 'Registration certificate and affiliation letter attached.',
            ],
            [
                'requester' => 'coach2@sportx.test',
                'type' => 'coach_profile',
                'id' => CoachProfile::where('user_id', SeedLookup::userId('coach2@sportx.test'))->value('id'),
                'status' => 'pending',
                'notes' => 'BWF Level 1 certification and government ID.',
            ],
            [
                'requester' => 'organizer2@sportx.test',
                'type' => 'organizer_profile',
                'id' => $organizer?->id,
                'status' => 'approved',
                'notes' => 'NGO registration verified against the state registry.',
                'reviewed_by' => $adminId,
                'decision_reason' => 'Registration certificate confirmed.',
            ],
            [
                'requester' => 'scout2@sportx.test',
                'type' => 'talent_scout_profile',
                'id' => TalentScoutProfile::where('user_id', SeedLookup::userId('scout2@sportx.test'))->value('id'),
                'status' => 'approved',
                'notes' => 'Federation affiliation letter verified.',
                'reviewed_by' => $adminId,
                'decision_reason' => 'Affiliation confirmed with the state association.',
            ],
            [
                'requester' => 'athlete.pending@sportx.test',
                'type' => 'coach_profile',
                'id' => $coach?->id,
                'status' => 'rejected',
                'notes' => 'Submitted an expired document.',
                'reviewed_by' => $adminId,
                'decision_reason' => 'Uploaded document had expired.',
            ],
        ];

        $requestCount = 0;

        foreach ($requests as $row) {
            if (! $row['id']) {
                continue;
            }

            VerificationRequest::updateOrCreate(
                [
                    'requester_user_id' => SeedLookup::userId($row['requester']),
                    'verifiable_type' => $row['type'],
                    'verifiable_id' => $row['id'],
                ],
                [
                    'status' => $row['status'],
                    'proof_media_ids' => [],
                    'notes' => $row['notes'],
                    'reviewed_by' => $row['reviewed_by'] ?? null,
                    'decision_reason' => $row['decision_reason'] ?? null,
                    'reviewed_at' => isset($row['reviewed_by']) ? now()->subDays(3) : null,
                ]
            );

            $requestCount++;
        }

        /* ── Guardian consents ────────────────────────────────────── */
        $consents = [
            [
                'athlete' => 'rahul@sportx.test',
                'guardian_name' => 'Sunil Sharma',
                'guardian_phone' => '+91 98250 11122',
                'relationship' => 'parent',
                'consent_status' => 'verified',
                'allow_messages' => true,
                'allow_public_profile' => true,
                'leaderboard_name_mode' => 'full',
            ],
            [
                'athlete' => 'priya@sportx.test',
                'guardian_name' => 'Nisha Patel',
                'guardian_phone' => '+91 98250 33344',
                'relationship' => 'parent',
                'consent_status' => 'pending',
                'allow_messages' => false,
                'allow_public_profile' => false,
                'leaderboard_name_mode' => 'first_name_initial',
            ],
            [
                'athlete' => 'diya@sportx.test',
                'guardian_name' => 'Anil Nair',
                'guardian_phone' => '+91 98250 55566',
                'relationship' => 'guardian',
                'consent_status' => 'verified',
                'allow_messages' => true,
                'allow_public_profile' => false,
                'leaderboard_name_mode' => 'first_name_initial',
            ],
            [
                'athlete' => 'athlete.pending@sportx.test',
                'guardian_name' => 'Kiran Khan',
                'guardian_phone' => '+91 98250 77788',
                'relationship' => 'parent',
                'consent_status' => 'revoked',
                'allow_messages' => false,
                'allow_public_profile' => false,
                'leaderboard_name_mode' => 'first_name_initial',
            ],
        ];

        $consentCount = 0;

        foreach ($consents as $row) {
            $athleteUserId = SeedLookup::userId($row['athlete']);

            if (! $athleteUserId) {
                continue;
            }

            GuardianConsent::updateOrCreate(
                [
                    'athlete_user_id' => $athleteUserId,
                    'guardian_phone' => $row['guardian_phone'],
                ],
                [
                    'guardian_name' => $row['guardian_name'],
                    'relationship' => $row['relationship'],
                    'consent_status' => $row['consent_status'],
                    'allow_messages' => $row['allow_messages'],
                    'allow_public_profile' => $row['allow_public_profile'],
                    'leaderboard_name_mode' => $row['leaderboard_name_mode'],
                    'verified_at' => $row['consent_status'] === 'verified' ? now()->subDays(10) : null,
                    'revoked_at' => $row['consent_status'] === 'revoked' ? now()->subDays(2) : null,
                ]
            );

            $consentCount++;
        }

        $this->command->info('Trust & safety seeded: '.$requestCount.' verification requests, '
            .$consentCount.' guardian consents');
    }
}
