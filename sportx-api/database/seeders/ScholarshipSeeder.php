<?php

namespace Database\Seeders;

use App\Models\Scholarship;
use App\Models\User;
use Illuminate\Database\Seeder;

class ScholarshipSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::where('role', 'admin')->first();

        $scholarships = [
            [
                'name' => 'Young Athlete Scholarship 2026',
                'organization_name' => 'Reliance Foundation',
                'sport_id' => 1,
                'created_by' => $admin?->id,
                'eligibility' => 'Athletes aged 12-18 from Gujarat\nNational-level representation preferred\nMinimum 60% academic score',
                'deadline' => now()->addDays(30)->toDateString(),
                'application_link' => 'https://rf.example.com/apply',
                'contact_email' => 'scholarships@rf.example.com',
                'contact_phone' => '+91 1800 123 4567',
                'amount' => 50000.00,
                'benefits' => 'Annual stipend + academy fees waived,Competition fee coverage',
                'documents_required' => ['Aadhaar Card', 'Performance certificate', 'School records', 'Income certificate'],
                'description' => 'Supporting young cricket talent across Gujarat. This scholarship aims to identify and nurture promising young cricketers who demonstrate exceptional skill and dedication to the sport.',
                'status' => 'published',
            ],
            [
                'name' => 'Women in Sports Scholarship',
                'organization_name' => 'Tata Trust',
                'sport_id' => 2,
                'created_by' => $admin?->id,
                'eligibility' => 'Female athletes aged 14-25\nActive competitor at state/district level\nStrong academic record',
                'deadline' => now()->addDays(45)->toDateString(),
                'application_link' => 'https://tata.example.com/sports',
                'contact_email' => 'sports@tata.example.com',
                'contact_phone' => '+91 22 6665 8282',
                'amount' => 75000.00,
                'benefits' => 'Training expenses + Equipment allowance,Monthly mentorship sessions',
                'documents_required' => ['Aadhaar Card', 'Performance records', 'Coach recommendation', 'School bonafide'],
                'description' => 'Empowering female athletes across India. This scholarship supports young women who show outstanding potential in sports and help them pursue their athletic dreams.',
                'status' => 'published',
            ],
            [
                'name' => 'SportyAI Junior Athlete Scholarship 2026',
                'organization_name' => 'SportyAI Foundation',
                'sport_id' => 1,
                'created_by' => $admin?->id,
                'eligibility' => 'Age 10-18 years\nActive in school or club sports\nInterest in technology-enhanced training',
                'deadline' => now()->addDays(25)->toDateString(),
                'application_link' => 'https://sportyai.example.com/junior',
                'contact_email' => 'scholarships@sportyai.example.com',
                'contact_phone' => '+91 80440 45678',
                'amount' => 35000.00,
                'benefits' => 'AI-powered training analysis,Equipment support,Competition entries',
                'documents_required' => ['Aadhaar Card', 'Sports certificates', 'School ID'],
                'description' => 'Supporting young athletes with cutting-edge AI training technology. Combines sports excellence with modern tech tools.',
                'status' => 'published',
            ],
            [
                'name' => 'GoSports Basketball Excellence Grant',
                'organization_name' => 'GoSports Foundation',
                'sport_id' => 6,
                'created_by' => $admin?->id,
                'eligibility' => 'Basketball players aged 13-22\nState/national level representation\nTeam player with leadership qualities',
                'deadline' => now()->addDays(40)->toDateString(),
                'application_link' => 'https://gosports.example.com/basketball',
                'contact_email' => 'grants@gosports.example.com',
                'contact_phone' => '+91 80 4567 8900',
                'amount' => 75000.00,
                'benefits' => 'Training gear package,Camp participation,Coaching access',
                'documents_required' => ['Aadhaar Card', 'Competition certificates', 'Coach NOC', 'Academic records'],
                'description' => 'Developing basketball excellence in India. Supports promising players with training and competitive opportunities.',
                'status' => 'published',
            ],
            [
                'name' => 'Swimming Talent Scholarship',
                'organization_name' => 'Aqua Sports Trust',
                'sport_id' => 4,
                'created_by' => $admin?->id,
                'eligibility' => 'Swimmers aged 8-20\n参加过市级以上比赛\nWater safety certification required',
                'deadline' => now()->addDays(20)->toDateString(),
                'application_link' => 'https://aquasports.example.com',
                'contact_email' => 'swimming@aquasports.example.com',
                'contact_phone' => '+91 98250 12345',
                'amount' => 40000.00,
                'benefits' => 'Pool access pass,Training coach fees,Competition entries',
                'documents_required' => ['Aadhaar Card', 'Swimming certificates', 'Medical fitness certificate'],
                'description' => 'Nurturing swimming talent across India. Provides comprehensive support for swimmers aiming for competitive excellence.',
                'status' => 'published',
            ],
            [
                'name' => 'Future Champions Athletics Grant',
                'organization_name' => 'Fit India Movement',
                'sport_id' => 5,
                'created_by' => $admin?->id,
                'eligibility' => 'Track and field athletes\nAge 12-24 years\nDistrict or state representation',
                'deadline' => now()->addDays(55)->toDateString(),
                'application_link' => 'https://fitindia.example.com/athletics',
                'contact_email' => 'athletics@fitindia.example.com',
                'contact_phone' => '+91 1800 456 7890',
                'amount' => 60000.00,
                'benefits' => 'Track access and training gear,Specialized coaching,Competition expenses',
                'documents_required' => ['Aadhaar Card', 'Achievement certificates', 'Medical clearance', 'Guardian consent'],
                'description' => 'Supporting Indias next generation of athletics champions. Focus on holistic athlete development.',
                'status' => 'published',
            ],
            [
                'name' => 'Tennis Excellence Program',
                'organization_name' => 'Rexanji Sports Trust',
                'sport_id' => 7,
                'created_by' => $admin?->id,
                'eligibility' => 'Tennis players aged 10-21\nAITF ranking or state champion\nCommitment to full-time training',
                'deadline' => now()->addDays(70)->toDateString(),
                'application_link' => 'https://rexanji.example.com/tennis',
                'contact_email' => 'tennis@rexanji.example.com',
                'contact_phone' => '+91 22 2345 6789',
                'amount' => 100000.00,
                'benefits' => 'Academy fees waiver,International tournament entries,Equipment sponsorship,Monthly stipend',
                'documents_required' => ['Aadhaar Card', 'AITF card or ranking certificate', 'Coach assessment', 'Academic records'],
                'description' => 'Creating tennis champions for India. Comprehensive support including academy training, equipment, and competition opportunities.',
                'status' => 'published',
            ],
            [
                'name' => 'Khelo India Youth Scholarship',
                'organization_name' => 'Khelo India',
                'sport_id' => null, // Multi-sport
                'created_by' => $admin?->id,
                'eligibility' => 'Multi-sport scholarship for talented youth\nAge 8-18 years\nRecommended by state sports authority\nAcademic requirement: 45% minimum',
                'deadline' => now()->addDays(90)->toDateString(),
                'application_link' => 'https://kheloindia.example.gov.in/youth',
                'contact_email' => 'youth@kheloindia.example.gov.in',
                'contact_phone' => '+91 11 2345 6789',
                'amount' => 150000.00,
                'benefits' => 'Annual scholarship amount,Priority access to training centers,Competition exposure,Equipment support',
                'documents_required' => ['Aadhaar Card', 'State sports authority recommendation', 'School bonafide', 'Medical certificate', 'Parent/guardian consent'],
                'description' => 'Government of India initiative to identify and nurture sporting talent across all Olympic and indigenous sports.',
                'status' => 'published',
            ],
        ];

        foreach ($scholarships as $scholarship) {
            Scholarship::updateOrCreate(
                ['name' => $scholarship['name']],
                $scholarship
            );
        }

        $this->command->info('Scholarships seeded: ' . count($scholarships));
    }
}
