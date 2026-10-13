<?php

namespace App\Http\Controllers;

use App\Exceptions\OtpDeliveryException;
use App\Models\OtpCode;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;

/**
 * One-time code issue and verification.
 *
 * Every endpoint is unauthenticated — a code is what *establishes* identity, so
 * it cannot be behind a bearer token. Abuse control is therefore per
 * destination rather than per user, and responses are deliberately uniform so
 * the endpoint cannot be used to discover which email addresses have accounts.
 *
 * @see \App\Services\OtpService
 * @see docs/API-Specification.md §1
 * @see docs/Email-Provider-Architecture.md
 */
class OtpController extends Controller
{
    public function __construct(protected OtpService $otp) {}

    /**
     * POST /auth/send-otp
     */
    public function send(Request $request): JsonResponse
    {
        $validated = $this->validateSend($request);

        $this->throttle($request, $validated['destination']);

        // Resolve a user when one exists so the code is tied to the account, but
        // never reveal that an account does or does not exist.
        $user = $this->resolveUser($validated['channel'], $validated['destination']);

        $this->assertPurposeAllowed($user, $validated['purpose']);

        try {
            $otp = $this->otp->generateAndSend(
                $user,
                $validated['channel'],
                $validated['destination'],
                $validated['purpose'],
            );
        } catch (OtpDeliveryException $e) {
            // e.g. a phone destination with no SMS vendor configured (AS-60).
            return response()->json([
                'error' => [
                    'code' => 'CHANNEL_UNAVAILABLE',
                    'message' => $e->getMessage(),
                ],
            ], 503);
        }

        return response()->json([
            'data' => [
                'sent' => true,
                'channel' => $otp->channel,
                'destination' => $this->mask($otp->destination),
                'purpose' => $otp->purpose,
                'expires_at' => $otp->expires_at->toIso8601String(),
                'resend_available_at' => now()
                    ->addSeconds((int) config('sportx.otp.resend_cooldown_seconds', 60))
                    ->toIso8601String(),
            ],
        ]);
    }

    /**
     * POST /auth/verify-otp
     *
     * Returns a Sanctum token when the code is valid and the destination maps
     * to an existing account.
     */
    public function verify(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'channel' => 'required|in:email,phone',
            'destination' => 'required|string|max:191',
            'code' => 'required|string|max:10',
            'purpose' => 'required|in:'.implode(',', OtpCode::PURPOSES),
            'name' => 'required_if:purpose,signup|string|max:100',
            'role' => 'required_if:purpose,signup|in:athlete,coach,academy,organizer,sponsor,talent_scout',
            'password' => 'required_if:purpose,signup|string|min:8',
            'phone' => 'nullable|string|max:20',
        ]);

        $channel = $validated['channel'];
        $destination = $this->otp->normalise($channel, $validated['destination']);
        $purpose = $validated['purpose'];

        $this->throttleVerify($request, $destination);

        $user = $this->resolveUser($channel, $destination);

        if (! $this->otp->verify($user, $channel, $destination, $validated['code'], $purpose)) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_OTP',
                    'message' => 'That code is incorrect or has expired.',
                ],
            ], 422);
        }

        // `signup` creates the account on successful verification, so the code
        // is what proves control of the contact channel.
        if ($user === null) {
            if ($purpose !== OtpCode::PURPOSE_SIGNUP) {
                return response()->json([
                    'error' => [
                        'code' => 'INVALID_OTP',
                        'message' => 'That code is incorrect or has expired.',
                    ],
                ], 422);
            }

            $user = $this->createUserFromVerifiedChannel($validated, $destination);
        }

        // The code proves control of the channel, so mark it verified.
        $this->markChannelVerified($user, $channel);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->userResource($user),
            'needs_onboarding' => ! $user->hasRoleProfile(),
            'pending_approval' => $user->status === 'pending',
        ]);
    }

    /**
     * POST /auth/resend-otp
     */
    public function resend(Request $request): JsonResponse
    {
        $validated = $this->validateSend($request);

        $this->throttle($request, $validated['destination']);

        $user = $this->resolveUser($validated['channel'], $validated['destination']);

        try {
            $otp = $this->otp->resend(
                $user,
                $validated['channel'],
                $validated['destination'],
                $validated['purpose'],
            );
        } catch (OtpDeliveryException $e) {
            return response()->json([
                'error' => ['code' => 'CHANNEL_UNAVAILABLE', 'message' => $e->getMessage()],
            ], 503);
        }

        return response()->json([
            'data' => [
                'sent' => true,
                'expires_at' => $otp->expires_at->toIso8601String(),
                'resend_available_at' => now()
                    ->addSeconds((int) config('sportx.otp.resend_cooldown_seconds', 60))
                    ->toIso8601String(),
            ],
        ]);
    }

    /* ---------------------------------------------------------------------
     | Internals
     | ------------------------------------------------------------------ */

    /**
     * @return array{channel: string, destination: string, purpose: string}
     */
    protected function validateSend(Request $request): array
    {
        $validated = $request->validate([
            'channel' => 'required|in:email,phone',
            'destination' => 'required|string|max:191',
            'purpose' => 'required|in:'.implode(',', OtpCode::PURPOSES),
        ]);

        return [
            'channel' => $validated['channel'],
            'destination' => $validated['destination'],
            'purpose' => $validated['purpose'],
        ];
    }

    /**
     * A password-reset code should not be issued for a channel with no account.
     */
    protected function assertPurposeAllowed(?User $user, string $purpose): void
    {
        if ($user === null && in_array($purpose, [
            OtpCode::PURPOSE_LOGIN,
            OtpCode::PURPOSE_RESET_PASSWORD,
        ], true)) {
            // Uniform response: do not disclose whether an account exists.
            abort(422, 'That code is incorrect or has expired.');
        }
    }

    /**
     * Find the account behind a channel, if any.
     */
    protected function resolveUser(string $channel, string $destination): ?User
    {
        $destination = $this->otp->normalise($channel, $destination);

        if ($channel === 'email') {
            return User::where('email', $destination)->first();
        }

        return User::where('phone', $destination)->first();
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    protected function createUserFromVerifiedChannel(array $validated, string $destination): User
    {
        $role = $validated['role'];
        $settings = $this->platformSettings();

        $needsApproval = match ($role) {
            'coach' => ! ($settings['auto_approve_coach'] ?? false),
            'sponsor' => ! ($settings['auto_approve_sponsor'] ?? false),
            'talent_scout' => ! ($settings['auto_approve_talent_scout'] ?? false),
            default => false,
        };

        $attributes = [
            'role' => $role,
            'name' => $validated['name'] ?? Str::before($destination, '@'),
            'password' => Hash::make($validated['password'] ?? Str::random(40)),
            // The code proved control of the channel.
            'email_verified_at' => $validated['channel'] === 'email' ? now() : null,
            'status' => $needsApproval ? 'pending' : 'active',
        ];

        if ($validated['channel'] === 'email') {
            $attributes['email'] = $destination;
        } else {
            $attributes['phone'] = $destination;
        }

        return User::create($attributes);
    }

    protected function markChannelVerified(User $user, string $channel): void
    {
        if ($channel === 'email' && $user->email_verified_at === null) {
            $user->forceFill(['email_verified_at' => now()])->save();
        }
    }

    /**
     * Cost abuse control: cap sends per destination per hour.
     */
    protected function throttle(Request $request, string $destination): void
    {
        $key = 'otp.send.'.sha1(strtolower(trim($destination)));

        if (RateLimiter::tooManyAttempts($key, 5)) {
            abort(429, 'Too many codes requested for this contact. Try again later.');
        }

        RateLimiter::hit($key, 3600);
    }

    /**
     * Guess protection: cap verification attempts per destination.
     *
     * On top of the per-code `max_attempts` counter, this bounds brute force
     * across a *stream* of freshly issued codes for the same destination.
     */
    protected function throttleVerify(Request $request, string $destination): void
    {
        $key = 'otp.verify.'.sha1(strtolower(trim($destination)));

        if (RateLimiter::tooManyAttempts($key, 10)) {
            abort(429, 'Too many incorrect codes. Try again later.');
        }

        RateLimiter::hit($key, 300);
    }

    /**
     * Never echo a full address back to the client.
     */
    protected function mask(string $destination): string
    {
        if (str_contains($destination, '@')) {
            [$local, $domain] = explode('@', $destination, 2);

            return Str::mask($local, 2, 2).'@'.$domain;
        }

        return '***'.substr($destination, -3);
    }

    protected function platformSettings(): array
    {
        $path = storage_path('app/platform_settings.json');

        if (is_file($path)) {
            $decoded = json_decode((string) @file_get_contents($path), true);

            return is_array($decoded) ? $decoded : [];
        }

        return [];
    }

    protected function userResource(User $user): array
    {
        return [
            'id' => $user->id,
            'role' => $user->role,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'email_verified_at' => $user->email_verified_at?->toIso8601String(),
            'status' => $user->status,
            'social_links' => $user->social_links,
        ];
    }
}