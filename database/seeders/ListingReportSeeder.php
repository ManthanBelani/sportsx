<?php

namespace Database\Seeders;

use App\Models\ListingReport;
use App\Models\User;
use Illuminate\Database\Seeder;

class ListingReportSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('role', 'athlete')->first();

        $reports = [
            [
                'reporter_user_id' => $user?->id ?? 2,
                'reportable_type' => 'trial',
                'reportable_id' => 1,
                'reason' => 'fake',
                'comment' => 'This listing appears to be fake with misleading information.',
                'status' => 'pending',
            ],
        ];

        foreach ($reports as $report) {
            ListingReport::updateOrCreate(
                [
                    'reporter_user_id' => $report['reporter_user_id'],
                    'reportable_type' => $report['reportable_type'],
                    'reportable_id' => $report['reportable_id'],
                ],
                $report
            );
        }

        $this->command->info('Listing reports seeded: ' . count($reports));
    }
}
