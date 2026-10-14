<?php

namespace App\Http\Controllers;

use App\Services\NotificationService;
use Illuminate\Http\Request;

/**
 * GET/PUT /me/notification-preferences.
 * account_action + registration_* rows are HARD OVERRIDES: always in-app +
 * email, so the API refuses to disable them instead of showing toggles
 * that silently do nothing.
 */
class NotificationPreferenceController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();

        return response()->json(['data' => [
            'prefs' => NotificationService::prefsFor($user),
            'hard_overrides' => NotificationService::HARD_OVERRIDE_TYPES,
            'hard_override_note' => 'Account decisions and registration outcomes always notify (in-app + email) and cannot be disabled.',
        ]]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'push' => 'nullable|boolean',
            'in_app' => 'nullable|boolean',
            'categories' => 'nullable|array',
            'categories.people' => 'nullable|boolean',
            'categories.opportunities' => 'nullable|boolean',
            'categories.events' => 'nullable|boolean',
            'categories.mentions' => 'nullable|boolean',
            'categories.reminders' => 'nullable|boolean',
            'categories.broadcasts' => 'nullable|boolean',
        ]);

        $user = $request->user();
        $current = NotificationService::prefsFor($user);

        $next = $current;
        foreach (['push', 'in_app'] as $k) {
            if (array_key_exists($k, $validated)) {
                $next[$k] = (bool) $validated[$k];
            }
        }
        if (isset($validated['categories'])) {
            foreach ($validated['categories'] as $cat => $val) {
                if (in_array($cat, NotificationService::CATEGORIES, true)) {
                    $next['categories'][$cat] = (bool) $val;
                }
            }
        }

        $user->forceFill(['notification_prefs' => $next])->save();

        return response()->json(['data' => [
            'prefs' => $next,
            'hard_overrides' => NotificationService::HARD_OVERRIDE_TYPES,
        ]]);
    }
}
