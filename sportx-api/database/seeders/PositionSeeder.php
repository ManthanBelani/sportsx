<?php

namespace Database\Seeders;

use App\Models\Position;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Playing positions master data (Phase 9).
 *
 * Positions are scoped to a sport and feed the athlete discovery filters.
 */
class PositionSeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            'Cricket' => ['Batsman', 'Wicket Keeper', 'All Rounder', 'Fast Bowler', 'Spin Bowler', 'Leg Spinner', 'Left Hand Batter'],
            'Football' => ['Goalkeeper', 'Defender', 'Centre Back', 'Full Back', 'Midfielder', 'Attacking Midfielder', 'Defensive Midfielder', 'Striker', 'Winger'],
            'Badminton' => ['Singles', 'Doubles', 'Mixed Doubles', 'Front Court', 'Back Court'],
            'Athletics' => ['Sprinter', 'Middle Distance', 'Long Distance', 'Pole Vault', 'Javelin Throw', 'Shot Put', 'Long Jump', 'High Jump', 'Race Walk'],
            'Swimming' => ['Freestyle', 'Backstroke', 'Breaststroke', 'Butterfly', 'Medley', 'Open Water'],
            'Basketball' => ['Point Guard', 'Shooting Guard', 'Small Forward', 'Power Forward', 'Center'],
            'Tennis' => ['Singles', 'Doubles', 'Baseline', 'Volley'],
            'Volleyball' => ['Outside Hitter', 'Opposite Hitter', 'Setter', 'Middle Blocker', 'Libero'],
            'Kabaddi' => ['Raider', 'Defender', 'All Rounder', 'Anchor'],
            'Hockey' => ['Goalkeeper', 'Defender', 'Midfielder', 'Forward', 'Penalty Corner Specialist'],
        ];

        $created = 0;

        foreach ($rows as $sportName => $positions) {
            $sportId = SeedLookup::sportId($sportName);

            if (! $sportId) {
                $this->command->warn('Sport not found: '.$sportName.'. Run MasterDataSeeder first.');
                continue;
            }

            foreach ($positions as $position) {
                Position::updateOrCreate(
                    ['sport_id' => $sportId, 'name' => $position],
                    []
                );
                $created++;
            }
        }

        $this->command->info('Positions seeded: '.$created);
    }
}
