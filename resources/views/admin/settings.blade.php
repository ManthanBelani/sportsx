@extends('admin.layouts.app')
@section('title', 'System Settings')

@section('content')
  <form method="POST" action="{{ route('admin.settings.update') }}">@csrf
    <div class="card no-pad">
      <div class="card-header"><div><div class="card-title">Platform</div><div class="card-desc">Core platform configuration</div></div></div>
      <div class="settings-list">
        <div class="settings-item"><div class="settings-icon"><i data-lucide="lock" style="width:20px;height:20px;color:#1677ff;"></i></div><div class="settings-info"><div class="settings-label">Moderation Required</div><div class="settings-desc">All new listings require admin approval</div></div><button type="submit" name="moderation_required" value="{{ $settings['moderation_required'] ? '0' : '1' }}" class="toggle {{ $settings['moderation_required'] ? 'on' : '' }}"></button><input type="hidden" name="moderation_required" value="0"></div>
        <div class="settings-item"><div class="settings-icon"><i data-lucide="check-circle" style="width:20px;height:20px;color:#16a34a;"></i></div><div class="settings-info"><div class="settings-label">Auto-verify coaches</div><div class="settings-desc">Auto-approve coaches with valid certification</div></div><button type="submit" name="auto_verify_coaches" value="{{ $settings['auto_verify_coaches'] ? '0' : '1' }}" class="toggle {{ $settings['auto_verify_coaches'] ? 'on' : '' }}"></button><input type="hidden" name="auto_verify_coaches" value="0"></div>
      </div>
    </div>

    <div class="card no-pad">
      <div class="card-header"><div><div class="card-title">Notifications</div><div class="card-desc">Alert and notification preferences</div></div></div>
      <div class="settings-list">
        <div class="settings-item"><div class="settings-icon"><i data-lucide="mail" style="width:20px;height:20px;color:#1677ff;"></i></div><div class="settings-info"><div class="settings-label">Email alerts</div><div class="settings-desc">Send email for critical reports</div></div><button type="submit" name="email_alerts" value="{{ $settings['email_alerts'] ? '0' : '1' }}" class="toggle {{ $settings['email_alerts'] ? 'on' : '' }}"></button><input type="hidden" name="email_alerts" value="0"></div>
        <div class="settings-item"><div class="settings-icon"><i data-lucide="bell" style="width:20px;height:20px;color:#d97706;"></i></div><div class="settings-info"><div class="settings-label">Push notifications</div><div class="settings-desc">Push alerts for urgent moderation</div></div><button type="submit" name="push_notifications" value="{{ $settings['push_notifications'] ? '0' : '1' }}" class="toggle {{ $settings['push_notifications'] ? 'on' : '' }}"></button><input type="hidden" name="push_notifications" value="0"></div>
      </div>
    </div>

    <div class="card no-pad">
      <div class="card-header"><div><div class="card-title">Security</div><div class="card-desc">Platform security settings</div></div></div>
      <div class="settings-list">
        <div class="settings-item"><div class="settings-icon"><i data-lucide="ban" style="width:20px;height:20px;color:#dc2626;"></i></div><div class="settings-info"><div class="settings-label">Suspicious login detection</div><div class="settings-desc">Flag accounts with unusual activity</div></div><button type="submit" name="suspicious_login_detection" value="{{ $settings['suspicious_login_detection'] ? '0' : '1' }}" class="toggle {{ $settings['suspicious_login_detection'] ? 'on' : '' }}"></button><input type="hidden" name="suspicious_login_detection" value="0"></div>
        <div class="settings-item"><div class="settings-icon"><i data-lucide="clock" style="width:20px;height:20px;color:#6b7280;"></i></div><div class="settings-info"><div class="settings-label">Session timeout</div><div class="settings-desc">Auto logout inactive users</div></div><span class="settings-value">30 min</span></div>
      </div>
    </div>

    <div class="card no-pad danger-zone">
      <div class="card-header"><div><div class="card-title">Danger Zone</div><div class="card-desc">Irreversible actions — proceed with caution</div></div></div>
      <div class="settings-list">
        <div class="settings-item"><div class="settings-icon"><i data-lucide="octagon" style="width:20px;height:20px;color:#dc2626;"></i></div><div class="settings-info"><div class="settings-label">Maintenance Mode</div><div class="settings-desc">Disable platform for all users</div></div><button type="submit" name="maintenance_mode" value="{{ $settings['maintenance_mode'] ? '0' : '1' }}" class="toggle {{ $settings['maintenance_mode'] ? 'on' : '' }}"></button><input type="hidden" name="maintenance_mode" value="0"></div>
      </div>
    </div>
    <div style="text-align:right;"><span class="muted" style="font-size:12px;">Click any toggle to save instantly.</span></div>
  </form>
@endsection
