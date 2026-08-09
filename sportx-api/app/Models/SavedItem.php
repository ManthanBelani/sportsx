<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class SavedItem extends Model
{
    protected $fillable = ['user_id', 'item_type', 'item_id'];

    public function item(): MorphTo
    {
        return $this->morphTo();
    }
}
