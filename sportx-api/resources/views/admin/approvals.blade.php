@extends('admin.layouts.app')
@section('title', 'Approvals')
@section('header-actions')
  <span class="header-badge" style="background:#fef3c7;color:#d97706;">{{ $counts['users'] + $counts['trials'] + $counts['tournaments'] }} Pending</span>
@endsection

@section('content')
@push('styles')
<style>
  .approval-tabs{display:flex;gap:4px;margin-bottom:20px;background:#fff;padding:4px;border-radius:10px;border:1px solid #e5e7eb;width:fit-content;}
  .approval-tab{padding:8px 14px;border-radius:8px;font-size:13px;font-weight:500;border:none;background:none;cursor:pointer;color:#6b7280;display:flex;gap:6px;align-items:center;}
  .approval-tab.active{background:#111;color:#fff;}
  .approval-tab .cnt{background:rgba(0,0,0,0.08);padding:2px 7px;border-radius:20px;font-size:11px;}
  .approval-tab.active .cnt{background:rgba(255,255,255,0.2);}
  .approval-pane{display:none;}
  .approval-pane.active{display:block;}
</style>
@endpush

<div class="approval-tabs">
  <button class="approval-tab active" data-tab="users" onclick="switchTab('users')">Users <span class="cnt">{{ $counts['users'] }}</span></button>
  <button class="approval-tab" data-tab="trials" onclick="switchTab('trials')">Trials <span class="cnt">{{ $counts['trials'] }}</span></button>
  <button class="approval-tab" data-tab="tournaments" onclick="switchTab('tournaments')">Tournaments <span class="cnt">{{ $counts['tournaments'] }}</span></button>
</div>

{{-- Auto-approve toggles hint --}}
<div class="card" style="padding:14px 18px;display:flex;align-items:center;justify-content:space-between;gap:12px;background:#f9fafb;">
  <div style="font-size:13px;color:#374151;"><i data-lucide="settings" style="width:14px;height:14px;vertical-align:middle;"></i> Auto-approve is <strong>{{ ($settings['auto_approve_coach'] ? 'ON' : 'OFF') }}</strong> for coaches, <strong>{{ ($settings['auto_approve_sponsor'] ? 'ON' : 'OFF') }}</strong> for sponsors, <strong>{{ ($settings['auto_approve_trials'] ? 'ON' : 'OFF') }}</strong> for trials. Change in <a href="{{ route('admin.settings') }}" style="color:#1677ff;text-decoration:underline;">Settings</a>.</div>
</div>

{{-- Users --}}
<div id="pane-users" class="approval-pane active">
  @forelse($pendingUsers as $u)
    <div class="card no-pad">
      <div class="listing-header">
        <div class="user-avatar" style="width:44px;height:44px;"><i data-lucide="user" style="width:20px;height:20px;"></i></div>
        <div class="listing-info">
          <div class="listing-name">{{ $u->name }} <span class="badge {{ $u->role }}" style="margin-left:8px;">{{ ucfirst(str_replace('_',' ',$u->role)) }}</span></div>
          <div class="listing-meta">{{ $u->email }} • Joined {{ $u->created_at?->diffForHumans() }}</div>
        </div>
        <span class="badge pending">Pending</span>
      </div>
      <div class="listing-body" style="display:flex;gap:10px;">
        <form method="POST" action="{{ route('admin.approvals.users.approve', $u->id) }}" style="flex:1;">@csrf<button class="action-btn approve" style="width:100%;justify-content:center;"><i data-lucide="check" style="width:14px;height:14px;"></i> Approve</button></form>
        <form method="POST" action="{{ route('admin.approvals.users.reject', $u->id) }}" style="flex:1;" onsubmit="return confirm('Reject this registration?')">@csrf<button class="action-btn reject" style="width:100%;justify-content:center;"><i data-lucide="x" style="width:14px;height:14px;"></i> Reject</button></form>
        <a href="{{ route('admin.users.detail', $u->id) }}" class="action-btn view" style="flex:0 0 auto;"><i data-lucide="eye" style="width:14px;height:14px;"></i> View</a>
      </div>
    </div>
  @empty
    <div class="card empty">No pending user approvals 🎉</div>
  @endforelse
  @if($pendingUsers->hasPages())<div class="pager">{{ $pendingUsers->links() }}</div>@endif
</div>

{{-- Trials --}}
<div id="pane-trials" class="approval-pane">
  @forelse($pendingTrials as $t)
    <div class="card no-pad">
      <div class="listing-header">
        <div class="listing-img"><i data-lucide="target" style="width:24px;height:24px;color:#d97706;"></i></div>
        <div class="listing-info">
          <div class="listing-name">{{ $t->name }}</div>
          <div class="listing-meta"><i data-lucide="map-pin" style="width:12px;height:12px;"></i> {{ $t->venue }} @if($t->city) • {{ $t->city->name }} @endif • {{ $t->event_datetime?->format('d M Y') }} @if($t->sport) • {{ $t->sport->name }} @endif</div>
        </div>
        <span class="badge pending">Draft</span>
      </div>
      <div class="listing-body">
        <div class="listing-desc">{{ \Illuminate\Support\Str::limit($t->eligibility ?? $t->benefits ?? 'No description', 120) }}</div>
        <div class="listing-actions">
          <form method="POST" action="{{ route('admin.approvals.trials.approve', $t->id) }}">@csrf<button class="action-btn approve"><i data-lucide="check" style="width:14px;height:14px;"></i> Approve & Publish</button></form>
          <form method="POST" action="{{ route('admin.approvals.trials.reject', $t->id) }}" onsubmit="return confirm('Reject this trial?')">@csrf<button class="action-btn reject"><i data-lucide="x" style="width:14px;height:14px;"></i> Reject</button></form>
          <a href="{{ route('admin.content.list', 'trials') }}" class="action-btn view"><i data-lucide="eye" style="width:14px;height:14px;"></i> All Trials</a>
        </div>
      </div>
    </div>
  @empty
    <div class="card empty">No trials awaiting approval 🎉</div>
  @endforelse
  @if($pendingTrials->hasPages())<div class="pager">{{ $pendingTrials->links() }}</div>@endif
</div>

{{-- Tournaments --}}
<div id="pane-tournaments" class="approval-pane">
  @forelse($pendingTournaments as $tm)
    <div class="card no-pad">
      <div class="listing-header">
        <div class="listing-img" style="background:#fef3c7;"><i data-lucide="trophy" style="width:24px;height:24px;color:#d97706;"></i></div>
        <div class="listing-info">
          <div class="listing-name">{{ $tm->name }}</div>
          <div class="listing-meta"><i data-lucide="map-pin" style="width:12px;height:12px;"></i> {{ $tm->venue }} @if($tm->city) • {{ $tm->city->name }} @endif • {{ $tm->start_date?->format('d M Y') }} @if($tm->sport) • {{ $tm->sport->name }} @endif</div>
        </div>
        <span class="badge pending">Draft</span>
      </div>
      <div class="listing-body">
        <div class="listing-desc">{{ \Illuminate\Support\Str::limit($tm->rules ?? $tm->prize_pool ?? 'No details', 120) }}</div>
        <div class="listing-actions">
          <form method="POST" action="{{ route('admin.approvals.tournaments.approve', $tm->id) }}">@csrf<button class="action-btn approve"><i data-lucide="check" style="width:14px;height:14px;"></i> Approve & Publish</button></form>
          <form method="POST" action="{{ route('admin.approvals.tournaments.reject', $tm->id) }}" onsubmit="return confirm('Reject this tournament?')">@csrf<button class="action-btn reject"><i data-lucide="x" style="width:14px;height:14px;"></i> Reject</button></form>
          <a href="{{ route('admin.content.list', 'tournaments') }}" class="action-btn view"><i data-lucide="eye" style="width:14px;height:14px;"></i> All Tournaments</a>
        </div>
      </div>
    </div>
  @empty
    <div class="card empty">No tournaments awaiting approval 🎉</div>
  @endforelse
  @if($pendingTournaments->hasPages())<div class="pager">{{ $pendingTournaments->links() }}</div>@endif
</div>

@push('scripts')
<script>
function switchTab(name){
  document.querySelectorAll('.approval-tab').forEach(el=>el.classList.toggle('active', el.dataset.tab===name));
  document.querySelectorAll('.approval-pane').forEach(el=>el.classList.toggle('active', el.id==='pane-'+name));
  lucide.createIcons();
}
</script>
@endpush
@endsection
