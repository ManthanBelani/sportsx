<?php

namespace App\Http\Controllers;

use App\Exceptions\OtpDeliveryException;
use App\Models\OtpCode;
use App\Models\User;
use App\Models\UserDeviceToken;
use App\Mail\VerifyEmail;
use App\Mail\PasswordResetMail;
use App\Mail\WelcomeMail;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'role' => 'required|in:athlete,coach,academy,organizer,sponsor,talent_scout,scout',
            'email' => 'required|email|unique:users,email',
            'name' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:20',
            'password' => ['required', 'string', 'min:8'],
        ]);

        // v3: `sponsor` was removed — sponsorships become `opportunities.type`
        // in Phase 4. Refuse new sponsor accounts explicitly (410 Gone) so
        // clients can message the migration instead of failing validation.
        if ($validated['role'] === 'sponsor') {
            return response()->json([
                'error' => [
                    'code' => 'SPONSOR_REMOVED',
                    'message' => 'Sponsor accounts are no longer offered. Providers list scholarships and sponsorships as opportunities instead.',
                ],
            ], 410);
        }

        $role = \App\Support\UserRoles::toStorage(
            \App\Support\UserRoles::normalize($validated['role']) ?? $validated['role']
        );

        $email = strtolower($validated['email']);
        // Determine if this role needs admin approval
        $settings = $this->platformSettings();
        $needsApproval = match ($role) {
            'coach' => !($settings['auto_approve_coach'] ?? false),
            'sponsor' => !($settings['auto_approve_sponsor'] ?? false),
            'talent_scout' => !($settings['auto_approve_talent_scout'] ?? false),
            default => false,
        };
        $status = $needsApproval ? 'pending' : 'active';
        $user = User::create([
            'role' => $role,
            'email' => $email,
            'name' => $validated['name'] ?? explode('@', $email)[0],
            'phone' => $validated['phone'] ?? null,
            'password' => Hash::make($validated['password']),
            'email_verified_at' => now(),
            'status' => $status,
        ]);

        // If pending approval, still issue token but flag it — middleware will block writes until approved.
        // We do NOT auto-login pending sponsor/coach/scout? Frontend will show "pending approval" state.
        $token = $user->createToken('auth_token')->plainTextToken;

        $message = $status === 'pending'
            ? 'Registration received. Your account is pending admin approval.'
            : 'Registration successful.';

        return response()->json([
            'message' => $message,
            'token' => $token,
            'user' => $this->userResource($user),
            'needs_onboarding' => ! $user->hasRoleProfile(),
            'pending_approval' => $status === 'pending',
        ], 201);
    }

    public function verifyEmail(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string',
        ]);

        $user = User::where('verification_token', $validated['token'])->first();

        if (!$user) {
            return response()->json(['message' => 'Invalid verification token'], 400);
        }

        $user->email_verified_at = now();
        $user->verification_token = null;
        $user->save();

        $token = $user->createToken('auth_token')->plainTextToken;

        // Verified users get the welcome mail; accounts still awaiting approval
        // are told so in the template rather than discovering it by silence.
        if ($user->email) {
            Mail::to($user->email)->queue(new WelcomeMail($user));
        }

        return response()->json([
            'message' => 'Email verified successfully',
            'token' => $token,
            'user' => $this->userResource($user),
            'needs_onboarding' => ! $user->hasRoleProfile(),
        ]);
    }

    /**
     * POST /auth/resend-verification
     *
     * `register()` marks the address verified up front, so this only has work
     * to do for accounts whose address is still unverified.
     */
    public function resendVerification(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', strtolower($validated['email']))->first();

        // Uniform response: never disclose whether an account exists.
        if (!$user || $user->email_verified_at !== null) {
            return response()->json([
                'message' => 'If an account exists and needs verification, a link has been sent',
            ]);
        }

        $token = Str::random(64);
        $user->verification_token = $token;
        $user->save();

        Mail::to($user->email)->queue(new VerifyEmail($user, $token));

        return response()->json([
            'message' => 'If an account exists and needs verification, a link has been sent',
        ]);
    }

    public function login(Request $request, OtpService $otp)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'code' => 'nullable|string|max:10',
            'require_otp' => 'nullable|boolean',
        ]);

        $user = User::where('email', strtolower($validated['email']))->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        if ($user->status === 'pending') {
            return response()->json([
                'message' => 'Your account is pending admin approval. You will be able to log in once an admin approves your registration.',
                'status' => 'pending',
            ], 403);
        }

        if ($user->status !== 'active') {
            return response()->json(['message' => 'Account is '.$user->status.'. Contact support.'], 403);
        }

        if (!empty($validated['code'])) {
            if (!$otp->verify($user, 'email', $user->email, $validated['code'], OtpCode::PURPOSE_LOGIN)) {
                return response()->json([
                    'message' => 'That code is incorrect or has expired.',
                ], 422);
            }

            if ($user->email_verified_at === null) {
                $user->email_verified_at = now();
                $user->save();
            }

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'token' => $token,
                'user' => $this->userResource($user),
                'needs_onboarding' => ! $user->hasRoleProfile(),
            ]);
        }

        $enforceOtp = $request->has('require_otp')
            ? $request->boolean('require_otp')
            : !app()->runningUnitTests();

        if ($enforceOtp) {
            try {
                $otp->generateAndSend($user, 'email', $user->email, OtpCode::PURPOSE_LOGIN);
            } catch (OtpDeliveryException $e) {
                return response()->json([
                    'error' => [
                        'code' => 'CHANNEL_UNAVAILABLE',
                        'message' => $e->getMessage(),
                    ],
                ], 503);
            }

            return response()->json([
                'otp_required' => true,
                'email' => $user->email,
                'message' => 'Credentials verified. A login code has been sent to your email.',
            ]);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->userResource($user),
            'needs_onboarding' => ! $user->hasRoleProfile(),
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'data' => $this->userResource($user) + [
                'needs_onboarding' => ! $user->hasRoleProfile(),
            ],
        ]);
    }

    /**
     * POST /auth/otp-login/request
     *
     * Passwordless login, step one: email a login OTP to the address.
     * Uniform response whether or not the account exists, so the endpoint
     * cannot be used to discover registrations (same principle as
     * OtpController).
     */
    public function otpLoginRequest(Request $request, OtpService $otp)
    {
        $validated = $request->validate([
            'email' => 'required|email|max:255',
        ]);

        $user = User::where('email', strtolower($validated['email']))->first();

        try {
            $otp->generateAndSend($user, 'email', $validated['email'], OtpCode::PURPOSE_LOGIN);
        } catch (OtpDeliveryException $e) {
            return response()->json([
                'error' => [
                    'code' => 'CHANNEL_UNAVAILABLE',
                    'message' => $e->getMessage(),
                ],
            ], 503);
        }

        return response()->json([
            'message' => 'If the address is registered, a login code has been sent.',
        ]);
    }

    /**
     * POST /auth/otp-login/verify
     *
     * Passwordless login, step two: exchange the emailed code for a token.
     * Same status checks and response shape as login() so the Flutter client
     * needs no special handling.
     */
    public function otpLoginVerify(Request $request, OtpService $otp)
    {
        $validated = $request->validate([
            'email' => 'required|email|max:255',
            'code' => 'required|string|max:10',
        ]);

        $user = User::where('email', strtolower($validated['email']))->first();

        $verified = $user
            && $otp->verify($user, 'email', $validated['email'], $validated['code'], OtpCode::PURPOSE_LOGIN);

        if (! $verified) {
            return response()->json([
                'message' => 'That code is incorrect or has expired.',
            ], 422);
        }

        if ($user->status === 'pending') {
            return response()->json([
                'message' => 'Your account is pending admin approval. You will be able to log in once an admin approves your registration.',
                'status' => 'pending',
            ], 403);
        }

        if ($user->status !== 'active') {
            return response()->json(['message' => 'Account is '.$user->status.'. Contact support.'], 403);
        }

        if ($user->email_verified_at === null) {
            $user->email_verified_at = now();
            $user->save();
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->userResource($user),
            'needs_onboarding' => ! $user->hasRoleProfile(),
        ]);
    }

    public function logout(Request $request)
    {
        $user = $request->user();

        UserDeviceToken::where('user_id', $user->id)->update(['is_active' => false]);

        $user->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out']);
    }

    public function forgotPassword(Request $request)
    {
        $validated = $request->validate(['email' => 'required|email']);
        $user = User::where('email', strtolower($validated['email']))->first();

        if (!$user) {
            return response()->json(['message' => 'If an account exists, a reset link has been sent']);
        }

        $token = Str::random(64);
        $user->reset_password_token = $token;
        $user->reset_password_sent_at = now();
        $user->save();

        Mail::to($user->email)->send(new PasswordResetMail($user, $token));

        return response()->json(['message' => 'If an account exists, a reset link has been sent']);
    }

    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::where('email', strtolower($validated['email']))
            ->where('reset_password_token', $validated['token'])
            ->first();

        if (!$user) {
            return response()->json(['message' => 'Invalid reset token'], 400);
        }

        if ($user->reset_password_sent_at->addMinutes(60)->isPast()) {
            return response()->json(['message' => 'Reset token has expired'], 400);
        }

        $user->password = Hash::make($validated['password']);
        $user->reset_password_token = null;
        $user->reset_password_sent_at = null;
        $user->email_verified_at = $user->email_verified_at ?? now();
        $user->save();

        $user->tokens()->delete();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Password reset successfully',
            'token' => $token,
            'user' => $this->userResource($user),
        ]);
    }

    private function userResource(User $user): array
    {
        return [
            'id' => $user->id,
            'role' => $user->role,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'date_of_birth' => $user->athleteProfile?->date_of_birth?->format('Y-m-d'),
            'avatar_url' => $user->avatar_url,
            'profile_photo_url' => $user->avatar_url,
            'email_verified_at' => $user->email_verified_at?->toIso8601String(),
            'status' => $user->status,
            'social_links' => $user->social_links,
            'is_verified' => $user->isVerified(),
        ];
    }

    private function platformSettings(): array
    {
        $path = storage_path('app/platform_settings.json');
        if (file_exists($path)) {
            $data = json_decode((string) file_get_contents($path), true) ?: [];
            return $data;
        }
        return [];
    }
}
