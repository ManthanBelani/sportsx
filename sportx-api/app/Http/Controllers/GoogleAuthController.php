<?php

namespace App\Http\Controllers;

use App\Exceptions\GoogleAuthException;
use App\Mail\WelcomeMail;
use App\Services\GoogleAuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

/**
 * "Continue with Google" sign-in and account linking.
 *
 * The mobile app obtains a Google ID token natively and hands it to the
 * backend, which verifies it. There is no server-side OAuth redirect, and the
 * backend never trusts any identity claim the client sends — only the token.
 *
 * @see \App\Services\GoogleAuthService
 * @see docs/Google-Authentication.md
 * @see docs/API-Specification.md §1
 */
class GoogleAuthController extends Controller
{
    public function __construct(protected GoogleAuthService $google) {}

    /**
     * POST /auth/google
     *
     * Verifies the ID token, then creates or links a SportX account and issues
     * a Sanctum token.
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id_token' => ['required', 'string', 'min:20'],
            // Validated against GOOGLE_ALLOWED_ROLES inside the service — an
            // unvalidated role would be a privilege-escalation hole.
            'role' => ['nullable', 'string'],
        ]);

        try {
            $profile = $this->google->verifyIdToken($validated['id_token']);

            $resolved = $this->google->resolveAccount($profile, $validated['role'] ?? null);
        } catch (GoogleAuthException $e) {
            return response()->json([
                'error' => [
                    'code' => $this->errorCode($e),
                    'message' => $e->getMessage(),
                ],
            ], $e->status());
        }

        /** @var \App\Models\User $user */
        $user = $resolved['user'];

        /*
         * Approval gate.
         *
         * On *creation* the account is handed a token with `pending_approval`
         * set, matching `/auth/register`: the applicant needs a session to see
         * the pending screen and their submission.
         *
         * On *returning* sign-in a pending account is refused outright, so
         * Google can never become a way around the gate.
         */
        if ($user->status === 'pending' && ! $resolved['created']) {
            return response()->json([
                'error' => [
                    'code' => 'PENDING_APPROVAL',
                    'message' => 'Your account is pending admin approval. You will be able to sign in once an admin approves your registration.',
                ],
            ], 403);
        }

        if (! in_array($user->status, ['active', 'pending'], true)) {
            return response()->json([
                'error' => [
                    'code' => 'ACCOUNT_DISABLED',
                    'message' => 'Account is '.$user->status.'. Contact support.',
                ],
            ], 403);
        }

        if ($resolved['created']) {
            Mail::to($user->email)->queue(new WelcomeMail($user));
        }

        return response()->json([
            'token' => $user->createToken('auth_token')->plainTextToken,
            'user' => $this->userResource($user),
            'needs_onboarding' => ! $user->hasRoleProfile(),
            'pending_approval' => $user->status === 'pending',
            'linked' => $resolved['linked'],
            'created' => $resolved['created'],
        ]);
    }

    /**
     * GET /me/social-accounts
     *
     * The identities currently linked to the caller's account.
     */
    public function index(Request $request): JsonResponse
    {
        $accounts = $request->user()
            ->socialAccounts()
            ->get()
            ->map(fn ($account) => [
                'provider' => $account->provider,
                'email' => $account->email,
                'name' => $account->name,
                'avatar_url' => $account->avatar_url,
                'linked_at' => $account->created_at?->toIso8601String(),
            ]);

        return response()->json(['data' => $accounts]);
    }

    /**
     * DELETE /me/social-accounts/{provider}
     *
     * Refuses to remove the last remaining credential — otherwise the user
     * locks themselves out permanently, since a Google-only account has no
     * password.
     */
    public function destroy(Request $request, string $provider): JsonResponse
    {
        $user = $request->user();

        $account = $user->socialAccounts()->where('provider', $provider)->first();

        if (! $account) {
            return response()->json([
                'error' => ['code' => 'NOT_FOUND', 'message' => 'No such linked account.'],
            ], 404);
        }

        if ($user->password === null && $user->socialAccounts()->count() <= 1) {
            return response()->json([
                'error' => [
                    'code' => 'LAST_CREDENTIAL',
                    'message' => 'Set a password before unlinking, or you will not be able to sign in.',
                ],
            ], 422);
        }

        $account->delete();

        return response()->json(['data' => ['message' => 'Account unlinked.']]);
    }

    /**
     * Map an exception to one of the documented domain error codes.
     */
    protected function errorCode(GoogleAuthException $e): string
    {
        return match ($e->status()) {
            403 => 'SIGNUP_DISABLED',
            409 => 'EMAIL_UNVERIFIED',
            422 => 'INVALID_ROLE',
            503 => 'GOOGLE_UNAVAILABLE',
            default => 'INVALID_ID_TOKEN',
        };
    }

    protected function userResource(\App\Models\User $user): array
    {
        return [
            'id' => $user->id,
            'role' => $user->role,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'email_verified_at' => $user->email_verified_at?->toIso8601String(),
            'status' => $user->status,
            'social_links' => $user->social_links,
            'is_verified' => $user->isVerified(),
        ];
    }
}