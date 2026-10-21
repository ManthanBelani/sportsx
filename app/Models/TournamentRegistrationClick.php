<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * One recorded click on a tournament's "Register" button when the tournament
 * uses an external registration URL.
 *
 * These are NOT registrations — the external site owns the actual sign-up, so
 * we only know that somebody expressed intent by tapping the button.
 */
class TournamentRegistrationClick extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'tournament_id', 'user_id', 'click_token',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    public function tournament(): BelongsTo
    {
        return $this->belongsTo(Tournament::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
