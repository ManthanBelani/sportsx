<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

/**
 * Validates an organizer's external registration URL.
 *
 * Only absolute http(s) links are accepted — the "Register" button opens the
 * link in the device browser, so anything else (javascript:, ftp:, a bare
 * domain without a scheme) is rejected with a clear message.
 */
class ExternalRegistrationUrl implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if ($value === null || $value === '') {
            return; // optional field
        }

        if (! is_string($value)) {
            $fail('The external registration URL must be a valid link.');

            return;
        }

        $url = trim($value);
        $parts = parse_url($url);

        if ($parts === false || empty($parts['scheme']) || empty($parts['host'])) {
            $fail('The external registration URL must be a valid link starting with http:// or https://.');

            return;
        }

        if (! in_array(strtolower($parts['scheme']), ['http', 'https'], true)) {
            $fail('The external registration URL must start with http:// or https://.');
        }
    }
}
