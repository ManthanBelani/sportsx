<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\Observation;
use App\Models\ScoutConnection;
use App\Models\ScoutShortlist;
use App\Models\TalentScoutProfile;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Talent-scout workspace (Phase 7): shortlists, connection requests and
 * scouting observations.
 */
class ScoutActivitySeeder extends Seeder
{
    public function run(): void
    {
        $scout = TalentScoutProfile::where('user_id', SeedLookup::userId('kiran@scout.test'))->first();
        $scout2 = TalentScoutProfile::where('user_id', SeedLookup::userId('scout2@sportx.test'))->first();

        if (! $scout) {
            $this->command->warn('Talent scout profile missing. Run TalentScoutSeeder first.');
            return;
        }

        $profileId = fn (string $email) => SeedLookup::userId($email)
            ? AthleteProfile::where('user_id', SeedLookup::userId($email))->value('id')
            : null;

        /* ── Shortlists ──────────────────────────────────────────── */
        $shortlists = [
            ['scout' => $scout, 'athlete' => 'rahul@sportx.test', 'status' => 'high', 'tags' => ['football', 'midfielder', 'district'], 'notes' => 'Excellent ball retention, needs to work on the weak foot.'],
            ['scout' => $scout, 'athlete' => 'priya@sportx.test', 'status' => 'good', 'tags' => ['swimming', 'freestyle'], 'notes' => 'Strong turns, best in the 100m free.'],
            ['scout' => $scout, 'athlete' => 'athlete@sportx.test', 'status' => 'under_review', 'tags' => ['cricket', 'batsman'], 'notes' => 'Watch the next league season.'],
            ['scout' => $scout2, 'athlete' => 'aarav@sportx.test', 'status' => 'final', 'tags' => ['basketball', 'point guard'], 'notes' => 'Shortlisted for the city club trial.'],
            ['scout' => $scout2, 'athlete' => 'kabir@sportx.test', 'status' => 'under_review', 'tags' => ['kabaddi', 'raider'], 'notes' => 'Good raiding percentage, verify with the coach.'],
        ];

        $shortlistCount = 0;

        foreach ($shortlists as $row) {
            $athleteProfileId = $profileId($row['athlete']);

            if (! $athleteProfileId) {
                continue;
            }

            ScoutShortlist::updateOrCreate(
                [
                    'talent_scout_profile_id' => $row['scout']->id,
                    'athlete_profile_id' => $athleteProfileId,
                ],
                [
                    'status' => $row['status'],
                    'tags' => $row['tags'],
                    'notes' => $row['notes'],
                ]
            );

            $shortlistCount++;
        }

        /* ── Scout <-> athlete connections ─────────────────────────── */
        $connections = [
            ['scout' => $scout, 'athlete' => 'rahul@sportx.test', 'requested_by' => 'kiran@scout.test', 'status' => 'accepted', 'message' => 'Loved your U-17 footage — would like to talk about a trial.'],
            ['scout' => $scout, 'athlete' => 'priya@sportx.test', 'requested_by' => 'priya@sportx.test', 'status' => 'pending', 'message' => 'Can I have your guidance for the state swimming squad?'],
            ['scout' => $scout, 'athlete' => 'athlete@sportx.test', 'requested_by' => 'kiran@scout.test', 'status' => 'pending', 'message' => 'Interested in a batting development pathway.'],
            ['scout' => $scout2, 'athlete' => 'aarav@sportx.test', 'requested_by' => 'scout2@sportx.test', 'status' => 'accepted', 'message' => 'We would like to shortlist you for our club trials.'],
            ['scout' => $scout2, 'athlete' => 'kabir@sportx.test', 'requested_by' => 'kabir@sportx.test', 'status' => 'rejected', 'message' => 'Please add me to your network.'],
        ];

        $connectionCount = 0;

        foreach ($connections as $row) {
            $athleteProfileId = $profileId($row['athlete']);

            if (! $athleteProfileId) {
                continue;
            }

            ScoutConnection::updateOrCreate(
                [
                    'talent_scout_profile_id' => $row['scout']->id,
                    'athlete_profile_id' => $athleteProfileId,
                ],
                [
                    'requested_by_user_id' => SeedLookup::userId($row['requested_by']),
                    'status' => $row['status'],
                    'message' => $row['message'],
                ]
            );

            $connectionCount++;
        }

        /* ── Observations ─────────────────────────────────────────── */
        $observations = [
            ['scout' => $scout, 'athlete' => 'rahul@sportx.test', 'rating' => 4, 'note' => 'Excellent distribution in the final third, calm under pressure.'],
            ['scout' => $scout, 'athlete' => 'priya@sportx.test', 'rating' => 5, 'note' => 'Fastest 100m freestyle time in the age group.'],
            ['scout' => $scout, 'athlete' => 'athlete@sportx.test', 'rating' => 3, 'note' => 'Solid technique, needs work on running between the wickets.'],
            ['scout' => $scout2, 'athlete' => 'aarav@sportx.test', 'rating' => 4, 'note' => 'Good court vision, improves when the game opens up.'],
        ];

        $observationCount = 0;

        foreach ($observations as $row) {
            $athleteProfileId = $profileId($row['athlete']);

            if (! $athleteProfileId) {
                continue;
            }

            Observation::updateOrCreate(
                [
                    'talent_scout_profile_id' => $row['scout']->id,
                    'athlete_profile_id' => $athleteProfileId,
                ],
                [
                    'rating' => $row['rating'],
                    'note' => $row['note'],
                ]
            );

            $observationCount++;
        }

        $this->command->info('Scout workspace seeded: '.$shortlistCount.' shortlists, '
            .$connectionCount.' connections, '.$observationCount.' observations');
    }
}
