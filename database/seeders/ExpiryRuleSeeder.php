<?php

namespace Database\Seeders;

use App\Models\ExpiryRule;
use Illuminate\Database\Seeder;

class ExpiryRuleSeeder extends Seeder
{
    public function run(): void
    {
        // AD8 defaults from wireframe (AS-05: reminder offset config)
        $rules = [
            ['content_type' => 'trial', 'trigger_field' => 'event_date', 'days_after' => 1],
            ['content_type' => 'tournament', 'trigger_field' => 'final_date', 'days_after' => 3],
            ['content_type' => 'sponsorship', 'trigger_field' => 'listed_deadline', 'days_after' => 0],
            ['content_type' => 'scholarship', 'trigger_field' => 'listed_deadline', 'days_after' => 0],
        ];

        foreach ($rules as $rule) {
            ExpiryRule::updateOrCreate(['content_type' => $rule['content_type']], $rule);
        }
    }
}
