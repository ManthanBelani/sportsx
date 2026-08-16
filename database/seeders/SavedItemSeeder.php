<?php

namespace Database\Seeders;

use App\Models\AthleteProfile;
use App\Models\SavedItem;
use App\Models\Trial;
use App\Models\Tournament;
use Illuminate\Database\Seeder;

class SavedItemSeeder extends Seeder
{
    public function run(): void
    {
        $athlete = AthleteProfile::first();
        $trial = Trial::first();
        $tournament = Tournament::first();

        if (!$athlete) {
            $this->command->warn('No athlete profile found. Run AthleteProfileSeeder first.');
            return;
        }

        $items = [];
        if ($trial) {
            $items[] = [
                'user_id' => $athlete->user_id,
                'item_type' => 'trial',
                'item_id' => $trial->id,
            ];
        }
        if ($tournament) {
            $items[] = [
                'user_id' => $athlete->user_id,
                'item_type' => 'tournament',
                'item_id' => $tournament->id,
            ];
        }

        foreach ($items as $item) {
            SavedItem::updateOrCreate($item);
        }

        $this->command->info('Saved items seeded: ' . count($items));
    }
}
