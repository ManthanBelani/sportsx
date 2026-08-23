<?php

namespace Database\Seeders;

use App\Models\SponsorProfile;
use App\Models\Sponsorship;
use Illuminate\Database\Seeder;

class SponsorshipSeeder extends Seeder
{
    public function run(): void
    {
        $sponsor = SponsorProfile::first();

        $sponsorships = [
            [
                'title' => 'U-14 Cricket Kit Sponsorship',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'Decathlon India',
                'sport_id' => 1,
                'eligibility_criteria' => 'Selected U-14 trial participants from Ahmedabad\nDistrict or state level representation\nActive in school/club cricket\nAge 10-14 years',
                'deadline' => now()->addDays(20)->toDateString(),
                'application_link' => 'https://decathlon.example.com/sponsor',
                'contact_email' => 'sports@decathlon.example.com',
                'contact_phone' => '+91 80405 67890',
                'benefits_offered' => 'Full cricket kit (bat, pads, gloves) for the season,Training camp access',
                'amount' => 15000.00,
                'status' => 'published',
            ],
            [
                'title' => 'Football Gear Sponsorship',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'Decathlon India',
                'sport_id' => 2,
                'eligibility_criteria' => 'Registered footballers with active tournament participation\nAge 12-18 years\nSchool or club level representation',
                'deadline' => now()->addDays(25)->toDateString(),
                'application_link' => 'https://decathlon.example.com/football',
                'contact_email' => 'sports@decathlon.example.com',
                'contact_phone' => '+91 80405 67890',
                'benefits_offered' => 'Complete football kit + boots,Access to Decathlon training centers',
                'amount' => 12000.00,
                'status' => 'published',
            ],
            [
                'title' => 'Nike Emerging Athletes Program 2026',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'Nike India',
                'sport_id' => 2,
                'eligibility_criteria' => 'Indian citizen aged 13-20 years\nActive competitor at district or state level\nMinimum 1 year consistent training\nStrong academic standing (min. 55%)',
                'deadline' => now()->addDays(45)->toDateString(),
                'application_link' => 'https://nike.example.com/athletes',
                'contact_email' => 'athlete@nike.example.com',
                'contact_phone' => '+91 80410 12345',
                'benefits_offered' => '₹25,000 monetary grant,Complete Nike footwear and apparel kit,3-month mentorship with Nike athlete coach,Priority entry to Nike-sponsored events',
                'amount' => 25000.00,
                'status' => 'published',
            ],
            [
                'title' => 'Adidas Grassroots Sports Initiative',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'Adidas India',
                'sport_id' => 2,
                'eligibility_criteria' => 'Young athletes from underserved communities\nAge 10-22 years\nDemonstrated passion and potential',
                'deadline' => now()->addDays(60)->toDateString(),
                'application_link' => 'https://adidas.example.com/grassroots',
                'contact_email' => 'sports@adidas.example.com',
                'contact_phone' => '+91 80420 23456',
                'benefits_offered' => 'Footwear and apparel kit,Training camp access,Global event participation opportunities',
                'amount' => 15000.00,
                'status' => 'published',
            ],
            [
                'title' => 'Red Bull Junior Athletes',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'Red Bull India',
                'sport_id' => 8,
                'eligibility_criteria' => 'Exceptional potential in action/adventure sports\nAge 14-25 years\nCompetition experience at state/national level',
                'deadline' => now()->addDays(90)->toDateString(),
                'application_link' => 'https://redbull.example.com/junior',
                'contact_email' => 'athletes@redbull.example.com',
                'contact_phone' => '+91 80430 34567',
                'benefits_offered' => '₹50,000 grant,Event entry sponsorship,Global exposure and mentorship',
                'amount' => 50000.00,
                'status' => 'published',
            ],
            [
                'title' => 'SportyAI Talent Development Program',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'SportyAI Foundation',
                'sport_id' => 1,
                'eligibility_criteria' => 'AI-powered sports training program\nAge 12-20 years\nCommitment to technology-enabled training',
                'deadline' => now()->addDays(30)->toDateString(),
                'application_link' => 'https://sportyai.example.com/apply',
                'contact_email' => 'talent@sportyai.example.com',
                'contact_phone' => '+91 80440 45678',
                'benefits_offered' => 'AI-powered training analysis,Expert coaching mentorship,Competition fee coverage',
                'amount' => 30000.00,
                'status' => 'published',
            ],
            [
                'title' => 'Gopalan Sports Excellence Award',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'Gopalan Enterprises',
                'sport_id' => 3,
                'eligibility_criteria' => 'Outstanding badminton players\nAge 10-22 years\nState rank or school champion',
                'deadline' => now()->addDays(35)->toDateString(),
                'application_link' => 'https://gopalan.example.com/sports',
                'contact_email' => 'awards@gopalan.example.com',
                'contact_phone' => '+91 80450 56789',
                'benefits_offered' => 'Annual training stipend,International tournament entries,Equipment sponsorship',
                'amount' => 60000.00,
                'status' => 'published',
            ],
            [
                'title' => 'OGQ Athlete Support Programme',
                'sponsor_id' => $sponsor?->id ?? 1,
                'organization_name' => 'Olympic Gold Quest',
                'sport_id' => 5,
                'eligibility_criteria' => 'Olympic sports athletes\nAge 14-28 years\nNational level competitor or higher\n medal winner at state level',
                'deadline' => now()->addDays(120)->toDateString(),
                'application_link' => 'https://ogq.example.com/support',
                'contact_email' => 'athletes@ogq.example.com',
                'contact_phone' => '+91 80460 67890',
                'benefits_offered' => 'Full training support,Competition expenses covered,Equipment and gear,Monthly stipend',
                'amount' => 200000.00,
                'status' => 'published',
            ],
        ];

        foreach ($sponsorships as $sponsorship) {
            Sponsorship::updateOrCreate(
                ['title' => $sponsorship['title']],
                $sponsorship
            );
        }

        $this->command->info('Sponsorships seeded: ' . count($sponsorships));
    }
}
