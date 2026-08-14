<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\FCMService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendPushNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60;

    public function __construct(
        public array $deviceTokens,
        public string $title,
        public string $body,
        public array $data = [],
        public ?int $userId = null,
    ) {}

    public function handle(FCMService $fcmService): void
    {
        if (empty($this->deviceTokens)) {
            return;
        }

        $fcmService->sendPushNotification(
            $this->deviceTokens,
            $this->title,
            $this->body,
            $this->data
        );
    }

    public function failed(\Throwable $exception): void
    {
        \Log::error('SendPushNotification job failed', [
            'user_id' => $this->userId,
            'title' => $this->title,
            'error' => $exception->getMessage(),
        ]);
    }
}
