<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Mailer
    |--------------------------------------------------------------------------
    |
    | This option controls the default mailer that is used to send all email
    | messages unless another mailer is explicitly specified when sending
    | the message. All additional mailers can be configured within the
    | "mailers" array. Examples of each type of mailer are provided.
    |
    */

    /*
    |--------------------------------------------------------------------------
    | Default Mailer
    |--------------------------------------------------------------------------
    |
    | SportX supports two first-class transactional email providers:
    |
    |   "smtp"  — Generic SMTP relay (Gmail/Google Workspace via App Password,
    |              Zoho, SendGrid, Amazon SES, Mailgun, Brevo, or any host).
    |              Configured with MAIL_HOST / MAIL_PORT / MAIL_USERNAME /
    |              MAIL_PASSWORD.
    |
    |   "gmail" — Direct Gmail API (OAuth2) delivery. Bypasses SMTP quota and
    |              works with Workspace accounts that enforce 2FA and block
    |              "less secure app" passwords. Configured with GMAIL_* vars.
    |
    | The active provider is resolved at runtime by
    | App\Services\MailProviderService (MAIL_PROVIDER env, overridable at
    | runtime from the admin panel), so this value is only the bootstrap
    | fallback. See config/sportx.php -> 'mail'.
    |
    */

    'default' => env('MAIL_MAILER', 'smtp'),

    /*
    |--------------------------------------------------------------------------
    | Mailer Configurations
    |--------------------------------------------------------------------------
    |
    | Here you may configure all of the mailers used by your application plus
    | their respective settings. Several examples have been configured for
    | you and you are free to add your own as your application requires.
    |
    | Laravel supports a variety of mail "transport" drivers that can be used
    | when delivering an email. You may specify which one you're using for
    | your mailers below. You may also add additional mailers if needed.
    |
    | Supported: "smtp", "sendmail", "mailgun", "ses", "ses-v2",
    |            "postmark", "resend", "log", "array",
    |            "failover", "roundrobin"
    |
    */

    'mailers' => [

        'smtp' => [
            'transport' => 'smtp',
            'scheme' => env('MAIL_SCHEME'),
            'url' => env('MAIL_URL'),
            'host' => env('MAIL_HOST', '127.0.0.1'),
            'port' => env('MAIL_PORT', 2525),
            'username' => env('MAIL_USERNAME'),
            'password' => env('MAIL_PASSWORD'),
            'timeout' => env('MAIL_TIMEOUT'),
            'local_domain' => env('MAIL_EHLO_DOMAIN', parse_url((string) env('APP_URL', 'http://localhost'), PHP_URL_HOST)),
        ],

        /*
         * Gmail API (OAuth2) transport — see App\Mail\Transport\GmailApiTransport.
         * Registered through Mail::extend() in AppServiceProvider.
         */
        'gmail' => [
            'transport' => 'gmail-api',
            'auth_mode' => env('GMAIL_AUTH_MODE', 'user'), // user | service_account
            'client_id' => env('GMAIL_CLIENT_ID'),
            'client_secret' => env('GMAIL_CLIENT_SECRET'),
            'refresh_token' => env('GMAIL_REFRESH_TOKEN'),
            'service_account_email' => env('GMAIL_SERVICE_ACCOUNT_EMAIL'),
            'private_key' => env('GMAIL_PRIVATE_KEY'),
            'private_key_id' => env('GMAIL_PRIVATE_KEY_ID'),
            'impersonate' => env('GMAIL_IMPERSONATE_USER', env('MAIL_FROM_ADDRESS')),
            'project_id' => env('GMAIL_PROJECT_ID', env('FCM_PROJECT_ID')),
            'token_cache_key' => env('GMAIL_TOKEN_CACHE_KEY', 'sportx.gmail.access_token'),
            'timeout' => env('GMAIL_TIMEOUT', 15),
        ],

        'ses' => [
            'transport' => 'ses',
        ],

        'postmark' => [
            'transport' => 'postmark',
            // 'message_stream_id' => env('POSTMARK_MESSAGE_STREAM_ID'),
            // 'client' => [
            //     'timeout' => 5,
            // ],
        ],

        'resend' => [
            'transport' => 'resend',
        ],

        'sendmail' => [
            'transport' => 'sendmail',
            'path' => env('MAIL_SENDMAIL_PATH', '/usr/sbin/sendmail -bs -i'),
        ],

        'log' => [
            'transport' => 'log',
            'channel' => env('MAIL_LOG_CHANNEL'),
        ],

        'array' => [
            'transport' => 'array',
        ],

        'failover' => [
            'transport' => 'failover',
            'mailers' => [
                'gmail',
                'smtp',
                'log',
            ],
            'retry_after' => 60,
        ],

        'roundrobin' => [
            'transport' => 'roundrobin',
            'mailers' => [
                'ses',
                'postmark',
            ],
            'retry_after' => 60,
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Global "From" Address
    |--------------------------------------------------------------------------
    |
    | You may wish for all emails sent by your application to be sent from
    | the same address. Here you may specify a name and address that is
    | used globally for all emails that are sent by your application.
    |
    */

    'from' => [
        'address' => env('MAIL_FROM_ADDRESS', 'hello@example.com'),
        'name' => env('MAIL_FROM_NAME', env('APP_NAME', 'Laravel')),
    ],

];
