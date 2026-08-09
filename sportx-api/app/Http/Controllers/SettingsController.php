<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class SettingsController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'data' => [
                'notification_prefs' => $user->notification_prefs ?? [
                    'email' => true,
                    'push' => true,
                    'sms' => false,
                    'in_app' => true,
                ],
                'language' => $user->language ?? 'en',
            ],
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'notification_prefs' => 'nullable|array',
            'notification_prefs.email' => 'boolean',
            'notification_prefs.push' => 'boolean',
            'notification_prefs.sms' => 'boolean',
            'notification_prefs.in_app' => 'boolean',
            'language' => 'nullable|in:en,hi',
        ]);

        $update = [];
        if (isset($validated['notification_prefs'])) {
            $existing = $user->notification_prefs ?? ['email' => true, 'push' => true, 'sms' => false, 'in_app' => true];
            $update['notification_prefs'] = array_merge($existing, $validated['notification_prefs']);
        }
        if (isset($validated['language'])) {
            $update['language'] = $validated['language'];
        }

        $user->update($update);

        return response()->json(['data' => [
            'notification_prefs' => $user->notification_prefs,
            'language' => $user->language,
        ]]);
    }

    public function updatePassword(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        abort_unless(Hash::check($validated['current_password'], $user->password), 401, 'Current password is incorrect');

        $user->update(['password' => Hash::make($validated['password'])]);

        return response()->json(['data' => ['message' => 'Password updated successfully']]);
    }

    public function destroy(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'password' => 'required|string',
        ]);

        abort_unless(Hash::check($validated['password'], $user->password), 401, 'Incorrect password');

        $user->delete();

        return response()->json(['data' => ['message' => 'Account deleted']], 200);
    }
}
