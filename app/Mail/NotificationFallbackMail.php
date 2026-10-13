<?php

namespace App\Mail;

use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

/**
 * Fallback delivery for users who cannot receive FCM pushes (no device token
 * registered, Play Services unavailable, notifications disabled). Pushed by
 * NotificationService only when a push could not be delivered.
 */
class NotificationFallbackMail extends SportXMail
{
    public function __construct(
        public string $recipient,
        public string $title,
        public string $body,
        public ?string $actionUrl = null,
    ) {
        parent::__construct();
    }

    public function envelope(): Envelope
    {
        return new Envelope(subject: '[SportX] '.$this->title);
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.notification-fallback',
            with: [
                'title' => $this->title,
                'body' => $this->body,
                'actionUrl' => $this->actionUrl
                    ? $this->deepLink('/open', ['url' => $this->actionUrl])
                    : $this->deepLink('/notifications'),
            ],
        );
    }

    public function attachments(): array
    {
        return [];
    }
}