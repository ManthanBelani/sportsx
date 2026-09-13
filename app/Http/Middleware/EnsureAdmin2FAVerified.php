<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin2FAVerified
{
    public function handle(Request $request, Closure $next): Response
    {
        // WARNING: 2FA is currently DISABLED — ship-blocker for production.
        // Enable by: 1) storing TOTP secret on User/AdminProfile, 2) verifying
        // code with pragmarx/google2fa, 3) setting admin_2fa_verified_at and
        // checking expiry (e.g. 12h) here before allowing the request.
        // See PRODUCTION_READINESS_AUDIT.md §1 #1.
        return $next($request);
    }
}
