<?php

namespace App\Services;

use App\Exceptions\GoogleAuthException;
use App\Models\SocialAccount;
use App\Models\User;
use App\Services\Support\GoogleKeySet;
use App\Support\PlatformSettings;
use Firebase\JWT\JWT;
use Illuminate\Http\Client\Factory as HttpFactory;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * "Continue with Google" — ID token verification and account resolution.
 *
 * The mobile app holds a Google credential; this service proves that credential
 * is genuine and maps it to a SportX account.
 *
 * ## Verification
 *
 * Six checks, any of which aborts the request:
 *
 *  1. JWT structure and `alg` pinned to **RS256** — the algorithm is asserted
 *     rather than trusted from the header, which closes the HMAC-confusion
 *     class of attack.
 *  2. Signature verified against Google's published JWKS, fetched from
 *     `https://www.googleapis.com/oauth2/v3/certs` and cached.
 *  3. `aud` contains the configured `GOOGLE_CLIENT_ID` — a token minted for a
 *     different app must not authenticate here.
 *  4. `exp` in the future (60s clock-skew allowance).
 *  5. `email_verified` is true.
 *  6. `iss` is a Google issuer.
 *
 * Every failure path **fails closed**: a JWKS fetch error rejects the token
 * rather than skipping verification.
 *
 * ## Why `firebase/php-jwt` and not `google/auth`
 *
 * `google/auth` mints and refreshes *access tokens*; it has no ID-token
 * verifier. `firebase/php-jwt`'s `CachedKeySet` provides JWKS resolution with
 * caching, which is exactly what is needed here.
 *
 * @see \App\Http\Controllers\GoogleAuthController
 * @see docs/Google-Authentication.md
 */
class GoogleAuthService
{
    public const JWKS_URI = 'https://www.googleapis.com/oauth2/v3/certs';

    public const ISSUER = 'https://accounts.google.com';

    public const ALLOWED_ALGORITHM = 'RS256';

    /** Seconds of clock skew tolerated on `exp`. */
    public const LEEWAY_SECONDS = 60;

    public function __construct(protected HttpFactory $http) {}

    /* ---------------------------------------------------------------------
     | Verification
     | ------------------------------------------------------------------ */

    /**
     * Verify a Google ID token and return the verified profile.
     *
     * @return array{sub: string, email: string, email_verified: bool, name: ?string, picture: ?string}
     *
     * @throws \App\Exceptions\GoogleAuthException
     */
    public function verifyIdToken(string $idToken): array
    {
        $clientId = $this->clientId();

        $header = $this->decodeHeader($idToken);

        // (1) Reject anything that is not RS256 before touching a key.
        if (($header['alg'] ?? null) !== self::ALLOWED_ALGORITHM) {
            throw GoogleAuthException::make(
                'Unsupported algorithm. Expected RS256, got '.($header['alg'] ?? 'none').'.'
            );
        }

        if (empty($header['kid'])) {
            throw GoogleAuthException::make('Token is missing a key id (kid).');
        }

        try {
            // This php-jwt version validates only the signature and the
            // nbf/iat/exp time claims — it performs NO audience check. `aud`,
            // `iss` and `email_verified` are therefore verified below.
            // `$leeway` covers clock skew; there is no validator callback in
            // this signature (argument 3 is an output-only `?stdClass`).
            JWT::$leeway = self::LEEWAY_SECONDS;

            $claims = (array) JWT::decode($idToken, $this->keySet($idToken));

            $this->validateClaims($claims, $clientId);
        } catch (GoogleAuthException $e) {
            throw $e;
        } catch (\Throwable $e) {
            // Covers signature failure, expiry, malformed input and JWKS
            // unreachability alike — all of them must reject the token.
            throw GoogleAuthException::make('Token verification failed: '.$e->getMessage());
        }

        // (5) Google, not the user, must assert ownership of the mailbox.
        if (($claims['email_verified'] ?? false) !== true) {
            throw GoogleAuthException::make('Google has not verified this email address.');
        }

        $email = strtolower((string) ($claims['email'] ?? ''));

        if ($email === '' || ! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw GoogleAuthException::make('Token does not contain a valid email address.');
        }

        // Optional single-tenant lock (Google Workspace).
        $hd = config('sportx.google.hd');

        if (! empty($hd) && ($claims['hd'] ?? null) !== $hd) {
            throw GoogleAuthException::make('This account is not permitted to sign in.');
        }

        return [
            'sub' => (string) $claims['sub'],
            'email' => $email,
            'email_verified' => true,
            'name' => $claims['name'] ?? null,
            'picture' => $claims['picture'] ?? null,
        ];
    }

    /**
     * Claim checks applied after the signature has been proven.
     *
     * `exp`/`nbf`/`iat` are handled by php-jwt itself (with `$leeway` set
     * above), so this covers only what the library does not.
     *
     * @param  array<string, mixed>  $claims
     */
    protected function validateClaims(array $claims, string $clientId): void
    {
        // (3) Audience — the token must have been minted for *this* app.
        $audience = $claims['aud'] ?? null;

        $audiences = is_array($audience) ? $audience : [$audience];

        if (! in_array($clientId, $audiences, true)) {
            throw GoogleAuthException::make('Token was issued for a different application.');
        }

        // (6) Issuer — only Google mints these.
        $issuer = (string) ($claims['iss'] ?? '');

        if (! in_array($issuer, [self::ISSUER, 'accounts.google.com'], true)) {
            throw GoogleAuthException::make('Unexpected token issuer.');
        }

        if (! isset($claims['sub']) || $claims['sub'] === '') {
            throw GoogleAuthException::make('Token is missing a subject (sub) claim.');
        }
    }

    /**
     * Decode the JWT header without verifying it.
     *
     * Used only to read `alg` and `kid` so the right key can be selected — the
     * signature is still verified afterwards, so nothing here is trusted.
     *
     * @return array<string, mixed>
     */
    protected function decodeHeader(string $idToken): array
    {
        $parts = explode('.', $idToken);

        if (count($parts) !== 3) {
            throw GoogleAuthException::make('Malformed token: expected three JWT segments.');
        }

        $header = json_decode(
            (string) base64_decode(strtr($parts[0], '-_', '+/'), true),
            true
        );

        if (! is_array($header)) {
            throw GoogleAuthException::make('Malformed token header.');
        }

        return $header;
    }

    /**
     * JWKS key set, fetched from Google and cached for a day.
     *
     * An unknown `kid` (a Google key rotation) forces exactly one re-fetch
     * before the token is rejected, so a rotation never requires a redeploy and
     * never causes a permanent outage.
     */
    protected function keySet(string $jwt): GoogleKeySet
    {
        $keySet = $this->cachedKeySet();

        $header = $this->decodeHeader($jwt);
        $kid = $header['kid'] ?? '';

        if ($kid !== '' && ! $keySet->has($kid)) {
            // Key rotation: drop the cache and try once against fresh keys.
            Cache::forget($this->jwksCacheKey());
            $keySet = $this->cachedKeySet();
        }

        return $keySet;
    }

    protected function cachedKeySet(): GoogleKeySet
    {
        $jwks = Cache::remember($this->jwksCacheKey(), now()->addDay(), function () {
            $response = $this->http->timeout(10)->get(self::JWKS_URI);

            if ($response->failed()) {
                // Fail closed: an unreachable JWKS must never downgrade to
                // "skip verification".
                Log::error('Google JWKS fetch failed', [
                    'status' => $response->status(),
                ]);

                throw GoogleAuthException::make(
                    'Unable to reach Google to verify the token. Please try again.',
                    503,
                );
            }

            return $response->json();
        });

        $keySet = GoogleKeySet::fromJwks((array) $jwks, self::ALLOWED_ALGORITHM);

        if ($keySet->count() === 0) {
            throw GoogleAuthException::make('Google returned an unusable signing key set.', 503);
        }

        return $keySet;
    }

    protected function jwksCacheKey(): string
    {
        // Per audience, so switching clients cannot reuse a stale key set.
        return 'google.jwks.'.sha1($this->clientId());
    }

    /* ---------------------------------------------------------------------
     | Account resolution
     | ------------------------------------------------------------------ */

    /**
     * Map a verified Google profile onto a SportX account.
     *
     * Resolution order:
     *   1. A known `social_accounts` row  → sign in.
     *   2. A SportX account with a **verified** matching email → link and sign in.
     *   3. Otherwise create a new account (when signup is enabled).
     *
     * @param  array{sub: string, email: string, email_verified: bool, name: ?string, picture: ?string}  $profile
     * @return array{user: User, linked: bool, created: bool}
     */
    public function resolveAccount(array $profile, ?string $requestedRole = null): array
    {
        $existing = SocialAccount::forProvider(SocialAccount::PROVIDER_GOOGLE)
            ->where('provider_user_id', $profile['sub'])
            ->with('user')
            ->first();

        if ($existing && $existing->user) {
            $this->refreshSnapshot($existing, $profile);

            return ['user' => $existing->user, 'linked' => true, 'created' => false];
        }

        $user = User::where('email', $profile['email'])->first();

        if ($user) {
            // Only link to an account that has already proven control of this
            // address. Linking to an unverified account would let whoever
            // registered the address first capture the Google identity.
            if ($user->email_verified_at === null) {
                throw GoogleAuthException::make(
                    'This email is already registered but not verified. Verify it first, then sign in with Google.',
                    409,
                );
            }

            $this->linkIdentity($user, $profile);

            return ['user' => $user, 'linked' => true, 'created' => false];
        }

        if (! config('sportx.google.allow_signup', true)) {
            throw GoogleAuthException::make(
                'Sign-in with Google is not available for new accounts.',
                403,
            );
        }

        $user = $this->createUser($profile, $requestedRole);
        $this->linkIdentity($user, $profile, justCreated: true);

        return ['user' => $user, 'linked' => false, 'created' => true];
    }

    /**
     * Create a SportX account from a verified Google profile.
     *
     * The role is validated against `GOOGLE_ALLOWED_ROLES` — accepting an
     * arbitrary `role` from the client would be a privilege-escalation hole.
     */
    protected function createUser(array $profile, ?string $requestedRole): User
    {
        $allowed = (array) config('sportx.google.restrict_roles', ['athlete']);
        // Accept the canonical `scout` alias anywhere roles are accepted.
        $allowed = array_values(array_unique(array_merge(
            $allowed,
            in_array(\App\Support\UserRoles::TALENT_SCOUT, $allowed, true)
                ? [\App\Support\UserRoles::SCOUT]
                : [],
            in_array(\App\Support\UserRoles::SCOUT, $allowed, true)
                ? [\App\Support\UserRoles::TALENT_SCOUT]
                : [],
        )));

        $normalized = $requestedRole !== null
            ? (\App\Support\UserRoles::normalize($requestedRole) ?? $requestedRole)
            : null;

        if ($normalized === \App\Support\UserRoles::SPONSOR) {
            throw GoogleAuthException::make(
                'Sponsor accounts are no longer offered. Providers list scholarships and sponsorships as opportunities instead.',
                410,
            );
        }

        $role = $normalized && in_array($normalized, $allowed, true)
            ? \App\Support\UserRoles::toStorage($normalized)
            : (string) config('sportx.google.default_role', 'athlete');

        if ($requestedRole && ! in_array($normalized, $allowed, true)) {
            throw GoogleAuthException::make(
                "Role [{$requestedRole}] is not permitted for Google sign-up.",
                422,
            );
        }

        return User::create([
            'role' => $role,
            'name' => $profile['name'] ?? Str::before($profile['email'], '@'),
            'email' => $profile['email'],
            // Google verified it, so SportX treats it as verified too.
            'email_verified_at' => now(),
            'password' => null, // no credential — Google is the only identity
            // Single source of truth for the approval rule — see PlatformSettings.
            'status' => PlatformSettings::needsApproval($role) ? 'pending' : 'active',
        ]);
    }

    /**
     * Attach the Google identity to a user.
     */
    public function linkIdentity(User $user, array $profile, bool $justCreated = false): SocialAccount
    {
        return SocialAccount::updateOrCreate(
            [
                'provider' => SocialAccount::PROVIDER_GOOGLE,
                'provider_user_id' => $profile['sub'],
            ],
            [
                'user_id' => $user->id,
                'email' => $profile['email'],
                'name' => $profile['name'],
                'avatar_url' => $profile['picture'],
            ],
        );
    }

    /**
     * Keep the mirrored profile data current on a returning sign-in.
     */
    protected function refreshSnapshot(SocialAccount $account, array $profile): void
    {
        $account->forceFill(array_filter([
            'email' => $profile['email'],
            'name' => $profile['name'],
            'avatar_url' => $profile['picture'],
        ], fn ($value) => $value !== null))->save();
    }

    protected function clientId(): string
    {
        $clientId = (string) config('sportx.google.client_id', '');

        if ($clientId === '') {
            throw GoogleAuthException::make(
                'Google sign-in is not configured. Set GOOGLE_CLIENT_ID.'
            );
        }

        return $clientId;
    }
}