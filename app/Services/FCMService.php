<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Google\Auth\Middleware\AuthTokenMiddleware;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class FCMService
{
    private string $projectId;
    private string $credentialsPath;

    public function __construct()
    {
        $this->projectId = (string) (config('services.fcm.project_id') ?? env('FCM_PROJECT_ID', '') ?? '');
        $path = (string) (config('services.fcm.credentials_path') ?? env('FCM_CREDENTIALS_PATH', '') ?? '');
        if ($path && !file_exists($path)) {
            if (file_exists(base_path($path))) {
                $path = base_path($path);
            } elseif (file_exists(storage_path($path))) {
                $path = storage_path($path);
            } elseif (file_exists(storage_path('app/' . $path))) {
                $path = storage_path('app/' . $path);
            }
        }
        if (empty($path) || !file_exists($path)) {
            $candidates = glob(storage_path('app/*firebase*.json'));
            if (!empty($candidates)) {
                $path = $candidates[0];
            }
        }
        $this->credentialsPath = $path;
    }

    public function isEnabled(): bool
    {
        return !empty($this->projectId) && !empty($this->credentialsPath) && file_exists($this->credentialsPath);
    }

    /**
     * Android notification channels per notification type.
     * Android 8+ silently drops notifications without a matching channel.
     */
    public const ANDROID_CHANNELS = [
        'default' => 'sportx_default',
        'enquiry' => 'sportx_enquiries',
        'reminder' => 'sportx_reminders',
        'update' => 'sportx_updates',
        'announcement' => 'sportx_announcements',
    ];

    public static function channelFor(string $type, ?string $category = null): string
    {
        $key = strtolower($category ?: $type);
        if (str_contains($key, 'enquir') || str_contains($key, 'message') || str_contains($key, 'chat')) {
            return self::ANDROID_CHANNELS['enquiry'];
        }
        if (str_contains($key, 'remind')) {
            return self::ANDROID_CHANNELS['reminder'];
        }
        if (str_contains($key, 'broadcast') || str_contains($key, 'announce')) {
            return self::ANDROID_CHANNELS['announcement'];
        }
        if (str_contains($key, 'status') || str_contains($key, 'regist') || str_contains($key, 'verif')
            || str_contains($key, 'account') || str_contains($key, 'connection') || str_contains($key, 'follow')) {
            return self::ANDROID_CHANNELS['update'];
        }

        return self::ANDROID_CHANNELS['default'];
    }

    /**
     * Send one FCM HTTP v1 `messages:send` per token (there is no
     * multicast endpoint in v1). Returns per-token results so callers can
     * retire UNREGISTERED tokens immediately and 3-strike transients.
     */
    public function sendPushNotification(array $deviceTokens, string $title, string $body, array $data = []): array
    {
        if (!$this->isEnabled()) {
            Log::warning('FCM is not enabled or not configured');
            return ['success' => false, 'message' => 'FCM not configured', 'sent' => [], 'failed' => []];
        }

        $tokens = array_values(array_unique(array_filter($deviceTokens)));
        if (empty($tokens)) {
            return ['success' => false, 'message' => 'No device tokens provided', 'sent' => [], 'failed' => []];
        }

        $type = (string) ($data['type'] ?? 'general');
        $category = (string) ($data['category'] ?? $type);
        $channelId = self::channelFor($type, $category);
        $sent = [];
        $failed = [];

        try {
            $accessToken = $this->getAccessToken();
        } catch (\Exception $e) {
            Log::error('FCM access token exception', ['error' => $e->getMessage()]);

            return [
                'success' => false,
                'message' => $e->getMessage(),
                'sent' => [],
                'failed' => array_fill_keys($tokens, 'auth_error: ' . $e->getMessage()),
            ];
        }

        foreach ($tokens as $token) {
            $message = [
                'message' => [
                    'token' => $token,
                    'notification' => ['title' => $title, 'body' => $body],
                    'data' => array_map('strval', $data),
                    'android' => ['notification' => ['channel_id' => $channelId]],
                    'apns' => [
                        'headers' => ['apns-priority' => '10', 'apns-push-type' => 'alert'],
                        'payload' => ['aps' => ['sound' => 'default', 'content-available' => 1]],
                    ],
                ],
            ];

            try {
                $ca = $this->getCaBundlePath();
                $http = Http::withToken($accessToken);
                if ($ca === false) {
                    $http = $http->withoutVerifying();
                } elseif (is_string($ca)) {
                    $http = $http->withOptions(['verify' => $ca]);
                }

                $response = $http->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send", $message);

                if ($response->successful()) {
                    $sent[] = $token;
                } else {
                    $code = $this->errorCode($response);
                    $failed[$token] = $code;
                    Log::warning('FCM per-token send failed', ['status' => $response->status(), 'code' => $code]);
                }
            } catch (\Exception $e) {
                $failed[$token] = 'transport_error: ' . $e->getMessage();
                Log::error('FCM per-token exception', ['error' => $e->getMessage()]);
            }
        }

        return [
            'success' => count($sent) > 0,
            'success_count' => count($sent),
            'failure_count' => count($failed),
            'sent' => $sent,
            'failed' => $failed,
        ];
    }

    /** Map an FCM error response to a stable per-token code. */
    protected function errorCode($response): string
    {
        try {
            $code = $response->json('error.details.0.errorCode')
                ?? $response->json('error.status')
                ?? '';
        } catch (\Throwable) {
            $code = '';
        }
        $code = strtoupper((string) $code);
        if (str_contains($code, 'UNREGISTERED') || str_contains($code, 'NOT_FOUND') || str_contains($code, 'INVALID_ARGUMENT')) {
            return 'UNREGISTERED';
        }
        if (str_contains($code, 'QUOTA') || str_contains($code, 'RESOURCE_EXHAUSTED')) {
            return 'QUOTA_EXHAUSTED';
        }
        if (str_contains($code, 'SENDER_ID_MISMATCH')) {
            return 'SENDER_ID_MISMATCH';
        }
        if (str_contains($code, 'PERMISSION_DENIED')) {
            $msg = (string) ($response->json('error.message') ?? '');
            return 'PERMISSION_DENIED: ' . ($msg ?: 'Enable Firebase Cloud Messaging API in Google Cloud Console');
        }

        return $code !== '' ? $code : 'SEND_FAILED';
    }

    public function sendToTopic(string $topic, string $title, string $body, array $data = []): array
    {
        if (!$this->isEnabled()) {
            Log::warning('FCM is not enabled or not configured');
            return ['success' => false, 'message' => 'FCM not configured'];
        }

        try {
            $message = [
                'message' => [
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => $data,
                    'topic' => $topic,
                ],
            ];

            $response = Http::withToken($this->getAccessToken())
                ->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send", $message);

            if ($response->successful()) {
                return ['success' => true];
            }

            return [
                'success' => false,
                'message' => 'FCM request failed: ' . $response->status(),
            ];
        } catch (\Exception $e) {
            Log::error('FCM topic notification exception', [
                'error' => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'message' => $e->getMessage(),
            ];
        }
    }

    protected function getCaBundlePath(): string|bool
    {
        if (file_exists(storage_path('cacert.pem'))) {
            return storage_path('cacert.pem');
        }
        if (file_exists('D:/php84/cacert.pem')) {
            return 'D:/php84/cacert.pem';
        }
        return app()->isLocal() ? false : true;
    }

    private function getAccessToken(): string
    {
        $cacheKey = 'fcm_access_token';

        $token = Cache::get($cacheKey);
        if ($token) {
            return $token;
        }

        $scopes = [
            'https://www.googleapis.com/auth/cloud-platform',
            'https://www.googleapis.com/auth/firebase.messaging',
        ];

        $credentials = new ServiceAccountCredentials($scopes, $this->credentialsPath);

        // Build Guzzle client configured with CA bundle or local development SSL fallback
        $ca = $this->getCaBundlePath();
        $guzzleOptions = [];
        if ($ca === false) {
            $guzzleOptions['verify'] = false;
        } elseif (is_string($ca)) {
            $guzzleOptions['verify'] = $ca;
        }

        $client = new \GuzzleHttp\Client($guzzleOptions);
        $httpHandler = \Google\Auth\HttpHandler\HttpHandlerFactory::build($client);

        $token = $credentials->fetchAuthToken($httpHandler);

        if (isset($token['access_token'])) {
            $expiresIn = $token['expires_in'] ?? 3600;
            Cache::put($cacheKey, $token['access_token'], $expiresIn - 60);
            return $token['access_token'];
        }

        $errorMsg = $token['error_description'] ?? $token['error'] ?? 'Unknown error';
        throw new \RuntimeException('Failed to fetch FCM access token: ' . $errorMsg);
    }
}
