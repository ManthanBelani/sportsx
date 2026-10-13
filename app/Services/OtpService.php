<?php

namespace App\Services;

use App\Exceptions\OtpDeliveryException;
use App\Mail\EmailOtpMail;
use App\Models\OtpCode;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

/**
 * Issues and verifies one-time codes.
 *
 * Codes are bcrypt-hashed at rest — the plaintext exists only inside the
 * outbound message. Delivery is queued so a slow SMTP handshake can never add
 * latency to the request that triggered it.
 *
 * @see \App\Mail\EmailOtpMail
 * @see \App\Models\OtpCode
 * @see docs/Email-Provider-Architecture.md
 */
class OtpService
{
    /**
     * Issue a new code and queue its delivery.
     *
     * `$user` is nullable on purpose: sign-in and sign-up both need a code
     * *before* an account exists, so verification is keyed on the normalised
     * destination rather than on a user id.
     *
     * Any previously issued code for the same tuple is consumed up front, so
     * only the most recent code ever validates. Without this a user could
     * replay an older code that is still inside its expiry window.
     */
    public function generateAndSend(
        ?User $user,
        string $channel,
        string $destination,
        string $purpose = OtpCode::PURPOSE_LOGIN,
    ): OtpCode {
        $destination = $this->normalise($channel, $destination);
        $code = $this->randomCode();

        // Burn any prior live code for this tuple.
        OtpCode::query()
            ->when($user, fn ($q) => $q->where('user_id', $user->id))
            ->forDestination($channel, $destination)
            ->pending()
            ->update(['consumed_at' => now()]);

        $otp = OtpCode::create([
            'user_id' => $user?->id,
            'channel' => $channel,
            'destination' => $destination,
            'code_hash' => Hash::make($code),
            'purpose' => $purpose,
            'expires_at' => now()->addMinutes((int) config('sportx.otp.expiry_minutes', 10)),
        ]);

        $this->deliver($destination, $code, $purpose);

        // Never log a live code once a real transport is configured.
        Log::info('OTP issued', [
            'channel' => $channel,
            'destination' => $destination,
            'purpose' => $purpose,
            'user_id' => $user?->id,
            'otp_id' => $otp->id,
            'expires_at' => $otp->expires_at->toIso8601String(),
        ]);

        return $otp;
    }

    /**
     * Verify a submitted code.
     *
     * A wrong guess increments `attempts`; once the code is exhausted no
     * further attempts are accepted and the caller must issue a new one.
     */
    public function verify(
        ?User $user,
        string $channel,
        string $destination,
        string $code,
        string $purpose = OtpCode::PURPOSE_LOGIN,
    ): bool {
        $destination = $this->normalise($channel, $destination);

        $otp = OtpCode::query()
            ->when($user, fn ($q) => $q->where('user_id', $user->id))
            ->forDestination($channel, $destination)
            ->where('purpose', $purpose)
            ->pending()
            ->first();

        if (! $otp || $otp->maxAttemptsReached()) {
            return false;
        }

        // Count the attempt before checking, so the counter is meaningful.
        $otp->increment('attempts');

        if (! Hash::check($code, $otp->code_hash)) {
            return false;
        }

        $otp->update(['consumed_at' => now()]);

        // Release the send cooldown so the next legitimate login is not blocked.
        EmailOtpMail::clearThrottle($destination, $purpose);

        return true;
    }

    /**
     * Re-issue a code, enforcing the resend cooldown.
     *
     * @throws \Symfony\Component\HttpKernel\Exception\HttpException 429 when called within the cooldown
     */
    public function resend(
        ?User $user,
        string $channel,
        string $destination,
        string $purpose = OtpCode::PURPOSE_LOGIN,
    ): OtpCode {
        $destination = $this->normalise($channel, $destination);
        $cooldown = (int) config('sportx.otp.resend_cooldown_seconds', 60);

        $withinCooldown = OtpCode::query()
            ->forDestination($channel, $destination)
            ->where('created_at', '>=', now()->subSeconds($cooldown))
            ->exists();

        if ($withinCooldown) {
            abort(429, 'Please wait before requesting another code.');
        }

        return $this->generateAndSend($user, $channel, $destination, $purpose);
    }

    /**
     * Seconds the caller must wait before another send is allowed.
     */
    public function resendAvailableIn(?User $user, string $channel, string $destination, string $purpose = OtpCode::PURPOSE_LOGIN): int
    {
        $cooldown = (int) config('sportx.otp.resend_cooldown_seconds', 60);

        $last = OtpCode::query()
            ->forDestination($channel, $this->normalise($channel, $destination))
            ->where('purpose', $purpose)
            ->latest()
            ->first();

        if (! $last) {
            return 0;
        }

        return max(0, $cooldown - $last->created_at->diffInSeconds(now()));
    }

    /**
     * Dispatch the code over its channel.
     *
     * Phone/SMS is not yet wired — no vendor is selected (AS-60). Until one is,
     * a phone code cannot be delivered and the caller is told so rather than
     * silently accepting a request that can never be completed.
     *
     * @throws \RuntimeException when the channel has no transport
     */
    protected function deliver(string $destination, string $code, string $purpose): void
    {
        if (! $this->isEmail($destination)) {
            throw new OtpDeliveryException(
                'No transport is configured for OTP delivery. Email is supported; '
                    .'phone/SMS requires an SMS vendor (AS-60).'
            );
        }

        $this->sendEmail($destination, $code, $purpose);
    }

    /**
     * Queue the email through the active SportX provider (SMTP or Gmail).
     */
    protected function sendEmail(string $destination, string $code, string $purpose): void
    {
        // A replayed request must not re-send to an already-cooled destination.
        if (! EmailOtpMail::throttle($destination, $purpose)) {
            Log::info('OTP email suppressed by cooldown', [
                'destination' => $destination,
                'purpose' => $purpose,
            ]);

            return;
        }

        Mail::to($destination)->queue(new EmailOtpMail($destination, $code, $purpose));
    }

    /**
     * Addresses are compared case-insensitively; phone numbers are reduced to
     * digits so `+91 98…` and `9198…` resolve to the same code row.
     */
    public function normalise(string $channel, string $destination): string
    {
        $destination = trim($destination);

        return strtolower($channel) === 'phone' || $this->isPhone($destination)
            ? preg_replace('/\D+/', '', $destination)
            : Str::lower($destination);
    }

    protected function isEmail(string $destination): bool
    {
        return (bool) filter_var($destination, FILTER_VALIDATE_EMAIL);
    }

    protected function isPhone(string $destination): bool
    {
        return (bool) preg_match('/^\+?\d[\d\s\-()]{7,}$/', $destination);
    }

    /**
     * Cryptographically random numeric code.
     *
     * Uses `random_int`, not `rand` — a predictable code makes the five-attempt
     * limit meaningless.
     */
    protected function randomCode(): string
    {
        $length = (int) config('sportx.otp.code_length', 6);

        $code = '';
        for ($i = 0; $i < $length; $i++) {
            $code .= (string) random_int(0, 9);
        }

        return $code;
    }
}