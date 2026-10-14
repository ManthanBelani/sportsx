<?php

namespace App\Jobs;

use App\Models\Notification;
use App\Models\User;
use App\Models\UserDeviceToken;
use App\Services\FCMService;
use App\Services\NotificationService;
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

    /** Separate queue so a slow SMTP handshake never starves push. */
    public $queue = 'push';

    public function __construct(
        public array $deviceTokens,
        public string $title,
        public string $body,
        public array $data = [],
        public ?int $userId = null,
        public ?int $notificationId = null,
    ) {}

    public function handle(FCMService $fcmService): void
    {
        if (empty($this->deviceTokens)) {
            return;
        }

        $result = $fcmService->sendPushNotification(
            $this->deviceTokens,
            $this->title,
            $this->body,
            $this->data
        );

        // Token lifecycle: UNREGISTERED retires immediately; transients
        // 3-strike via recordFailure(); success resets via markSeen().
        foreach ($result['sent'] ?? [] as $token) {
            UserDeviceToken::where('token', $token)->first()?->markSeen();
        }
        foreach ($result['failed'] ?? [] as $token => $code) {
            $row = UserDeviceToken::where('token', $token)->first();
            if (!$row) {
                continue;
            }
            if ($code === 'UNREGISTERED') {
                $row->update(['is_active' => false]);
            } elseif ($row->recordFailure()) {
                $row->update(['is_active' => false]);
            }
        }

        if ($this->notificationId) {
            $status = ($result['success_count'] ?? 0) > 0
                ? ((($result['failure_count'] ?? 0) > 0) ? 'partial' : 'sent')
                : 'failed';
            Notification::where('id', $this->notificationId)->update([
                'push_status' => $status,
                'pushed_at' => now(),
            ]);

            // Push impossible/failed everywhere → email fallback (once:
            // guarded by push_status so retries never double-send).
            if (($result['success_count'] ?? 0) === 0 && $this->userId) {
                $n = Notification::find($this->notificationId);
                $user = User::find($this->userId);
                if ($n && $user) {
                    (new NotificationService)->emailFallback($user, $n);
                }
            }
        }
    }

    public function failed(\Throwable $exception): void
    {
        \Log::error('SendPushNotification job failed', [
            'user_id' => $this->userId,
            'notification_id' => $this->notificationId,
            'title' => $this->title,
            'error' => $exception->getMessage(),
        ]);
    }
}
