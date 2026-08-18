<?php

namespace Database\Seeders;

use App\Models\Academy;
use App\Models\AthleteProfile;
use App\Models\CoachProfile;
use App\Models\MediaItem;
use App\Models\OrganizerProfile;
use App\Models\Post;
use App\Models\Scholarship;
use App\Models\SportsVenue;
use App\Models\Sponsorship;
use App\Models\Trial;
use App\Models\Tournament;
use Illuminate\Database\Seeder;

class MediaItemSeeder extends Seeder
{
    public function run(): void
    {
        $this->seedAthletePhotos();
        $this->seedCoachPhotos();
        $this->seedAcademyPhotos();
        $this->seedOrganizerPhotos();
        $this->seedVenuePhotos();
        $this->seedTrialPhotos();
        $this->seedTournamentPhotos();
        $this->seedScholarshipPhotos();
        $this->seedSponsorshipPhotos();
        $this->seedPostMedia();
    }

    private function seedAthletePhotos(): void
    {
        $athletes = AthleteProfile::take(5)->get();
        foreach ($athletes as $index => $athlete) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => AthleteProfile::class,
                    'owner_id' => $athlete->id,
                    'media_type' => 'photo',
                ],
                [
                    'disk' => 'public',
                    'path' => 'avatars/athlete_' . ($index + 1) . '.jpg',
                    'original_name' => 'athlete_photo_' . ($index + 1) . '.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(50000, 200000),
                    'sort_order' => 1,
                ]
            );
        }
        $this->command->info('Athlete profile photos seeded');
    }

    private function seedCoachPhotos(): void
    {
        $coaches = CoachProfile::take(3)->get();
        foreach ($coaches as $index => $coach) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => CoachProfile::class,
                    'owner_id' => $coach->id,
                    'media_type' => 'photo',
                ],
                [
                    'disk' => 'public',
                    'path' => 'avatars/coach_' . ($index + 1) . '.jpg',
                    'original_name' => 'coach_photo_' . ($index + 1) . '.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(50000, 200000),
                    'sort_order' => 1,
                ]
            );
        }
        $this->command->info('Coach profile photos seeded');
    }

    private function seedAcademyPhotos(): void
    {
        $academies = Academy::take(3)->get();
        foreach ($academies as $index => $academy) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => Academy::class,
                    'owner_id' => $academy->id,
                    'media_type' => 'photo',
                ],
                [
                    'disk' => 'public',
                    'path' => 'academies/academy_' . ($index + 1) . '_cover.jpg',
                    'original_name' => 'academy_cover_' . ($index + 1) . '.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(100000, 500000),
                    'sort_order' => 1,
                ]
            );

            MediaItem::updateOrCreate(
                [
                    'owner_type' => Academy::class,
                    'owner_id' => $academy->id,
                    'media_type' => 'photo',
                    'sort_order' => 2,
                ],
                [
                    'disk' => 'public',
                    'path' => 'academies/academy_' . ($index + 1) . '_gallery_1.jpg',
                    'original_name' => 'academy_gallery_' . ($index + 1) . '_1.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(100000, 500000),
                ]
            );
        }
        $this->command->info('Academy photos seeded');
    }

    private function seedOrganizerPhotos(): void
    {
        $organizers = OrganizerProfile::take(3)->get();
        foreach ($organizers as $index => $organizer) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => OrganizerProfile::class,
                    'owner_id' => $organizer->id,
                    'media_type' => 'photo',
                ],
                [
                    'disk' => 'public',
                    'path' => 'organizers/org_' . ($index + 1) . '_logo.png',
                    'original_name' => 'organizer_logo_' . ($index + 1) . '.png',
                    'mime_type' => 'image/png',
                    'size_bytes' => rand(20000, 100000),
                    'sort_order' => 1,
                ]
            );
        }
        $this->command->info('Organizer logos seeded');
    }

    private function seedVenuePhotos(): void
    {
        $venues = SportsVenue::take(3)->get();
        foreach ($venues as $index => $venue) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => SportsVenue::class,
                    'owner_id' => $venue->id,
                    'media_type' => 'photo',
                ],
                [
                    'disk' => 'public',
                    'path' => 'venues/venue_' . ($index + 1) . '_cover.jpg',
                    'original_name' => 'venue_cover_' . ($index + 1) . '.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(100000, 500000),
                    'sort_order' => 1,
                ]
            );

            MediaItem::updateOrCreate(
                [
                    'owner_type' => SportsVenue::class,
                    'owner_id' => $venue->id,
                    'media_type' => 'photo',
                    'sort_order' => 2,
                ],
                [
                    'disk' => 'public',
                    'path' => 'venues/venue_' . ($index + 1) . '_gallery_1.jpg',
                    'original_name' => 'venue_gallery_' . ($index + 1) . '_1.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(100000, 500000),
                ]
            );
        }
        $this->command->info('Venue photos seeded');
    }

    private function seedTrialPhotos(): void
    {
        $trials = Trial::take(3)->get();
        foreach ($trials as $index => $trial) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => Trial::class,
                    'owner_id' => $trial->id,
                    'media_type' => 'photo',
                ],
                [
                    'disk' => 'public',
                    'path' => 'trials/trial_' . ($index + 1) . '_banner.jpg',
                    'original_name' => 'trial_banner_' . ($index + 1) . '.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(100000, 400000),
                    'sort_order' => 1,
                ]
            );
        }
        $this->command->info('Trial banners seeded');
    }

    private function seedTournamentPhotos(): void
    {
        $tournaments = Tournament::take(3)->get();
        foreach ($tournaments as $index => $tournament) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => Tournament::class,
                    'owner_id' => $tournament->id,
                    'media_type' => 'photo',
                ],
                [
                    'disk' => 'public',
                    'path' => 'tournaments/tournament_' . ($index + 1) . '_cover.jpg',
                    'original_name' => 'tournament_cover_' . ($index + 1) . '.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(100000, 500000),
                    'sort_order' => 1,
                ]
            );

            MediaItem::updateOrCreate(
                [
                    'owner_type' => Tournament::class,
                    'owner_id' => $tournament->id,
                    'media_type' => 'document',
                ],
                [
                    'disk' => 'public',
                    'path' => 'tournaments/tournament_' . ($index + 1) . '_bracket.pdf',
                    'original_name' => 'tournament_bracket_' . ($index + 1) . '.pdf',
                    'mime_type' => 'application/pdf',
                    'size_bytes' => rand(50000, 200000),
                    'sort_order' => 2,
                ]
            );
        }
        $this->command->info('Tournament media seeded');
    }

    private function seedScholarshipPhotos(): void
    {
        $scholarships = Scholarship::take(3)->get();
        foreach ($scholarships as $index => $scholarship) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => Scholarship::class,
                    'owner_id' => $scholarship->id,
                    'media_type' => 'photo',
                ],
                [
                    'disk' => 'public',
                    'path' => 'scholarships/scholarship_' . ($index + 1) . '_banner.jpg',
                    'original_name' => 'scholarship_banner_' . ($index + 1) . '.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(80000, 300000),
                    'sort_order' => 1,
                ]
            );
        }
        $this->command->info('Scholarship banners seeded');
    }

    private function seedSponsorshipPhotos(): void
    {
        $sponsorships = Sponsorship::take(3)->get();
        foreach ($sponsorships as $index => $sponsorship) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => Sponsorship::class,
                    'owner_id' => $sponsorship->id,
                    'media_type' => 'photo',
                ],
                [
                    'disk' => 'public',
                    'path' => 'sponsorships/sponsorship_' . ($index + 1) . '_banner.jpg',
                    'original_name' => 'sponsorship_banner_' . ($index + 1) . '.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(80000, 300000),
                    'sort_order' => 1,
                ]
            );
        }
        $this->command->info('Sponsorship banners seeded');
    }

    private function seedPostMedia(): void
    {
        $posts = Post::take(5)->get();
        foreach ($posts as $index => $post) {
            MediaItem::updateOrCreate(
                [
                    'owner_type' => Post::class,
                    'owner_id' => $post->id,
                    'media_type' => 'photo',
                    'sort_order' => 1,
                ],
                [
                    'disk' => 'public',
                    'path' => 'posts/post_' . ($index + 1) . '_image.jpg',
                    'original_name' => 'post_image_' . ($index + 1) . '.jpg',
                    'mime_type' => 'image/jpeg',
                    'size_bytes' => rand(100000, 800000),
                ]
            );
        }
        $this->command->info('Post media seeded');
    }
}
