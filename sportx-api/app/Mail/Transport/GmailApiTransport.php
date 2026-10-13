<?php

namespace App\Mail\Transport;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Google\Auth\Credentials\UserRefreshCredentials;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Symfony\Component\Mailer\Exception\TransportException;
use Symfony\Component\Mailer\SentMessage;
use Symfony\Component\Mailer\Transport\AbstractTransport;
use Symfony\Component\Mime\Email;
use Symfony\Component\Mime\RawMessage;

/**
 * Delivers mail through the Gmail REST API (v1) instead of SMTP.
 *
 * Why this exists alongside the plain `smtp` mailer:
 *  - Google Workspace accounts that enforce 2FA refuse "less secure app"
 *    passwords, so a normal SMTP + password login is impossible. The Gmail API
 *    works with an OAuth2 refresh token (user mode) or a service account with
 *    domain-wide delegation (service_account mode).
 *  - It removes the 500 msg/day consumer Gmail SMTP cap and the low
 *    per-connection rate limits, which matters for admin broadcasts.
 *
 * Registered as the `gmail-api` transport through Mail::extend().
 */
class GmailApiTransport extends AbstractTransport
{
    public const SEND_ENDPOINT = 'https://gmail.googleapis.com/gmail/v1/users/me/messages/send';

    public const PROFILE_ENDPOINT = 'https://gmail.googleapis.com/gmail/v1/users/me/profile';

    public const SCOPES = ['https://mail.google.com/'];

    /**
     * @param  array<string, mixed>  $config
     */
    public function __construct(protected array $config = [])
    {
        parent::__construct();
    }

    /**
     * {@inheritdoc}
     */
    protected function doSend(SentMessage $message): void
    {
        /** @var RawMessage $raw */
        $raw = $message->getOriginalMessage();

        $response = $this->client()->post(self::SEND_ENDPOINT, [
            'raw' => base64_encode($raw->toString()),
        ]);

        if ($response->failed()) {
            $detail = $response->json('error.message') ?? $response->body();

            Log::error('GmailApiTransport: send failed', [
                'status' => $response->status(),
                'detail' => $detail,
            ]);

            throw new TransportException(
                'Gmail API rejected the message (HTTP '.$response->status().'): '.$detail,
                $response->status()
            );
        }

        $messageId = $response->json('id');

        if (is_string($messageId) && $messageId !== '') {
            $message->setMessageId($messageId);
            $raw->getHeaders()->addTextHeader('X-Gmail-Message-Id', $messageId);
        }

        $this->getLogger()->info('GmailApiTransport: message accepted', [
            'message_id' => $messageId,
            'thread' => $response->json('threadId'),
        ]);
    }

    /**
     * Cheap connectivity + auth probe used by the admin "Test connection" action.
     *
     * @return array{ok: bool, detail: string}
     */
    public function probe(): array
    {
        try {
            $token = $this->accessToken();

            if ($token === null) {
                return ['ok' => false, 'detail' => 'Gmail OAuth2 credentials are incomplete.'];
            }

            $profile = Http::withToken($token)->timeout($this->timeout())->get(self::PROFILE_ENDPOINT);

            if ($profile->successful()) {
                return [
                    'ok' => true,
                    'detail' => 'Authenticated as '.$profile->json('emailAddress', 'unknown').'.',
                ];
            }

            return [
                'ok' => false,
                'detail' => 'Gmail profile lookup failed (HTTP '.$profile->status().').',
            ];
        } catch (\Throwable $e) {
            return ['ok' => false, 'detail' => $e->getMessage()];
        }
    }

    /**
     * Resolve — and cache — a Gmail OAuth2 access token.
     *
     * Both auth modes are supported:
     *  - "user": a refresh token produced by an OAuth consent flow.
     *  - "service_account": a service account key plus an impersonated
     *    Workspace user (domain-wide delegation).
     */
    public function accessToken(): ?string
    {
        $cacheKey = (string) ($this->config['token_cache_key'] ?? 'sportx.gmail.access_token');

        $cached = Cache::get($cacheKey);

        if (is_string($cached) && $cached !== '') {
            return $cached;
        }

        $mode = (string) ($this->config['auth_mode'] ?? 'user');

        $credentials = $mode === 'service_account'
            ? $this->serviceAccountCredentials()
            : $this->userRefreshCredentials();

        $token = $credentials->fetchAuthToken();

        $accessToken = $token['access_token'] ?? null;

        if (! is_string($accessToken) || $accessToken === '') {
            Log::error('GmailApiTransport: no access token returned', ['auth_mode' => $mode]);

            return null;
        }

        Cache::put(
            $cacheKey,
            $accessToken,
            max(60, (int) ($token['expires_in'] ?? 3600) - 60)
        );

        return $accessToken;
    }

    protected function userRefreshCredentials(): UserRefreshCredentials
    {
        $clientId = $this->config['client_id'] ?? null;
        $clientSecret = $this->config['client_secret'] ?? null;
        $refreshToken = $this->config['refresh_token'] ?? null;

        if (! $clientId || ! $clientSecret || ! $refreshToken) {
            throw new TransportException(
                'GMAIL_AUTH_MODE=user requires GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET and GMAIL_REFRESH_TOKEN.'
            );
        }

        return new UserRefreshCredentials((string) $clientId, (string) $clientSecret, (string) $refreshToken);
    }

    protected function serviceAccountCredentials(): ServiceAccountCredentials
    {
        $email = $this->config['service_account_email'] ?? null;
        $privateKey = $this->config['private_key'] ?? null;

        if (! $email || ! $privateKey) {
            throw new TransportException(
                'GMAIL_AUTH_MODE=service_account requires GMAIL_SERVICE_ACCOUNT_EMAIL and GMAIL_PRIVATE_KEY.'
            );
        }

        $key = [
            'type' => 'service_account',
            'client_email' => $email,
            'private_key' => $this->normalisePrivateKey((string) $privateKey),
            'token_uri' => 'https://oauth2.googleapis.com/token',
        ];

        if (! empty($this->config['private_key_id'])) {
            $key['private_key_id'] = $this->config['private_key_id'];
        }

        if (! empty($this->config['project_id'])) {
            $key['project_id'] = $this->config['project_id'];
        }

        return new ServiceAccountCredentials(
            self::SCOPES,
            $key,
            $this->config['impersonate'] ?? null
        );
    }

    /**
     * Env values frequently arrive with literal "\n" sequences when injected
     * through CI/CD secret stores.
     */
    protected function normalisePrivateKey(string $key): string
    {
        $key = str_replace('\\n', "\n", trim($key));

        return str_contains($key, 'BEGIN PRIVATE KEY')
            ? $key
            : "-----BEGIN PRIVATE KEY-----\n{$key}\n-----END PRIVATE KEY-----\n";
    }

    protected function client(): \Illuminate\Http\Client\PendingRequest
    {
        $token = $this->accessToken();

        if ($token === null) {
            throw new TransportException('Gmail API is not configured (missing OAuth2 credentials).');
        }

        return Http::withToken($token)
            ->asJson()
            ->timeout($this->timeout())
            ->withHeaders(['X-Goog-Api-Client' => 'sportx-api/1.0']);
    }

    protected function timeout(): int
    {
        return (int) ($this->config['timeout'] ?? 15);
    }

    public function __toString(): string
    {
        return 'gmailapi://gmail.googleapis.com';
    }
}