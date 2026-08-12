@extends('admin.layouts.app')
@section('title', 'Dashboard')

@section('content')
  <div class="stat-grid">
    <div class="stat-card">
      <div class="stat-icon blue"><i data-lucide="users" style="width:22px;height:22px;color:#1677ff;"></i></div>
      <div class="stat-label">Total Users</div>
      <div class="stat-value">{{ number_format($stats['total_users']) }}</div>
      <div class="stat-change up">↑ {{ $stats['new_signups_30d'] }} new in 30 days</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon green"><i data-lucide="file-text" style="width:22px;height:22px;color:#16a34a;"></i></div>
      <div class="stat-label">Active Listings</div>
      <div class="stat-value">{{ number_format($stats['active_listings']) }}</div>
      <div class="stat-change">Published across directories</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon orange"><i data-lucide="clock" style="width:22px;height:22px;color:#d97706;"></i></div>
      <div class="stat-label">Pending Reviews</div>
      <div class="stat-value">{{ number_format(\App\Models\ListingReport::where('status','pending')->count()) }}</div>
      <div class="stat-change" style="color:#d97706;">Awaiting moderation</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon red"><i data-lucide="alert-triangle" style="width:22px;height:22px;color:#dc2626;"></i></div>
      <div class="stat-label">Reports Filed</div>
      <div class="stat-value">{{ number_format(\App\Models\ListingReport::count()) }}</div>
      <div class="stat-change">All time</div>
    </div>
  </div>

  <div class="grid-2">
    <div class="card">
      <div class="card-header">
        <span class="card-title"><i data-lucide="alert-circle"></i>Pending Alerts</span>
        <a href="{{ route('admin.reports') }}" class="see-all">View All</a>
      </div>
      @forelse($pendingReports as $r)
        @php $morphName = class_basename($r->reportable_type ?? 'Listing'); @endphp
        <div class="alert-card">
          <div class="alert-icon danger"><i data-lucide="alert-triangle" style="width:20px;height:20px;color:#dc2626;"></i></div>
          <div class="alert-content">
            <div class="alert-title">{{ $r->reason ?: 'Report on '.$morphName.' #'.$r->reportable_id }}</div>
            <div class="alert-meta">{{ \Illuminate\Support\Str::limit($r->comment ?? 'No comment', 60) }} • {{ $r->created_at?->diffForHumans() }}</div>
          </div>
          <span class="alert-badge pending">Pending</span>
        </div>
      @empty
        <div class="empty">No pending alerts 🎉</div>
      @endforelse
    </div>

    <div class="card">
      <div class="card-header"><span class="card-title"><i data-lucide="zap"></i>Quick Actions</span></div>
      <div class="quick-action-grid">
        <a href="{{ route('admin.moderation') }}" class="quick-action"><div class="quick-action-icon"><i data-lucide="clipboard-check" style="width:20px;height:20px;color:#6b7280;"></i></div><div class="quick-action-label">Moderate</div></a>
        <a href="{{ route('admin.users') }}" class="quick-action"><div class="quick-action-icon"><i data-lucide="users" style="width:20px;height:20px;color:#6b7280;"></i></div><div class="quick-action-label">Users</div></a>
        <a href="{{ route('admin.analytics') }}" class="quick-action"><div class="quick-action-icon"><i data-lucide="bar-chart-2" style="width:20px;height:20px;color:#6b7280;"></i></div><div class="quick-action-label">Analytics</div></a>
        <a href="{{ route('admin.settings') }}" class="quick-action"><div class="quick-action-icon"><i data-lucide="settings" style="width:20px;height:20px;color:#6b7280;"></i></div><div class="quick-action-label">Settings</div></a>
      </div>
    </div>
  </div>

  <div class="card">
    <div class="card-header"><span class="card-title"><i data-lucide="trending-up"></i>Weekly Activity</span></div>
    <div class="bar-chart">
      @foreach($weekly as $day => $count)
        <div class="bar-group">
          <div class="bar {{ $loop->last ? 'highlight' : '' }}" style="height: max(20px, {{ round($count / $weekMax * 100) }}%);"></div>
          <span class="bar-label">{{ $day }}</span>
        </div>
      @endforeach
    </div>
    <div class="chart-stats">
      <div class="chart-stat"><div class="chart-stat-value">{{ $weekSignups }}</div><div class="chart-stat-label">Signups (7d)</div></div>
      <div class="chart-stat"><div class="chart-stat-value">{{ number_format($stats['active_listings']) }}</div><div class="chart-stat-label">Live Listings</div></div>
      <div class="chart-stat"><div class="chart-stat-value">{{ number_format($stats['total_users']) }}</div><div class="chart-stat-label">Total Users</div></div>
    </div>
  </div>
@endsection
