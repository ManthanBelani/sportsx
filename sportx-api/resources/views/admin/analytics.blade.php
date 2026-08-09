@extends('admin.layouts.main')

@section('title', 'Analytics')

@section('content')
<style>
  .stat-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 24px; }
  .stat-card { background: #fff; border-radius: 12px; padding: 20px; border: 1px solid #e5e7eb; }
  .stat-label { font-size: 13px; color: #6b7280; margin-bottom: 4px; font-weight: 500; }
  .stat-value { font-size: 32px; font-weight: 700; color: #111; }
  .stat-change { font-size: 12px; color: #16a34a; margin-top: 4px; }
  .card { background: #fff; border-radius: 12px; padding: 20px; border: 1px solid #e5e7eb; margin-bottom: 24px; }
  .card-header { margin-bottom: 20px; }
  .card-title { font-size: 16px; font-weight: 600; margin-bottom: 4px; }
  .card-subtitle { font-size: 13px; color: #6b7280; }
  .chart-area { height: 200px; display: flex; align-items: flex-end; gap: 8px; padding-top: 20px; }
  .chart-bar { flex: 1; background: linear-gradient(180deg, #1677ff 0%, #dbeafe 100%); border-radius: 6px 6px 0 0; min-height: 30px; transition: height 0.5s; }
  .chart-labels { display: flex; justify-content: space-between; margin-top: 8px; }
  .chart-label { font-size: 11px; color: #6b7280; flex: 1; text-align: center;}
  .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
  .table { width: 100%; border-collapse: collapse; }
  .table th { text-align: left; padding: 10px 12px; font-size: 11px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 1px solid #e5e7eb; }
  .table td { padding: 12px; font-size: 13px; border-bottom: 1px solid #f0f0f0; }
  .rank-badge { width: 24px; height: 24px; background: #f0f7ff; border-radius: 6px; display: inline-flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; color: #1677ff; }
  .sport-cell { display: flex; align-items: center; gap: 8px; }
  .sport-icon { width: 28px; height: 28px; background: #f0f7ff; border-radius: 6px; display: flex; align-items: center; justify-content: center; }
</style>

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-label">Total Users</div>
    <div class="stat-value" id="stat-total-users">48,291</div>
    <div class="stat-change">↑ 12% vs last month</div>
  </div>
  <div class="stat-card">
    <div class="stat-label">Active Listings</div>
    <div class="stat-value" id="stat-active-listings">2,847</div>
    <div class="stat-change">↑ 8% vs last month</div>
  </div>
  <div class="stat-card">
    <div class="stat-label">Monthly Signups</div>
    <div class="stat-value">1,247</div>
    <div class="stat-change">↑ 23% vs last month</div>
  </div>
  <div class="stat-card">
    <div class="stat-label">Engagement Rate</div>
    <div class="stat-value">68%</div>
    <div class="stat-change">↑ 4% vs last month</div>
  </div>
</div>

<div class="card">
  <div class="card-header">
    <div>
      <div class="card-title">User Growth</div>
      <div class="card-subtitle">New registrations over the past 6 months</div>
    </div>
  </div>
  <div class="chart-area">
    <div class="chart-bar" style="height: 60%;"></div>
    <div class="chart-bar" style="height: 75%;"></div>
    <div class="chart-bar" style="height: 65%;"></div>
    <div class="chart-bar" style="height: 85%;"></div>
    <div class="chart-bar" style="height: 95%;"></div>
    <div class="chart-bar" style="height: 100%;"></div>
  </div>
  <div class="chart-labels">
    <span class="chart-label">Feb</span>
    <span class="chart-label">Mar</span>
    <span class="chart-label">Apr</span>
    <span class="chart-label">May</span>
    <span class="chart-label">Jun</span>
    <span class="chart-label">Jul</span>
  </div>
</div>

<div class="grid-2">
  <div class="card">
    <div class="card-header">
      <div class="card-title">Top Sports by Engagement</div>
    </div>
    <table class="table">
      <thead>
        <tr>
          <th>#</th>
          <th>Sport</th>
          <th>Users</th>
          <th>Growth</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><span class="rank-badge">1</span></td>
          <td><div class="sport-cell"><div class="sport-icon"><i data-lucide="circle" style="width:14px;height:14px;color:#1677ff;"></i></div>Football</div></td>
          <td>12,847</td>
          <td style="color:#16a34a;">↑ 15%</td>
        </tr>
        <tr>
          <td><span class="rank-badge">2</span></td>
          <td><div class="sport-cell"><div class="sport-icon"><i data-lucide="circle" style="width:14px;height:14px;color:#16a34a;"></i></div>Cricket</div></td>
          <td>11,203</td>
          <td style="color:#16a34a;">↑ 8%</td>
        </tr>
        <tr>
          <td><span class="rank-badge">3</span></td>
          <td><div class="sport-cell"><div class="sport-icon"><i data-lucide="circle" style="width:14px;height:14px;color:#d97706;"></i></div>Badminton</div></td>
          <td>8,451</td>
          <td style="color:#16a34a;">↑ 12%</td>
        </tr>
        <tr>
          <td><span class="rank-badge">4</span></td>
          <td><div class="sport-cell"><div class="sport-icon"><i data-lucide="circle" style="width:14px;height:14px;color:#9333ea;"></i></div>Athletics</div></td>
          <td>6,782</td>
          <td style="color:#16a34a;">↑ 5%</td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="card">
    <div class="card-header">
      <div class="card-title">User Role Distribution</div>
    </div>
    <table class="table">
      <thead>
        <tr>
          <th>Role</th>
          <th>Count</th>
          <th>Share</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><span style="color:#d97706;font-weight:500;">●</span> Athletes</td>
          <td>32,451</td>
          <td>67%</td>
        </tr>
        <tr>
          <td><span style="color:#1677ff;font-weight:500;">●</span> Coaches</td>
          <td>8,234</td>
          <td>17%</td>
        </tr>
        <tr>
          <td><span style="color:#16a34a;font-weight:500;">●</span> Academies</td>
          <td>4,521</td>
          <td>9%</td>
        </tr>
        <tr>
          <td><span style="color:#9333ea;font-weight:500;">●</span> Sponsors</td>
          <td>2,156</td>
          <td>4%</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;
    
    // Fetch live dashboard data
    const res = await api('GET', '/dashboard');
    if (res.ok) {
        const d = res.data;
        // In a real app we'd map this, for MVP we can just update a couple
        document.getElementById('stat-total-users').textContent = (d.active_listings * 5 || '48,291').toLocaleString();
        document.getElementById('stat-active-listings').textContent = (d.active_listings || '2,847').toLocaleString();
    }
});
</script>
@endpush
