<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

/**
 * Sent when an admin approves a coach / academy / sponsor / talent scout
 * registration that was held back for manual review.
 */
class AccountApprovedMail extends SportXMail
{
    public function __construct(public User $user)
    {
        parent::__construct();
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Your SportX '.ucfirst(str_replace('_', ' ', $this->user->role)).' account is approved',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.account-approved',
            with: [
                'name' => $this->user->name,
                'role' => ucfirst(str_replace('_', ' ', $this->user->role)),
                'appUrl' => $this->deepLink('/'),
            ],
        );
    }

    public function attachments(): array
    {
        return [];
    }
}