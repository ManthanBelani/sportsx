@extends('admin.layouts.main')

@section('title', 'Sponsor Verification')

@push('topbar-actions')
<span class="header-badge" id="pending-badge" style="background:#d97706; color:#fff; font-size:12px; padding:4px 12px; border-radius:20px; font-weight:500;">Loading...</span>
@endpush

@section('content')
<style>
  .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
  .card { background: #fff; border-radius: 12px; border: 1px solid #e5e7eb; overflow: hidden; margin-bottom: 20px;}
  .sponsor-header { display: flex; align-items: center; gap: 16px; padding: 16px 20px; border-bottom: 1px solid #f0f0f0; }
  .sponsor-logo { width: 56px; height: 56px; background: #f0f7ff; border-radius: 12px; display: flex; align-items: center; justify-content: center; }
  .sponsor-info { flex: 1; }
  .sponsor-name { font-size: 16px; font-weight: 600; margin-bottom: 2px; }
  .sponsor-type { font-size: 13px; color: #6b7280; }
  .sponsor-tier { padding: 4px 12px; border-radius: 6px; font-size: 11px; font-weight: 600; }
  .sponsor-tier.platinum { background: #e0e7ff; color: #4338ca; }
  .sponsor-tier.gold { background: #fef3c7; color: #d97706; }
  .docs-section { padding: 16px 20px; }
  .docs-title { font-size: 13px; font-weight: 600; margin-bottom: 12px; }
  .doc-row { display: flex; align-items: center; gap: 12px; padding: 10px 0; border-bottom: 1px solid #f0f0f0; }
  .doc-row:last-child { border-bottom: none; }
  .doc-icon { width: 32px; height: 32px; background: #f9fafb; border-radius: 8px; display: flex; align-items: center; justify-content: center; }
  .doc-name { flex: 1; font-size: 13px; }
  .doc-status { font-size: 11px; padding: 4px 10px; border-radius: 6px; font-weight: 500; display: flex; align-items: center; gap: 4px; }
  .doc-status.verified { background: #dcfce7; color: #16a34a; }
  .doc-status.pending { background: #fef3c7; color: #d97706; }
  .sponsor-actions { display: flex; gap: 10px; padding: 14px 20px; border-top: 1px solid #f0f0f0; background: #f9fafb; }
  .action-btn { flex: 1; padding: 10px 16px; border-radius: 8px; font-size: 13px; font-weight: 500; border: none; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 6px; text-decoration: none;}
  .action-btn.approve { background: #dcfce7; color: #16a34a; }
  .action-btn.reject { background: #fee2e2; color: #dc2626; }
  .action-btn.view { background: #fff; color: #111; border: 1px solid #e5e7eb; }
</style>

<div class="grid-2" id="sponsor-list">
  <div style="text-align:center;padding:40px;color:#6b7280;grid-column: span 2;">Loading sponsors...</div>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', () => {
    if (!requireAuth()) return;
    renderSponsors();
});

function renderSponsors() {
    const list = document.getElementById('sponsor-list');
    
    // MVP mock data
    const sponsors = [
        {
            id: 1, name: 'Tata Sports', type: 'Corporate Sponsor', location: 'Mumbai, MH', tier: 'platinum',
            docs: [
                { name: 'Company Registration', status: 'verified' },
                { name: 'GST Certificate', status: 'verified' },
                { name: 'Sports Ministry License', status: 'pending' },
            ]
        },
        {
            id: 2, name: 'Nike India', type: 'Brand Sponsor', location: 'Bangalore, KA', tier: 'gold',
            docs: [
                { name: 'Brand Authorization', status: 'pending' },
                { name: 'Corporate ID', status: 'pending' },
            ]
        }
    ];

    document.getElementById('pending-badge').textContent = '8 Pending';

    list.innerHTML = sponsors.map(s => `
        <div class="card">
          <div class="sponsor-header">
            <div class="sponsor-logo"><i data-lucide="briefcase" style="width:28px;height:28px;color:#${s.tier === 'platinum' ? '1677ff' : 'd97706'};"></i></div>
            <div class="sponsor-info">
              <div class="sponsor-name">${s.name}</div>
              <div class="sponsor-type">${s.type} • ${s.location}</div>
            </div>
            <span class="sponsor-tier ${s.tier}">${s.tier.charAt(0).toUpperCase() + s.tier.slice(1)}</span>
          </div>
          <div class="docs-section">
            <div class="docs-title">Documents</div>
            ${s.docs.map(d => `
                <div class="doc-row">
                  <div class="doc-icon"><i data-lucide="file-text" style="width:16px;height:16px;color:#6b7280;"></i></div>
                  <span class="doc-name">${d.name}</span>
                  <span class="doc-status ${d.status}"><i data-lucide="${d.status === 'verified' ? 'check' : 'clock'}" style="width:12px;height:12px;"></i> ${d.status.charAt(0).toUpperCase() + d.status.slice(1)}</span>
                </div>
            `).join('')}
          </div>
          <div class="sponsor-actions">
            <button class="action-btn approve" onclick="alert('Approve ${s.id}')"><i data-lucide="check" style="width:14px;height:14px;"></i> Approve</button>
            <button class="action-btn reject" onclick="alert('Reject ${s.id}')"><i data-lucide="x" style="width:14px;height:14px;"></i> Reject</button>
            <a href="#" class="action-btn view"><i data-lucide="eye" style="width:14px;height:14px;"></i> Profile</a>
          </div>
        </div>
    `).join('');
    
    lucide.createIcons();
}
</script>
@endpush
