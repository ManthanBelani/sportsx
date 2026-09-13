<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\UserDeviceToken;
use App\Mail\VerifyEmail;
use App\Mail\PasswordResetMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'role' => 'required|in:athlete,coach,academy,organizer,sponsor,talent_scout',
            'email' => 'required|email|unique:users,email',
            'name' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:20',
            'password' => ['required', 'string', 'min:8'],
        ]);

        $email = strtolower($validated['email']);
        // Determine if this role needs admin approval
        $settings = $this->platformSettings();
        $needsApproval = match ($validated['role']) {
            'coach' => !($settings['auto_approve_coach'] ?? false),
            'sponsor' => !($settings['auto_approve_sponsor'] ?? false),
            'talent_scout' => !($settings['auto_approve_talent_scout'] ?? false),
            default => false,
        };
        $status = $needsApproval ? 'pending' : 'active';
        $user = User::create([
            'role' => $validated['role'],
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

        return response()->json([
            'message' => 'Email verified successfully',
            'token' => $token,
            'user' => $this->userResource($user),
            'needs_onboarding' => ! $user->hasRoleProfile(),
        ]);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
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
            'email_verified_at' => $user->email_verified_at?->toIso8601String(),
            'status' => $user->status,
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
