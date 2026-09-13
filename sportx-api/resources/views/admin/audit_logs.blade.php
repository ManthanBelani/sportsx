@extends('admin.layouts.app')
@section('title', 'Audit Log')

@section('content')
<style>
.audit-stats { display:grid; grid-template-columns: repeat(5,1fr); gap:12px; margin-bottom:16px; }
.audit-stat { background:#fff; border:1px solid #e5e7eb; border-radius:12px; padding:14px; text-align:center; }
.audit-stat b { display:block; font-size:20px; font-weight:700; color:#111827; }
.audit-stat span { font-size:11px; font-weight:600; text-transform:uppercase; color:#6b7280; letter-spacing:.5px; }
@media(max-width:860px){ .audit-stats{ grid-template-columns: repeat(3,1fr);} }
@media(max-width:560px){ .audit-stats{ grid-template-columns: repeat(2,1fr);} }
.action-badge { padding:4px 8px; border-radius:6px; font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.3px; }
.action-badge.create { background:#dcfce7; color:#166534; }
.action-badge.update { background:#dbeafe; color:#1e40af; }
.action-badge.delete { background:#fee2e2; color:#991b1b; }
.type-badge { background:#f3f4f6; color:#374151; padding:3px 8px; border-radius:6px; font-size:11px; font-weight:600; }
</style>

<div class="audit-stats">
  <div class="audit-stat"><b>{{ number_format($stats['total']) }}</b><span>Total events</span></div>
  <div class="audit-stat"><b>{{ number_format($stats['today']) }}</b><span>Today</span></div>
  <div class="audit-stat"><b style="color:#166534">{{ number_format($stats['creates']) }}</b><span>Creates</span></div>
  <div class="audit-stat"><b style="color:#1e40af">{{ number_format($stats['updates']) }}</b><span>Updates</span></div>
  <div class="audit-stat"><b style="color:#991b1b">{{ number_format($stats['deletes']) }}</b><span>Deletes</span></div>
</div>

<div class="card no-pad" style="margin-bottom:16px;">
  <form method="GET" class="search-bar" style="gap:10px;">
    <div class="search-input" style="flex:1;">
      <i data-lucide="search" style="width:16px;height:16px;color:#9ca3af;"></i>
      <input type="text" name="q" value="{{ request('q') }}" placeholder="Search label, user, type, route...">
    </div>
    <select class="select" name="action" style="width:140px;">
      <option value="">All actions</option>
      @foreach($actions as $a)<option value="{{ $a }}" @if(request('action')===$a) selected @endif>{{ ucfirst($a) }}</option>@endforeach
    </select>
    <select class="select" name="auditable_type" style="width:160px;">
      <option value="">All types</option>
      @foreach($types as $t)<option value="{{ $t }}" @if(request('auditable_type')===$t) selected @endif>{{ $t }}</option>@endforeach
    </select>
    <input class="input" type="date" name="from" value="{{ request('from') }}" style="width:150px;">
    <input class="input" type="date" name="to" value="{{ request('to') }}" style="width:150px;">
    <button class="btn btn-primary">Filter</button>
    <a href="{{ route('admin.audit.logs') }}" class="btn btn-ghost">Reset</a>
  </form>
</div>

<div class="card no-pad">
  <div class="card-header"><span class="card-title">Every DB operation</span><span class="header-badge">{{ $logs->total() }} records</span></div>
  <div class="table-scroll">
  <table class="table">
    <thead><tr><th>Time</th><th>User</th><th>Action</th><th>Type</th><th>Record</th><th>Changed fields</th><th>IP</th><th></th></tr></thead>
    <tbody>
      @forelse($logs as $log)
        <tr>
          <td style="white-space:nowrap;">
            <div style="font-size:13px; font-weight:500;">{{ $log->created_at->format('d M Y') }}</div>
            <div style="font-size:11px; color:#6b7280;">{{ $log->created_at->format('h:i A') }}</div>
          </td>
          <td>
            <div style="font-size:13px; font-weight:600;">{{ $log->user_name }}</div>
            <div style="font-size:11px; color:#6b7280;">{{ $log->user_role }} @if($log->user_id) #{{ $log->user_id }} @endif</div>
          </td>
          <td><span class="action-badge {{ $log->action }}">{{ $log->action }}</span></td>
          <td><span class="type-badge">{{ $log->auditable_type }}</span> <span style="font-size:11px; color:#6b7280;">#{{ $log->auditable_id }}</span></td>
          <td><div style="font-size:13px; font-weight:500; max-width:180px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="{{ $log->auditable_label }}">{{ $log->auditable_label }}</div><div style="font-size:11px; color:#6b7280; max-width:180px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">{{ $log->route }}</div></td>
          <td style="max-width:200px;">
            @if($log->changed_fields)
              <div style="display:flex; flex-wrap:wrap; gap:4px;">
                @foreach(array_slice($log->changed_fields,0,4) as $f)<span style="background:#f3f4f6; padding:2px 6px; border-radius:4px; font-size:11px;">{{ $f }}</span>@endforeach
                @if(count($log->changed_fields)>4)<span style="font-size:11px; color:#6b7280;">+{{ count($log->changed_fields)-4 }} more</span>@endif
              </div>
            @else <span style="font-size:11px; color:#9ca3af;">—</span> @endif
          </td>
          <td style="font-size:12px; color:#6b7280;">{{ $log->ip_address }}</td>
          <td><a href="{{ route('admin.audit.show', $log->id) }}" class="action-btn view"><i data-lucide="eye" style="width:12px;height:12px;"></i> View</a></td>
        </tr>
      @empty
        <tr><td colspan="8" class="empty">No audit events yet. Create/update/delete any record to see it here.<br><small style="color:#9ca3af;">Ensure <code>audit_log_enabled</code> is ON in Settings.</small></td></tr>
      @endforelse
    </tbody>
  </table>
  </div>
</div>
@if($logs->hasPages())<div class="pager">{{ $logs->links() }}</div>@endif
@endsection
