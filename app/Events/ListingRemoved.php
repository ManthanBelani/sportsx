<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ListingRemoved
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public $listing, public ?string $reason = null)
    {
    }
}
