<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AgeGroup extends Model
{
    protected $fillable = ['name', 'min_age', 'max_age', 'is_active'];

    public $timestamps = true;
}
