@extends('admin.layouts.app')
@section('title', 'Review Queue')
@section('header-actions')
  <span class="header-badge warning">{{ $approvalCounts['users'] + $approvalCounts['trials'] + $approvalCounts['tournaments'] + $counts['pending'] }} Pending</span>
@endsection

@section('content')
@push('styles')
<style>
  .approval-tabs{display:flex;gap:4px;margin-bottom:12px;background:#fff;padding:4px;border-radius:10px;border:1px solid #e5e7eb;width:fit-content;}
  .approval-tab{padding:7px 12px;border-radius:8px;font-size:12px;font-weight:600;border:none;background:none;cursor:pointer;color:#6b7280;display:flex;gap:6px;align-items:center;}
  .approval-tab.active{background:#111;color:#fff;}
  .approval-tab .cnt{background:#e5e7eb;padding:2px 6px;border-radius:20px;font-size:11px;}
  .approval-tab.active .cnt{background:rgba(255,255,255,0.2);}
  .approval-pane{display:none;}
  .approval-pane.active{display:block;}
</style>
@endpush

{{-- Unified Approvals (merged) --}}
<div class="card no-pad">
  <div class="card-header"><span class="card-title"><i data-lucide="check-circle" style="width:16px;height:16px;color:#16a34a;"></i> Pending Approvals</span><span style="font-size:11px;color:#6b7280;">Auto-approve: coach {{ ($settings['auto_approve_coach'] ?? false) ? 'ON' : 'OFF' }} · sponsor {{ ($settings['auto_approve_sponsor'] ?? false) ? 'ON' : 'OFF' }} · trials {{ ($settings['auto_approve_trials'] ?? false) ? 'ON' : 'OFF' }} · <a href="{{ route('admin.settings') }}" style="color:#1677ff;">Settings</a></span></div>
  <div style="padding:12px 16px;">
    <div class="approval-tabs">
      <button class="approval-tab active" data-tab="users" onclick="switchApprovalTab('users')">Users <span class="cnt">{{ $approvalCounts['users'] }}</span></button>
      <button class="approval-tab" data-tab="trials" onclick="switchApprovalTab('trials')">Trials <span class="cnt">{{ $approvalCounts['trials'] }}</span></button>
      <button class="approval-tab" data-tab="tournaments" onclick="switchApprovalTab('tournaments')">Tournaments <span class="cnt">{{ $approvalCounts['tournaments'] }}</span></button>
    </div>
  </div>

  {{-- Users --}}
  <div id="pane-users" class="approval-pane active" style="padding:0 16px 16px;">
    @forelse($pendingUsers as $u)
      <div class="card no-pad" style="margin-bottom:10px;">
        <div class="listing-header">
          <div class="user-avatar" style="width:40px;height:40px;"><i data-lucide="user" style="width:18px;height:18px;"></i></div>
          <div class="listing-info">
            <div class="listing-name">{{ $u->name }} <span class="badge {{ $u->role }}" style="margin-left:6px;">{{ ucfirst(str_replace('_',' ', $u->role)) }}</span></div>
            <div class="listing-meta">{{ $u->email }} • {{ $u->created_at?->diffForHumans() }}</div>
          </div>
          <span class="badge pending">Pending</span>
        </div>
        <div class="listing-body" style="display:flex;gap:8px;">
          <form method="POST" action="{{ route('admin.approvals.users.approve', $u->id) }}" style="flex:1;">@csrf<button class="action-btn approve" style="width:100%;justify-content:center;"><i data-lucide="check" style="width:14px;height:14px;"></i> Approve</button></form>
          <form method="POST" action="{{ route('admin.approvals.users.reject', $u->id) }}" style="flex:1;" onsubmit="return confirm('Reject this registration?')">@csrf<button class="action-btn reject" style="width:100%;justify-content:center;"><i data-lucide="x" style="width:14px;height:14px;"></i> Reject</button></form>
          <a href="{{ route('admin.users.detail', $u->id) }}" class="action-btn view"><i data-lucide="eye" style="width:14px;height:14px;"></i> View</a>
        </div>
      </div>
    @empty
      <div class="empty" style="padding:20px;">No pending user approvals 🎉</div>
    @endforelse
    @if($pendingUsers->hasPages())<div class="pager">{{ $pendingUsers->links() }}</div>@endif
  </div>

  {{-- Trials --}}
  <div id="pane-trials" class="approval-pane" style="padding:0 16px 16px;">
    @forelse($pendingTrials as $t)
      <div class="card no-pad" style="margin-bottom:10px;">
        <div class="listing-header">
          <div class="listing-img"><i data-lucide="target" style="width:22px;height:22px;color:#d97706;"></i></div>
          <div class="listing-info">
            <div class="listing-name">{{ $t->name }}</div>
            <div class="listing-meta"><i data-lucide="map-pin" style="width:12px;height:12px;"></i> {{ $t->venue }} @if($t->city) • {{ $t->city->name }} @endif • {{ $t->event_datetime?->format('d M Y') }}</div>
          </div>
          <span class="badge pending">Draft</span>
        </div>
        <div class="listing-body">
          <div class="listing-desc">{{ \Illuminate\Support\Str::limit($t->eligibility ?? 'No details', 100) }}</div>
          <div class="listing-actions">
            <form method="POST" action="{{ route('admin.approvals.trials.approve', $t->id) }}">@csrf<button class="action-btn approve"><i data-lucide="check" style="width:14px;height:14px;"></i> Approve & Publish</button></form>
            <form method="POST" action="{{ route('admin.approvals.trials.reject', $t->id) }}" onsubmit="return confirm('Reject this trial?')">@csrf<button class="action-btn reject"><i data-lucide="x" style="width:14px;height:14px;"></i> Reject</button></form>
          </div>
        </div>
      </div>
    @empty
      <div class="empty" style="padding:20px;">No trials awaiting approval 🎉</div>
    @endforelse
    @if($pendingTrials->hasPages())<div class="pager">{{ $pendingTrials->links() }}</div>@endif
  </div>

  {{-- Tournaments --}}
  <div id="pane-tournaments" class="approval-pane" style="padding:0 16px 16px;">
    @forelse($pendingTournaments as $tm)
      <div class="card no-pad" style="margin-bottom:10px;">
        <div class="listing-header">
          <div class="listing-img" style="background:#fef3c7;"><i data-lucide="trophy" style="width:22px;height:22px;color:#d97706;"></i></div>
          <div class="listing-info">
            <div class="listing-name">{{ $tm->name }}</div>
            <div class="listing-meta"><i data-lucide="map-pin" style="width:12px;height:12px;"></i> {{ $tm->venue }} @if($tm->city) • {{ $tm->city->name }} @endif • {{ $tm->start_date?->format('d M Y') }}</div>
          </div>
          <span class="badge pending">Draft</span>
        </div>
        <div class="listing-body">
          <div class="listing-desc">{{ \Illuminate\Support\Str::limit($tm->rules ?? $tm->prize_pool ?? 'No details', 100) }}</div>
          <div class="listing-actions">
            <form method="POST" action="{{ route('admin.approvals.tournaments.approve', $tm->id) }}">@csrf<button class="action-btn approve"><i data-lucide="check" style="width:14px;height:14px;"></i> Approve & Publish</button></form>
            <form method="POST" action="{{ route('admin.approvals.tournaments.reject', $tm->id) }}" onsubmit="return confirm('Reject this tournament?')">@csrf<button class="action-btn reject"><i data-lucide="x" style="width:14px;height:14px;"></i> Reject</button></form>
          </div>
        </div>
      </div>
    @empty
      <div class="empty" style="padding:20px;">No tournaments awaiting approval 🎉</div>
    @endforelse
    @if($pendingTournaments->hasPages())<div class="pager">{{ $pendingTournaments->links() }}</div>@endif
  </div>
</div>

{{-- Reports --}}
<div class="card no-pad">
  <div class="card-header"><span class="card-title"><i data-lucide="flag" style="width:16px;height:16px;color:#dc2626;"></i> Reported Content</span></div>
  <div style="padding:12px 16px;">
    <div class="tabs">
      @foreach(['pending'=>'Pending','approved'=>'Resolved','removed'=>'Removed/Warned','all'=>'All'] as $key => $label)
        <a class="tab {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.moderation', ['status' => $key]) }}">{{ $label }} ({{ number_format($counts[$key]) }})</a>
      @endforeach
    </div>
  </div>
  <div style="padding:0 16px 16px;">
    @forelse($reports as $r)
      @php $reportable = $r->reportable; @endphp
      <div class="card no-pad" style="margin-bottom:10px;">
        <div class="listing-header">
          <div class="listing-img"><i data-lucide="file-text" style="width:22px;height:22px;color:#1677ff;"></i></div>
          <div class="listing-info">
            <div class="listing-name">{{ $reportable?->name ?? $reportable?->full_name ?? class_basename($r->reportable_type ?? 'Listing').' #'.$r->reportable_id }}</div>
            <div class="listing-meta"><i data-lucide="flag" style="width:12px;height:12px;"></i> {{ $r->reason ?: 'Reported' }} • {{ $r->created_at?->diffForHumans() }}</div>
          </div>
          @if($r->status === 'pending')<span class="listing-flagged"><i data-lucide="alert-triangle" style="width:12px;height:12px;"></i> Flagged</span>@else <span class="badge active">{{ $r->status }}</span>@endif
        </div>
        <div class="listing-body">
          <div class="listing-desc">{{ $r->comment ?: 'No additional detail.' }}</div>
          @if($r->status === 'pending')
          <div class="listing-actions">
            <a href="{{ route('admin.content') }}" class="action-btn view"><i data-lucide="eye"></i> View</a>
            <form method="POST" action="{{ route('admin.moderation.action', $r->id) }}">@csrf<input type="hidden" name="action" value="approve"><button class="action-btn approve"><i data-lucide="check"></i> Approve</button></form>
            <form method="POST" action="{{ route('admin.moderation.action', $r->id) }}">@csrf<input type="hidden" name="action" value="remove"><button class="action-btn reject" onclick="return confirm('Remove this listing?')"><i data-lucide="x"></i> Reject & Remove</button></form>
          </div>
          @endif
        </div>
      </div>
    @empty
      <div class="empty">No listings awaiting moderation 🎉</div>
    @endforelse
    @if($reports->hasPages())<div class="pager">{{ $reports->links() }}</div>@endif
  </div>
</div>

@push('scripts')
<script>
function switchApprovalTab(name){
  document.querySelectorAll('.approval-tab').forEach(el=>el.classList.toggle('active', el.dataset.tab===name));
  document.querySelectorAll('.approval-pane').forEach(el=>el.classList.toggle('active', el.id==='pane-'+name));
  lucide.createIcons();
}
</script>
@endpush
@endsection
