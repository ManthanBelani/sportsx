<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TournamentResult extends Model
{
    protected $fillable = ['tournament_id', 'category_id', 'place', 'winner_name', 'bracket_media_id', 'published_at'];

    protected $casts = ['published_at' => 'datetime'];

    public function tournament(): BelongsTo
    {
        return $this->belongsTo(Tournament::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(TournamentCategory::class, 'category_id');
    }
}
