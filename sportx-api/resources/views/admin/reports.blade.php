@extends('admin.layouts.app')
@section('title', 'Report Center')
@section('header-actions')
  <span class="header-badge warning">{{ number_format($pendingCount) }} Pending</span>
@endsection

@section('content')
  @forelse($reports as $r)
    @php $morphName = class_basename($r->reportable_type ?? 'Item'); @endphp
    <div class="card no-pad">
      <div class="report-row-head">
        <div class="report-type" style="background:{{ $r->status==='pending'?'#fef3c7':($r->status==='removed' || $r->status==='warned'?'#fee2e2':'#dcfce7') }};"><i data-lucide="flag" style="width:20px;height:20px;color:{{ $r->status==='pending'?'#d97706':($r->status==='removed' || $r->status==='warned'?'#dc2626':'#16a34a') }};"></i></div>
        <div class="report-info">
          <div class="report-title">{{ $r->reason ?: 'Report on '.$morphName.' #'.$r->reportable_id }}</div>
          <div class="report-meta">Filed {{ $r->created_at?->diffForHumans() }} • By {{ $r->reporter?->name ?? ('User #'.($r->reporter_user_id ?? 'Anon')) }}</div>
        </div>
        <span class="report-badge {{ $r->status==='pending'?'pending':($r->status==='removed'?'critical':($r->status==='warned'?'critical':'resolved')) }}">{{ ucfirst($r->status) }}</span>
      </div>
      <div class="card-body">
        <div class="report-detail">{{ $r->comment ?: 'No additional detail.' }}</div>
        <div class="report-target"><i data-lucide="users" style="width:14px;height:14px;color:#6b7280;"></i> Target: {{ $morphName }} #{{ $r->reportable_id }}</div>
        <div class="action-bar">
          @if($r->status === 'pending')
            <form method="POST" action="{{ route('admin.reports.action', $r->id) }}">@csrf<input type="hidden" name="action" value="resolve"><button class="action-btn resolve"><i data-lucide="check"></i> Resolve</button></form>
            <form method="POST" action="{{ route('admin.reports.action', $r->id) }}">@csrf<input type="hidden" name="action" value="escalate"><button class="action-btn escalate"><i data-lucide="alert-triangle"></i> Escalate</button></form>
          @endif
          <a href="{{ route('admin.reports.detail', $r->id) }}" class="action-btn view"><i data-lucide="eye"></i> View</a>
        </div>
      </div>
    </div>
  @empty
    <div class="card empty">No reports.</div>
  @endforelse
  @if($reports->hasPages())<div class="pager">{{ $reports->links() }}</div>@endif
@endsection
