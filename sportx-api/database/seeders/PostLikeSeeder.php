<?php

namespace Database\Seeders;

use App\Models\Post;
use App\Models\PostLike;
use App\Models\User;
use Illuminate\Database\Seeder;

class PostLikeSeeder extends Seeder
{
    public function run(): void
    {
        $posts = Post::limit(3)->get();
        $users = User::limit(3)->get();

        if ($posts->isEmpty()) {
            $this->command->warn('No posts found. Run PostSeeder first.');
            return;
        }

        $likes = [];
        foreach ($posts as $postIndex => $post) {
            foreach ($users->take(2) as $userIndex => $user) {
                if (($postIndex + $userIndex) % 2 === 0) {
                    $likes[] = [
                        'post_id' => $post->id,
                        'user_id' => $user->id,
                    ];
                }
            }
        }

        foreach ($likes as $like) {
            PostLike::updateOrCreate($like);
        }

        $this->command->info('Post likes seeded: ' . count($likes));
    }
}
