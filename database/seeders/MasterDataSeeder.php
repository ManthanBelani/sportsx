<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MasterDataSeeder extends Seeder
{
    public function run(): void
    {
        // Sports (S6 trending chips + AS-14 launch city set)
        $sports = [
            ['name' => 'Cricket', 'sort_order' => 1],
            ['name' => 'Football', 'sort_order' => 2],
            ['name' => 'Badminton', 'sort_order' => 3],
            ['name' => 'Athletics', 'sort_order' => 4],
            ['name' => 'Swimming', 'sort_order' => 5],
            ['name' => 'Basketball', 'sort_order' => 6],
            ['name' => 'Tennis', 'sort_order' => 7],
            ['name' => 'Volleyball', 'sort_order' => 8],
            ['name' => 'Kabaddi', 'sort_order' => 9],
            ['name' => 'Hockey', 'sort_order' => 10],
        ];
        foreach ($sports as $sport) {
            DB::table('sports')->updateOrInsert(['name' => $sport['name']], $sport);
        }

        // Cities (launch city set — assumption AS-14)
        $cities = [
            ['name' => 'Ahmedabad', 'state' => 'Gujarat'],
            ['name' => 'Surat', 'state' => 'Gujarat'],
            ['name' => 'Vadodara', 'state' => 'Gujarat'],
            ['name' => 'Rajkot', 'state' => 'Gujarat'],
            ['name' => 'Mumbai', 'state' => 'Maharashtra'],
            ['name' => 'Pune', 'state' => 'Maharashtra'],
            ['name' => 'Delhi', 'state' => 'Delhi'],
            ['name' => 'Bengaluru', 'state' => 'Karnataka'],
            ['name' => 'Chennai', 'state' => 'Tamil Nadu'],
            ['name' => 'Hyderabad', 'state' => 'Telangana'],
            ['name' => 'Kolkata', 'state' => 'West Bengal'],
            ['name' => 'Jaipur', 'state' => 'Rajasthan'],
        ];
        foreach ($cities as $city) {
            DB::table('cities')->updateOrInsert(
                ['name' => $city['name'], 'state' => $city['state']],
                $city
            );
        }

        // Age groups (A1 options)
        $ageGroups = [
            ['name' => 'Under-10', 'min_age' => null, 'max_age' => 9],
            ['name' => 'Under-12', 'min_age' => 10, 'max_age' => 11],
            ['name' => 'Under-14', 'min_age' => 12, 'max_age' => 13],
            ['name' => 'Under-16', 'min_age' => 14, 'max_age' => 15],
            ['name' => 'Under-18', 'min_age' => 16, 'max_age' => 17],
            ['name' => 'Open', 'min_age' => 18, 'max_age' => null],
        ];
        foreach ($ageGroups as $group) {
            DB::table('age_groups')->updateOrInsert(['name' => $group['name']], $group);
        }
    }
}
