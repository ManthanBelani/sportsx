<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TrialRegistrationDocument extends Model
{
    protected $fillable = ['trial_registration_id', 'document_type', 'media_item_id', 'status'];

    public function registration(): BelongsTo
    {
        return $this->belongsTo(TrialRegistration::class, 'trial_registration_id');
    }

    public function mediaItem(): BelongsTo
    {
        return $this->belongsTo(MediaItem::class);
    }
}
