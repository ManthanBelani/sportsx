@extends('admin.layouts.app')
@section('title', 'System Settings')

@section('content')
  <form id="settingsForm" method="POST" action="{{ route('admin.settings.update') }}">@csrf
    <div class="card no-pad">
      <div class="card-header"><div><div class="card-title">Platform</div><div class="card-desc">Core platform configuration</div></div></div>
      <div class="settings-list">
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="lock" style="width:20px;height:20px;color:#1677ff;"></i></div>
          <div class="settings-info"><div class="settings-label">Moderation Required</div><div class="settings-desc">All new listings require admin approval</div></div>
          <label class="toggle {{ $settings['moderation_required'] ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="moderation_required" value="1" {{ $settings['moderation_required'] ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="check-circle" style="width:20px;height:20px;color:#16a34a;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-verify coaches</div><div class="settings-desc">Auto-approve coaches with valid certification (legacy - prefer per-type toggles below)</div></div>
          <label class="toggle {{ $settings['auto_verify_coaches'] ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_verify_coaches" value="1" {{ $settings['auto_verify_coaches'] ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="user-plus" style="width:20px;height:20px;color:#0ea5e9;"></i></div>
          <div class="settings-info"><div class="settings-label">Registrations Open</div><div class="settings-desc">Allow new user signups. OFF = block /register endpoint</div></div>
          <label class="toggle {{ ($settings['registrations_open'] ?? true) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="registrations_open" value="1" {{ ($settings['registrations_open'] ?? true) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
      </div>
    </div>

    <div class="card no-pad">
      <div class="card-header"><div><div class="card-title">Approvals & Auto-publish</div><div class="card-desc">When OFF, new items stay pending until admin approves. When ON, they go live immediately.</div></div></div>
      <div class="settings-list">
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="user-check" style="width:20px;height:20px;color:#1677ff;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-approve coaches</div><div class="settings-desc">Coach registrations go active without review</div></div>
          <label class="toggle {{ ($settings['auto_approve_coach'] ?? false) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_approve_coach" value="1" {{ ($settings['auto_approve_coach'] ?? false) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="briefcase" style="width:20px;height:20px;color:#4338ca;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-approve sponsors</div><div class="settings-desc">Sponsor registrations go active without review</div></div>
          <label class="toggle {{ ($settings['auto_approve_sponsor'] ?? false) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_approve_sponsor" value="1" {{ ($settings['auto_approve_sponsor'] ?? false) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="search" style="width:20px;height:20px;color:#d97706;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-approve talent scouts</div><div class="settings-desc">Talent scout registrations go active without review</div></div>
          <label class="toggle {{ ($settings['auto_approve_talent_scout'] ?? false) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_approve_talent_scout" value="1" {{ ($settings['auto_approve_talent_scout'] ?? false) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="target" style="width:20px;height:20px;color:#16a34a;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-approve trials</div><div class="settings-desc">New trials publish immediately (OFF = draft pending approval)</div></div>
          <label class="toggle {{ ($settings['auto_approve_trials'] ?? false) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_approve_trials" value="1" {{ ($settings['auto_approve_trials'] ?? false) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="trophy" style="width:20px;height:20px;color:#d97706;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-approve tournaments</div><div class="settings-desc">New tournaments publish immediately (OFF = draft pending approval)</div></div>
          <label class="toggle {{ ($settings['auto_approve_tournaments'] ?? false) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_approve_tournaments" value="1" {{ ($settings['auto_approve_tournaments'] ?? false) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="graduation-cap" style="width:20px;height:20px;color:#7c3aed;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-approve scholarships</div><div class="settings-desc">New scholarships publish immediately</div></div>
          <label class="toggle {{ ($settings['auto_approve_scholarships'] ?? false) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_approve_scholarships" value="1" {{ ($settings['auto_approve_scholarships'] ?? false) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="handshake" style="width:20px;height:20px;color:#0891b2;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-approve sponsorships</div><div class="settings-desc">New sponsorship opportunities publish immediately</div></div>
          <label class="toggle {{ ($settings['auto_approve_sponsorships'] ?? false) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_approve_sponsorships" value="1" {{ ($settings['auto_approve_sponsorships'] ?? false) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="building-2" style="width:20px;height:20px;color:#16a34a;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-approve academies</div><div class="settings-desc">New academy listings publish immediately</div></div>
          <label class="toggle {{ ($settings['auto_approve_academies'] ?? false) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_approve_academies" value="1" {{ ($settings['auto_approve_academies'] ?? false) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="map-pin" style="width:20px;height:20px;color:#ea580c;"></i></div>
          <div class="settings-info"><div class="settings-label">Auto-approve venues</div><div class="settings-desc">New sports venue listings publish immediately</div></div>
          <label class="toggle {{ ($settings['auto_approve_venues'] ?? false) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="auto_approve_venues" value="1" {{ ($settings['auto_approve_venues'] ?? false) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
      </div>
    </div>

    <div class="card no-pad">
      <div class="card-header"><div><div class="card-title">Platform Limits</div><div class="card-desc">Rate limits, uploads, and abuse prevention</div></div></div>
      <div class="settings-list">
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="hash" style="width:20px;height:20px;color:#6b7280;"></i></div>
          <div class="settings-info"><div class="settings-label">Max listings per user / day</div><div class="settings-desc">Throttle creation of trials, tournaments, etc. (1-100)</div></div>
          <input class="input" type="number" name="max_listings_per_user_per_day" value="{{ $settings['max_listings_per_user_per_day'] ?? 5 }}" min="1" max="100" style="width:90px; text-align:center;">
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="image" style="width:20px;height:20px;color:#6b7280;"></i></div>
          <div class="settings-info"><div class="settings-label">Media max size (MB)</div><div class="settings-desc">Max upload per file for banners/logos</div></div>
          <input class="input" type="number" name="media_max_size_mb" value="{{ $settings['media_max_size_mb'] ?? 10 }}" min="1" max="100" style="width:90px; text-align:center;">
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="shield-alert" style="width:20px;height:20px;color:#dc2626;"></i></div>
          <div class="settings-info"><div class="settings-label">Login rate limit (per minute)</div><div class="settings-desc">Throttle /auth/login & /panel/login (5-100)</div></div>
          <input class="input" type="number" name="rate_limit_login_per_minute" value="{{ $settings['rate_limit_login_per_minute'] ?? 10 }}" min="5" max="100" style="width:90px; text-align:center;">
        </div>
      </div>
    </div>

    <div class="card no-pad">
      <div class="card-header"><div><div class="card-title">Notifications</div><div class="card-desc">Alert and notification preferences</div></div></div>
      <div class="settings-list">
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="mail" style="width:20px;height:20px;color:#1677ff;"></i></div>
          <div class="settings-info"><div class="settings-label">Email alerts</div><div class="settings-desc">Send email for critical reports</div></div>
          <label class="toggle {{ $settings['email_alerts'] ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="email_alerts" value="1" {{ $settings['email_alerts'] ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="bell" style="width:20px;height:20px;color:#d97706;"></i></div>
          <div class="settings-info"><div class="settings-label">Push notifications</div><div class="settings-desc">Push alerts for urgent moderation</div></div>
          <label class="toggle {{ $settings['push_notifications'] ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="push_notifications" value="1" {{ $settings['push_notifications'] ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
      </div>
    </div>

    <div class="card no-pad">
      <div class="card-header"><div><div class="card-title">Security</div><div class="card-desc">Platform security settings</div></div></div>
      <div class="settings-list">
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="ban" style="width:20px;height:20px;color:#dc2626;"></i></div>
          <div class="settings-info"><div class="settings-label">Suspicious login detection</div><div class="settings-desc">Flag accounts with unusual activity</div></div>
          <label class="toggle {{ $settings['suspicious_login_detection'] ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="suspicious_login_detection" value="1" {{ $settings['suspicious_login_detection'] ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="scroll-text" style="width:20px;height:20px;color:#6b7280;"></i></div>
          <div class="settings-info"><div class="settings-label">Audit log</div><div class="settings-desc">Record admin actions (publish, delete, user status changes)</div></div>
          <label class="toggle {{ ($settings['audit_log_enabled'] ?? true) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="audit_log_enabled" value="1" {{ ($settings['audit_log_enabled'] ?? true) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="clock" style="width:20px;height:20px;color:#6b7280;"></i></div>
          <div class="settings-info"><div class="settings-label">Session timeout</div><div class="settings-desc">Auto logout inactive users</div></div>
          <select class="select" name="session_lifetime_minutes" style="width:130px;">
            @foreach([15=> '15 min', 30=>'30 min', 60=>'1 hour', 120=>'2 hours', 240=>'4 hours', 480=>'8 hours'] as $v=>$label)
              <option value="{{ $v }}" {{ (($settings['session_lifetime_minutes'] ?? 30)==$v)?'selected':'' }}>{{ $label }}</option>
            @endforeach
          </select>
        </div>
      </div>
    </div>

    <div class="card no-pad">
      <div class="card-header"><div><div class="card-title">Data & Compliance</div><div class="card-desc">GDPR, retention, and user rights</div></div></div>
      <div class="settings-list">
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="database" style="width:20px;height:20px;color:#6b7280;"></i></div>
          <div class="settings-info"><div class="settings-label">Data retention</div><div class="settings-desc">Days to keep soft-deleted data before purge</div></div>
          <input class="input" type="number" name="data_retention_days" value="{{ $settings['data_retention_days'] ?? 365 }}" min="30" max="3650" style="width:90px; text-align:center;">
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="download" style="width:20px;height:20px;color:#1677ff;"></i></div>
          <div class="settings-info"><div class="settings-label">Allow user data export</div><div class="settings-desc">Users can request GDPR export via /me/*</div></div>
          <label class="toggle {{ ($settings['allow_user_data_export'] ?? true) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="allow_user_data_export" value="1" {{ ($settings['allow_user_data_export'] ?? true) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="trash-2" style="width:20px;height:20px;color:#dc2626;"></i></div>
          <div class="settings-info"><div class="settings-label">Allow user data delete</div><div class="settings-desc">Users can request account/data deletion</div></div>
          <label class="toggle {{ ($settings['allow_user_data_delete'] ?? true) ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="allow_user_data_delete" value="1" {{ ($settings['allow_user_data_delete'] ?? true) ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
      </div>
    </div>

    <div class="card no-pad danger-zone">
      <div class="card-header"><div><div class="card-title" style="color:#dc2626;">Danger Zone</div><div class="card-desc">Irreversible actions — proceed with caution</div></div></div>
      <div class="settings-list">
        <div class="settings-item">
          <div class="settings-icon"><i data-lucide="octagon" style="width:20px;height:20px;color:#dc2626;"></i></div>
          <div class="settings-info"><div class="settings-label">Maintenance Mode</div><div class="settings-desc">Disable platform for all users (APP_MAINTENANCE). Wire to middleware to actually block API/panel.</div></div>
          <label class="toggle {{ $settings['maintenance_mode'] ? 'on' : '' }}" style="cursor:pointer;">
            <input type="checkbox" name="maintenance_mode" value="1" {{ $settings['maintenance_mode'] ? 'checked' : '' }} hidden onchange="this.closest('label').classList.toggle('on', this.checked)">
          </label>
        </div>
      </div>
    </div>
    <div style="text-align:right; display:flex; gap:10px; justify-content:flex-end;">
      <span class="muted" style="font-size:12px; align-self:center; color:#6b7280;">Toggle then Save</span>
      <button class="btn btn-primary"><i data-lucide="save" style="width:14px;height:14px;"></i> Save Settings</button>
    </div>
  </form>
@endsection
