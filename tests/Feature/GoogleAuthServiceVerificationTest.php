<?php

namespace Tests\Feature;

use App\Exceptions\GoogleAuthException;
use App\Services\GoogleAuthService;
use App\Services\Support\GoogleKeySet;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * Exercises the real cryptographic path — a locally generated RSA key pair,
 * a stubbed JWKS endpoint, and genuine RS256 signatures.
 *
 * The endpoint tests mock `GoogleAuthService` because minting a valid token per
 * request is pointless ceremony; this suite exists to prove the part that a
 * mock cannot: that a forged, expired, wrong-audience or unsigned token is
 * actually rejected.
 *
 * @see \App\Services\GoogleAuthService
 */
class GoogleAuthServiceVerificationTest extends TestCase
{
    /** PEM-encoded private key, for signing. */
    private static string $privateKey;

    /** \OpenSSLAsymmetricKey handle, for extracting the public modulus. */
    private static $privateKeyHandle;

    private const KID = 'test-key-1';

    private const CLIENT_ID = 'test-client-id.apps.googleusercontent.com';

    public static function setUpBeforeClass(): void
    {
        $resource = openssl_pkey_new([
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        ]);

        openssl_pkey_export($resource, $privateKey);

        self::$privateKey = $privateKey;
        self::$privateKeyHandle = $resource;
    }

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'sportx.google.client_id' => self::CLIENT_ID,
            'sportx.google.allow_signup' => true,
            'sportx.google.hd' => null,
        ]);

        Cache::flush();
    }

    /**
     * Serve a JWKS document containing the test public key.
     */
    protected function stubJwks(?string $kid = null): void
    {
        $details = openssl_pkey_get_details(self::$privateKeyHandle);

        Http::fake([
            GoogleAuthService::JWKS_URI => Http::response([
                'keys' => [[
                    'kty' => 'RSA',
                    'alg' => 'RS256',
                    'use' => 'sig',
                    'kid' => $kid ?? self::KID,
                    'n' => rtrim(strtr(base64_encode($details['rsa']['n']), '+/', '-_'), '='),
                    'e' => rtrim(strtr(base64_encode($details['rsa']['e']), '+/', '-_'), '='),
                ]],
            ]),
        ]);
    }

    /**
     * Mint a genuinely signed ID token.
     *
     * @param  array<string, mixed>  $overrides
     */
    protected function token(array $overrides = [], string $kid = self::KID, string $alg = 'RS256'): string
    {
        $claims = array_merge([
            'iss' => GoogleAuthService::ISSUER,
            'aud' => self::CLIENT_ID,
            'sub' => '100948372948372948',
            'email' => 'kiran@example.com',
            'email_verified' => true,
            'name' => 'Kiran Patel',
            'iat' => time(),
            'exp' => time() + 3600,
        ], $overrides);

        return JWT::encode($claims, self::$privateKey, $alg, $kid);
    }

    protected function service(): GoogleAuthService
    {
        return app(GoogleAuthService::class);
    }

    /* ---------------------------------------------------------------------
     | happy path
     | ------------------------------------------------------------------ */

    public function test_a_genuinely_signed_token_is_accepted(): void
    {
        $this->stubJwks();

        $profile = $this->service()->verifyIdToken($this->token());

        $this->assertSame('100948372948372948', $profile['sub']);
        $this->assertSame('kiran@example.com', $profile['email']);
        $this->assertTrue($profile['email_verified']);
    }

    /* ---------------------------------------------------------------------
     | the six checks
     | ------------------------------------------------------------------ */

    public function test_a_token_signed_with_a_different_key_is_rejected(): void
    {
        $this->stubJwks();

        // Valid structure and claims, but the signature does not match the
        // published key. This is the forgery the whole design exists to stop.
        $other = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
        $otherKey = null;
        openssl_pkey_export($other, $otherKey);

        $forged = JWT::encode([
            'iss' => GoogleAuthService::ISSUER,
            'aud' => self::CLIENT_ID,
            'sub' => 'attacker',
            'email' => 'attacker@evil.test',
            'email_verified' => true,
            'exp' => time() + 3600,
        ], $otherKey, 'RS256', self::KID);

        $this->expectException(GoogleAuthException::class);

        $this->service()->verifyIdToken($forged);
    }

    public function test_alg_none_is_rejected_before_any_key_lookup(): void
    {
        $this->stubJwks();

        // Unsecured JWT: header claims "none" and there is no signature at all.
        $header = rtrim(strtr(base64_encode(json_encode(['alg' => 'none', 'kid' => self::KID])), '+/', '-_'), '=');
        $payload = rtrim(strtr(base64_encode(json_encode([
            'iss' => GoogleAuthService::ISSUER,
            'aud' => self::CLIENT_ID,
            'sub' => 'attacker',
            'email' => 'attacker@evil.test',
            'email_verified' => true,
            'exp' => time() + 3600,
        ])), '+/', '-_'), '=');

        $this->expectException(GoogleAuthException::class);
        $this->expectExceptionMessageMatches('/RS256/');

        $this->service()->verifyIdToken($header.'.'.$payload.'.');
    }

    public function test_hmac_alg_is_rejected(): void
    {
        $this->stubJwks();

        $this->expectException(GoogleAuthException::class);

        $this->service()->verifyIdToken($this->token(alg: 'HS256'));
    }

    public function test_token_for_a_different_client_id_is_rejected(): void
    {
        $this->stubJwks();

        $this->expectException(GoogleAuthException::class);
        $this->expectExceptionMessageMatches('/different application/');

        $this->service()->verifyIdToken($this->token(['aud' => 'some-other-app.apps.googleusercontent.com']));
    }

    public function test_expired_token_is_rejected(): void
    {
        $this->stubJwks();

        $this->expectException(GoogleAuthException::class);

        $this->service()->verifyIdToken($this->token([
            'iat' => time() - 7200,
            'exp' => time() - 3600,
        ]));
    }

    public function test_token_within_the_skew_allowance_is_accepted(): void
    {
        $this->stubJwks();

        // 30s expired — inside the 60s clock-skew allowance.
        $profile = $this->service()->verifyIdToken($this->token([
            'iat' => time() - 3600,
            'exp' => time() - 30,
        ]));

        $this->assertSame('kiran@example.com', $profile['email']);
    }

    public function test_unverified_google_email_is_rejected(): void
    {
        $this->stubJwks();

        $this->expectException(GoogleAuthException::class);
        $this->expectExceptionMessageMatches('/has not verified/');

        $this->service()->verifyIdToken($this->token(['email_verified' => false]));
    }

    public function test_non_google_issuer_is_rejected(): void
    {
        $this->stubJwks();

        $this->expectException(GoogleAuthException::class);
        $this->expectExceptionMessageMatches('/issuer/');

        $this->service()->verifyIdToken($this->token(['iss' => 'https://evil.test']));
    }

    public function test_malformed_token_is_rejected(): void
    {
        $this->stubJwks();

        $this->expectException(GoogleAuthException::class);
        $this->expectExceptionMessageMatches('/Malformed/');

        $this->service()->verifyIdToken('not-a-jwt');
    }

    public function test_token_missing_sub_is_rejected(): void
    {
        $this->stubJwks();

        $claims = [
            'iss' => GoogleAuthService::ISSUER,
            'aud' => self::CLIENT_ID,
            'email' => 'kiran@example.com',
            'email_verified' => true,
            'exp' => time() + 3600,
        ];

        $this->expectException(GoogleAuthException::class);
        $this->expectExceptionMessageMatches('/subject/');

        $this->service()->verifyIdToken(
            JWT::encode($claims, self::$privateKey, 'RS256', self::KID)
        );
    }

    /* ---------------------------------------------------------------------
     | JWKS availability — must fail closed
     | ------------------------------------------------------------------ */

    public function test_unreachable_jwks_fails_closed_rather_than_skipping_verification(): void
    {
        Http::fake([
            GoogleAuthService::JWKS_URI => Http::response('boom', 500),
        ]);

        $this->expectException(GoogleAuthException::class);

        $this->service()->verifyIdToken($this->token());
    }

    public function test_empty_jwks_is_rejected(): void
    {
        Http::fake([
            GoogleAuthService::JWKS_URI => Http::response(['keys' => []]),
        ]);

        $this->expectException(GoogleAuthException::class);
        $this->expectExceptionMessageMatches('/unusable signing key set/');

        $this->service()->verifyIdToken($this->token());
    }

    /* ---------------------------------------------------------------------
     | key rotation
     | ------------------------------------------------------------------ */

    public function test_unknown_kid_triggers_exactly_one_refetch(): void
    {
        // Cached keys contain only the old kid; the served set is current.
        $this->stubJwks('rotated-key-2');

        $token = $this->token(kid: 'rotated-key-2');

        $profile = $this->service()->verifyIdToken($token);
        $this->assertSame('kiran@example.com', $profile['email']);

        // The rotation should not have hammered the endpoint.
        Http::assertSentCount(1);
    }

    public function test_jwks_is_cached_between_calls(): void
    {
        $this->stubJwks();

        $this->service()->verifyIdToken($this->token());
        $this->service()->verifyIdToken($this->token());

        Http::assertSentCount(1);
    }

    /* ---------------------------------------------------------------------
     | tenant lock
     | ------------------------------------------------------------------ */

    public function test_workspace_domain_lock_rejects_other_tenants(): void
    {
        $this->stubJwks();
        config(['sportx.google.hd' => 'sportx.in']);

        $this->expectException(GoogleAuthException::class);
        $this->expectExceptionMessageMatches('/not permitted/');

        $this->service()->verifyIdToken($this->token(['hd' => 'someone-else.com']));
    }

    public function test_workspace_domain_lock_accepts_the_configured_tenant(): void
    {
        $this->stubJwks();
        config(['sportx.google.hd' => 'sportx.in']);

        $profile = $this->service()->verifyIdToken($this->token(['hd' => 'sportx.in']));

        $this->assertSame('kiran@example.com', $profile['email']);
    }

    /* ---------------------------------------------------------------------
     | configuration guard
     | ------------------------------------------------------------------ */

    public function test_missing_client_id_fails_closed(): void
    {
        config(['sportx.google.client_id' => '']);

        $this->expectException(GoogleAuthException::class);
        $this->expectExceptionMessageMatches('/not configured/');

        $this->service()->verifyIdToken($this->token());
    }
}