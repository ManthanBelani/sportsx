<?php

namespace App\Services\Support;

use ArrayAccess;
use Firebase\JWT\Key;
use OutOfBoundsException;
use UnexpectedValueException;

/**
 * A JWKS key set resolved once and held in memory.
 *
 * `JWT::decode()` accepts a `Key`, a `CachedKeySet`, or any `ArrayAccess`
 * keyed by `kid`, and calls `offsetGet($kid)`. Google's key set is fetched and cached upstream
 * by {@see \App\Services\GoogleAuthService}, so this class only has to map a
 * key id onto a parsed `Key`.
 *
 * Implemented here rather than using `CachedKeySet` so the JWKS fetch and its
 * cache policy stay in one readable place — `CachedKeySet` requires a PSR-6
 * pool, a PSR-18 client and a PSR-17 request factory, none of which this app
 * otherwise needs.
 *
 * @implements \ArrayAccess<string, \Firebase\JWT\Key>
 *
 * Deliberately does not extend `CachedKeySet`: that class requires a PSR-6 pool,
 * a PSR-18 client and a PSR-17 request factory, and it is given the
 * auto-refresh behaviour we do not want — the service handles a key rotation
 * with one deliberate refetch instead.
 */
class GoogleKeySet implements ArrayAccess
{
    /**
     * @param  array<string, Key>  $keys  keyed by `kid`
     */
    public function __construct(private array $keys) {}

    public static function fromJwks(array $jwks, string $algorithm): self
    {
        $keys = [];

        foreach ((array) ($jwks['keys'] ?? []) as $jwk) {
            if (! is_array($jwk) || empty($jwk['kid'])) {
                continue;
            }

            // parseKeySet enforces that the key material is a usable RSA key,
            // so malformed entries are rejected here rather than at verify time.
            $parsed = \Firebase\JWT\JWK::parseKeySet(
                ['keys' => [$jwk]],
                $algorithm,
            );

            if (isset($parsed[$jwk['kid']])) {
                $keys[$jwk['kid']] = $parsed[$jwk['kid']];
            }
        }

        return new self($keys);
    }

    public function offsetExists(mixed $offset): bool
    {
        return isset($this->keys[$offset]);
    }

    public function offsetGet(mixed $offset): Key
    {
        if (! isset($this->keys[$offset])) {
            // Raised for an unknown `kid`, which is how a Google key rotation
            // surfaces. The caller re-fetches the JWKS once before giving up.
            throw new OutOfBoundsException('Google signing key not found: '.$offset);
        }

        return $this->keys[$offset];
    }

    public function offsetSet(mixed $offset, mixed $value): void
    {
        $this->keys[$offset] = $value;
    }

    public function offsetUnset(mixed $offset): void
    {
        unset($this->keys[$offset]);
    }

    public function has(string $kid): bool
    {
        return isset($this->keys[$kid]);
    }

    public function count(): int
    {
        return count($this->keys);
    }
}