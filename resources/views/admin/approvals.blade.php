@extends('admin.layouts.main')

@section('title', 'Pending Approvals')

@section('back-url', route('admin.dashboard'))

@section('content')
<div>
    <div class="section-label">NEW REGISTRATIONS (<span id="pending-count">0</span>)</div>
    <div style="display:flex;flex-direction:column;gap:12px;margin-top:8px;" id="approvals-list">
        <div class="empty-state">
            <div class="empty-state-icon">&#x23F3;</div>
            <div class="empty-state-title">Loading approvals...</div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
const pendingUsers = [
    { id: 1, name: 'Kavya Singh', role: 'Athlete', city: 'Hyderabad', registered: 'Today' },
    { id: 2, name: 'Manish Reddy', role: 'Athlete', city: 'Pune', registered: 'Today' },
    { id: 3, name: 'Sneha Patel', role: 'Coach', city: 'Ahmedabad', registered: 'Yesterday' },
    { id: 4, name: 'Ravi Sports', role: 'Sponsor', city: 'Chennai', registered: 'Yesterday' },
    { id: 5, name: 'Amit Verma', role: 'Athlete', city: 'Jaipur', registered: '2 days ago' },
];

document.addEventListener('DOMContentLoaded', () => {
    if (!requireAuth()) return;
    document.getElementById('pending-count').textContent = pendingUsers.length;
    renderApprovals();
});

function renderApprovals() {
    const list = document.getElementById('approvals-list');
    if (pendingUsers.length === 0) {
        list.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">&#x2705;</div>
                <div class="empty-state-title">No more pending items</div>
                <div class="empty-state-desc">All registrations have been reviewed.</div>
            </div>`;
        return;
    }

    list.innerHTML = pendingUsers.map(u => `
        <div class="card" id="approval-${u.id}">
            <div style="padding:12px;">
                <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;">
                    ${renderAvatar(u.name, 'avatar-md')}
                    <div>
                        <p style="font-size:14px;font-weight:600;color:#111827;">${escapeHtml(u.name)}</p>
                        <p style="font-size:12px;color:#6B7280;">&#x1F464; ${u.role} &middot; ${escapeHtml(u.city)}</p>
                        <p style="font-size:12px;color:#9CA3AF;">Registered: ${u.registered}</p>
                    </div>
                </div>
                <div style="display:flex;gap:8px;">
                    <button class="btn btn-danger btn-sm" style="flex:1;" onclick="rejectUser(${u.id})">Reject</button>
                    <button class="btn btn-success btn-sm" style="flex:1;" onclick="approveUser(${u.id})">Approve</button>
                </div>
            </div>
        </div>
    `).join('');
}

function approveUser(id) {
    const idx = pendingUsers.findIndex(u => u.id === id);
    if (idx > -1) {
        pendingUsers.splice(idx, 1);
        document.getElementById('pending-count').textContent = pendingUsers.length;
        renderApprovals();
        showToast('User approved!', 'success');
    }
}

function rejectUser(id) {
    if (confirm('Reject this registration?')) {
        const idx = pendingUsers.findIndex(u => u.id === id);
        if (idx > -1) {
            pendingUsers.splice(idx, 1);
            document.getElementById('pending-count').textContent = pendingUsers.length;
            renderApprovals();
            showToast('Registration rejected.', 'error');
        }
    }
}
</script>
@endpush
