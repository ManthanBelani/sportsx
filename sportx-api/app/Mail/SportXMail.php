<?php

namespace App\Mail;

use App\Services\MailProviderService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Base class for every transactional SportX email.
 *
 * Guarantees two things the hand-rolled mailables in this app were missing:
 *
 *  1. **Delivery goes through the resolved provider.** `mail.default` is set to
 *     MailProviderService::activeMailer() during boot (AppServiceProvider), and
 *     because both the synchronous and the queued send paths resolve the default
 *     driver at the moment they run, an admin flipping SMTP <-> Gmail in the
 *     panel takes effect immediately — no config cache rebuild required.
 *  2. **Sending is queued and retryable.** Mailables implement ShouldQueue, so a
 *     slow SMTP handshake can never add latency to an API request. Transient
 *     provider errors are retried with backoff; terminal failures are logged.
 *
 * Subclasses only implement envelope() and content().
 *
 * @see \App\Services\MailProviderService
 * @see \App\Http\Controllers\Admin\EmailSettingsController
 */
abstract class SportXMail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    /**
     * Number of queue attempts before the message is treated as bounced.
     */
    public int $tries = 3;

    /**
     * Seconds to wait between attempts: 10s, 30s, 90s.
     */
    public array $backoff = [10, 30, 90];

    /**
     * Seconds the job may occupy a queue worker before timing out.
     */
    public int $timeout = 60;

    public function __construct()
    {
        $this->onQueue('mail');
    }

    /**
     * Terminal failure hook: the message exhausted its retries.
     */
    public function failed(\Throwable $exception): void
    {
        Log::error('SportX mail failed permanently', [
            'mailable' => static::class,
            'provider' => app(MailProviderService::class)->activeProvider(),
            'recipients' => $this->recipients(),
            'error' => $exception->getMessage(),
        ]);
    }

    /**
     * Helper for building deep links into the Flutter app / marketing site.
     *
     * @param  array<string, mixed>  $query
     */
    protected function deepLink(string $path, array $query = []): string
    {
        $base = (string) config('app.frontend_url', config('app.url'));

        $url = rtrim($base, '/').'/'.ltrim($path, '/');

        return $query === [] ? $url : $url.'?'.http_build_query($query);
    }

    /**
     * @return array<int, string>
     */
    protected function recipients(): array
    {
        $to = $this->to ?? [];

        return array_values(array_filter(array_map(
            fn ($recipient) => is_array($recipient) ? ($recipient['address'] ?? null) : $recipient,
            $to
        )));
    }
}