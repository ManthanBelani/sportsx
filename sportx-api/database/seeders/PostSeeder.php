<?php

namespace Database\Seeders;

use App\Models\Post;
use App\Models\User;
use Illuminate\Database\Seeder;

class PostSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::limit(4)->get();

        if ($users->isEmpty()) {
            $this->command->warn('No users found. Run UserSeeder first.');
            return;
        }

        $posts = [
            [
                'user_id' => $users[0]->id,
                'body' => 'Just completed an amazing training session! #cricket #training',
                'visibility' => 'public',
            ],
            [
                'user_id' => $users[1]->id,
                'body' => 'Excited to announce my participation in the upcoming U-16 State Cup!',
                'visibility' => 'public',
            ],
            [
                'user_id' => $users[2]->id,
                'body' => 'Looking for teammates for the football tournament. DM if interested!',
                'visibility' => 'public',
            ],
        ];

        foreach ($posts as $post) {
            Post::updateOrCreate(
                [
                    'user_id' => $post['user_id'],
                    'body' => $post['body'],
                ],
                $post
            );
        }

        $this->command->info('Posts seeded: ' . count($posts));
    }
}
