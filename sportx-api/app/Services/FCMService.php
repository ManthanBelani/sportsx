<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FCMService
{
    private string $serverKey;
    private string $senderId;
    private string $projectId;

    public function __construct()
    {
        $this->serverKey = config('services.fcm.server_key', env('FCM_SERVER_KEY', ''));
        $this->senderId = config('services.fcm.sender_id', env('FCM_SENDER_ID', ''));
        $this->projectId = config('services.fcm.project_id', env('FCM_PROJECT_ID', ''));
    }

    public function isEnabled(): bool
    {
        return !empty($this->serverKey) && !empty($this->projectId);
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
        return $this->serverKey;
    }
}
