<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\Relations\HasMany;

class City extends Model
{
    use Auditable;
    protected $fillable = ['name', 'state', 'is_active'];

    public $timestamps = true;
}
