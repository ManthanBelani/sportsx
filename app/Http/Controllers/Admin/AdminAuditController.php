<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\Request;

class AdminAuditController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->only(['q', 'action', 'auditable_type', 'user_id']);

        $query = AuditLog::with('user')->latest();

        if ($request->filled('q')) {
            $q = $request->q;
            $query->where(function ($b) use ($q) {
                $b->where('auditable_label', 'like', "%{$q}%")
                  ->orWhere('auditable_type', 'like', "%{$q}%")
                  ->orWhere('user_name', 'like', "%{$q}%")
                  ->orWhere('action', 'like', "%{$q}%")
                  ->orWhere('route', 'like', "%{$q}%");
            });
        }
        if ($request->filled('action')) {
            $query->where('action', $request->action);
        }
        if ($request->filled('auditable_type')) {
            $query->where('auditable_type', $request->auditable_type);
        }
        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->to);
        }

        $logs = $query->paginate(25)->appends($request->query());

        $actions = AuditLog::select('action')->distinct()->pluck('action');
        $types = AuditLog::select('auditable_type')->distinct()->pluck('auditable_type');

        $stats = [
            'total' => AuditLog::count(),
            'today' => AuditLog::whereDate('created_at', today())->count(),
            'creates' => AuditLog::where('action', 'create')->count(),
            'updates' => AuditLog::where('action', 'update')->count(),
            'deletes' => AuditLog::where('action', 'delete')->count(),
        ];

        return view('admin.audit_logs', compact('logs', 'actions', 'types', 'stats', 'filters'));
    }

    public function show($id)
    {
        $log = AuditLog::with('user')->findOrFail($id);
        return view('admin.audit_log_detail', ['log' => $log]);
    }
}
