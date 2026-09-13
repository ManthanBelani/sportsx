<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AgeGroup extends Model
{
    use Auditable;
    protected $fillable = ['name', 'min_age', 'max_age', 'is_active'];

    public $timestamps = true;
}
