@extends('admin.layouts.main')

@section('title', 'Opportunity Approvals')

@section('back-url', route('admin.dashboard'))

@section('content')
<div>
    <div class="section-label">PENDING (<span id="pending-opp-count">0</span>)</div>
    <div style="display:flex;flex-direction:column;gap:12px;margin-top:8px;" id="pending-opps">
        <div class="empty-state">
            <div class="empty-state-icon">&#x23F3;</div>
            <div class="empty-state-title">Loading opportunities...</div>
        </div>
    </div>
</div>

<div style="margin-top:16px;">
    <div class="section-label">RECENTLY APPROVED</div>
    <div style="display:flex;flex-direction:column;gap:12px;margin-top:8px;" id="approved-opps">
        <div class="card">
            <div style="display:flex;align-items:center;gap:12px;padding:12px;">
                <div class="avatar avatar-sm" style="background:#111827;">NI</div>
                <div style="flex:1;min-width:0;">
                    <p style="font-size:14px;font-weight:700;color:#111827;">Athlete Sponsorship 2024</p>
                    <p style="font-size:12px;color:#6B7280;">Nike India</p>
                    <p style="font-size:12px;color:#9CA3AF;">Approved: Oct 12 2024</p>
                </div>
                <button class="btn btn-ghost btn-sm">View</button>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
const pendingOpps = [
    { id: 1, org: 'Adidas India', title: 'Youth Cricket Program 2024', sport: 'Cricket', region: 'Maharashtra', submitted: 'Today' },
    { id: 2, org: 'Puma Sports', title: 'Women in Sports Fund', sport: 'Athletics', region: 'Pan-India', submitted: 'Yesterday' },
    { id: 3, org: 'Samsung India', title: 'Young Athletes Tech Grant', sport: 'Multi-sport', region: 'Pan-India', submitted: '2 days ago' },
    { id: 4, org: 'HSBC India', title: 'Grassroots Football Program', sport: 'Football', region: 'Delhi', submitted: '3 days ago' },
];

document.addEventListener('DOMContentLoaded', () => {
    if (!requireAuth()) return;
    document.getElementById('pending-opp-count').textContent = pendingOpps.length;
    renderPendingOpps();
});

function renderPendingOpps() {
    const container = document.getElementById('pending-opps');
    if (pendingOpps.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">&#x2705;</div><div class="empty-state-title">No pending opportunities</div></div>';
        return;
    }

    container.innerHTML = pendingOpps.map(opp => `
        <div class="card">
            <div style="padding:12px;cursor:pointer;">
                <div style="display:flex;align-items:flex-start;gap:12px;margin-bottom:12px;">
                    <div class="avatar avatar-sm" style="background:${avatarColor(opp.org)};">${getInitials(opp.org)}</div>
                    <div style="flex:1;min-width:0;">
                        <p style="font-size:14px;font-weight:700;color:#111827;">${escapeHtml(opp.title)}</p>
                        <p style="font-size:12px;color:#6B7280;">${escapeHtml(opp.org)}</p>
                        <p style="font-size:12px;color:#9CA3AF;">${opp.sport} &middot; ${opp.region}</p>
                        <p style="font-size:12px;color:#9CA3AF;">Submitted: ${opp.submitted}</p>
                    </div>
                </div>
                <div style="display:flex;gap:8px;">
                    <button class="btn btn-danger btn-sm" style="flex:1;" onclick="event.stopPropagation();rejectOpp(${opp.id})">Reject</button>
                    <button class="btn btn-success btn-sm" style="flex:1;" onclick="event.stopPropagation();approveOpp(${opp.id})">Approve</button>
                </div>
            </div>
        </div>
    `).join('');
}

function approveOpp(id) {
    const idx = pendingOpps.findIndex(o => o.id === id);
    if (idx > -1) {
        const opp = pendingOpps.splice(idx, 1)[0];
        document.getElementById('pending-opp-count').textContent = pendingOpps.length;
        renderPendingOpps();
        showToast(`"${opp.title}" approved!`, 'success');
    }
}

function rejectOpp(id) {
    if (confirm('Reject this opportunity?')) {
        const idx = pendingOpps.findIndex(o => o.id === id);
        if (idx > -1) {
            pendingOpps.splice(idx, 1);
            document.getElementById('pending-opp-count').textContent = pendingOpps.length;
            renderPendingOpps();
            showToast('Opportunity rejected.', 'error');
        }
    }
}
</script>
@endpush
