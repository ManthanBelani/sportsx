<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AcademySport extends Model
{
    protected $fillable = ['academy_id', 'sport_id'];

    public function academy(): BelongsTo
    {
        return $this->belongsTo(Academy::class);
    }

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }
}
