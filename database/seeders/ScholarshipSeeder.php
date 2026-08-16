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
                'created_by_user_id' => $admin?->id,
                'eligibility' => 'Athletes aged 12-18 from Gujarat, national-level representation preferred',
                'deadline' => now()->addDays(30)->toDateString(),
                'application_link' => 'https://rf.example.com/apply',
                'contact_email' => 'scholarships@rf.example.com',
                'contact_phone' => '+91 1800 123 4567',
                'amount' => 50000.00,
                'benefits' => 'Annual stipend + academy fees waived',
                'documents_required' => json_encode(['Aadhaar', 'Performance certificate', 'School records']),
                'description' => 'Supporting young cricket talent across Gujarat',
                'status' => 'published',
            ],
            [
                'name' => 'Women in Sports Scholarship',
                'organization_name' => 'Tata Trust',
                'sport_id' => 2,
                'created_by_user_id' => $admin?->id,
                'eligibility' => 'Female athletes aged 14-25',
                'deadline' => now()->addDays(45)->toDateString(),
                'application_link' => 'https://tata.example.com/sports',
                'contact_email' => 'sports@tata.example.com',
                'contact_phone' => '+91 22 6665 8282',
                'amount' => 75000.00,
                'benefits' => 'Training expenses + Equipment allowance',
                'documents_required' => json_encode(['Aadhaar', 'Performance records', 'Coach recommendation']),
                'description' => 'Empowering female athletes across India',
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
