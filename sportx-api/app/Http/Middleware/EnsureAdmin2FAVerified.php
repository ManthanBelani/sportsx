<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin2FAVerified
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        // Only enforce for admin users who have 2FA enabled
        if ($user && $user->role === 'admin' && $user->two_factor_secret) {
            if (!$request->session()->has('admin_2fa_verified')) {
                if ($request->expectsJson()) {
                    return response()->json(['message' => '2FA verification required.'], 403);
                }
                
                return redirect()->route('admin.2fa.prompt');
            }
        }

        return $next($request);
    }
}
