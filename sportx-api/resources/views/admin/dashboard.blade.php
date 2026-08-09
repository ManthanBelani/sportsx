@extends('admin.layouts.main')

@section('title', 'Dashboard')

@push('topbar-actions')
<span class="header-badge">Super Admin</span>
@endpush

@section('content')
<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-icon blue"><i data-lucide="users" style="width:22px;height:22px;color:#1677ff;"></i></div>
    <div class="stat-label">Total Users</div>
    <div class="stat-value" id="stat-users">-</div>
    <div class="stat-change up">↑ active players</div>
  </div>
  <div class="stat-card">
    <div class="stat-icon green"><i data-lucide="file-text" style="width:22px;height:22px;color:#16a34a;"></i></div>
    <div class="stat-label">Active Listings</div>
    <div class="stat-value" id="stat-listings">-</div>
    <div class="stat-change up">↑ steady growth</div>
  </div>
  <div class="stat-card">
    <div class="stat-icon orange"><i data-lucide="clock" style="width:22px;height:22px;color:#d97706;"></i></div>
    <div class="stat-label">Pending Expirations</div>
    <div class="stat-value" id="stat-pending">-</div>
    <div class="stat-change" style="color:#d97706;">Needs review</div>
  </div>
  <div class="stat-card">
    <div class="stat-icon red"><i data-lucide="alert-triangle" style="width:22px;height:22px;color:#dc2626;"></i></div>
    <div class="stat-label">Flagged Items</div>
    <div class="stat-value" id="stat-reports">-</div>
    <div class="stat-change">Requires action</div>
  </div>
</div>

<div class="grid-2">
  <div class="card">
    <div class="card-header">
      <span class="card-title"><i data-lucide="alert-circle"></i>Pending Alerts</span>
      <a href="{{ route('admin.reports') }}" class="see-all">View All</a>
    </div>
    
    <div id="recent-activity-container">
      <div style="text-align:center;padding:20px;color:#6b7280;font-size:14px;">Loading recent activity...</div>
    </div>
  </div>

  <div class="card">
    <div class="card-header">
      <span class="card-title"><i data-lucide="zap"></i>Quick Actions</span>
    </div>
    <div class="quick-action-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px;">
      <a href="{{ route('admin.moderation') }}" class="btn btn-outline" style="flex-direction:column;gap:8px;padding:16px;">
        <i data-lucide="clipboard-check" style="width:20px;height:20px;color:#6b7280;"></i>
        <div style="font-size:12px;font-weight:500;">Moderate</div>
      </a>
      <a href="{{ route('admin.users') }}" class="btn btn-outline" style="flex-direction:column;gap:8px;padding:16px;">
        <i data-lucide="users" style="width:20px;height:20px;color:#6b7280;"></i>
        <div style="font-size:12px;font-weight:500;">Users</div>
      </a>
      <a href="{{ route('admin.approvals') }}" class="btn btn-outline" style="flex-direction:column;gap:8px;padding:16px;">
        <i data-lucide="check-circle" style="width:20px;height:20px;color:#6b7280;"></i>
        <div style="font-size:12px;font-weight:500;">Approvals</div>
      </a>
      <a href="{{ route('admin.notifications.compose') }}" class="btn btn-outline" style="flex-direction:column;gap:8px;padding:16px;">
        <i data-lucide="bell" style="width:20px;height:20px;color:#6b7280;"></i>
        <div style="font-size:12px;font-weight:500;">Notify</div>
      </a>
    </div>
    
    <div class="card-header" style="margin-top: 24px; border-top: 1px solid #f0f0f0; padding-top: 16px;">
      <span class="card-title"><i data-lucide="pie-chart"></i>User Breakdown</span>
    </div>
    <div id="user-breakdown" style="display:flex; flex-direction:column; gap:12px;">
      <div style="display:flex; justify-content:space-between; align-items:center; padding-bottom:8px; border-bottom:1px solid #f0f0f0;">
        <div style="display:flex;align-items:center;gap:8px;"><i data-lucide="user" style="width:16px;height:16px;color:#6b7280;"></i> <span style="font-size:14px;">Athletes</span></div>
        <span style="font-weight:600;" id="breakdown-athletes">-</span>
      </div>
      <div style="display:flex; justify-content:space-between; align-items:center; padding-bottom:8px; border-bottom:1px solid #f0f0f0;">
        <div style="display:flex;align-items:center;gap:8px;"><i data-lucide="briefcase" style="width:16px;height:16px;color:#6b7280;"></i> <span style="font-size:14px;">Coaches</span></div>
        <span style="font-weight:600;" id="breakdown-coaches">-</span>
      </div>
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div style="display:flex;align-items:center;gap:8px;"><i data-lucide="building" style="width:16px;height:16px;color:#6b7280;"></i> <span style="font-size:14px;">Sponsors</span></div>
        <span style="font-weight:600;" id="breakdown-sponsors">-</span>
      </div>
    </div>
  </div>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;

    const res = await api('GET', '/dashboard');
    if (res.ok) {
        const d = res.data;
        document.getElementById('stat-users').textContent = (d.active_listings || 0).toLocaleString(); // mocked
        document.getElementById('stat-listings').textContent = (d.active_listings || 0).toLocaleString();
        document.getElementById('stat-pending').textContent = d.pending_expirations || 0;
        document.getElementById('stat-reports').textContent = d.flagged_items || 0;
        
        // Mocked breakdown since it's not in the response yet
        document.getElementById('breakdown-athletes').textContent = '24,150';
        document.getElementById('breakdown-coaches').textContent = '1,204';
        document.getElementById('breakdown-sponsors').textContent = '342';
        
        // Render recent activity alerts
        const container = document.getElementById('recent-activity-container');
        container.innerHTML = `
          <div style="display:flex; align-items:center; gap:14px; padding:14px 0; border-bottom:1px solid #f0f0f0;">
            <div style="width:40px;height:40px;border-radius:10px;background:#fee2e2;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                <i data-lucide="alert-triangle" style="width:20px;height:20px;color:#dc2626;"></i>
            </div>
            <div style="flex:1;min-width:0;">
                <div style="font-size:13px;font-weight:500;">Content report flagged for review</div>
                <div style="font-size:11px;color:#6b7280;margin-top:2px;">1 hour ago</div>
            </div>
            <span style="font-size:10px;padding:4px 10px;border-radius:6px;font-weight:500;background:#fee2e2;color:#dc2626;">Critical</span>
          </div>
          <div style="display:flex; align-items:center; gap:14px; padding:14px 0; border-bottom:1px solid #f0f0f0;">
            <div style="width:40px;height:40px;border-radius:10px;background:#fef3c7;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                <i data-lucide="clock" style="width:20px;height:20px;color:#d97706;"></i>
            </div>
            <div style="flex:1;min-width:0;">
                <div style="font-size:13px;font-weight:500;">New athlete registration: Priya Patel</div>
                <div style="font-size:11px;color:#6b7280;margin-top:2px;">2 mins ago</div>
            </div>
            <span style="font-size:10px;padding:4px 10px;border-radius:6px;font-weight:500;background:#fef3c7;color:#d97706;">Pending</span>
          </div>
          <div style="display:flex; align-items:center; gap:14px; padding:14px 0;">
            <div style="width:40px;height:40px;border-radius:10px;background:#dbeafe;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                <i data-lucide="sparkles" style="width:20px;height:20px;color:#1677ff;"></i>
            </div>
            <div style="flex:1;min-width:0;">
                <div style="font-size:13px;font-weight:500;">New academy added: Delhi Cricket Academy</div>
                <div style="font-size:11px;color:#6b7280;margin-top:2px;">15 mins ago</div>
            </div>
            <span style="font-size:10px;padding:4px 10px;border-radius:6px;font-weight:500;background:#dbeafe;color:#1677ff;">New</span>
          </div>
        `;
        lucide.createIcons();
    } else {
        document.getElementById('recent-activity-container').innerHTML = `<div style="text-align:center;padding:20px;color:#dc2626;font-size:14px;">Error loading data</div>`;
    }
});
</script>
@endpush
