<?php

namespace Database\Seeders;

use App\Models\RecentSearch;
use App\Models\User;
use Illuminate\Database\Seeder;

class RecentSearchSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::limit(3)->get();

        if ($users->isEmpty()) {
            $this->command->warn('No users found. Run UserSeeder first.');
            return;
        }

        $searches = [
            ['user_id' => $users[0]->id, 'search_query' => 'cricket trials ahmedabad'],
            ['user_id' => $users[0]->id, 'search_query' => 'U-14 football'],
            ['user_id' => $users[1]->id, 'search_query' => 'swimming academy'],
            ['user_id' => $users[2]->id, 'search_query' => 'scholarship 2026'],
        ];

        foreach ($searches as $search) {
            RecentSearch::updateOrCreate($search);
        }

        $this->command->info('Recent searches seeded: ' . count($searches));
    }
}
