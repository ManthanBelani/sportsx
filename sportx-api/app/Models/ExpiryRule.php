<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ExpiryRule extends Model
{
    protected $fillable = ['content_type', 'trigger_field', 'days_after', 'is_active'];

    protected $casts = ['is_active' => 'boolean'];
}
