@extends('admin.layouts.main')

@section('title', 'Report Center')

@push('topbar-actions')
<span class="header-badge" id="reports-badge" style="background:#fef3c7; color:#d97706; padding:4px 12px; border-radius:20px; font-weight:500; font-size:12px;">Loading...</span>
@endpush

@section('content')
<style>
  .card { background: #fff; border-radius: 12px; border: 1px solid #e5e7eb; margin-bottom: 16px; overflow: hidden; }
  .card-header { padding: 16px 20px; border-bottom: 1px solid #f0f0f0; display: flex; align-items: center; gap: 14px; }
  .report-type { width: 40px; height: 40px; background: #f0f7ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; }
  .report-info { flex: 1; }
  .report-title { font-size: 14px; font-weight: 600; }
  .report-meta { font-size: 12px; color: #6b7280; margin-top: 2px; }
  .report-badge { font-size: 11px; padding: 4px 10px; border-radius: 6px; font-weight: 500; }
  .report-badge.critical { background: #fee2e2; color: #dc2626; }
  .report-badge.pending { background: #fef3c7; color: #d97706; }
  .report-badge.resolved { background: #dcfce7; color: #16a34a; }
  .card-body { padding: 16px 20px; }
  .report-detail { font-size: 13px; color: #6b7280; line-height: 1.5; margin-bottom: 12px; }
  .report-target { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #111; background: #f9fafb; padding: 10px 12px; border-radius: 8px; margin-bottom: 12px; }
  .action-bar { display: flex; gap: 10px; }
  .action-btn { padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 500; border: none; cursor: pointer; display: flex; align-items: center; gap: 6px; text-decoration: none; }
  .action-btn.resolve { background: #dcfce7; color: #16a34a; }
  .action-btn.escalate { background: #fef3c7; color: #d97706; }
  .action-btn.view { background: #f0f7ff; color: #1677ff; }
</style>

<div id="reports-list">
  <div style="text-align:center;padding:40px;color:#6b7280;">Loading reports...</div>
</div>
@endsection

@push('scripts')
<script>
let reports = [];

document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;
    await loadReports();
});

async function loadReports() {
    // MVP mock data
    reports = [
        { id: 1, title: 'Suspicious scholarship listing reported', meta: 'Filed 15 min ago • By Anonymous', detail: 'User reported a suspicious scholarship listing that appears to be collecting personal data for non-legitimate purposes.', target: 'SportsIndia Trust (AC-3301)', status: 'critical', iconColor: '#dc2626' },
        { id: 2, title: 'User harassment complaint', meta: 'Filed 2 hours ago • By Vikram Sharma', detail: 'Coach allegedly sending inappropriate messages to athletes through the platform inquiry system.', target: 'Vikram Sharma (COA-1283)', status: 'pending', iconColor: '#d97706' },
        { id: 3, title: 'Fake brand sponsorship claim', meta: 'Filed 5 hours ago • By Nike India', detail: 'False claim of Nike sponsorship being used to attract athletes. Listing has been removed and user warned.', target: 'Nike Sports Hub (SP-5512)', status: 'resolved', iconColor: '#16a34a' }
    ];
    document.getElementById('reports-badge').textContent = '12 Pending';
    renderReports();
}

function renderReports() {
    const list = document.getElementById('reports-list');
    
    if (reports.length === 0) {
        list.innerHTML = '<div style="text-align:center;padding:40px;color:#6b7280;">No reports found.</div>';
        return;
    }

    list.innerHTML = reports.map(r => `
        <div class="card">
          <div class="card-header">
            <div class="report-type"><i data-lucide="flag" style="width:20px;height:20px;color:${r.iconColor};"></i></div>
            <div class="report-info">
              <div class="report-title">${r.title}</div>
              <div class="report-meta">${r.meta}</div>
            </div>
            <span class="report-badge ${r.status}">${r.status.charAt(0).toUpperCase() + r.status.slice(1)}</span>
          </div>
          <div class="card-body">
            <div class="report-detail">${r.detail}</div>
            <div class="report-target"><i data-lucide="users" style="width:14px;height:14px;color:#6b7280;"></i> Target: ${r.target}</div>
            <div class="action-bar">
              ${r.status !== 'resolved' ? `
              <button class="action-btn resolve" onclick="alert('Resolve ${r.id}')"><i data-lucide="check" style="width:14px;height:14px;"></i> Resolve</button>
              <button class="action-btn escalate" onclick="alert('Escalate ${r.id}')"><i data-lucide="alert-triangle" style="width:14px;height:14px;"></i> Escalate</button>
              ` : ''}
              <a href="#" class="action-btn view"><i data-lucide="eye" style="width:14px;height:14px;"></i> View</a>
            </div>
          </div>
        </div>
    `).join('');
    
    lucide.createIcons();
}
</script>
@endpush
