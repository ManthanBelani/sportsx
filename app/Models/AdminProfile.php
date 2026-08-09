<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AdminProfile extends Model
{
    protected $fillable = ['user_id', 'two_factor_secret', 'is_super_admin'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
