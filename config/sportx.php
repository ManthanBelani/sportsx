<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Email delivery (see docs/Email-Provider-Architecture.md)
    |--------------------------------------------------------------------------
    |
    | "provider" selects the primary transport:
    |   smtp   -> config('mail.mailers.smtp')  (MAIL_HOST / MAIL_PORT / ...)
    |   gmail  -> config('mail.mailers.gmail') (OAuth2 Gmail API)
    |
    | "failover" wraps the provider chain into a single resilient mailer so a
    | provider outage never silently drops a transactional email. Set
    | MAIL_FAILOVER_ENABLED=false to send strictly through "provider".
    |
    | The admin panel can override "provider" at runtime; that override lives in
    | storage/app/platform_settings.json and wins over this config.
    |
    */
    'mail' => [
        'provider' => env('MAIL_PROVIDER', 'smtp'),
        'failover' => [
            'enabled' => env('MAIL_FAILOVER_ENABLED', true),
            'chain' => ['gmail', 'smtp', 'log'],
        ],
        'retry_after' => env('MAIL_FAILOVER_RETRY_AFTER', 60),
        // Connection test used by the admin "Email settings" screen.
        'test_recipient' => env('MAIL_TEST_RECIPIENT'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Google platform integrations (see docs/Google-Authentication.md)
    |--------------------------------------------------------------------------
    */
    'google' => [
        // OAuth 2.0 client used by "Continue with Google" (ID token verification).
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect_uri' => env('GOOGLE_REDIRECT_URI'),
        'hd' => env('GOOGLE_WORKSPACE_HD'), // optional Workspace domain restriction
        // When true a Google login for an unknown e-mail silently creates a new
        // account. When false the client must pass an explicit, allow-listed role.
        'allow_signup' => env('GOOGLE_ALLOW_SIGNUP', true),
        'default_role' => env('GOOGLE_DEFAULT_ROLE', 'athlete'),
        'restrict_roles' => array_filter(explode(',', (string) env('GOOGLE_ALLOWED_ROLES', 'athlete,coach,academy,organizer,sponsor,talent_scout'))),
    ],

    /*
    |--------------------------------------------------------------------------
    | Push notifications (see docs/FCM-Notification-System.md)
    |--------------------------------------------------------------------------
    */
    'notifications' => [
        'channels' => ['in_app', 'push', 'email'],
        'defaults' => [
            'in_app' => true,
            'push' => true,
            'email' => false,
        ],
        // Per-type channel defaults. Any type not listed falls back to 'defaults'.
        'type_channels' => [
            'reminder' => ['in_app' => true, 'push' => true],
            'enquiry_reply' => ['in_app' => true, 'push' => true, 'email' => true],
            'status_update' => ['in_app' => true, 'push' => true],
            'registration_approved' => ['in_app' => true, 'push' => true, 'email' => true],
            'registration_rejected' => ['in_app' => true, 'push' => true, 'email' => true],
            'trial_approved' => ['in_app' => true, 'push' => true, 'email' => true],
            'trial_rejected' => ['in_app' => true, 'push' => true, 'email' => true],
            'tournament_approved' => ['in_app' => true, 'push' => true, 'email' => true],
            'tournament_rejected' => ['in_app' => true, 'push' => true, 'email' => true],
            'account_action' => ['in_app' => true, 'push' => true, 'email' => true],
            'broadcast' => ['in_app' => true, 'push' => true, 'email' => false],
        ],
        'fcm' => [
            'enabled' => env('FCM_ENABLED', true),
            'project_id' => env('FCM_PROJECT_ID'),
            'credentials_path' => env('FCM_CREDENTIALS_PATH'),
            'timeout' => env('FCM_TIMEOUT', 15),
            // FCM HTTP v1 has no multicast endpoint; tokens are sent in this
            // batch size through a single multiSendRequest-less loop.
            'batch_size' => (int) env('FCM_BATCH_SIZE', 500),
            'max_retries' => (int) env('FCM_MAX_RETRIES', 3),
            'dry_run' => env('FCM_DRY_RUN', false),
            'default_android_channel_id' => env('FCM_DEFAULT_CHANNEL_ID', 'sportx_default'),
            'topics' => [
                'broadcast' => env('FCM_TOPIC_BROADCAST', 'sportx_broadcast'),
                'sport' => env('FCM_TOPIC_SPORT', 'sportx_sport'),
            ],
        ],
        // In-app rows older than this are pruned by PruneNotificationRowsJob.
        'retention_days' => (int) env('NOTIFICATION_RETENTION_DAYS', 180),
        // Device tokens untouched for this long are considered stale.
        'device_token_ttl_days' => (int) env('DEVICE_TOKEN_TTL_DAYS', 120),
    ],

    /*
    |--------------------------------------------------------------------------
    | OTP Settings (AS-03: vendor-agnostic, channel = email for MVP)
    |--------------------------------------------------------------------------
    */
    'otp' => [
        'code_length' => 6,
        'expiry_minutes' => 10,
        'max_attempts' => 5,
        'resend_cooldown_seconds' => 60,
        'channel' => 'email',
    ],

    /*
    |--------------------------------------------------------------------------
    | Reminder offsets (AS-05) — days before the event/deadline
    |--------------------------------------------------------------------------
    */
    'reminder' => [
        'offsets' => [
            '2_days' => 2,
            '1_day' => 1,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Auto-expiry engine
    |--------------------------------------------------------------------------
    */
    'expiry' => [
        'sweep_frequency_minutes' => 60,
    ],

    /*
    |--------------------------------------------------------------------------
    | Pagination
    |--------------------------------------------------------------------------
    */
    'pagination' => [
        'default_per_page' => 20,
        'max_per_page' => 50,
    ],

    /*
    |--------------------------------------------------------------------------
    | Media uploads
    |--------------------------------------------------------------------------
    */
    'media' => [
        'max_upload_mb' => 10,
        'allowed_image_types' => ['jpg', 'jpeg', 'png', 'webp'],
        'allowed_video_types' => ['mp4'],
        'allowed_document_types' => ['pdf', 'jpg', 'jpeg', 'png'],
    ],
];
