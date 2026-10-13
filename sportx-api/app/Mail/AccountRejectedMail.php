<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

/**
 * Sent when an admin declines a registration held for manual review, or
 * suspends an existing account. `$reason` is optional and shown verbatim.
 */
class AccountRejectedMail extends SportXMail
{
    public function __construct(
        public User $user,
        public ?string $reason = null,
        public bool $suspended = false,
    ) {
        parent::__construct();
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: $this->suspended
                ? 'Your SportX account has been suspended'
                : 'Update on your SportX registration',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.account-rejected',
            with: [
                'name' => $this->user->name,
                'role' => ucfirst(str_replace('_', ' ', $this->user->role)),
                'reason' => $this->reason,
                'suspended' => $this->suspended,
                'supportUrl' => $this->deepLink('/settings/help'),
                'appUrl' => $this->deepLink('/'),
            ],
        );
    }

    public function attachments(): array
    {
        return [];
    }
}