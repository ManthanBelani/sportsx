<?php

namespace App\Exceptions;

use Exception;

/**
 * A Google ID token could not be trusted, or an account could not be resolved.
 *
 * Carries an HTTP status so `GoogleAuthController` can return the documented
 * domain error code from `API-Specification.md` §21 without a mapping table.
 */
class GoogleAuthException extends Exception
{
    /**
     * @var array<string, mixed>
     */
    public array $context = [];

    /**
     * @param  array<string, mixed>  $context
     */
    public static function make(string $message, int $status = 401, array $context = []): self
    {
        $exception = new self($message, $status);
        $exception->context = $context;

        return $exception;
    }

    /**
     * The HTTP status this failure should surface as.
     */
    public function status(): int
    {
        return $this->getCode() >= 400 && $this->getCode() < 600
            ? $this->getCode()
            : 401;
    }
}