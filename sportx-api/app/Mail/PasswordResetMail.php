<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class PasswordResetMail extends SportXMail
{
    public function __construct(
        public User $user,
        public string $token,
    ) {
        parent::__construct();
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Reset your SportX password',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.password-reset',
            with: [
                'name' => $this->user->name,
                'resetUrl' => $this->deepLink('/reset-password', ['token' => $this->token]),
                'appUrl' => $this->deepLink('/'),
            ],
        );
    }

    public function attachments(): array
    {
        return [];
    }
}