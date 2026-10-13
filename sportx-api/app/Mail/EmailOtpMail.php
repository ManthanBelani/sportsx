<?php

namespace App\Mail;

use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Support\Facades\RateLimiter;

/**
 * One-time login code delivered over the user's verified email.
 *
 * Rendered through the active SportX provider (SMTP or Gmail API) and always
 * carries the same rate-limit reasoning as the API endpoint that triggered it,
 * so the code cannot be brute-forced from the mailbox side either.
 */
class EmailOtpMail extends SportXMail
{
    /**
     * Attempts allowed per code before the code itself is burned.
     */
    public const MAX_VERIFY_ATTEMPTS = 5;

    public function __construct(
        public string $destination,
        public string $code,
        public string $purpose = 'login',
    ) {
        parent::__construct();
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: $this->subjectLine(),
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.otp',
            with: [
                'code' => $this->code,
                'purpose' => $this->purpose,
                'appUrl' => $this->deepLink('/otp-verify'),
                'expiresInMinutes' => (int) config('sportx.otp.expiry_minutes', 10),
            ],
        );
    }

    public function attachments(): array
    {
        return [];
    }

    protected function subjectLine(): string
    {
        return match ($this->purpose) {
            'verify_email' => 'Confirm your SportX email address',
            'reset_password' => 'Your SportX password reset code',
            default => 'Your SportX verification code',
        };
    }

    /**
     * Throttle duplicate sends of the same code to one per cooldown window.
     *
     * @return bool true when the send should proceed
     */
    public static function throttle(string $destination, string $purpose): bool
    {
        $key = 'sportx.otp.mail.'.$purpose.'.'.sha1(strtolower($destination));
        $cooldown = (int) config('sportx.otp.resend_cooldown_seconds', 60);

        if (RateLimiter::tooManyAttempts($key, 1)) {
            return false;
        }

        RateLimiter::hit($key, $cooldown);

        return true;
    }

    /**
     * Clear the throttle once a code has been consumed so the next login is
     * not silently blocked.
     */
    public static function clearThrottle(string $destination, string $purpose): void
    {
        RateLimiter::clear('sportx.otp.mail.'.$purpose.'.'.sha1(strtolower($destination)));
    }
}