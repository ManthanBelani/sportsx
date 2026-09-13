<?php

namespace App\Traits;

use App\Models\AuditLog;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Request;

trait Auditable
{
    public static function bootAuditable(): void
    {
        static::created(function ($model) {
            self::recordAudit('create', $model);
        });

        static::updated(function ($model) {
            // Skip if only timestamps changed
            $changes = $model->getChanges();
            unset($changes['updated_at']);
            if (empty($changes)) return;
            self::recordAudit('update', $model);
        });

        static::deleted(function ($model) {
            self::recordAudit('delete', $model);
        });
    }

    protected static function recordAudit(string $action, $model): void
    {
        // Respect audit_log_enabled setting
        try {
            $path = storage_path('app/platform_settings.json');
            if (file_exists($path)) {
                $settings = json_decode((string) file_get_contents($path), true) ?: [];
                if (array_key_exists('audit_log_enabled', $settings) && $settings['audit_log_enabled'] === false) {
                    return;
                }
            }
        } catch (\Throwable $e) {}

        try {
            $user = Auth::user() ?? Request::user();
            $old = $action === 'update' ? array_intersect_key($model->getOriginal(), $model->getChanges()) : null;
            $new = $action === 'create' ? $model->getAttributes() : ($action === 'update' ? $model->getChanges() : $model->getAttributes());

            // Sanitize sensitive fields
            foreach (['password', 'remember_token', 'verification_token', 'reset_password_token'] as $s) {
                unset($old[$s], $new[$s]);
            }

            $label = $model->name ?? $model->title ?? $model->full_name ?? $model->organization_name ?? $model->brand_name ?? $model->email ?? ('#'.$model->getKey());

            AuditLog::create([
                'user_id' => $user?->id,
                'user_name' => $user?->name ?? 'System',
                'user_role' => $user?->role ?? 'system',
                'action' => $action,
                'auditable_type' => class_basename($model),
                'auditable_id' => $model->getKey(),
                'auditable_label' => substr((string) $label, 0, 190),
                'old_values' => $old ? array_map(fn($v) => is_scalar($v) || is_null($v) ? $v : json_encode($v), $old) : null,
                'new_values' => $new ? array_map(fn($v) => is_scalar($v) || is_null($v) ? $v : json_encode($v), $new) : null,
                'changed_fields' => $action === 'update' ? array_keys($model->getChanges()) : null,
                'ip_address' => Request::ip(),
                'user_agent' => substr((string) Request::userAgent(), 0, 500),
                'route' => substr(Request::path() ?? '', 0, 190),
            ]);
        } catch (\Throwable $e) {
            // Never break main operation on audit failure
            \Illuminate\Support\Facades\Log::warning('Audit log failed', ['error' => $e->getMessage()]);
        }
    }
}
