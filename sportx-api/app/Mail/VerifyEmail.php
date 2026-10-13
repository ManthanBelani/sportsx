<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class VerifyEmail extends SportXMail
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
            subject: 'Verify your SportX account',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.verify-email',
            with: [
                'name' => $this->user->name,
                'verifyUrl' => $this->deepLink('/verify-email', ['token' => $this->token]),
                'appUrl' => $this->deepLink('/'),
            ],
        );
    }

    public function attachments(): array
    {
        return [];
    }
}