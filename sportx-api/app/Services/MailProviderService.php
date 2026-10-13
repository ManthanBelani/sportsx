<?php

namespace App\Services;

use App\Mail\Transport\GmailApiTransport;
use Illuminate\Contracts\Mail\Factory as MailFactory;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

/**
 * Runtime registry for the two transactional email providers SportX supports.
 *
 * Providers
 * --------
 *  "smtp"   Generic SMTP relay. Works with Gmail/Google Workspace App
 *           Passwords, Zoho, SendGrid, Amazon SES, Mailgun, Brevo, or any
 *           host reachable over SMTP/STARTTLS.
 *  "gmail"  Direct Gmail API (OAuth2) delivery via GmailApiTransport. Bypasses
 *           SMTP quota and is the only option for 2FA-enforced Workspace
 *           accounts, which reject app-password logins from unfamiliar IPs.
 *
 * Resolution order for the active provider
 * ----------------------------------------
 *  1. Admin override in storage/app/platform_settings.json (runtime switch,
 *     no deploy required).
 *  2. config('sportx.mail.provider')  ->  MAIL_PROVIDER env.
 *  3. "smtp".
 *
 * When failover is enabled the resolved provider is wrapped in the
 * `sportx_failover` mailer so a provider outage degrades to the next provider
 * instead of dropping the message. See config/mail.php.
 *
 * @see \App\Mail\SportXMail
 * @see \App\Http\Controllers\Admin\EmailSettingsController
 */
class MailProviderService
{
    public const PROVIDER_SMTP = 'smtp';

    public const PROVIDER_GMAIL = 'gmail';

    public const FAILOVER_MAILER = 'sportx_failover';

    public function __construct(protected MailFactory $mailFactory) {}

    /* ---------------------------------------------------------------------
     | Provider resolution
     | ------------------------------------------------------------------ */

    /**
     * The provider every outbound message is sent through by default.
     */
    public function activeProvider(): string
    {
        $override = $this->overrides()['mail_provider'] ?? null;

        if (is_string($override) && $this->isKnownProvider($override)) {
            return $override;
        }

        $configured = (string) config('sportx.mail.provider', self::PROVIDER_SMTP);

        return $this->isKnownProvider($configured) ? $configured : self::PROVIDER_SMTP;
    }

    /**
     * The Laravel mailer name that should be used as `mail.default`.
     *
     * With failover enabled this is `sportx_failover`; otherwise it is the
     * provider name itself so that a misconfigured provider fails loudly
     * instead of silently succeeding through the log driver.
     */
    public function activeMailer(): string
    {
        // Feature tests drive MAIL_MAILER=array so `Mail::assertSent()` can
        // inspect the payload without any real provider being reachable.
        if (app()->runningUnitTests()) {
            return (string) config('mail.default', 'array');
        }

        if (! config('sportx.mail.failover.enabled', true)) {
            return $this->activeProvider();
        }

        return self::FAILOVER_MAILER;
    }

    /**
     * Providers that actually have usable credentials right now, in the order
     * the failover chain will try them.
     *
     * @return array<int, string>
     */
    public function configuredChain(): array
    {
        $chain = (array) config('sportx.mail.failover.chain', [self::PROVIDER_GMAIL, self::PROVIDER_SMTP]);

        $active = $this->activeProvider();

        // The explicitly selected provider always gets first refusal.
        usort($chain, fn ($a, $b) => ($a === $active ? -1 : 0) <=> ($b === $active ? -1 : 0));

        return array_values(array_filter(
            $chain,
            fn (string $provider) => $this->isKnownProvider($provider) && $this->isConfigured($provider)
        ));
    }

    public function isKnownProvider(?string $provider): bool
    {
        return in_array($provider, [self::PROVIDER_SMTP, self::PROVIDER_GMAIL, 'log', 'array'], true);
    }

    /* ---------------------------------------------------------------------
     | Configuration introspection
     | ------------------------------------------------------------------ */

    public function isConfigured(string $provider): bool
    {
        return match ($provider) {
            self::PROVIDER_SMTP => $this->isSmtpConfigured(),
            self::PROVIDER_GMAIL => $this->isGmailConfigured(),
            default => $provider === 'log' || $provider === 'array',
        };
    }

    public function isSmtpConfigured(): bool
    {
        $mailer = config('mail.mailers.smtp', []);

        return ! empty($mailer['host']) && ! empty($mailer['port']);
    }

    public function isGmailConfigured(): bool
    {
        $mailer = config('mail.mailers.gmail', []);

        if (($mailer['auth_mode'] ?? 'user') === 'service_account') {
            return ! empty($mailer['service_account_email']) && ! empty($mailer['private_key']);
        }

        return ! empty($mailer['client_id'])
            && ! empty($mailer['client_secret'])
            && ! empty($mailer['refresh_token']);
    }

    /**
     * Summary payload for the admin "Email settings" screen.
     *
     * @return array<string, mixed>
     */
    public function status(): array
    {
        $active = $this->activeProvider();

        $providers = [];

        foreach ([self::PROVIDER_SMTP, self::PROVIDER_GMAIL] as $provider) {
            $providers[$provider] = [
                'configured' => $this->isConfigured($provider),
                'active' => $provider === $active,
                'details' => $this->describe($provider),
            ];
        }

        return [
            'active_provider' => $active,
            'active_mailer' => $this->activeMailer(),
            'failover_enabled' => (bool) config('sportx.mail.failover.enabled', true),
            'configured_chain' => $this->configuredChain(),
            'from' => config('mail.from'),
            'providers' => $providers,
        ];
    }

    /**
     * Non-secret description of how a provider is wired up, for the admin UI.
     *
     * @return array<string, mixed>
     */
    public function describe(string $provider): array
    {
        if ($provider === self::PROVIDER_SMTP) {
            $mailer = config('mail.mailers.smtp', []);

            return [
                'label' => 'SMTP relay',
                'hint' => 'Works with Gmail App Password, Zoho, SendGrid, SES, Mailgun, Brevo or any SMTP host.',
                'host' => $mailer['host'] ?? null,
                'port' => $mailer['port'] ?? null,
                'encryption' => $mailer['scheme'] ?? (($mailer['port'] ?? null) === 465 ? 'smtps' : 'smtp'),
                'username' => $mailer['username'] ?? null,
            ];
        }

        if ($provider === self::PROVIDER_GMAIL) {
            $mailer = config('mail.mailers.gmail', []);

            return [
                'label' => 'Gmail API (OAuth2)',
                'hint' => 'Recommended for Google Workspace accounts with 2FA enforced.',
                'auth_mode' => $mailer['auth_mode'] ?? 'user',
                'client_id' => $mailer['client_id'] ?? null,
                'impersonate' => $mailer['impersonate'] ?? null,
            ];
        }

        return ['label' => ucfirst($provider), 'hint' => null];
    }

    /* ---------------------------------------------------------------------
     | Runtime overrides
     | ------------------------------------------------------------------ */

    /**
     * Persist a provider switch to platform settings so ops can flip the
     * transport without a redeploy. Returns the resulting provider.
     */
    public function setActiveProvider(string $provider): string
    {
        abort_unless($this->isKnownProvider($provider), 422, "Unsupported mail provider [{$provider}].");

        $settings = $this->overrides();
        $settings['mail_provider'] = $provider;

        $path = $this->settingsPath();

        if (! is_dir(dirname($path))) {
            mkdir(dirname($path), 0755, true);
        }

        file_put_contents($path, json_encode($settings, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

        // Mailers are memoised per request, so drop the resolved instances.
        Mail::purge();

        return $provider;
    }

    /**
     * @return array<string, mixed>
     */
    public function overrides(): array
    {
        $path = $this->settingsPath();

        if (! is_file($path)) {
            return [];
        }

        $decoded = json_decode((string) @file_get_contents($path), true);

        return is_array($decoded) ? $decoded : [];
    }

    protected function settingsPath(): string
    {
        return storage_path('app/platform_settings.json');
    }

    /* ---------------------------------------------------------------------
     | Diagnostics
     | ------------------------------------------------------------------ */

    /**
     * Deliver a real message to verify the provider end to end.
     *
     * @return array{ok: bool, detail: string}
     */
    public function testConnection(?string $provider = null, ?string $recipient = null): array
    {
        $provider = $provider !== null ? $provider : $this->activeProvider();

        if (! $this->isKnownProvider($provider)) {
            return ['ok' => false, 'detail' => "Unknown provider [{$provider}]."];
        }

        if (! $this->isConfigured($provider)) {
            return ['ok' => false, 'detail' => $provider.' is not configured. Fill in its credentials first.'];
        }

        $recipient = $recipient
            ?: config('sportx.mail.test_recipient')
            ?: config('mail.from.address');

        if (! $recipient) {
            return ['ok' => false, 'detail' => 'No test recipient available. Set MAIL_TEST_RECIPIENT.'];
        }

        try {
            // Probe first for Gmail so a broken OAuth setup reports the real
            // reason instead of an opaque send failure.
            if ($provider === self::PROVIDER_GMAIL) {
                $probe = $this->probeGmail();

                if (! $probe['ok']) {
                    return $probe;
                }
            }

            Mail::mailer($this->testMailerFor($provider))
                ->raw(
                    'SportX email test via '.$provider.' — delivered at '.now()->toDateTimeString().'.',
                    function ($message) use ($recipient) {
                        $message->to($recipient)
                            ->subject('[SportX] Email provider test ('.$provider.')')
                            ->html('<p>Your <strong>'.$provider.'</strong> email provider is working.</p>');
                    }
                );

            return ['ok' => true, 'detail' => "Test message delivered to {$recipient} via {$provider}."];
        } catch (Throwable $e) {
            Log::error('MailProviderService: connection test failed', [
                'provider' => $provider,
                'error' => $e->getMessage(),
            ]);

            return ['ok' => false, 'detail' => $e->getMessage()];
        }
    }

    /**
     * Reachability check that does not send mail — used by health checks so a
     * monitoring system can alert before users notice.
     *
     * @return array<string, mixed>
     */
    public function diagnostics(): array
    {
        $status = $this->status();

        $gmail = $this->isGmailConfigured()
            ? $this->probeGmail()
            : ['ok' => false, 'detail' => 'Not configured.'];

        return array_merge($status, [
            'gmail_probe' => $gmail,
            'smtp_reachable' => $this->isSmtpConfigured() ? $this->probeSmtpSocket() : null,
        ]);
    }

    /**
     * @return array{ok: bool, detail: string}
     */
    protected function probeGmail(): array
    {
        try {
            return app(GmailApiTransport::class)->probe();
        } catch (Throwable $e) {
            return ['ok' => false, 'detail' => $e->getMessage()];
        }
    }

    /**
     * @return array{ok: bool, detail: string}
     */
    protected function probeSmtpSocket(): array
    {
        $host = (string) config('mail.mailers.smtp.host');
        $port = (int) config('mail.mailers.smtp.port', 587);

        $errno = 0;
        $errstr = '';
        $socket = @fsockopen($host, $port, $errno, $errstr, 5);

        if ($socket === false) {
            return ['ok' => false, 'detail' => "Cannot reach {$host}:{$port} — {$errstr} ({$errno})."];
        }

        $banner = trim((string) stream_get_contents($socket, 128));
        fclose($socket);

        return ['ok' => true, 'detail' => "Connected to {$host}:{$port} — {$banner}"];
    }

    /**
     * Test messages must exercise the provider itself, not the failover chain,
     * otherwise a broken primary silently reports success through the fallback.
     */
    protected function testMailerFor(string $provider): string
    {
        return $this->isConfigured($provider) ? $provider : 'log';
    }

    /**
     * Convenience wrapper used by jobs that need the mail factory resolved
     * through a specific provider.
     */
    public function mailer(string $provider): \Illuminate\Mail\Mailer
    {
        return $this->mailFactory->mailer($provider);
    }

    /**
     * Registered in AppServiceProvider so `app(GmailApiTransport::class)` and
     * `Mail::extend()` share one configured instance.
     */
    public function gmailTransport(): GmailApiTransport
    {
        return new GmailApiTransport((array) config('mail.mailers.gmail', []));
    }

    /**
     * Clears cached OAuth tokens — part of the admin "rotate credentials" flow.
     */
    public function clearTokenCache(): void
    {
        Cache::forget((string) config('mail.mailers.gmail.token_cache_key', 'sportx.gmail.access_token'));
    }
}