@extends('admin.layouts.app')
@section('title', 'Audit #'.$log->id)
@section('header-actions')
  <a href="{{ route('admin.audit.logs') }}" class="btn btn-ghost">← Back to log</a>
@endsection

@section('content')
<div class="card">
  <div class="card-header"><span class="card-title">Audit #{{ $log->id }} — {{ ucfirst($log->action) }} {{ $log->auditable_type }} #{{ $log->auditable_id }}</span><span class="header-badge">{{ $log->created_at->format('d M Y h:i A') }}</span></div>
  <div class="grid-2" style="gap:16px; margin-bottom:16px;">
    <div><div style="font-size:11px; color:#6b7280; text-transform:uppercase; font-weight:600;">Actor</div><div style="font-weight:600;">{{ $log->user_name }} <span style="color:#6b7280; font-weight:400;">({{ $log->user_role }} @if($log->user_id)#{{ $log->user_id }}@endif)</span></div></div>
    <div><div style="font-size:11px; color:#6b7280; text-transform:uppercase; font-weight:600;">Request</div><div style="font-family:monospace; font-size:13px;">{{ $log->route }} — {{ $log->ip_address }}</div><div style="font-size:11px; color:#6b7280; overflow:hidden; text-overflow:ellipsis;">{{ $log->user_agent }}</div></div>
    <div><div style="font-size:11px; color:#6b7280; text-transform:uppercase; font-weight:600;">Record</div><div style="font-weight:600;">{{ $log->auditable_label }}</div><div style="font-size:12px; color:#6b7280;">{{ $log->auditable_type }} #{{ $log->auditable_id }}</div></div>
    <div><div style="font-size:11px; color:#6b7280; text-transform:uppercase; font-weight:600;">Changed fields</div><div>@if($log->changed_fields) @foreach($log->changed_fields as $f)<span style="background:#f3f4f6; padding:2px 6px; border-radius:4px; font-size:11px; margin-right:4px;">{{ $f }}</span>@endforeach @else — @endif</div></div>
  </div>

  <div class="grid-2">
    <div>
      <div style="font-size:13px; font-weight:700; margin-bottom:8px;">Old values</div>
      <pre style="background:#f9fafb; border:1px solid #e5e7eb; border-radius:8px; padding:12px; font-size:12px; overflow:auto; max-height:400px;">{{ $log->old_values ? json_encode($log->old_values, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE) : '—' }}</pre>
    </div>
    <div>
      <div style="font-size:13px; font-weight:700; margin-bottom:8px;">New values</div>
      <pre style="background:#f0fdf4; border:1px solid #bbf7d0; border-radius:8px; padding:12px; font-size:12px; overflow:auto; max-height:400px;">{{ $log->new_values ? json_encode($log->new_values, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE) : '—' }}</pre>
    </div>
  </div>
</div>
@endsection
