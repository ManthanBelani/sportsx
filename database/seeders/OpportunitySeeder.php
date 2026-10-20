<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\MediaItem;
use App\Models\Opportunity;
use App\Models\OpportunityApplication;
use App\Models\OrganizerProfile;
use App\Models\Sport;
use App\Models\TalentScoutProfile;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Unified opportunities (Phase 4) — the replacement for the legacy
 * scholarship / sponsorship listings.
 *
 * One listing per provider type (academy, organizer, coach, scout) so the
 * "create listing" screens of every provider role have something to show, in
 * every status (published / draft / closed).
 */
class OpportunitySeeder extends Seeder
{
    public function run(): void
    {
        $academy = Academy::where('owner_user_id', SeedLookup::userId('academy@sportx.test'))->first();
        $organizer = OrganizerProfile::where('user_id', SeedLookup::userId('organizer@sportx.test'))->first();
        $coach = CoachProfile::where('user_id', SeedLookup::userId('coach@sportx.test'))->first();
        $scout = TalentScoutProfile::where('user_id', SeedLookup::userId('kiran@scout.test'))->first();

        if (! $academy || ! $organizer || ! $coach || ! $scout) {
            $this->command->warn('Provider profiles missing. Run the profile seeders first.');
            return;
        }

        $rows = [
            [
                'key' => 'State Cricket Scholarship 2026',
                'provider_type' => 'academy',
                'provider_id' => $academy->id,
                'created_by' => 'academy@sportx.test',
                'type' => 'scholarship',
                'title' => 'State Cricket Scholarship 2026',
                'sport' => 'Cricket',
                'age_group' => 'Under-18',
                'eligibility' => 'State-level cricketers aged 14-18 with a minimum 60% school aggregate.',
                'benefits' => 'Annual coaching fee waiver, kit allowance and exposure to state camps.',
                'amount' => 50000,
                'deadline' => now()->addDays(30)->toDateString(),
                'documents_required' => ['Birth certificate', 'Recent form', 'Bank passbook'],
                'description' => 'Full and half scholarships for talented cricketers from the Elite Cricket Academy network.',
                'status' => 'published',
            ],
            [
                'key' => 'Sportswear Sponsorship — Season 2026',
                'provider_type' => 'organizer_profile',
                'provider_id' => $organizer->id,
                'created_by' => 'organizer@sportx.test',
                'type' => 'sponsorship',
                'title' => 'Sportswear Sponsorship — Season 2026',
                'sport' => 'Football',
                'age_group' => 'Under-18',
                'eligibility' => 'Registered state footballers taking part in the district league.',
                'benefits' => 'Kit, footwear and a season stipend.',
                'amount' => 15000,
                'deadline' => now()->addDays(45)->toDateString(),
                'documents_required' => ['Aadhaar card', 'League registration'],
                'description' => 'Sponsor-a-athlete programme for the Gujarat district football league.',
                'status' => 'published',
            ],
            [
                'key' => 'National Cricket Tryout Round 2',
                'provider_type' => 'coach_profile',
                'provider_id' => $coach->id,
                'created_by' => 'coach@sportx.test',
                'type' => 'tryout',
                'title' => 'National Cricket Tryout Round 2',
                'sport' => 'Cricket',
                'age_group' => 'Under-16',
                'eligibility' => 'Open to all cricketers born between 2008 and 2010.',
                'benefits' => 'Selection for the national training camp.',
                'amount' => null,
                'deadline' => now()->addDays(12)->toDateString(),
                'documents_required' => ['Birth certificate', 'ID proof'],
                'description' => 'Second-round selection trials hosted in Ahmedabad.',
                'status' => 'published',
            ],
            [
                'key' => 'Summer Multi-Sport Camp',
                'provider_type' => 'academy',
                'provider_id' => $academy->id,
                'created_by' => 'academy@sportx.test',
                'type' => 'camp',
                'title' => 'Summer Multi-Sport Camp',
                'sport' => 'Athletics',
                'age_group' => 'Under-14',
                'eligibility' => 'Athletes aged 11-14 in any discipline.',
                'benefits' => 'Two weeks of coaching, meals and a participation certificate.',
                'amount' => 2500,
                'deadline' => now()->addDays(20)->toDateString(),
                'documents_required' => ['Guardian consent form'],
                'description' => 'Two-week residential camp covering fitness, skill and match play.',
                'status' => 'published',
            ],
            [
                'key' => 'Basketball Scouting Camp — Mumbai',
                'provider_type' => 'talent_scout_profile',
                'provider_id' => $scout->id,
                'created_by' => 'kiran@scout.test',
                'type' => 'camp',
                'title' => 'Basketball Scouting Camp — Mumbai',
                'sport' => 'Basketball',
                'age_group' => 'Open',
                'eligibility' => 'Boys and girls aged 15+ with club playing experience.',
                'benefits' => 'Scouting evaluation, club trials and a strength programme.',
                'amount' => null,
                'deadline' => now()->addDays(60)->toDateString(),
                'documents_required' => ['Aadhaar card'],
                'description' => 'Open selection camp run by Metro Sports Scouting Cell.',
                'status' => 'published',
            ],
            [
                'key' => 'Draft Hockey Academy Grant',
                'provider_type' => 'academy',
                'provider_id' => $academy->id,
                'created_by' => 'academy@sportx.test',
                'type' => 'scholarship',
                'title' => 'Draft Hockey Academy Grant',
                'sport' => 'Hockey',
                'age_group' => 'Under-18',
                'eligibility' => 'Hockey players registered with a state association.',
                'benefits' => 'Annual training grant.',
                'amount' => 30000,
                'deadline' => now()->addDays(90)->toDateString(),
                'documents_required' => [],
                'description' => 'Work-in-progress listing that still needs admin review before publishing.',
                'status' => 'draft',
            ],
            [
                'key' => 'Closed Athletics Sponsorship',
                'provider_type' => 'organizer_profile',
                'provider_id' => $organizer->id,
                'created_by' => 'organizer@sportx.test',
                'type' => 'sponsorship',
                'title' => 'Closed Athletics Sponsorship',
                'sport' => 'Athletics',
                'age_group' => 'Open',
                'eligibility' => 'District athletics athletes.',
                'benefits' => 'Shoes and training kit.',
                'amount' => 8000,
                'deadline' => now()->subDays(5)->toDateString(),
                'documents_required' => [],
                'description' => 'Closed listing so the "closed" tab and expired state are exercised.',
                'status' => 'closed',
            ],
        ];

        $created = 0;

        foreach ($rows as $row) {
            $creatorId = SeedLookup::userId($row['created_by']);

            $opportunity = Opportunity::updateOrCreate(
                [
                    'provider_type' => $row['provider_type'],
                    'provider_id' => $row['provider_id'],
                    'title' => $row['title'],
                ],
                [
                    'created_by_user_id' => $creatorId,
                    'type' => $row['type'],
                    'sport_id' => SeedLookup::sportId($row['sport']),
                    'age_group_id' => SeedLookup::ageGroupId($row['age_group']),
                    'eligibility' => $row['eligibility'],
                    'benefits' => $row['benefits'],
                    'amount' => $row['amount'],
                    'deadline' => $row['deadline'],
                    'documents_required' => $row['documents_required'],
                    'description' => $row['description'],
                    'status' => $row['status'],
                    'expires_at' => $row['status'] === 'published'
                        ? \Carbon\Carbon::parse($row['deadline'])->endOfDay()
                        : null,
                ]
            );

            $created++;
        }

        // Logos so the opportunity cards are not blank.
        foreach (Opportunity::whereIn('status', ['published', 'closed'])->get() as $opportunity) {
            $logo = MediaItem::updateOrCreate(
                [
                    'owner_type' => Opportunity::class,
                    'owner_id' => $opportunity->id,
                    'media_type' => 'photo',
                    'sort_order' => 1,
                ],
                [
                    'disk' => 'public',
                    'path' => 'opportunities/opportunity_'.$opportunity->id.'.png',
                    'original_name' => 'opportunity_'.$opportunity->id.'.png',
                    'mime_type' => 'image/png',
                    'size_bytes' => 38000,
                    'caption' => $opportunity->title,
                ]
            );

            if (! $opportunity->logo_media_id) {
                $opportunity->forceFill(['logo_media_id' => $logo->id])->save();
            }
        }

        // Applications: athletes applying to the published listings.
        $athleteEmails = ['rahul@sportx.test', 'aarav@sportx.test', 'priya@sportx.test', 'kabir@sportx.test'];
        $applications = [
            ['opportunity' => 'State Cricket Scholarship 2026', 'athlete' => 'rahul@sportx.test', 'status' => 'submitted', 'pitch' => 'District U-17 captain with a 62 average and state selection.'],
            ['opportunity' => 'State Cricket Scholarship 2026', 'athlete' => 'priya@sportx.test', 'status' => 'shortlisted', 'pitch' => 'State-level all-rounder, keen to move into a formal coaching setup.'],
            ['opportunity' => 'National Cricket Tryout Round 2', 'athlete' => 'rahul@sportx.test', 'status' => 'submitted', 'pitch' => 'Looking for a national-level platform to test my game.'],
            ['opportunity' => 'Sportswear Sponsorship — Season 2026', 'athlete' => 'kabir@sportx.test', 'status' => 'submitted', 'pitch' => 'Kabaddi player with strong district-level numbers, brand fit for sportswear.'],
            ['opportunity' => 'Summer Multi-Sport Camp', 'athlete' => 'priya@sportx.test', 'status' => 'declined', 'pitch' => 'Swimmer interested in the athletics conditioning track.'],
            ['opportunity' => 'Basketball Scouting Camp — Mumbai', 'athlete' => 'aarav@sportx.test', 'status' => 'shortlisted', 'pitch' => 'Point guard playing at city level, ready to be evaluated.'],
        ];

        $appCount = 0;

        foreach ($applications as $app) {
            $opportunity = Opportunity::where('title', $app['opportunity'])->first();
            $athleteUserId = SeedLookup::userId($app['athlete']);
            $athleteProfileId = $athleteUserId
                ? \App\Models\AthleteProfile::where('user_id', $athleteUserId)->value('id')
                : null;

            if (! $opportunity || ! $athleteProfileId) {
                continue;
            }

            OpportunityApplication::updateOrCreate(
                [
                    'opportunity_id' => $opportunity->id,
                    'athlete_id' => $athleteProfileId,
                ],
                [
                    'pitch' => $app['pitch'],
                    'status' => $app['status'],
                    'document_media_ids' => [],
                    'snapshot' => [
                        'full_name' => $app['athlete'],
                        'sports' => [],
                        'skill_level' => 'competitive',
                    ],
                    'decision_note' => $app['status'] === 'declined' ? 'Profile did not match the role criteria.' : null,
                    'replied_at' => in_array($app['status'], ['shortlisted', 'declined'], true) ? now()->subDays(1) : null,
                ]
            );

            $appCount++;
        }

        $this->command->info('Opportunities seeded: '.$created.' (applications: '.$appCount.')');
    }
}
