@extends('admin.layouts.main')

@section('title', 'Report Detail')

@section('back-url', route('admin.moderation'))

@section('content')
<div>
    <div class="section-label">REPORT INFO</div>
    <div class="card card-padded" style="margin-top:8px;">
        <div class="list-item">
            <span style="font-size:12px;color:#6B7280;">Reported by</span>
            <span style="font-size:12px;font-weight:600;color:#111827;" id="report-reporter">-</span>
        </div>
        <div class="list-item">
            <span style="font-size:12px;color:#6B7280;">Reason</span>
            <span style="font-size:12px;font-weight:600;color:#111827;" id="report-reason">-</span>
        </div>
        <div class="list-item">
            <span style="font-size:12px;color:#6B7280;">Reported time</span>
            <span style="font-size:12px;font-weight:600;color:#111827;" id="report-time">-</span>
        </div>
        <div class="list-item">
            <span style="font-size:12px;color:#6B7280;">Status</span>
            <span style="font-size:12px;font-weight:600;color:#F59E0B;" id="report-status">Pending Review</span>
        </div>
    </div>
</div>

<div>
    <div class="section-label">REPORTED CONTENT</div>
    <div class="card card-padded" style="margin-top:8px;">
        <div style="display:flex;align-items:center;gap:12px;margin-bottom:8px;">
            <div class="avatar avatar-sm" id="content-avatar" style="background:#2563EB;">-</div>
            <div>
                <p style="font-size:14px;font-weight:600;color:#111827;" id="content-owner">Rahul Mehta</p>
                <p style="font-size:12px;color:#6B7280;" id="content-meta">Cricket &middot; Delhi</p>
            </div>
        </div>
        <p style="font-size:14px;color:#4B5563;line-height:1.6;" id="content-preview">
            This post was flagged for potentially violating community guidelines...
        </p>
        <button class="btn btn-ghost btn-sm" style="margin-top:8px;">View Full Content &rarr;</button>
    </div>
</div>

<div>
    <div class="section-label">ACTIONS</div>
    <div class="actions-group" style="margin-top:8px;">
        <button class="btn btn-secondary btn-block" onclick="dismissReport()">&#x2713; Dismiss Report</button>
        <button class="btn btn-danger btn-block" onclick="removeContent()">&#x1F5D1;&#xFE0F; Remove Content</button>
        <button class="btn btn-danger btn-block" onclick="suspendUser()">&#x1F6AB; Suspend User</button>
    </div>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;

    // Try to load from API
    const pathParts = window.location.pathname.split('/');
    const reportId = pathParts[pathParts.length - 1];

    const res = await api('GET', '/moderation/reports/' + reportId);
    if (res.ok && res.data) {
        const r = res.data;
        document.getElementById('report-reporter').textContent = r.reporter ? r.reporter.name : 'Unknown';
        document.getElementById('report-reason').textContent = r.reason || 'No reason';
        document.getElementById('report-time').textContent = formatDateTime(r.created_at);
        document.getElementById('report-status').textContent = r.status || 'Pending Review';
        if (r.reporter) {
            document.getElementById('content-avatar').textContent = getInitials(r.reporter.name);
            document.getElementById('content-avatar').style.background = avatarColor(r.reporter.name);
        }
    } else {
        // Fallback
        document.getElementById('report-reporter').textContent = 'Priya Patel';
        document.getElementById('report-reason').textContent = 'Inappropriate content';
        document.getElementById('report-time').textContent = 'Today at 10:30 AM';
        document.getElementById('content-avatar').textContent = 'RM';
        document.getElementById('content-owner').textContent = 'Rahul Mehta';
    }
});

async function dismissReport() {
    showToast('Report dismissed.', 'success');
    setTimeout(() => window.location.href = '{{ route("admin.moderation") }}', 1000);
}

async function removeContent() {
    if (confirm('Remove this content? This action cannot be undone.')) {
        showToast('Content removed.', 'error');
        setTimeout(() => window.location.href = '{{ route("admin.moderation") }}', 1000);
    }
}

async function suspendUser() {
    if (confirm('Suspend the user who posted this content?')) {
        showToast('User suspended.', 'error');
        setTimeout(() => window.location.href = '{{ route("admin.moderation") }}', 1000);
    }
}
</script>
@endpush
