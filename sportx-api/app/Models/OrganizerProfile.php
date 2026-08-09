<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OrganizerProfile extends Model
{
    protected $fillable = ['user_id', 'organization_name', 'org_type', 'verification_status'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function tournaments(): HasMany
    {
        return $this->hasMany(Tournament::class, 'organizer_id');
    }
}
