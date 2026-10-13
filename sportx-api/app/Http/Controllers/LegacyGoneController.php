<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;

/**
 * Legacy scholarship / sponsorship endpoints (Phase 4 cutover).
 *
 * Scholarships and sponsorships are unified under `opportunities` — every
 * legacy route answers 410 Gone with a machine-readable pointer so clients
 * (and the mobile app) can migrate instead of guessing.
 */
class LegacyGoneController extends Controller
{
    public function gone(): JsonResponse
    {
        return response()->json([
            'error' => [
                'code' => 'LEGACY_MOVED',
                'message' => 'Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead.',
                'replacement' => '/api/v1/opportunities',
            ],
        ], 410);
    }
}
