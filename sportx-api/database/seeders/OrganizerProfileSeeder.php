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
            // One profile per tournament owner so every event belongs to the
            // organisation that actually runs it.
            [
                'email' => 'organizer.cricket@sportx.test',
                'organization_name' => 'Gujarat Cricket Federation',
                'org_type' => 'federation',
                'city' => 'Ahmedabad',
                'description' => 'State cricket body running age-group state cups and district tournaments.',
                'event_types' => ['tournament', 'trial'],
                'registration_number' => 'GCF/AHM/2012/0031',
                'website' => 'https://gcf.example.com',
                'verification_status' => 'verified',
                'sports' => ['Cricket'],
            ],
            [
                'email' => 'organizer.badminton@sportx.test',
                'organization_name' => 'Badminton Association of India',
                'org_type' => 'federation',
                'city' => 'Ahmedabad',
                'description' => 'National badminton body hosting open championships.',
                'event_types' => ['tournament'],
                'registration_number' => 'BAI/DEL/1990/0102',
                'website' => 'https://bai.example.com',
                'verification_status' => 'verified',
                'sports' => ['Badminton'],
            ],
            [
                'email' => 'organizer.swimming@sportx.test',
                'organization_name' => 'Mumbai Swimming Association',
                'org_type' => 'ngo',
                'city' => 'Mumbai',
                'description' => 'Swimming association running junior time-trial championships.',
                'event_types' => ['tournament', 'camp'],
                'registration_number' => 'MSA/MUM/2014/0455',
                'website' => 'https://msa.example.com',
                'verification_status' => 'verified',
                'sports' => ['Swimming'],
            ],
            [
                'email' => 'organizer.athletics@sportx.test',
                'organization_name' => 'Delhi Athletics Federation',
                'org_type' => 'federation',
                'city' => 'Delhi',
                'description' => 'Track and field federation organising district and state meets.',
                'event_types' => ['tournament'],
                'registration_number' => 'DAF/DEL/2001/0099',
                'website' => 'https://daf.example.com',
                'verification_status' => 'verified',
                'sports' => ['Athletics'],
            ],
            [
                'email' => 'organizer.basketball@sportx.test',
                'organization_name' => 'Karnataka Basketball Association',
                'org_type' => 'club',
                'city' => 'Bengaluru',
                'description' => 'City basketball league operator running junior and senior leagues.',
                'event_types' => ['league', 'tournament'],
                'registration_number' => 'KBA/BLR/2018/0121',
                'website' => 'https://kba.example.com',
                'verification_status' => 'verified',
                'sports' => ['Basketball'],
            ],
            [
                'email' => 'organizer.tennis@sportx.test',
                'organization_name' => 'All India Tennis Association',
                'org_type' => 'federation',
                'city' => 'Chennai',
                'description' => 'National tennis body hosting open and junior championships.',
                'event_types' => ['tournament'],
                'registration_number' => 'AITA/CHN/1988/0004',
                'website' => 'https://aita.example.com',
                'verification_status' => 'verified',
                'sports' => ['Tennis'],
            ],
            [
                'email' => 'organizer.wfootball@sportx.test',
                'organization_name' => 'Women Football Association',
                'org_type' => 'ngo',
                'city' => 'Mumbai',
                'description' => 'Women-only football league and cup operator.',
                'event_types' => ['tournament', 'league'],
                'registration_number' => 'WFA/MUM/2016/0233',
                'website' => 'https://wfa.example.com',
                'verification_status' => 'verified',
                'sports' => ['Football'],
            ],
            [
                'email' => 'organizer.kabaddi@sportx.test',
                'organization_name' => 'Gujarat Kabaddi Association',
                'org_type' => 'federation',
                'city' => 'Ahmedabad',
                'description' => 'State kabaddi body running professional and youth leagues.',
                'event_types' => ['tournament', 'league'],
                'registration_number' => 'GKA/AHM/2011/0076',
                'website' => 'https://gka.example.com',
                'verification_status' => 'verified',
                'sports' => ['Kabaddi'],
            ],
            [
                'email' => 'organizer.chess@sportx.test',
                'organization_name' => 'Ahmedabad Chess Association',
                'org_type' => 'club',
                'city' => 'Ahmedabad',
                'description' => 'City chess association running junior and open Swiss tournaments.',
                'event_types' => ['tournament'],
                'registration_number' => 'ACA/AHM/2009/0104',
                'website' => 'https://aca.example.com',
                'verification_status' => 'verified',
                'sports' => ['Chess'],
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
