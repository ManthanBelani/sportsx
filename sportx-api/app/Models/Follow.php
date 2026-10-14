<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Follow extends Model
{
    protected $fillable = ['follower_user_id', 'followee_user_id'];

    public function follower(): BelongsTo
    {
        return $this->belongsTo(User::class, 'follower_user_id');
    }

    public function followee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'followee_user_id');
    }
}
