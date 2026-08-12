<?php

namespace App\Http\Controllers;

use App\Models\User;
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
            'role' => 'required|in:athlete,coach,academy,organizer,sponsor',
            'email' => 'required|email|unique:users,email',
            'name' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:20',
            'password' => ['required', 'string', 'min:8'],
        ]);

        $email = strtolower($validated['email']);
        $user = User::create([
            'role' => $validated['role'],
            'email' => $email,
            'name' => $validated['name'] ?? explode('@', $email)[0],
            'phone' => $validated['phone'] ?? null,
            'password' => Hash::make($validated['password']),
            'email_verified_at' => now(),
            'status' => 'active',
        ]);

        // Email/password-only auth: auto-verify and issue a session token
        // immediately (no OTP / verification step).
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'token' => $token,
            'user' => $this->userResource($user),
            'needs_onboarding' => ! $user->{$user->role.'Profile'},
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
            'needs_onboarding' => ! in_array($user->role, ['athlete', 'coach', 'academy', 'organizer', 'sponsor'])
                    || ! $user->{$user->role.'Profile'},
        ]);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', strtolower($validated['email']))->where('status', 'active')->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->userResource($user),
            'needs_onboarding' => ! $user->{$user->role.'Profile'},
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'data' => $this->userResource($user) + [
                'needs_onboarding' => ! in_array($user->role, ['admin'])
                    && ! $user->{$user->role.'Profile'},
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

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
}
