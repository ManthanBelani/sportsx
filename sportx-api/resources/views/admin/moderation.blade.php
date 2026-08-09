@extends('admin.layouts.main')

@section('title', 'Listing Moderation')

@push('topbar-actions')
<span class="header-badge" id="pending-badge">Loading...</span>
@endpush

@section('content')
<style>
  .card { background: #fff; border-radius: 12px; border: 1px solid #e5e7eb; margin-bottom: 24px; overflow: hidden; }
  .card-header { padding: 16px 20px; border-bottom: 1px solid #e5e7eb; display: flex; justify-content: space-between; align-items: center; }
  .search-bar { display: flex; gap: 12px; padding: 16px 20px; background: #f9fafb; border-bottom: 1px solid #e5e7eb; }
  .search-input { flex: 1; display: flex; align-items: center; gap: 10px; background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 10px 14px; }
  .search-input input { border: none; background: none; outline: none; font-size: 14px; flex: 1; }
  .filter-btn { display: flex; align-items: center; gap: 6px; padding: 10px 14px; background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; font-size: 14px; font-weight: 500; cursor: pointer; outline:none; }
  
  .tab-pills { display: flex; gap: 8px; }
  .tab-pill { padding: 8px 16px; border-radius: 20px; font-size: 13px; font-weight: 500; cursor: pointer; background: #fff; border: 1px solid #e5e7eb; color: #6b7280; transition: all 0.15s; }
  .tab-pill:hover { background: #f9fafb; }
  .tab-pill.active { background: #1677ff; color: #fff; border-color: #1677ff; }

  .table { width: 100%; border-collapse: collapse; }
  .table th { text-align: left; padding: 12px 20px; font-size: 12px; font-weight: 600; color: #6b7280; background: #f9fafb; border-bottom: 1px solid #e5e7eb; }
  .table td { padding: 14px 20px; font-size: 14px; border-bottom: 1px solid #f0f0f0; vertical-align: top;}
  .table tr:hover { background: #f9fafb; }
  
  .listing-title { font-weight: 600; font-size:14px; margin-bottom:2px;}
  .listing-meta { font-size: 12px; color: #6b7280; }
  
  .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 500; }
  .badge.pending { background: #fef3c7; color: #d97706; }
  .badge.approved { background: #dcfce7; color: #16a34a; }
  .badge.rejected { background: #fee2e2; color: #dc2626; }
  .badge.type { background: #f3f4f6; color: #4b5563; border: 1px solid #e5e7eb; }
  
  .action-btns { display: flex; gap: 8px; }
  .action-btn { padding: 6px 12px; border-radius: 6px; font-size: 13px; font-weight: 500; border: none; cursor: pointer; text-decoration: none; display: inline-block;}
  .action-btn.view { background: #f0f7ff; color: #1677ff; }
  .action-btn.approve { background: #dcfce7; color: #16a34a; }
  .action-btn.reject { background: #fee2e2; color: #dc2626; }
</style>

<div class="card">
  <div class="card-header">
    <div class="tab-pills" id="mod-tabs">
      <button class="tab-pill active" data-tab="all" onclick="switchModTab(this)">All Pending</button>
      <button class="tab-pill" data-tab="Trials" onclick="switchModTab(this)">Trials</button>
      <button class="tab-pill" data-tab="Academies" onclick="switchModTab(this)">Academies</button>
      <button class="tab-pill" data-tab="Tournaments" onclick="switchModTab(this)">Tournaments</button>
    </div>
  </div>
  <div class="search-bar">
    <div class="search-input">
      <i data-lucide="search" style="width:18px;height:18px;color:#6b7280;"></i>
      <input type="text" id="search-input" placeholder="Search listings..." oninput="renderReports()">
    </div>
    <select id="status-filter" class="filter-btn" onchange="renderReports()">
      <option value="pending">Pending</option>
      <option value="approved">Approved</option>
      <option value="rejected">Rejected</option>
    </select>
  </div>
  <table class="table">
    <thead>
      <tr>
        <th>Listing Details</th>
        <th>Type</th>
        <th>Submitted By</th>
        <th>Status</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody id="moderation-list">
      <tr><td colspan="5" style="text-align:center;padding:20px;color:#6b7280;">Loading items...</td></tr>
    </tbody>
  </table>
</div>
@endsection

@push('scripts')
<script>
let reports = [];
let currentModTab = 'all';

document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;
    await loadReports();
});

async function loadReports() {
    const res = await api('GET', '/moderation/queue?per_page=50');
    // MVP mock data
    reports = [
        { id: 1, title: 'Summer Football Camp', meta: 'Mumbai, Maharashtra', type: 'Trials', submitter: 'Priya Sharma', status: 'pending', date: 'Jan 15, 2024' },
        { id: 2, title: 'Delhi Cricket Academy', meta: 'New Delhi', type: 'Academies', submitter: 'Rahul Singh', status: 'pending', date: 'Jan 16, 2024' },
        { id: 3, title: 'U-19 State Tournament', meta: 'Bangalore, Karnataka', type: 'Tournaments', submitter: 'Karnataka Sports', status: 'pending', date: 'Jan 17, 2024' },
    ];
    document.getElementById('pending-badge').textContent = reports.length + ' Pending';
    renderReports();
}

function switchModTab(el) {
    document.querySelectorAll('#mod-tabs .tab-pill').forEach(b => b.classList.remove('active'));
    el.classList.add('active');
    currentModTab = el.dataset.tab;
    renderReports();
}

function renderReports() {
    const list = document.getElementById('moderation-list');
    const search = document.getElementById('search-input').value.toLowerCase();
    const statusFilter = document.getElementById('status-filter').value;
    
    let filtered = reports.filter(r => {
        if (currentModTab !== 'all' && r.type !== currentModTab) return false;
        if (r.status !== statusFilter) return false;
        if (search && !r.title.toLowerCase().includes(search) && !r.submitter.toLowerCase().includes(search)) return false;
        return true;
    });

    if (filtered.length === 0) {
        list.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:20px;color:#6b7280;">No items found.</td></tr>';
        return;
    }

    list.innerHTML = filtered.map(r => `
        <tr>
          <td>
            <div class="listing-title">${r.title}</div>
            <div class="listing-meta">${r.meta}</div>
            <div class="listing-meta" style="margin-top:4px;">Submitted: ${r.date}</div>
          </td>
          <td><span class="badge type">${r.type}</span></td>
          <td>${r.submitter}</td>
          <td><span class="badge ${r.status}">${r.status.charAt(0).toUpperCase() + r.status.slice(1)}</span></td>
          <td>
            <div class="action-btns">
              <a href="#" class="action-btn view">Review</a>
              ${r.status === 'pending' ? `
              <button class="action-btn approve" onclick="alert('Approve ${r.id}')">Approve</button>
              <button class="action-btn reject" onclick="alert('Reject ${r.id}')">Reject</button>
              ` : ''}
            </div>
          </td>
        </tr>
    `).join('');
    
    lucide.createIcons();
}
</script>
@endpush
