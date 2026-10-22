<?php

namespace Database\Seeders;

use App\Models\Group;
use App\Models\GroupMember;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Community groups shown on the Community tab and the /groups screen.
 */
class GroupSeeder extends Seeder
{
    public function run(): void
    {
        $groups = [
            ['name' => 'Cricket Coaches Network', 'description' => 'Coaches sharing drills, drills plans and match analysis.', 'type' => 'coaching'],
            ['name' => 'Ahmedabad Athletes', 'description' => 'Training partners and local meetups for athletes in Ahmedabad.', 'type' => 'athletes'],
            ['name' => 'Trials & Tryouts India', 'description' => 'Every open trial and selection camp, posted in one place.', 'type' => 'trials'],
            ['name' => 'Football Academy Owners', 'description' => 'Academy directors discussing operations, admissions and fixtures.', 'type' => 'coaching'],
            ['name' => 'U18 Championship Circle', 'description' => 'Players, parents and coaches of the U18 championship.', 'type' => 'general'],
            ['name' => 'Marathon Training Squad', 'description' => 'Weekly long runs, pace groups and race logistics.', 'type' => 'athletes'],
        ];

        foreach ($groups as $g) {
            Group::updateOrCreate(
                ['name' => $g['name']],
                [
                    'description' => $g['description'],
                    'type' => $g['type'],
                    'status' => 'active',
                ]
            );
        }

        // Make the demo athlete a member of the first two groups so "My
        // Groups" and the joined state have data.
        $member = User::where('role', 'athlete')->first();
        if ($member) {
            foreach (Group::orderBy('id')->take(2)->get() as $group) {
                GroupMember::firstOrCreate(
                    ['group_id' => $group->id, 'user_id' => $member->id],
                    ['role' => 'member', 'joined_at' => now()]
                );
            }
        }

        $this->command->info('Groups seeded: ' . Group::count());
    }
}
