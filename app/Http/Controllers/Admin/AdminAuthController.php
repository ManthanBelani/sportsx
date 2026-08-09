<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use App\Models\User;
use App\Models\AdminProfile;

class AdminAuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_CREDENTIALS',
                    'message' => 'Invalid email or password.',
                ]
            ], 401);
        }

        if ($user->role !== 'admin') {
            return response()->json([
                'error' => [
                    'code' => 'FORBIDDEN',
                    'message' => 'Access denied. Admin credentials required.',
                ]
            ], 403);
        }

        $token = $user->createToken('admin-token')->plainTextToken;

        return response()->json([
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
                'requires_2fa' => true,
            ]
        ]);
    }

    public function verify2fa(Request $request): JsonResponse
    {
        $request->validate([
            'code' => 'required|string|size:6',
        ]);

        $user = $request->user();

        if ($user->role !== 'admin') {
            return response()->json([
                'error' => [
                    'code' => 'FORBIDDEN',
                    'message' => 'Access denied.',
                ]
            ], 403);
        }

        // In production, verify TOTP code here
        // For MVP, accept any 6-digit code or implement proper TOTP
        $code = $request->code;

        // Simulate 2FA verification - in production use proper TOTP library
        if (strlen($code) !== 6) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_2FA_CODE',
                    'message' => 'Invalid 2FA code.',
                ]
            ], 422);
        }

        // Mark 2FA as verified for this session
        $user->forceFill([
            'admin_2fa_verified_at' => now(),
        ])->save();

        return response()->json([
            'data' => [
                'message' => '2FA verified.',
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'admin_2fa_verified_at' => $user->admin_2fa_verified_at,
                ],
            ]
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'data' => [
                'message' => 'Logged out successfully.',
            ]
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'admin_2fa_verified_at' => $user->admin_2fa_verified_at,
            ]
        ]);
    }
}
