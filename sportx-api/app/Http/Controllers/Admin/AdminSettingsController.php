<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Support\PlatformSettings;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * JSON API for the platform settings file (Phase 9/10 admin).
 *
 * The mobile System Settings screen reads/writes here; the legacy web panel
 * keeps its own form endpoint. Both share PlatformSettings as the single
 * source of truth for defaults and the writable key set.
 */
class AdminSettingsController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(['data' => ['settings' => PlatformSettings::effective()]]);
    }

    public function update(Request $request): JsonResponse
    {
        $rules = [];
        foreach (PlatformSettings::writable() as $key) {
            $rules[$key] = 'sometimes|boolean';
        }
        $validated = $request->validate($rules);

        $before = PlatformSettings::effective();
        $settings = PlatformSettings::update($validated);

        $changed = array_keys($validated);
        try {
            AuditLog::create([
                'user_id' => $request->user()?->id,
                'user_name' => $request->user()?->name ?? 'System',
                'user_role' => $request->user()?->role ?? 'system',
                'action' => 'settings.update',
                'auditable_type' => 'PlatformSettings',
                'auditable_id' => 0,
                'auditable_label' => implode(',', $changed) ?: 'settings',
                'old_values' => array_intersect_key($before, array_flip($changed)),
                'new_values' => $validated,
                'changed_fields' => $changed,
                'ip_address' => $request->ip(),
                'user_agent' => substr((string) $request->userAgent(), 0, 500),
                'route' => substr($request->path() ?? '', 0, 190),
            ]);
        } catch (\Throwable) {
            // Audit must never break the settings write.
        }

        return response()->json(['data' => ['settings' => $settings]]);
    }
}
