@extends('admin.layouts.app')
@section('title', 'Analytics')

@section('content')
  @php $verifiedRate = $totalUsers ? round(\App\Models\User::whereNotNull('email_verified_at')->count() / $totalUsers * 100) : 0; @endphp
  <div class="stat-grid">
    <div class="stat-card"><div class="stat-label">Total Users</div><div class="stat-value">{{ number_format($totalUsers) }}</div><div class="stat-change up">All time</div></div>
    <div class="stat-card"><div class="stat-label">Active Listings</div><div class="stat-value">{{ number_format($activeListings) }}</div><div class="stat-change">Published</div></div>
    <div class="stat-card"><div class="stat-label">Signups This Month</div><div class="stat-value">{{ number_format($monthlySignups) }}</div><div class="stat-change up">↑ current month</div></div>
    <div class="stat-card"><div class="stat-label">Verified Rate</div><div class="stat-value">{{ $verifiedRate }}%</div><div class="stat-change">Email-verified users</div></div>
  </div>

  <div class="card">
    <div class="card-header"><div><div class="card-title">User Growth</div><div class="card-subtitle">New registrations over the past 6 months</div></div></div>
    <div class="chart-area">
      @foreach($growth as $label => $count)
        <div class="chart-bar" style="height: {{ max(8, round($count / $growthMax * 100)) }}%;"></div>
      @endforeach
    </div>
    <div class="chart-labels">
      @foreach($growth as $label => $count)<span class="chart-label">{{ $label }}</span>@endforeach
    </div>
  </div>

  <div class="grid-2">
    <div class="card no-pad">
      <div class="card-header"><span class="card-title">Top Sports by Trials</span></div>
      <table class="table">
        <thead><tr><th>#</th><th>Sport</th><th>Trials</th></tr></thead>
        <tbody>
          @foreach($topSports as $i => $sport)
            <tr><td><span class="rank-badge">{{ $i+1 }}</span></td>
              <td><div class="sport-cell"><div class="sport-icon"><i data-lucide="circle" style="width:14px;height:14px;color:#1677ff;"></i></div>{{ $sport->name }}</div></td>
              <td>{{ number_format($sport->cnt) }}</td></tr>
          @endforeach
        </tbody>
      </table>
    </div>
    <div class="card no-pad">
      <div class="card-header"><span class="card-title">User Role Distribution</span></div>
      <table class="table">
        <thead><tr><th>Role</th><th>Count</th><th>Share</th></tr></thead>
        <tbody>
          @foreach(['athlete'=>'#d97706','coach'=>'#1677ff','academy'=>'#16a34a','organizer'=>'#4338ca','sponsor'=>'#9333ea','admin'=>'#6b7280'] as $role => $color)
            @php $cnt = $roleDistribution[$role] ?? 0; @endphp
            <tr><td><span style="color:{{ $color }};font-weight:500;">●</span> {{ ucfirst($role) }}s</td>
              <td>{{ number_format($cnt) }}</td>
              <td>{{ $totalUsers ? round($cnt / $totalUsers * 100) : 0 }}%</td></tr>
          @endforeach
        </tbody>
      </table>
    </div>
  </div>
@endsection
