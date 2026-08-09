<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AcademyCoach extends Model
{
    protected $fillable = ['academy_id', 'coach_user_id', 'display_name'];

    public function academy(): BelongsTo
    {
        return $this->belongsTo(Academy::class);
    }

    public function coachUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'coach_user_id');
    }
}
