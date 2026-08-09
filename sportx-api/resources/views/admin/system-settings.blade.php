@extends('admin.layouts.main')

@section('title', 'System Settings')

@section('content')
<style>
  .card { background: #fff; border-radius: 12px; border: 1px solid #e5e7eb; margin-bottom: 20px; overflow: hidden; }
  .card-header { padding: 16px 20px; border-bottom: 1px solid #e5e7eb; }
  .card-title { font-size: 15px; font-weight: 600; margin-bottom: 4px; }
  .card-desc { font-size: 13px; color: #6b7280; }
  .settings-list { }
  .settings-item { display: flex; align-items: center; gap: 14px; padding: 16px 20px; border-bottom: 1px solid #f0f0f0; }
  .settings-item:last-child { border-bottom: none; }
  .settings-icon { width: 40px; height: 40px; background: #f0f7ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; }
  .settings-info { flex: 1; }
  .settings-label { font-size: 14px; font-weight: 500; }
  .settings-desc { font-size: 12px; color: #6b7280; margin-top: 2px; }
  .toggle { width: 48px; height: 28px; background: #d9dee7; border-radius: 14px; position: relative; cursor: pointer; border: none; transition: background 0.2s; outline:none; }
  .toggle.on { background: #16a34a; }
  .toggle::after { content: ''; position: absolute; width: 24px; height: 24px; background: #fff; border-radius: 50%; top: 2px; left: 2px; transition: left 0.2s; box-shadow: 0 1px 3px rgba(0,0,0,0.2); }
  .toggle.on::after { left: 22px; }
  .settings-value { font-size: 14px; color: #6b7280; }
  .settings-arrow { color: #9ca3af; font-size: 18px; }
  .danger-zone { border-color: #fecaca; }
  .danger-zone .settings-item:first-child .settings-label { color: #dc2626; }
  .btn { padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 500; border: none; cursor: pointer; display: flex; align-items: center; gap: 6px; outline:none; }
  .btn-danger { background: #fee2e2; color: #dc2626; }
</style>

<div class="card">
  <div class="card-header">
    <div class="card-title">Platform</div>
    <div class="card-desc">Core platform configuration</div>
  </div>
  <div class="settings-list">
    <div class="settings-item">
      <div class="settings-icon"><i data-lucide="lock" style="width:20px;height:20px;color:#1677ff;"></i></div>
      <div class="settings-info">
        <div class="settings-label">Moderation Required</div>
        <div class="settings-desc">All new listings require admin approval</div>
      </div>
      <button class="toggle on" onclick="this.classList.toggle('on')"></button>
    </div>
    <div class="settings-item">
      <div class="settings-icon"><i data-lucide="check-circle" style="width:20px;height:20px;color:#16a34a;"></i></div>
      <div class="settings-info">
        <div class="settings-label">Auto-verify coaches</div>
        <div class="settings-desc">Auto-approve coaches with valid certification</div>
      </div>
      <button class="toggle" onclick="this.classList.toggle('on')"></button>
    </div>
    <div class="settings-item">
      <div class="settings-icon"><i data-lucide="users" style="width:20px;height:20px;color:#6b7280;"></i></div>
      <div class="settings-info">
        <div class="settings-label">Min age for registration</div>
        <div class="settings-desc">Minimum age to create an account</div>
      </div>
      <span class="settings-value">13 years</span>
      <span class="settings-arrow">&rsaquo;</span>
    </div>
  </div>
</div>

<div class="card">
  <div class="card-header">
    <div class="card-title">Notifications</div>
    <div class="card-desc">Alert and notification preferences</div>
  </div>
  <div class="settings-list">
    <div class="settings-item">
      <div class="settings-icon"><i data-lucide="mail" style="width:20px;height:20px;color:#1677ff;"></i></div>
      <div class="settings-info">
        <div class="settings-label">Email alerts</div>
        <div class="settings-desc">Send email for critical reports</div>
      </div>
      <button class="toggle on" onclick="this.classList.toggle('on')"></button>
    </div>
    <div class="settings-item">
      <div class="settings-icon"><i data-lucide="bell" style="width:20px;height:20px;color:#d97706;"></i></div>
      <div class="settings-info">
        <div class="settings-label">Push notifications</div>
        <div class="settings-desc">Push alerts for urgent moderation</div>
      </div>
      <button class="toggle on" onclick="this.classList.toggle('on')"></button>
    </div>
  </div>
</div>

<div class="card">
  <div class="card-header">
    <div class="card-title">Security</div>
    <div class="card-desc">Platform security settings</div>
  </div>
  <div class="settings-list">
    <div class="settings-item">
      <div class="settings-icon"><i data-lucide="ban" style="width:20px;height:20px;color:#dc2626;"></i></div>
      <div class="settings-info">
        <div class="settings-label">Suspicious login detection</div>
        <div class="settings-desc">Flag accounts with unusual activity</div>
      </div>
      <button class="toggle on" onclick="this.classList.toggle('on')"></button>
    </div>
    <div class="settings-item">
      <div class="settings-icon"><i data-lucide="clock" style="width:20px;height:20px;color:#6b7280;"></i></div>
      <div class="settings-info">
        <div class="settings-label">Session timeout</div>
        <div class="settings-desc">Auto logout inactive users</div>
      </div>
      <span class="settings-value">30 min</span>
      <span class="settings-arrow">&rsaquo;</span>
    </div>
  </div>
</div>

<div class="card danger-zone">
  <div class="card-header">
    <div class="card-title" style="color:#dc2626;">Danger Zone</div>
    <div class="card-desc">Irreversible actions - proceed with caution</div>
  </div>
  <div class="settings-list">
    <div class="settings-item">
      <div class="settings-icon"><i data-lucide="octagon" style="width:20px;height:20px;color:#dc2626;"></i></div>
      <div class="settings-info">
        <div class="settings-label">Maintenance Mode</div>
        <div class="settings-desc">Disable platform for all users</div>
      </div>
      <button class="toggle" onclick="this.classList.toggle('on')"></button>
    </div>
    <div class="settings-item">
      <div class="settings-icon"><i data-lucide="trash-2" style="width:20px;height:20px;color:#dc2626;"></i></div>
      <div class="settings-info">
        <div class="settings-label">Wipe all data</div>
        <div class="settings-desc">Permanently delete all user data</div>
      </div>
      <button class="btn btn-danger" onclick="alert('Are you sure?')"><i data-lucide="alert-triangle" style="width:14px;height:14px;"></i> Wipe Data</button>
    </div>
  </div>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', () => {
    if (!requireAuth()) return;
    lucide.createIcons();
});
</script>
@endpush
