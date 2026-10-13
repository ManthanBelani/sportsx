<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * A code could not be handed to a delivery transport.
 *
 * Deliberately distinct from a plain `RuntimeException`: Symfony's
 * `HttpException` (raised by `abort()`) *extends* `RuntimeException`, so a
 * broad catch around a service call swallows rate-limit and validation aborts
 * and rewrites them as delivery failures.
 */
class OtpDeliveryException extends RuntimeException {}