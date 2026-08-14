<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin2FAVerified
{
    private const VERIFICATION_WINDOW_MINUTES = 30;

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || $user->role !== 'admin') {
            return $next($request);
        }

        if (!$user->two_factor_secret) {
            return $next($request);
        }

        $verifiedAt = $user->admin_2fa_verified_at;

        if (!$verifiedAt || !$verifiedAt->isAfter(now()->subMinutes(self::VERIFICATION_WINDOW_MINUTES))) {
            if ($request->expectsJson()) {
                return response()->json([
                    'error' => [
                        'code' => '2FA_REQUIRED',
                        'message' => '2FA verification required. Please complete 2FA setup or verification.',
                    ]
                ], 403);
            }

            return redirect()->route('admin.2fa.prompt');
        }

        return $next($request);
    }
}
