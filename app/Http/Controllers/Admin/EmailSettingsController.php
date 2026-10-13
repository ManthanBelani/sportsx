<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\MailProviderService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin API for inspecting and switching the transactional email provider.
 *
 * Credentials themselves live in the environment (never in the database); this
 * controller only exposes the *resolved* status so operators can tell which
 * provider is live and verify it end to end.
 *
 * @see \App\Services\MailProviderService
 * @see docs/Email-Provider-Architecture.md
 */
class EmailSettingsController extends Controller
{
    public function __construct(protected MailProviderService $mail)
    {}

    /**
     * GET /api/v1/admin/email-settings
     */
    public function show(): JsonResponse
    {
        return response()->json(['data' => $this->mail->status()]);
    }

    /**
     * GET /api/v1/admin/email-settings/diagnostics
     *
     * Deeper probe: authenticates against Gmail, opens an SMTP socket, and
     * reports the resolved failover chain. Slow enough that the UI should show
     * a spinner, which is why it is a separate endpoint from `show`.
     */
    public function diagnostics(): JsonResponse
    {
        return response()->json(['data' => $this->mail->diagnostics()]);
    }

    /**
     * POST /api/v1/admin/email-settings/provider
     *
     * Switch the active provider at runtime.
     */
    public function switchProvider(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'provider' => 'required|in:smtp,gmail',
        ]);

        $provider = $this->mail->setActiveProvider($validated['provider']);

        return response()->json([
            'data' => array_merge($this->mail->status(), [
                'message' => "Active email provider switched to {$provider}.",
            ]),
        ]);
    }

    /**
     * POST /api/v1/admin/email-settings/test
     *
     * Send a real test message through the chosen provider.
     */
    public function test(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'provider' => 'nullable|in:smtp,gmail',
            'recipient' => 'nullable|email',
        ]);

        $result = $this->mail->testConnection(
            $validated['provider'] ?? null,
            $validated['recipient'] ?? null,
        );

        return response()->json(['data' => $result], $result['ok'] ? 200 : 422);
    }

    /**
     * POST /api/v1/admin/email-settings/clear-token-cache
     *
     * Drop the cached Gmail OAuth2 access token after a credential rotation.
     */
    public function clearTokenCache(): JsonResponse
    {
        $this->mail->clearTokenCache();

        return response()->json([
            'data' => ['message' => 'Cached Gmail access token cleared.'],
        ]);
    }
}