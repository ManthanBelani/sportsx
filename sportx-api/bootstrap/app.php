<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Sentry\Laravel\Integration;

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

        \Illuminate\Auth\Middleware\Authenticate::redirectUsing(function (Request $request) {
            return $request->is('api/*') ? null : route('admin.login');
        });
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        Integration::handles($exceptions);

        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }
        });

        $exceptions->render(function (\Illuminate\Validation\ValidationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'The given data was invalid.',
                        'errors' => $e->errors(),
                    ]
                ], 422);
            }
        });

        $exceptions->render(function (\Illuminate\Database\Eloquent\ModelNotFoundException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Resource not found.',
                    ]
                ], 404);
            }
        });

        $exceptions->render(function (\Symfony\Component\HttpKernel\Exception\NotFoundHttpException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Endpoint not found.',
                    ]
                ], 404);
            }
        });

        // Any other HTTP error (403, 409, 422 …) thrown by the controllers.
        // Laravel's default payload leaks the exception class, the absolute
        // server path and a stack trace — the API answers with the same
        // envelope as every other error instead.
        $exceptions->render(function (\Symfony\Component\HttpKernel\Exception\HttpException $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            $status = $e->getStatusCode();
            $message = trim((string) $e->getMessage());
            if ($message === '') {
                $message = match ($status) {
                    403 => 'Forbidden.',
                    404 => 'Endpoint not found.',
                    405 => 'Method not allowed.',
                    409 => 'Conflict.',
                    429 => 'Too many attempts.',
                    default => 'Request failed.',
                };
            }

            return response()->json([
                'message' => $message,
                'error' => [
                    'code' => match ($status) {
                        403 => 'FORBIDDEN',
                        404 => 'NOT_FOUND',
                        405 => 'METHOD_NOT_ALLOWED',
                        409 => 'CONFLICT',
                        429 => 'TOO_MANY_REQUESTS',
                        default => 'REQUEST_FAILED',
                    },
                    'message' => $message,
                ],
            ], $status, $e->getHeaders());
        });

        // Unhandled server errors: never leak the stack trace or file paths.
        $exceptions->render(function (\Throwable $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            $message = config('app.debug') && $e->getMessage() !== ''
                ? $e->getMessage()
                : 'Something went wrong. Please try again.';

            return response()->json([
                'message' => $message,
                'error' => [
                    'code' => 'SERVER_ERROR',
                    'message' => $message,
                ],
            ], 500);
        });
    })->create();
