<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PostComment extends Model
{
    protected $fillable = ['post_id', 'user_id', 'body', 'parent_id'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function replies()
    {
        return $this->hasMany(PostComment::class, 'parent_id')->latest();
    }
}
