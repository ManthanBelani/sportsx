<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Post extends Model
{
    protected $fillable = ['user_id', 'body', 'image_url', 'video_url', 'visibility'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function likes(): HasMany
    {
        return $this->hasMany(PostLike::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(PostComment::class)->whereNull('parent_id')->latest();
    }

    public function likedBy(User $user): bool
    {
        return $this->likes()->where('user_id', $user->id)->exists();
    }
}
