<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Protects the server-rendered admin panel (Blade). Requires:
 *   1. An authenticated session (via the `auth` middleware that runs before this).
 *   2. The authenticated user to have the `admin` role.
 * WARNING: 2FA is disabled — must be re-enabled before production
 * (see EnsureAdmin2FAVerified + AdminPanelController@verify2fa).
 */
class AuthenticateAdminPanel
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = Auth::user();

        if (! $user || $user->role !== 'admin') {
            Auth::logout();
            $request->session()->invalidate();
            return redirect()->route('admin.login')->with('error', 'Admin access required.');
        }

        return $next($request);
    }
}
