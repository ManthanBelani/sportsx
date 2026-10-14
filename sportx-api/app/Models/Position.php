<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Position extends Model
{
    protected $fillable = ['sport_id', 'name'];

    public function sport(): BelongsTo
    {
        return $this->belongsTo(Sport::class);
    }
}
