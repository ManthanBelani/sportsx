<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RegistrationActivityLog extends Model
{
    protected $fillable = [
        'registration_type', 'registration_id', 'action',
        'actor_type', 'actor_id', 'metadata',
        'ip_address', 'user_agent',
    ];

    protected function casts(): array
    {
        return [
            'metadata' => 'array',
        ];
    }
}
