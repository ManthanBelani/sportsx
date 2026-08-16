<?php

namespace Database\Seeders;

use App\Models\Post;
use App\Models\PostComment;
use App\Models\User;
use Illuminate\Database\Seeder;

class PostCommentSeeder extends Seeder
{
    public function run(): void
    {
        $post = Post::first();
        $users = User::limit(3)->get();

        if (!$post) {
            $this->command->warn('No post found. Run PostSeeder first.');
            return;
        }

        $comments = [
            ['post_id' => $post->id, 'user_id' => $users->first()?->id ?? 2, 'content' => 'Great post! Keep it up!'],
            ['post_id' => $post->id, 'user_id' => $users->last()?->id ?? 3, 'content' => 'Congrats on the achievement!'],
        ];

        foreach ($comments as $comment) {
            PostComment::updateOrCreate(
                ['post_id' => $comment['post_id'], 'user_id' => $comment['user_id'], 'content' => $comment['content']],
                $comment
            );
        }

        $this->command->info('Post comments seeded: ' . count($comments));
    }
}
