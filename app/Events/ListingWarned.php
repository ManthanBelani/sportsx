<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ListingWarned
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public $listing, public ?string $message = null)
    {
    }
}
