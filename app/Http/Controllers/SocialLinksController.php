<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

/**
 * Social media links for every role (athlete, coach, academy, organizer,
 * sponsor, talent_scout, admin). Stored once on users.social_links as
 * {instagram, facebook, youtube, x, linkedin, website} and surfaced wherever
 * the user relation is embedded in profile payloads.
 *
 * GET /me/social-links | PUT /me/social-links  (auth:sanctum)
 */
class SocialLinksController extends Controller
{
    public const PLATFORMS = ['instagram', 'facebook', 'youtube', 'x', 'linkedin', 'website'];

    public function show(Request $request)
    {
        return response()->json(['data' => self::forUser($request->user())]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'social_links' => 'nullable|array',
            'social_links.*' => 'nullable|string|max:500',
            // Flat aliases: {instagram: "...", ...} accepted alongside social_links{...}.
            'instagram' => 'nullable|string|max:500',
            'facebook' => 'nullable|string|max:500',
            'youtube' => 'nullable|string|max:500',
            'x' => 'nullable|string|max:500',
            'linkedin' => 'nullable|string|max:500',
            'website' => 'nullable|string|max:500',
        ]);

        $input = $validated['social_links'] ?? [];
        foreach (self::PLATFORMS as $platform) {
            if (array_key_exists($platform, $validated) && $validated[$platform] !== null) {
                $input[$platform] = $validated[$platform];
            }
        }

        $links = [];
        $errors = [];
        foreach (self::PLATFORMS as $platform) {
            $raw = $input[$platform] ?? null;
            if ($raw === null || trim((string) $raw) === '') {
                continue;
            }
            $normalized = $this->normalize((string) $raw);
            if (! $this->isValidUrl($normalized)) {
                $errors[$platform] = "The {$platform} link must be a valid URL.";
                continue;
            }
            $links[$platform] = $normalized;
        }

        if (! empty($errors)) {
            return response()->json([
                'message' => 'Invalid social links.',
                'errors' => $errors,
            ], 422);
        }

        $user = $request->user();
        $user->update(['social_links' => $links ?: null]);

        return response()->json(['data' => self::forUser($user->fresh())]);
    }

    /**
     * Normalized {platform: url|null} map for a user. Used by profile
     * payloads so every role exposes links without extra queries.
     */
    public static function forUser($user): array
    {
        $links = $user?->social_links ?? [];
        $out = [];
        foreach (self::PLATFORMS as $platform) {
            $out[$platform] = $links[$platform] ?? null;
        }

        return $out;
    }

    /**
     * Attach a top-level `social_links` attribute to a profile model/array
     * payload for the given owner user.
     */
    public static function attach($profile, $user)
    {
        if ($profile instanceof \Illuminate\Database\Eloquent\Model) {
            $profile->setAttribute('social_links', self::forUser($user));
        } elseif (is_array($profile)) {
            $profile['social_links'] = self::forUser($user);
        }

        return $profile;
    }

    private function present($user): array
    {
        return self::forUser($user);
    }

    /**
     * Accept "instagram.com/xyz" and "@handle"-style input; store full https URLs.
     */
    private function normalize(string $raw): string
    {
        $value = trim($raw);
        $value = ltrim($value, '@');

        if (! preg_match('~^[a-z][a-z0-9+.-]*://~i', $value)) {
            $value = 'https://'.$value;
        }

        return $value;
    }

    private function isValidUrl(string $value): bool
    {
        if (strlen($value) > 500) {
            return false;
        }

        return (bool) preg_match('~^https?://[^\s/$.?#].[^\s]*$~i', $value);
    }
}
