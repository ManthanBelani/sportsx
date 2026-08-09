<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\AgeGroup;
use App\Models\OrganizerProfile;
use App\Models\Scholarship;
use App\Models\SportsVenue;
use App\Models\Sponsorship;
use App\Models\SponsorProfile;
use App\Models\Trial;
use App\Models\Tournament;
use App\Models\TournamentCategory;
use App\Models\User;
use Illuminate\Database\Seeder;

class DevDataSeeder extends Seeder
{
    public function run(): void
    {
        $coachUser = User::where('role', 'coach')->first();
        $academy = Academy::first();

        $trial = Trial::firstOrCreate(
            ['name' => 'U-14 Cricket Trials Ahmedabad'],
            [
                'posted_by_user_id' => $coachUser?->id ?? User::first()->id,
                'academy_id' => $academy?->id,
                'organization_name' => 'Elite Cricket Academy',
                'sport_id' => 1,
                'event_datetime' => now()->addDays(14),
                'venue' => 'Narendra Modi Stadium',
                'google_maps_url' => 'https://maps.google.com/?q=Narendra+Modi+Stadium',
                'city_id' => 1,
                'contact_number' => '+91 98765 43210',
                'registration_deadline' => now()->addDays(7),
                'eligibility' => 'Boys, Under-14, Ahmedabad residents',
                'entry_fee' => '200',
                'required_documents' => ['Aadhaar Card', 'Passport Photo'],
                'vacancies' => 30,
                'benefits' => 'Selected athletes get free academy kit',
                'status' => 'published',
            ]
        );
        $this->command->info("Trial created: {$trial->id}");

        $orgUser = User::firstOrCreate(
            ['email' => 'org1@sportx.test'],
            ['role' => 'organizer', 'name' => 'Rohan Desai', 'password' => bcrypt('password')]
        );
        $orgProfile = OrganizerProfile::firstOrCreate(
            ['user_id' => $orgUser->id],
            ['organization_name' => 'Gujarat Cricket Federation', 'org_type' => 'federation']
        );
        $tournament = Tournament::firstOrCreate(
            ['name' => 'U-16 State Cup 2026'],
            [
                'organizer_id' => $orgProfile->id,
                'sport_id' => 1,
                'organizer_name' => 'Gujarat Cricket Federation',
                'format' => 'knockout',
                'start_date' => now()->addDays(21)->toDateString(),
                'end_date' => now()->addDays(26)->toDateString(),
                'registration_deadline' => now()->addDays(10)->toDateString(),
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
        $this->command->info("Tournament created: {$tournament->id}");

        $ageGroup = AgeGroup::where('name', 'Under-16')->first();
        TournamentCategory::firstOrCreate(
            ['tournament_id' => $tournament->id, 'age_group_id' => $ageGroup?->id],
            [
                'name' => 'U-16 Boys',
                'capacity' => 24,
                'waitlist_enabled' => true,
            ]
        );
        $this->command->info('Tournament category created');

        Scholarship::firstOrCreate(
            ['name' => 'Young Athlete Scholarship 2026'],
            [
                'organization_name' => 'Reliance Foundation',
                'sport_id' => 1,
                'eligibility' => 'Athletes aged 12-18 from Gujarat, national-level representation preferred',
                'deadline' => now()->addDays(30)->toDateString(),
                'application_link' => 'https://rf.example.com/apply',
                'contact_email' => 'scholarships@rf.example.com',
                'contact_phone' => '+91 1800 123 4567',
                'amount' => 50000.00,
                'benefits' => 'Annual stipend + academy fees waived',
                'documents_required' => ['Aadhaar', 'Performance certificate', 'School records'],
                'description' => 'Supporting young cricket talent across Gujarat',
                'status' => 'published',
            ]
        );
        $this->command->info('Scholarship created');

        $sponsorUser = User::firstOrCreate(
            ['email' => 'sponsor1@sportx.test'],
            ['role' => 'sponsor', 'name' => 'Priya Sharma', 'password' => bcrypt('password')]
        );
        $sponsorProfile = SponsorProfile::firstOrCreate(
            ['user_id' => $sponsorUser->id],
            ['brand_name' => 'Decathlon India', 'category' => 'Sports retail']
        );
        Sponsorship::firstOrCreate(
            ['title' => 'U-14 Cricket Kit Sponsorship', 'sponsor_id' => $sponsorProfile->id],
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
        $this->command->info('Sponsorship created');

        SportsVenue::firstOrCreate(
            ['name' => 'Sardar Patel Stadium'],
            [
                'sport_id' => 1,
                'address' => 'Motera, Ahmedabad',
                'google_maps_url' => 'https://maps.google.com/?q=Sardar+Patel+Stadium',
                'contact_number' => '+91 79 2345 6789',
                'city_id' => 1,
                'booking_available' => true,
                'pricing' => '₹2,000/hour for nets, ₹5,000/day for ground',
                'facilities' => ['Floodlights', 'Dressing Rooms', 'Practice Nets', 'Parking'],
                'working_hours' => '6 AM - 10 PM',
                'listing_status' => 'published',
            ]
        );
        $this->command->info('Sports venue created');
    }
}
