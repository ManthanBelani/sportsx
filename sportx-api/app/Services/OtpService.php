<?php

namespace App\Services;

use App\Models\OtpCode;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class OtpService
{
    public function generateAndSend(User $user, string $channel, string $destination): OtpCode
    {
        $length = (int) config('sportx.otp.code_length', 6);
        $min = (int) (10 ** ($length - 1));
        $max = (int) ((10 ** $length) - 1);
        $code = (string) random_int($min, $max);

        $otp = OtpCode::create([
            'user_id' => $user->id,
            'channel' => $channel,
            'destination' => $destination,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes((int) config('sportx.otp.expiry_minutes', 10)),
        ]);

        // Development: log code (AS-03 vendor undecided)
        // Production: integrate SMS/Email vendor here
        Log::info("OTP for {$destination}: {$code}");

        return $otp;
    }

    public function verify(User $user, string $channel, string $destination, string $code): bool
    {
        $otp = OtpCode::where('user_id', $user->id)
            ->where('channel', $channel)
            ->where('destination', $destination)
            ->whereNull('consumed_at')
            ->where('expires_at', '>=', now())
            ->latest()
            ->first();

        if (! $otp) {
            return false;
        }

        if ($otp->attempts >= (int) config('sportx.otp.max_attempts', 5)) {
            return false;
        }

        $otp->increment('attempts');

        if (! Hash::check($code, $otp->code_hash)) {
            return false;
        }

        $otp->update(['consumed_at' => now()]);

        return true;
    }

    public function resend(User $user, string $channel, string $destination): OtpCode
    {
        $cooldown = (int) config('sportx.otp.resend_cooldown_seconds', 60);

        $existing = OtpCode::where('user_id', $user->id)
            ->where('channel', $channel)
            ->where('destination', $destination)
            ->where('created_at', '>=', now()->subSeconds($cooldown))
            ->exists();

        if ($existing) {
            abort(429, 'Please wait before requesting another OTP.');
        }

        return $this->generateAndSend($user, $channel, $destination);
    }
}
