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
        $this->credentialsPath = (string) (config('services.fcm.credentials_path') ?? env('FCM_CREDENTIALS_PATH', '') ?? '');
    }

    public function isEnabled(): bool
    {
        return !empty($this->projectId) && !empty($this->credentialsPath) && file_exists($this->credentialsPath);
    }

    public function sendPushNotification(array $deviceTokens, string $title, string $body, array $data = []): array
    {
        if (!$this->isEnabled()) {
            Log::warning('FCM is not enabled or not configured');
            return ['success' => false, 'message' => 'FCM not configured'];
        }

        if (empty($deviceTokens)) {
            return ['success' => false, 'message' => 'No device tokens provided'];
        }

        $message = [
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => $data,
            'tokens' => $deviceTokens,
        ];

        try {
            $response = Http::withToken($this->getAccessToken())
                ->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:sendMulticast", $message);

            if ($response->successful()) {
                $result = $response->json();
                $successCount = $result['responses'][0]['successCount'] ?? count($deviceTokens);
                $failureCount = $result['responses'][0]['failureCount'] ?? 0;

                return [
                    'success' => true,
                    'success_count' => $successCount,
                    'failure_count' => $failureCount,
                ];
            }

            Log::error('FCM push notification failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            return [
                'success' => false,
                'message' => 'FCM request failed: ' . $response->status(),
            ];
        } catch (\Exception $e) {
            Log::error('FCM push notification exception', [
                'error' => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'message' => $e->getMessage(),
            ];
        }
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

    private function getAccessToken(): string
    {
        $cacheKey = 'fcm_access_token';

        $token = Cache::get($cacheKey);
        if ($token) {
            return $token;
        }

        $scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

        $credentials = new ServiceAccountCredentials($scopes, $this->credentialsPath);
        $token = $credentials->fetchAccessTokenWithAssertion();

        if (isset($token['access_token'])) {
            $expiresIn = $token['expires_in'] ?? 3600;
            Cache::put($cacheKey, $token['access_token'], $expiresIn - 60);
            return $token['access_token'];
        }

        throw new \RuntimeException('Failed to fetch FCM access token');
    }
}
