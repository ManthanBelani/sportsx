@extends('admin.layouts.main')

@section('title', 'User Detail')

@section('back-url', route('admin.users'))

@section('content')
<div class="profile-header">
    <div class="avatar avatar-lg" id="user-avatar" style="background:#2563EB;">-</div>
    <p class="profile-name" id="user-name">Loading...</p>
    <p class="profile-role" id="user-role">-</p>
    <p class="profile-status" id="user-status" style="color:#F59E0B;">-</p>
</div>

<div>
    <div class="section-label">PROFILE INFO</div>
    <div class="card card-padded" style="margin-top:8px;">
        <div class="list-item">
            <span style="font-size:12px;color:#6B7280;">Email</span>
            <span style="font-size:12px;font-weight:600;color:#111827;" id="profile-email">-</span>
        </div>
        <div class="list-item">
            <span style="font-size:12px;color:#6B7280;">Phone</span>
            <span style="font-size:12px;font-weight:600;color:#111827;" id="profile-phone">-</span>
        </div>
        <div class="list-item">
            <span style="font-size:12px;color:#6B7280;">Joined</span>
            <span style="font-size:12px;font-weight:600;color:#111827;" id="profile-joined">-</span>
        </div>
        <div class="list-item">
            <span style="font-size:12px;color:#6B7280;">Last Active</span>
            <span style="font-size:12px;font-weight:600;color:#111827;" id="profile-last-active">-</span>
        </div>
    </div>
</div>

<div>
    <div class="section-label">VERIFICATION</div>
    <div style="display:flex;flex-direction:column;gap:12px;margin-top:8px;" id="verification-list">
        <div class="card">
            <div style="display:flex;align-items:center;gap:12px;padding:12px;">
                <span style="font-size:24px;">&#x1F4DC;</span>
                <div style="flex:1;">
                    <p style="font-size:14px;font-weight:600;color:#111827;">State Championship 2024</p>
                    <p style="font-size:12px;color:#6B7280;">Achievement Certificate</p>
                </div>
                <button class="btn btn-ghost btn-sm">View Document</button>
            </div>
        </div>
        <div class="card">
            <div style="display:flex;align-items:center;gap:12px;padding:12px;">
                <span style="font-size:24px;">&#x1F3CF;</span>
                <div style="flex:1;">
                    <p style="font-size:14px;font-weight:600;color:#111827;">Mumbai Premier League</p>
                    <p style="font-size:12px;color:#6B7280;">Participation Certificate</p>
                </div>
                <button class="btn btn-ghost btn-sm">View Document</button>
            </div>
        </div>
    </div>
</div>

<div class="actions-group" style="margin-top:8px;">
    <button class="btn btn-success btn-block" onclick="verifyUser()">&#x2713; Verify & Add Badge</button>
    <button class="btn btn-amber btn-block" onclick="suspendUser()">Suspend Account</button>
    <button class="btn btn-danger btn-block" onclick="deleteUser()">&#x1F5D1;&#xFE0F; Delete Account</button>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', () => {
    if (!requireAuth()) return;
    // Load user detail - for now show placeholder
    const user = {
        name: 'Rohan Sharma',
        role: 'Athlete',
        city: 'Mumbai, MH',
        email: 'rohan@email.com',
        phone: '+91 98765 43210',
        joined: 'Oct 15 2024',
        lastActive: 'Today',
        verified: false,
    };
    document.getElementById('user-avatar').textContent = getInitials(user.name);
    document.getElementById('user-avatar').style.background = avatarColor(user.name);
    document.getElementById('user-name').textContent = user.name;
    document.getElementById('user-role').innerHTML = `&#x1F464; ${user.role} &middot; ${user.city}`;
    document.getElementById('user-status').textContent = `Status: ${user.verified ? 'Verified' : 'Unverified'}`;
    document.getElementById('user-status').style.color = user.verified ? '#22C55E' : '#F59E0B';
    document.getElementById('profile-email').textContent = user.email;
    document.getElementById('profile-phone').textContent = user.phone;
    document.getElementById('profile-joined').textContent = user.joined;
    document.getElementById('profile-last-active').textContent = user.lastActive;
});

async function verifyUser() {
    showToast('User verified and badge added!', 'success');
}

async function suspendUser() {
    if (confirm('Are you sure you want to suspend this account?')) {
        showToast('Account suspended.', 'error');
    }
}

async function deleteUser() {
    if (confirm('Are you sure you want to delete this account? This action cannot be undone.')) {
        showToast('Account deleted.', 'error');
    }
}
</script>
@endpush
