<?php

return [
    'dsn' => env('SENTRY_DSN'),

    'enabled' => env('SENTRY_ENABLED', false),

    'tracing' => [
        'enabled' => env('SENTRY_TRACING_ENABLED', true),
        'sample_rate' => env('SENTRY_TRACING_SAMPLE_RATE', 0.1),
    ],

    'performance' => [
        'db_query_min_duration' => env('SENTRY_DB_QUERY_MIN_DURATION', 1),
    ],

    'send_default_pii' => env('SENTRY_SEND_DEFAULT_PII', false),

    'ignore_exceptions' => [
        'Illuminate\Auth\AuthenticationException',
        'Illuminate\Auth\Access\AuthorizationException',
        'Illuminate\Database\Eloquent\ModelNotFoundException',
        'Illuminate\Validation\ValidationException',
        'Symfony\Component\HttpKernel\Exception\NotFoundHttpException',
        'Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException',
    ],

    'local_env_vars' => ['APP_DEBUG'],
];
