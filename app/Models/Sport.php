<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sport extends Model
{
    use Auditable;
    protected $fillable = ['name', 'is_active', 'sort_order'];

    public function sportsVenues(): HasMany
    {
        return $this->hasMany(SportsVenue::class);
    }
}
