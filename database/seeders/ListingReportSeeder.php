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
                'report_type' => 'fake_listing',
                'item_type' => 'trial',
                'item_id' => 1,
                'reason' => 'This listing appears to be fake with misleading information.',
                'status' => 'pending',
            ],
        ];

        foreach ($reports as $report) {
            ListingReport::updateOrCreate(
                [
                    'reporter_user_id' => $report['reporter_user_id'],
                    'item_type' => $report['item_type'],
                    'item_id' => $report['item_id'],
                ],
                $report
            );
        }

        $this->command->info('Listing reports seeded: ' . count($reports));
    }
}
