<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

/**
 * Sent once after a successful registration (email/password or Google) and after
 * an email address is verified. Sets expectations for the approval flow of
 * coach / sponsor / talent_scout accounts.
 */
class WelcomeMail extends SportXMail
{
    public function __construct(public User $user)
    {
        parent::__construct();
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Welcome to SportX India, '.$this->user->name,
        );
    }

    public function content(): Content
    {
        $role = $this->user->role;

        $pendingApproval = in_array($role, ['coach', 'sponsor', 'talent_scout'], true)
            && $this->user->status === 'pending';

        return new Content(
            view: 'emails.welcome',
            with: [
                'name' => $this->user->name,
                'role' => ucfirst(str_replace('_', ' ', $role)),
                'pendingApproval' => $pendingApproval,
                'appUrl' => $this->deepLink('/'),
            ],
        );
    }

    public function attachments(): array
    {
        return [];
    }
}