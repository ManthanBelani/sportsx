<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\Achievement;
use App\Models\AgeGroup;
use App\Models\AthleteProfile;
use App\Models\City;
use App\Models\CoachProfile;
use App\Models\Connection;
use App\Models\Conversation;
use App\Models\ConversationParticipant;
use App\Models\Enquiry;
use App\Models\EnquiryMessage;
use App\Models\ExpiryRule;
use App\Models\ListingReport;
use App\Models\Message;
use App\Models\Notification;
use App\Models\OrganizerProfile;
use App\Models\Post;
use App\Models\PostComment;
use App\Models\PostLike;
use App\Models\RecentSearch;
use App\Models\SavedItem;
use App\Models\Scholarship;
use App\Models\ShortlistEntry;
use App\Models\Sport;
use App\Models\SponsorProfile;
use App\Models\Sponsorship;
use App\Models\SponsorshipApplication;
use App\Models\SportsVenue;
use App\Models\Trial;
use App\Models\TrialRegistration;
use App\Models\Tournament;
use App\Models\TournamentCategory;
use App\Models\TournamentRegistration;
use App\Models\TournamentResult;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class TestSeeder extends Seeder
{
    public function run(): void
    {
        $this->command->info('Starting comprehensive test database seeding...');

        $this->seedMasterData();
        $this->seedUsers();
        $this->seedProfiles();
        $this->seedAcademyRelations();
        $this->seedTrials();
        $this->seedTournaments();
        $this->seedScholarships();
        $this->seedSponsorships();
        $this->seedSportsVenues();
        $this->seedSocial();
        $this->seedConnections();
        $this->seedNotifications();
        $this->seedEnquiries();
        $this->seedSavedItems();
        $this->seedListingReports();
        $this->seedRecentSearches();
        $this->seedExpiryRules();

        $this->command->info('Test database seeding completed!');
        $this->printUserCredentials();
    }

    private function seedMasterData(): void
    {
        $this->command->info('Seeding master data...');

        $sports = [
            ['name' => 'Cricket', 'sort_order' => 1],
            ['name' => 'Football', 'sort_order' => 2],
            ['name' => 'Badminton', 'sort_order' => 3],
            ['name' => 'Athletics', 'sort_order' => 4],
            ['name' => 'Swimming', 'sort_order' => 5],
            ['name' => 'Basketball', 'sort_order' => 6],
            ['name' => 'Tennis', 'sort_order' => 7],
            ['name' => 'Volleyball', 'sort_order' => 8],
            ['name' => 'Kabaddi', 'sort_order' => 9],
            ['name' => 'Hockey', 'sort_order' => 10],
        ];
        foreach ($sports as $sport) {
            Sport::updateOrInsert(['name' => $sport['name']], $sport);
        }

        $cities = [
            ['name' => 'Ahmedabad', 'state' => 'Gujarat'],
            ['name' => 'Surat', 'state' => 'Gujarat'],
            ['name' => 'Vadodara', 'state' => 'Gujarat'],
            ['name' => 'Rajkot', 'state' => 'Gujarat'],
            ['name' => 'Mumbai', 'state' => 'Maharashtra'],
            ['name' => 'Pune', 'state' => 'Maharashtra'],
            ['name' => 'Delhi', 'state' => 'Delhi'],
            ['name' => 'Bengaluru', 'state' => 'Karnataka'],
        ];
        foreach ($cities as $city) {
            City::updateOrInsert(['name' => $city['name'], 'state' => $city['state']], $city);
        }

        $ageGroups = [
            ['name' => 'Under-10', 'min_age' => null, 'max_age' => 9],
            ['name' => 'Under-12', 'min_age' => 10, 'max_age' => 11],
            ['name' => 'Under-14', 'min_age' => 12, 'max_age' => 13],
            ['name' => 'Under-16', 'min_age' => 14, 'max_age' => 15],
            ['name' => 'Under-18', 'min_age' => 16, 'max_age' => 17],
            ['name' => 'Open', 'min_age' => 18, 'max_age' => null],
        ];
        foreach ($ageGroups as $group) {
            AgeGroup::updateOrInsert(['name' => $group['name']], $group);
        }

        $this->command->info('Master data seeded: ' . Sport::count() . ' sports, ' . City::count() . ' cities, ' . AgeGroup::count() . ' age groups');
    }

    private function seedUsers(): void
    {
        $this->command->info('Seeding users...');

        $users = [
            ['id' => 1, 'name' => 'Admin User', 'email' => 'admin@sportx.test', 'role' => 'admin'],
            ['id' => 2, 'name' => 'John Athlete', 'email' => 'athlete1@sportx.test', 'role' => 'athlete'],
            ['id' => 3, 'name' => 'Sarah Coach', 'email' => 'coach1@sportx.test', 'role' => 'coach'],
            ['id' => 4, 'name' => 'Elite Academy Owner', 'email' => 'academy1@sportx.test', 'role' => 'academy'],
            ['id' => 5, 'name' => 'Gujarat Sports Federation', 'email' => 'organizer1@sportx.test', 'role' => 'organizer'],
            ['id' => 6, 'name' => 'Decathlon India', 'email' => 'sponsor1@sportx.test', 'role' => 'sponsor'],
            ['id' => 7, 'name' => 'Rahul Sharma', 'email' => 'athlete2@sportx.test', 'role' => 'athlete'],
            ['id' => 8, 'name' => 'Priya Patel', 'email' => 'athlete3@sportx.test', 'role' => 'athlete'],
            ['id' => 9, 'name' => 'Vikram Singh', 'email' => 'coach2@sportx.test', 'role' => 'coach'],
            ['id' => 10, 'name' => 'Mumbai Cricket Academy', 'email' => 'academy2@sportx.test', 'role' => 'academy'],
            ['id' => 11, 'name' => 'Ananya Desai', 'email' => 'athlete4@sportx.test', 'role' => 'athlete'],
            ['id' => 12, 'name' => 'Rohit Verma', 'email' => 'athlete5@sportx.test', 'role' => 'athlete'],
        ];

        foreach ($users as $user) {
            User::updateOrCreate(
                ['email' => $user['email']],
                [
                    'name' => $user['name'],
                    'password' => Hash::make('password'),
                    'role' => $user['role'],
                    'email_verified_at' => now(),
                    'status' => 'active',
                    'language' => 'en',
                ]
            );
        }

        DB::table('admin_profiles')->updateOrInsert(
            ['user_id' => 1],
            ['user_id' => 1, 'is_super_admin' => true]
        );

        $this->command->info('Users seeded: ' . User::count() . ' users');
    }

    private function seedProfiles(): void
    {
        $this->command->info('Seeding profiles...');

        $athleteProfiles = [
            ['user_id' => 2, 'full_name' => 'John Athlete', 'phone' => '+91 98765 11111', 'date_of_birth' => '2012-05-15', 'gender' => 'male', 'city_id' => 1, 'age_group_id' => 3, 'skill_level' => 'intermediate', 'position' => 'Batsman', 'experience' => '3 years'],
            ['user_id' => 7, 'full_name' => 'Rahul Sharma', 'phone' => '+91 98765 22222', 'date_of_birth' => '2010-08-22', 'gender' => 'male', 'city_id' => 2, 'age_group_id' => 4, 'skill_level' => 'competitive', 'position' => 'Midfielder', 'experience' => '5 years'],
            ['user_id' => 8, 'full_name' => 'Priya Patel', 'phone' => '+91 98765 33333', 'date_of_birth' => '2013-03-10', 'gender' => 'female', 'city_id' => 1, 'age_group_id' => 2, 'skill_level' => 'advanced', 'position' => 'Freestyle', 'experience' => '4 years'],
            ['user_id' => 11, 'full_name' => 'Ananya Desai', 'phone' => '+91 98765 66666', 'date_of_birth' => '2011-11-25', 'gender' => 'female', 'city_id' => 3, 'age_group_id' => 3, 'skill_level' => 'intermediate', 'position' => 'All-rounder', 'experience' => '2 years'],
            ['user_id' => 12, 'full_name' => 'Rohit Verma', 'phone' => '+91 98765 77777', 'date_of_birth' => '2009-07-18', 'gender' => 'male', 'city_id' => 4, 'age_group_id' => 5, 'skill_level' => 'advanced', 'position' => 'Wicketkeeper', 'experience' => '6 years'],
        ];
        foreach ($athleteProfiles as $profile) {
            AthleteProfile::updateOrCreate(['user_id' => $profile['user_id']], $profile);
        }

        $coachProfiles = [
            [
                'user_id' => 3,
                'full_name' => 'Sarah Coach',
                'headline' => 'Professional Cricket Coach | BCCI Level 2 Certified',
                'contact_number' => '+91 98765 44444',
                'sport_id' => 1,
                'city_id' => 1,
                'location' => 'Navrangpura, Ahmedabad',
                'experience' => '10',
                'qualification' => 'BCCI Level 2, NCCF Certified',
                'certifications' => json_encode(['BCCI Level 2', 'NCCF Certified']),
                'languages' => json_encode(['English', 'Hindi', 'Gujarati']),
                'bio' => 'Certified cricket coach with 10 years experience specializing in youth development and technical skill building. Former state-level player with a passion for nurturing young talent.',
                'fee_per_session' => 800,
                'fee_monthly' => 5000,
                'fee_quarterly' => 13000,
                'availability' => json_encode([
                    'Mon' => ['4-6 PM'],
                    'Tue' => ['4-6 PM'],
                    'Wed' => ['4-6 PM'],
                    'Thu' => [],
                    'Fri' => ['4-6 PM'],
                    'Sat' => ['10-12 PM', '4-6 PM'],
                    'Sun' => ['10-12 PM', '4-6 PM'],
                ]),
                'listing_status' => 'published',
            ],
            [
                'user_id' => 9,
                'full_name' => 'Vikram Singh',
                'headline' => 'Former Ranji Player | Cricket Coaching Expert',
                'contact_number' => '+91 98765 55555',
                'sport_id' => 1,
                'city_id' => 5,
                'location' => 'Andheri West, Mumbai',
                'experience' => '8',
                'qualification' => 'BCCI Level 1, Sports Science Degree',
                'certifications' => json_encode(['BCI Level 1']),
                'languages' => json_encode(['English', 'Hindi', 'Marathi']),
                'bio' => 'Former Ranji player turned coach with expertise in batting technique and match strategy. Trained 50+ district level champions.',
                'fee_per_session' => 1000,
                'fee_monthly' => 6000,
                'fee_quarterly' => 15000,
                'availability' => json_encode([
                    'Mon' => ['6-8 AM', '4-6 PM'],
                    'Tue' => ['6-8 AM'],
                    'Wed' => ['6-8 AM', '4-6 PM'],
                    'Thu' => ['4-6 PM'],
                    'Fri' => ['6-8 AM', '4-6 PM'],
                    'Sat' => ['8-10 AM', '4-6 PM'],
                    'Sun' => ['8-10 AM', '4-6 PM'],
                ]),
                'listing_status' => 'published',
            ],
        ];
        foreach ($coachProfiles as $profile) {
            CoachProfile::updateOrCreate(['user_id' => $profile['user_id']], $profile);
        }

        $academies = [
            ['owner_user_id' => 4, 'name' => 'Elite Cricket Academy', 'address' => 'Narendra Modi Stadium Campus, Ahmedabad', 'city_id' => 1, 'contact_number' => '+91 79 2345 6789', 'email' => 'info@elitecricket.example.com', 'description' => 'Premier cricket academy in Gujarat', 'year_established' => 2015, 'facilities' => json_encode(['Nets', 'Ground', 'Video Analysis', 'Gym']), 'achievements' => json_encode(['Produced 5 state-level champions']), 'website' => 'https://elitecricket.example.com', 'listing_status' => 'published'],
            ['owner_user_id' => 10, 'name' => 'Mumbai Cricket Academy', 'address' => 'Wankhede Stadium Complex, Mumbai', 'city_id' => 5, 'contact_number' => '+91 22 2345 6789', 'email' => 'contact@mca.example.com', 'description' => 'Historic cricket coaching center', 'year_established' => 2010, 'facilities' => json_encode(['Nets', 'Ground', 'Swimming Pool', 'Gym']), 'achievements' => json_encode(['NCA affiliated']), 'website' => 'https://mca.example.com', 'listing_status' => 'published'],
        ];
        foreach ($academies as $academy) {
            Academy::updateOrCreate(['owner_user_id' => $academy['owner_user_id']], $academy);
        }

        OrganizerProfile::updateOrCreate(
            ['user_id' => 5],
            ['user_id' => 5, 'organization_name' => 'Gujarat Sports Federation', 'org_type' => 'federation', 'verification_status' => 'verified']
        );

        SponsorProfile::updateOrCreate(
            ['user_id' => 6],
            ['user_id' => 6, 'brand_name' => 'Decathlon India', 'category' => 'Sports Retail', 'verification_status' => 'verified']
        );

        foreach (AthleteProfile::all() as $index => $athlete) {
            Achievement::updateOrCreate(
                ['athlete_id' => $athlete->id, 'text' => 'District Cricket Championship Winner'],
                ['sort_order' => 1]
            );
            if ($index % 2 === 0) {
                Achievement::updateOrCreate(
                    ['athlete_id' => $athlete->id, 'text' => 'Best Batsman Award'],
                    ['sort_order' => 2]
                );
            }
        }

        $this->command->info('Profiles seeded: ' . AthleteProfile::count() . ' athletes, ' . CoachProfile::count() . ' coaches, ' . Academy::count() . ' academies');
    }

    private function seedAcademyRelations(): void
    {
        $this->command->info('Seeding academy relations...');

        DB::table('academy_sports')->updateOrInsert(
            ['academy_id' => 1, 'sport_id' => 1],
            ['academy_id' => 1, 'sport_id' => 1]
        );
        DB::table('academy_sports')->updateOrInsert(
            ['academy_id' => 2, 'sport_id' => 1],
            ['academy_id' => 2, 'sport_id' => 1]
        );

        DB::table('academy_coaches')->updateOrInsert(
            ['academy_id' => 1, 'coach_user_id' => 3],
            ['academy_id' => 1, 'coach_user_id' => 3, 'display_name' => 'Sarah Coach']
        );

        if (CoachProfile::find(1)) {
            DB::table('athlete_profiles')->where('user_id', 2)->update(['academy_id' => 1, 'coach_id' => 1]);
        }
        if (CoachProfile::find(2)) {
            DB::table('athlete_profiles')->where('user_id', 7)->update(['academy_id' => 2, 'coach_id' => 2]);
        }

        $this->command->info('Academy relations seeded');
    }

    private function seedTrials(): void
    {
        $this->command->info('Seeding trials...');

        $trials = [
            ['name' => 'U-14 Cricket Trials Ahmedabad', 'posted_by_user_id' => 3, 'academy_id' => 1, 'organization_name' => 'Elite Cricket Academy', 'sport_id' => 1, 'event_datetime' => now()->addDays(14)->toDateTimeString(), 'venue' => 'Narendra Modi Stadium', 'google_maps_url' => 'https://maps.google.com/?q=Narendra+Modi+Stadium', 'city_id' => 1, 'contact_number' => '+91 98765 43210', 'registration_deadline' => now()->addDays(7)->toDateString(), 'eligibility' => 'Boys, Under-14, Ahmedabad residents', 'entry_fee' => '200', 'required_documents' => json_encode(['Aadhaar Card', 'Passport Photo']), 'vacancies' => 30, 'benefits' => 'Selected athletes get free academy kit', 'status' => 'published'],
            ['name' => 'U-16 Football Trials Mumbai', 'posted_by_user_id' => 9, 'academy_id' => 2, 'organization_name' => 'Mumbai Cricket Academy', 'sport_id' => 2, 'event_datetime' => now()->addDays(21)->toDateTimeString(), 'venue' => 'Cooperage Ground', 'google_maps_url' => 'https://maps.google.com/?q=Cooperage+Ground', 'city_id' => 5, 'contact_number' => '+91 22 2345 6789', 'registration_deadline' => now()->addDays(14)->toDateString(), 'eligibility' => 'Open to all U-16 footballers', 'entry_fee' => '300', 'required_documents' => json_encode(['Aadhaar Card', 'School ID']), 'vacancies' => 20, 'benefits' => 'Trial kit provided', 'status' => 'published'],
            ['name' => 'Swimming Camp Registration', 'posted_by_user_id' => 3, 'academy_id' => 1, 'organization_name' => 'Elite Cricket Academy', 'sport_id' => 5, 'event_datetime' => now()->addDays(7)->toDateTimeString(), 'venue' => 'SGP Sports Complex', 'google_maps_url' => 'https://maps.google.com/?q=SGP+Sports', 'city_id' => 1, 'contact_number' => '+91 98765 43210', 'registration_deadline' => now()->addDays(3)->toDateString(), 'eligibility' => 'All age groups welcome', 'entry_fee' => '500', 'required_documents' => json_encode(['Medical Certificate']), 'vacancies' => 50, 'benefits' => 'Free swimming cap and goggles', 'status' => 'published'],
        ];
        foreach ($trials as $trial) {
            Trial::updateOrCreate(['name' => $trial['name']], $trial);
        }

        $trial = Trial::first();
        $athlete = AthleteProfile::first();
        if ($trial && $athlete) {
            TrialRegistration::updateOrCreate(
                ['trial_id' => $trial->id, 'athlete_id' => $athlete->id],
                ['registration_ref' => 'TR-' . strtoupper(uniqid()), 'document_status' => 'pending', 'verification_status' => 'pending']
            );
        }

        $this->command->info('Trials seeded: ' . Trial::count() . ' trials, ' . TrialRegistration::count() . ' registrations');
    }

    private function seedTournaments(): void
    {
        $this->command->info('Seeding tournaments...');

        $organizer = OrganizerProfile::first();
        if (!$organizer) {
            $this->command->warn('No organizer profile found, skipping tournaments');
            return;
        }

        $tournament = Tournament::updateOrCreate(
            ['name' => 'U-16 State Cup 2026'],
            [
                'organizer_id' => $organizer->id,
                'sport_id' => 1,
                'organizer_name' => 'Gujarat Sports Federation',
                'format' => 'knockout',
                'start_date' => now()->addDays(30)->toDateString(),
                'end_date' => now()->addDays(35)->toDateString(),
                'registration_deadline' => now()->addDays(20)->toDateString(),
                'venue' => 'GMDC Ground, Ahmedabad',
                'google_maps_url' => 'https://maps.google.com/?q=GMDC+Ground',
                'city_id' => 1,
                'entry_fee' => '500',
                'contact_number' => '+91 98111 22222',
                'registration_link' => 'https://forms.example.com/u16',
                'prize_pool' => '50000',
                'rules' => 'ICC standard rules apply',
                'gender' => 'male',
                'status' => 'published',
            ]
        );

        $u16AgeGroup = AgeGroup::where('name', 'Under-16')->first();
        TournamentCategory::updateOrCreate(
            ['tournament_id' => $tournament->id, 'age_group_id' => $u16AgeGroup?->id],
            ['name' => 'U-16 Boys', 'capacity' => 24, 'waitlist_enabled' => true]
        );

        $u14AgeGroup = AgeGroup::where('name', 'Under-14')->first();
        TournamentCategory::updateOrCreate(
            ['tournament_id' => $tournament->id, 'age_group_id' => $u14AgeGroup?->id],
            ['name' => 'U-14 Boys', 'capacity' => 20, 'waitlist_enabled' => false]
        );

        $category = TournamentCategory::first();
        $athlete = AthleteProfile::first();
        if ($category && $athlete) {
            TournamentRegistration::updateOrCreate(
                ['tournament_id' => $tournament->id, 'category_id' => $category->id, 'athlete_id' => $athlete->id],
                ['participation_type' => 'individual', 'payment_status' => 'pending', 'status' => 'pending']
            );
        }

        TournamentResult::updateOrCreate(
            ['category_id' => $category?->id ?? 1, 'place' => 1],
            [
                'tournament_id' => $tournament->id,
                'winner_name' => 'Team Gujarat Warriors',
            ]
        );

        $this->command->info('Tournaments seeded: ' . Tournament::count() . ' tournaments, ' . TournamentCategory::count() . ' categories');
    }

    private function seedScholarships(): void
    {
        $this->command->info('Seeding scholarships...');

        $scholarships = [
            ['name' => 'Young Athlete Scholarship 2026', 'organization_name' => 'Reliance Foundation', 'sport_id' => 1, 'eligibility' => 'Athletes aged 12-18 from Gujarat, national-level representation preferred', 'deadline' => now()->addDays(30)->toDateString(), 'application_link' => 'https://rf.example.com/apply', 'contact_email' => 'scholarships@rf.example.com', 'contact_phone' => '+91 1800 123 4567', 'amount' => 50000.00, 'benefits' => 'Annual stipend + academy fees waived', 'documents_required' => json_encode(['Aadhaar', 'Performance certificate', 'School records']), 'description' => 'Supporting young cricket talent across Gujarat', 'status' => 'published', 'created_by' => 1],
            ['name' => 'Sports Excellence Scholarship', 'organization_name' => 'Paytm', 'sport_id' => null, 'eligibility' => 'Any sport, merit-based', 'deadline' => now()->addDays(45)->toDateString(), 'application_link' => 'https://paytm.example.com/sports', 'contact_email' => 'sports@paytm.example.com', 'amount' => 25000.00, 'benefits' => 'Monthly allowance', 'status' => 'published', 'created_by' => 1],
        ];
        foreach ($scholarships as $scholarship) {
            Scholarship::updateOrCreate(['name' => $scholarship['name']], $scholarship);
        }

        $this->command->info('Scholarships seeded: ' . Scholarship::count());
    }

    private function seedSponsorships(): void
    {
        $this->command->info('Seeding sponsorships...');

        $sponsor = SponsorProfile::first();
        if (!$sponsor) {
            $this->command->warn('No sponsor profile found, skipping sponsorships');
            return;
        }

        Sponsorship::updateOrCreate(
            ['title' => 'U-14 Cricket Kit Sponsorship', 'sponsor_id' => $sponsor->id],
            [
                'organization_name' => 'Decathlon India',
                'sport_id' => 1,
                'eligibility_criteria' => 'Selected U-14 trial participants from Ahmedabad',
                'deadline' => now()->addDays(20)->toDateString(),
                'application_link' => 'https://decathlon.example.com/sponsor',
                'contact_email' => 'sports@decathlon.example.com',
                'contact_phone' => '+91 80405 67890',
                'benefits_offered' => 'Full cricket kit (bat, pads, gloves) for the season',
                'status' => 'published',
            ]
        );

        $sponsorship = Sponsorship::first();
        $athlete = AthleteProfile::first();
        if ($sponsorship && $athlete) {
            SponsorshipApplication::updateOrCreate(
                ['sponsorship_id' => $sponsorship->id, 'athlete_id' => $athlete->id],
                ['pitch_note' => 'I am a dedicated cricket player with 3 years of experience and have represented my district.', 'status' => 'submitted']
            );
        }

        ShortlistEntry::updateOrCreate(
            ['sponsor_id' => $sponsor->id, 'athlete_id' => $athlete?->id ?? 1],
            ['note' => 'Strong performance in local tournaments']
        );

        $this->command->info('Sponsorships seeded: ' . Sponsorship::count());
    }

    private function seedSportsVenues(): void
    {
        $this->command->info('Seeding sports venues...');

        $venues = [
            ['name' => 'Sardar Patel Stadium', 'sport_id' => 1, 'address' => 'Motera, Ahmedabad', 'google_maps_url' => 'https://maps.google.com/?q=Sardar+Patel+Stadium', 'contact_number' => '+91 79 2345 6789', 'city_id' => 1, 'booking_available' => true, 'pricing' => '₹2,000/hour for nets, ₹5,000/day for ground', 'facilities' => json_encode(['Floodlights', 'Dressing Rooms', 'Practice Nets', 'Parking']), 'working_hours' => '6 AM - 10 PM', 'listing_status' => 'published'],
            ['name' => 'Cooperage Ground', 'sport_id' => 2, 'address' => 'Colaba, Mumbai', 'google_maps_url' => 'https://maps.google.com/?q=Cooperage+Ground', 'contact_number' => '+91 22 2345 6789', 'city_id' => 5, 'booking_available' => true, 'pricing' => '₹3,000/hour', 'facilities' => json_encode(['Floodlights', 'Changing Rooms', 'Parking']), 'working_hours' => '5 AM - 9 PM', 'listing_status' => 'published'],
        ];
        foreach ($venues as $venue) {
            SportsVenue::updateOrCreate(['name' => $venue['name']], $venue);
        }

        $this->command->info('Sports venues seeded: ' . SportsVenue::count());
    }

    private function seedSocial(): void
    {
        $this->command->info('Seeding social data...');

        $users = User::limit(5)->get();
        if ($users->count() < 2) {
            $this->command->warn('Not enough users for social data');
            return;
        }

        $conversationId = DB::table('conversations')->insertGetId([
            'type' => 'private',
            'created_at' => now()->subDays(2),
            'updated_at' => now(),
        ]);

        foreach ($users->take(3) as $user) {
            DB::table('conversation_participants')->updateOrInsert(
                ['conversation_id' => $conversationId, 'user_id' => $user->id],
                ['last_read_at' => now()->subDays(1), 'updated_at' => now()]
            );
        }

        $messages = [
            ['conversation_id' => $conversationId, 'sender_user_id' => $users[0]->id, 'body' => 'Hey, anyone interested in cricket trials?', 'type' => 'text'],
            ['conversation_id' => $conversationId, 'sender_user_id' => $users[1]->id, 'body' => 'Yes! I saw the U-14 trials announcement.', 'type' => 'text'],
            ['conversation_id' => $conversationId, 'sender_user_id' => $users[2]->id, 'body' => 'Count me in! When is the registration deadline?', 'type' => 'text'],
        ];
        foreach ($messages as $msg) {
            Message::updateOrInsert(
                ['conversation_id' => $msg['conversation_id'], 'sender_user_id' => $msg['sender_user_id'], 'body' => $msg['body']],
                $msg
            );
        }

        $posts = [
            ['user_id' => $users[0]->id, 'body' => 'Just completed an amazing training session! #cricket #training', 'visibility' => 'public'],
            ['user_id' => $users[1]->id, 'body' => 'Excited to announce my participation in the upcoming U-16 State Cup!', 'visibility' => 'public'],
            ['user_id' => $users[2]->id, 'body' => 'Looking for teammates for the football tournament. DM if interested!', 'visibility' => 'public'],
        ];
        foreach ($posts as $post) {
            Post::updateOrInsert(['user_id' => $post['user_id'], 'body' => $post['body']], $post);
        }

        $firstPost = Post::first();
        if ($firstPost && $users->count() > 1) {
            PostLike::updateOrInsert(['post_id' => $firstPost->id, 'user_id' => $users[1]->id], []);
            PostComment::updateOrInsert(
                ['post_id' => $firstPost->id, 'user_id' => $users[2]->id, 'body' => 'Great session! Keep it up!'],
                []
            );
        }

        $this->command->info('Social data seeded: ' . Post::count() . ' posts, ' . Message::count() . ' messages');
    }

    private function seedConnections(): void
    {
        $this->command->info('Seeding connections...');

        $users = User::limit(8)->get();
        if ($users->count() < 3) {
            $this->command->warn('Not enough users for connections');
            return;
        }

        $connections = [
            ['follower_user_id' => $users[1]->id, 'followee_user_id' => $users[2]->id, 'status' => 'accepted'],
            ['follower_user_id' => $users[2]->id, 'followee_user_id' => $users[1]->id, 'status' => 'accepted'],
            ['follower_user_id' => $users[1]->id, 'followee_user_id' => $users[3]->id, 'status' => 'accepted'],
            ['follower_user_id' => $users[3]->id, 'followee_user_id' => $users[1]->id, 'status' => 'accepted'],
            ['follower_user_id' => $users[4]->id, 'followee_user_id' => $users[2]->id, 'status' => 'pending'],
            ['follower_user_id' => $users[5]->id, 'followee_user_id' => $users[1]->id, 'status' => 'pending'],
        ];
        foreach ($connections as $connection) {
            Connection::updateOrInsert(
                ['follower_user_id' => $connection['follower_user_id'], 'followee_user_id' => $connection['followee_user_id']],
                $connection
            );
        }

        $this->command->info('Connections seeded: ' . Connection::count());
    }

    private function seedNotifications(): void
    {
        $this->command->info('Seeding notifications...');

        $users = User::limit(5)->get();
        foreach ($users as $user) {
            Notification::updateOrInsert(
                ['user_id' => $user->id, 'type' => 'reminder', 'title' => 'Trial Registration Reminder'],
                [
                    'user_id' => $user->id,
                    'type' => 'reminder',
                    'title' => 'Trial Registration Reminder',
                    'body' => 'Don\'t forget to register for the U-14 Cricket Trials!',
                    'created_at' => now()->subDays(1),
                ]
            );
        }

        $this->command->info('Notifications seeded: ' . Notification::count());
    }

    private function seedEnquiries(): void
    {
        $this->command->info('Seeding enquiries...');

        $athlete = AthleteProfile::first();
        $athlete2 = AthleteProfile::skip(1)->first();
        $academy = Academy::first();
        $coach = CoachProfile::first();
        if (!$athlete || !$academy) {
            $this->command->warn('No athlete or academy for enquiries');
            return;
        }

        // Academy enquiry
        $enquiry1 = Enquiry::updateOrInsert(
            ['athlete_id' => $athlete->id, 'subject_type' => 'academy', 'subject_id' => $academy->id],
            ['athlete_id' => $athlete->id, 'subject_type' => 'academy', 'subject_id' => $academy->id, 'preferred_datetime' => now()->addDays(7)]
        );

        EnquiryMessage::updateOrInsert(
            ['enquiry_id' => 1, 'sender_user_id' => $athlete->user_id, 'body' => 'Hi, I am interested in joining your academy. What are the coaching timings?'],
            ['enquiry_id' => 1, 'sender_user_id' => $athlete->user_id, 'body' => 'Hi, I am interested in joining your academy. What are the coaching timings?', 'read_at' => now()]
        );
        EnquiryMessage::updateOrInsert(
            ['enquiry_id' => 1, 'sender_user_id' => $academy->owner_user_id, 'body' => 'We have sessions at 6 AM and 4 PM. Which suits you better?'],
            ['enquiry_id' => 1, 'sender_user_id' => $academy->owner_user_id, 'body' => 'We have sessions at 6 AM and 4 PM. Which suits you better?', 'read_at' => null]
        );

        // Coach enquiries (for coach1@sportx.test - Sarah Coach)
        if ($coach) {
            $enquiry2 = Enquiry::firstOrCreate(
                ['athlete_id' => $athlete->id, 'subject_type' => 'coach_profile', 'subject_id' => $coach->id],
                ['athlete_id' => $athlete->id, 'subject_type' => 'coach_profile', 'subject_id' => $coach->id, 'preferred_datetime' => now()->addDays(5)]
            );

            EnquiryMessage::updateOrInsert(
                ['enquiry_id' => $enquiry2->id, 'sender_user_id' => $athlete->user_id, 'body' => 'Hi Sarah, I am a 14-year-old footballer looking to improve my striking and dribbling skills. I am available on weekends and Wednesday evenings. Would you have time for a trial session?'],
                ['enquiry_id' => $enquiry2->id, 'sender_user_id' => $athlete->user_id, 'body' => 'Hi Sarah, I am a 14-year-old footballer looking to improve my striking and dribbling skills. I am available on weekends and Wednesday evenings. Would you have time for a trial session?', 'read_at' => null]
            );

            if ($athlete2) {
                $enquiry3 = Enquiry::firstOrCreate(
                    ['athlete_id' => $athlete2->id, 'subject_type' => 'coach_profile', 'subject_id' => $coach->id],
                    ['athlete_id' => $athlete2->id, 'subject_type' => 'coach_profile', 'subject_id' => $coach->id, 'preferred_datetime' => now()->addDays(3)]
                );

                EnquiryMessage::updateOrInsert(
                    ['enquiry_id' => $enquiry3->id, 'sender_user_id' => $athlete2->user_id, 'body' => 'Hello! Interested in monthly training sessions. What slots are available on weekends?'],
                    ['enquiry_id' => $enquiry3->id, 'sender_user_id' => $athlete2->user_id, 'body' => 'Hello! Interested in monthly training sessions. What slots are available on weekends?', 'read_at' => now()]
                );
                EnquiryMessage::updateOrInsert(
                    ['enquiry_id' => $enquiry3->id, 'sender_user_id' => $coach->user_id, 'body' => 'Great! I have slots available on Saturday (10-12 PM) and Sunday (4-6 PM). Would you like to come for a free trial?'],
                    ['enquiry_id' => $enquiry3->id, 'sender_user_id' => $coach->user_id, 'body' => 'Great! I have slots available on Saturday (10-12 PM) and Sunday (4-6 PM). Would you like to come for a free trial?', 'read_at' => null]
                );
            }
        }

        $this->command->info('Enquiries seeded: ' . Enquiry::count() . ' enquiries, ' . EnquiryMessage::count() . ' messages');
    }

    private function seedSavedItems(): void
    {
        $this->command->info('Seeding saved items...');

        $user = User::first();
        $trial = Trial::first();
        $tournament = Tournament::first();
        if (!$user) {
            return;
        }

        if ($trial) {
            SavedItem::updateOrInsert(
                ['user_id' => $user->id, 'item_type' => 'trial', 'item_id' => $trial->id],
                ['user_id' => $user->id, 'item_type' => 'trial', 'item_id' => $trial->id]
            );
        }
        if ($tournament) {
            SavedItem::updateOrInsert(
                ['user_id' => $user->id, 'item_type' => 'tournament', 'item_id' => $tournament->id],
                ['user_id' => $user->id, 'item_type' => 'tournament', 'item_id' => $tournament->id]
            );
        }

        $this->command->info('Saved items seeded: ' . SavedItem::count());
    }

    private function seedListingReports(): void
    {
        $this->command->info('Seeding listing reports...');

        $user = User::skip(1)->first();
        $trial = Trial::first();
        if (!$user || !$trial) {
            return;
        }

        ListingReport::updateOrInsert(
            ['reporter_user_id' => $user->id, 'reportable_type' => 'App\Models\Trial', 'reportable_id' => $trial->id],
            [
                'reporter_user_id' => $user->id,
                'reportable_type' => 'App\Models\Trial',
                'reportable_id' => $trial->id,
                'reason' => 'outdated',
                'comment' => 'This trial seems to have already concluded.',
                'status' => 'pending',
            ]
        );

        $this->command->info('Listing reports seeded: ' . ListingReport::count());
    }

    private function seedRecentSearches(): void
    {
        $this->command->info('Seeding recent searches...');

        $users = User::limit(3)->get();
        foreach ($users as $user) {
            RecentSearch::updateOrInsert(
                ['user_id' => $user->id, 'query' => 'cricket trials ahmedabad'],
                ['user_id' => $user->id, 'query' => 'cricket trials ahmedabad']
            );
            RecentSearch::updateOrInsert(
                ['user_id' => $user->id, 'query' => 'football coaching'],
                ['user_id' => $user->id, 'query' => 'football coaching']
            );
        }

        $this->command->info('Recent searches seeded: ' . RecentSearch::count());
    }

    private function seedExpiryRules(): void
    {
        $this->command->info('Seeding expiry rules...');

        $rules = [
            ['content_type' => 'trial', 'trigger_field' => 'event_date', 'days_after' => 1, 'is_active' => true],
            ['content_type' => 'tournament', 'trigger_field' => 'final_date', 'days_after' => 7, 'is_active' => true],
            ['content_type' => 'sponsorship', 'trigger_field' => 'listed_deadline', 'days_after' => 0, 'is_active' => true],
            ['content_type' => 'scholarship', 'trigger_field' => 'listed_deadline', 'days_after' => 0, 'is_active' => true],
        ];
        foreach ($rules as $rule) {
            ExpiryRule::updateOrInsert(['content_type' => $rule['content_type']], $rule);
        }

        $this->command->info('Expiry rules seeded: ' . ExpiryRule::count());
    }

    private function printUserCredentials(): void
    {
        $this->command->info('');
        $this->command->info('=== TEST USER CREDENTIALS ===');
        $this->command->info('All users have password: password');
        $this->command->info('');
        $this->command->info('Athletes (user_id 2, 7, 8, 11, 12):');
        $this->command->info('  athlete1@sportx.test (ID: 2) - John Athlete');
        $this->command->info('  athlete2@sportx.test (ID: 7) - Rahul Sharma');
        $this->command->info('  athlete3@sportx.test (ID: 8) - Priya Patel');
        $this->command->info('');
        $this->command->info('Coaches (user_id 3, 9):');
        $this->command->info('  coach1@sportx.test (ID: 3) - Sarah Coach');
        $this->command->info('  coach2@sportx.test (ID: 9) - Vikram Singh');
        $this->command->info('');
        $this->command->info('Academies (user_id 4, 10):');
        $this->command->info('  academy1@sportx.test (ID: 4) - Elite Cricket Academy');
        $this->command->info('  academy2@sportx.test (ID: 10) - Mumbai Cricket Academy');
        $this->command->info('');
        $this->command->info('To test connection requests:');
        $this->command->info('  Authenticate as athlete1@sportx.test, then send connection request to user_id 3');
    }
}
