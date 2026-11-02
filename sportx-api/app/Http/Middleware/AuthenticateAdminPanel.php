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
 *   3. A completed TOTP challenge for this session (admin_2fa_ok), unless
 *      ADMIN_2FA_ENFORCE=false (local-dev escape hatch, matches the API).
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

        if (! session('admin_2fa_ok')
            && filter_var(env('ADMIN_2FA_ENFORCE', true), FILTER_VALIDATE_BOOLEAN)) {
            return redirect()->route('admin.2fa');
        }

        return $next($request);
    }
}
