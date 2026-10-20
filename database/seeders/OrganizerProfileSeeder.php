<?php

namespace Database\Seeders;

use App\Models\MediaItem;
use App\Models\OrganizerProfile;
use Database\Seeders\Support\SeedLookup;
use Illuminate\Database\Seeder;

/**
 * Organizer profiles for every seeded organizer.
 *
 * `org_type` covers the widened enum (event_company / individual / club /
 * college / federation / ngo / other) and the new mandatory columns
 * (city, description, event_types, registration_number, website) are filled
 * in, together with a logo/cover media item so the organizer card is not
 * blank in the app.
 */
class OrganizerProfileSeeder extends Seeder
{
    public function run(): void
    {
        $organizers = [
            [
                'email' => 'organizer@sportx.test',
                'organization_name' => 'Gujarat Sports Federation',
                'org_type' => 'federation',
                'city' => 'Ahmedabad',
                'description' => 'State level sports federation running district and state championships across 14 sports.',
                'event_types' => ['tournament', 'trial', 'camp'],
                'registration_number' => 'GSF/AHM/2009/2211',
                'website' => 'https://gsf.example.com',
                'verification_status' => 'verified',
                'sports' => ['Cricket', 'Football', 'Athletics'],
            ],
            [
                'email' => 'organizer2@sportx.test',
                'organization_name' => 'Mumbai District Sports Council',
                'org_type' => 'ngo',
                'city' => 'Mumbai',
                'description' => 'NGO promoting grassroots sport in Mumbai suburban districts through weekend leagues.',
                'event_types' => ['tournament', 'camp'],
                'registration_number' => 'MDSC/MUM/2015/0087',
                'website' => 'https://mdsc.example.com',
                'verification_status' => 'verified',
                'sports' => ['Basketball', 'Volleyball', 'Kabaddi'],
            ],
            [
                'email' => 'organizer.pending@sportx.test',
                'organization_name' => 'Pending Organizer',
                'org_type' => 'individual',
                'city' => 'Ahmedabad',
                'description' => 'Individual event organiser awaiting admin approval.',
                'event_types' => ['camp'],
                'registration_number' => null,
                'website' => null,
                'verification_status' => 'pending',
                'sports' => ['Badminton'],
            ],
        ];

        $created = 0;

        foreach ($organizers as $row) {
            $userId = SeedLookup::userId($row['email']);

            if (! $userId) {
                $this->command->warn("User {$row['email']} not found. Run UserSeeder first.");
                continue;
            }

            $organizer = OrganizerProfile::updateOrCreate(
                ['user_id' => $userId],
                [
                    'organization_name' => $row['organization_name'],
                    'org_type' => $row['org_type'],
                    'city_id' => SeedLookup::cityId($row['city']),
                    'description' => $row['description'],
                    'event_types' => $row['event_types'],
                    'registration_number' => $row['registration_number'],
                    'website' => $row['website'],
                    'verification_status' => $row['verification_status'],
                ]
            );

            $organizer->sports()->sync(SeedLookup::sportIds($row['sports']));

            // Logo + cover media so the organizer card renders an image.
            $logo = MediaItem::updateOrCreate(
                [
                    'owner_type' => OrganizerProfile::class,
                    'owner_id' => $organizer->id,
                    'media_type' => 'photo',
                    'sort_order' => 1,
                ],
                [
                    'disk' => 'public',
                    'path' => 'organizers/organizer_'.$organizer->id.'_logo.png',
                    'original_name' => 'organizer_logo.png',
                    'mime_type' => 'image/png',
                    'size_bytes' => 45000,
                    'caption' => $row['organization_name'].' logo',
                ]
            );

            $cover = MediaItem::updateOrCreate(
                [
                    'owner_type' => OrganizerProfile::class,
                    'owner_id' => $organizer->id,
                    'media_type' => 'photo',
                    'sort_order' => 2,
                ],
                [
                    'disk' => 'public',
                    'path' => 'organizers/organizer_'.$organizer->id.'_cover.jpg',
                    'original_name' => 'organizer_cover.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => 180000,
                    'caption' => $row['organization_name'].' cover',
                ]
            );

            $organizer->forceFill([
                'logo_media_id' => $logo->id,
                'cover_media_id' => $cover->id,
            ])->save();

            $created++;
        }

        $this->command->info('Organizer profiles seeded: '.$created);
    }
}
