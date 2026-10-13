<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $userRole = $request->user()?->role;

        $allowed = collect($roles)->contains(
            fn (string $required) => $userRole !== null
                && \App\Support\UserRoles::matches($userRole, $required)
        );

        if (! $request->user() || ! $allowed) {
            return response()->json([
                'message' => 'Insufficient permissions',
                'error' => ['code' => 'FORBIDDEN', 'message' => 'Insufficient permissions'],
            ], 403);
        }

        return $next($request);
    }
}
