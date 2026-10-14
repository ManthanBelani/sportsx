<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin2FAVerified
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user && $user->role === 'admin') {
            $verifiedAt = $user->admin_2fa_verified_at;
            $fresh = $verifiedAt && \Carbon\Carbon::parse($verifiedAt)->gt(now()->subHours(12));
            if (!$fresh) {
                return response()->json(['error' => ['code' => '2FA_REQUIRED', 'message' => 'Admin 2FA verification required.']], 403);
            }
        }

        return $next($request);
    }
}
