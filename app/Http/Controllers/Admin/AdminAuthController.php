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
use App\Services\TotpService;

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
        // Fresh login always requires a new 2FA verification (12h session).
        $user->forceFill(['admin_2fa_verified_at' => null])->save();

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
        $request->validate(['code' => 'nullable|string']);
        $user = $request->user();
        abort_unless($user && $user->role === 'admin', 403, 'Admin required.');

        // Local-dev escape hatch (tests/seed): ADMIN_2FA_ENFORCE=false keeps
        // the legacy any-6-digits pass. Production MUST leave it true.
        if (!filter_var(env('ADMIN_2FA_ENFORCE', true), FILTER_VALIDATE_BOOLEAN)) {
            $request->validate(['code' => 'required|string']);
            if (strlen((string) $request->code) !== 6) {
                return response()->json(['error' => ['code' => 'INVALID_2FA_CODE', 'message' => 'Invalid code.']], 401);
            }
            $user->forceFill(['admin_2fa_verified_at' => now()])->save();

            return response()->json(['data' => ['message' => 'Verified (2FA enforcement disabled).', 'user' => [
                'id' => $user->id, 'name' => $user->name, 'email' => $user->email, 'role' => $user->role,
            ]]]);
        }

        // First-time enrollment: provision a secret and return otpauth_url.
        // The client shows a QR, then calls verify again with a live code.
        if (empty($user->google2fa_secret)) {
            $secret = TotpService::generateSecret();
            $user->forceFill(['google2fa_secret' => $secret])->save();

            return response()->json(['data' => [
                'setup_required' => true,
                'otpauth_url' => TotpService::otpauthUrl($secret, $user->email),
                'message' => 'Scan the QR in your authenticator app, then verify with a 6-digit code.',
            ]]);
        }

        $request->validate(['code' => 'required|string']);
        if (!TotpService::verify((string) $user->google2fa_secret, (string) $request->code)) {
            return response()->json(['error' => ['code' => 'INVALID_2FA_CODE', 'message' => 'Invalid 2FA code.']], 401);
        }
        $user->forceFill(['admin_2fa_verified_at' => now()])->save();

        return response()->json([
            'data' => [
                'message' => 'Verified.',
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
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
