<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        apiPrefix: 'api',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => \App\Http\Middleware\EnsureRole::class,
            'admin.2fa' => \App\Http\Middleware\EnsureAdmin2FAVerified::class,
            'admin.panel' => \App\Http\Middleware\AuthenticateAdminPanel::class,
        ]);

        // API-only app with a separate Blade admin panel. The default
        // Authenticate redirectTo callback calls route('login'), which doesn't
        // exist — it would throw RouteNotFoundException (a 500). Return null for
        // API requests (rendered as a 401 by the handler below) and redirect web
        // panel requests to the admin login route.
        \Illuminate\Auth\Middleware\Authenticate::redirectUsing(function (Request $request) {
            return $request->is('api/*') ? null : route('admin.login');
        });
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        // API-only app: there is no web "login" route, so the default
        // Authenticate middleware would try route('login') and throw a 500.
        // Return a clean 401 JSON instead for every unauthenticated api/* request.
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }
        });
    })->create();
