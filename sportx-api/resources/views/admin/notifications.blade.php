@extends('admin.layouts.app')
@section('title', 'Notification Templates')
@section('header-actions')
  <span class="header-badge">Total sent: {{ number_format($sent['_total'] ?? $sent->sum()) }}</span>
@endsection

@section('content')
  <!-- Test Notification Card -->
  <div class="card" style="border: 1px solid #93c5fd; background: linear-gradient(to bottom, #f8fafc, #ffffff); margin-bottom: 24px;">
    <div class="card-header" style="border-bottom: 1px solid #e2e8f0;">
      <span class="card-title" style="color: #1e40af; font-weight: 600;">
        <i data-lucide="bell-ring" style="color: #2563eb;"></i>Test Push Notification (FCM)
      </span>
      <div style="display: flex; gap: 8px; align-items: center;">
        @if($fcmEnabled)
          <span class="badge active" style="background: #ecfdf5; color: #059669; border: 1px solid #a7f3d0;">
            <i data-lucide="check-circle-2" style="width: 12px; height: 12px; display: inline-block;"></i> FCM Ready
          </span>
        @else
          <span class="header-badge warning" style="background: #fef2f2; color: #dc2626; border: 1px solid #fecaca;">
            <i data-lucide="alert-circle" style="width: 12px; height: 12px; display: inline-block;"></i> FCM Not Configured
          </span>
        @endif
        <span class="header-badge" style="background: #eff6ff; color: #1d4ed8;">
          {{ $totalActiveTokens ?? 0 }} Registered Device(s)
        </span>
      </div>
    </div>

    <form method="POST" action="{{ route('admin.notifications.test') }}" id="testNotifyForm" style="padding: 16px;">
      @csrf

      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin-bottom: 16px;">
        <!-- Target Mode -->
        <div class="form-group">
          <label class="form-label" style="font-weight: 600;">Send Target *</label>
          <div style="display: flex; gap: 8px; margin-top: 4px; flex-wrap: wrap;">
            <label style="display: flex; align-items: center; gap: 6px; font-size: 13px; background: #fff; border: 1px solid #cbd5e1; padding: 6px 12px; border-radius: 6px; cursor: pointer;">
              <input type="radio" name="target_mode" value="token" checked onchange="toggleTestTargetMode(this.value)"> Custom FCM Token
            </label>
            <label style="display: flex; align-items: center; gap: 6px; font-size: 13px; background: #fff; border: 1px solid #cbd5e1; padding: 6px 12px; border-radius: 6px; cursor: pointer;">
              <input type="radio" name="target_mode" value="user" onchange="toggleTestTargetMode(this.value)"> App User
            </label>
            <label style="display: flex; align-items: center; gap: 6px; font-size: 13px; background: #fff; border: 1px solid #cbd5e1; padding: 6px 12px; border-radius: 6px; cursor: pointer;">
              <input type="radio" name="target_mode" value="broadcast_test" onchange="toggleTestTargetMode(this.value)"> All Devices
            </label>
          </div>
        </div>

        <!-- Notification Channel -->
        <div class="form-group">
          <label class="form-label" style="font-weight: 600;">Android Channel</label>
          <select class="select" name="channel">
            <option value="sportx_default">Default (sportx_default)</option>
            <option value="sportx_enquiries">Enquiries / Messages (sportx_enquiries)</option>
            <option value="sportx_reminders">Reminders (sportx_reminders)</option>
            <option value="sportx_updates">Updates / Status (sportx_updates)</option>
            <option value="sportx_announcements">Announcements (sportx_announcements)</option>
          </select>
        </div>
      </div>

      <!-- Custom Token Field -->
      <div class="form-group" id="group-target-token">
        <label class="form-label" style="font-weight: 600;">Device FCM Token *</label>
        <input class="input" type="text" name="device_token" id="test-device-token" placeholder="Paste device token from Flutter console (e.g. eX9bL4...)" value="" required>
        <div style="font-size: 12px; color: #64748b; margin-top: 4px;">
          You can copy the FCM token printed in your Flutter app console or from your mobile device.
        </div>
      </div>

      <!-- Select User Field -->
      <div class="form-group" id="group-target-user" style="display: none;">
        <label class="form-label" style="font-weight: 600;">Select User with Registered Device *</label>
        <select class="select" name="user_id" id="test-user-select">
          <option value="">-- Choose User --</option>
          @if(isset($tokenUsers))
            @forelse($tokenUsers as $tu)
              <option value="{{ $tu->id }}">
                {{ $tu->name }} ({{ $tu->email }}) — {{ ucfirst($tu->role) }} [{{ $tu->deviceTokens->count() }} token(s)]
              </option>
            @empty
              <option value="" disabled>No users with registered device tokens yet</option>
            @endforelse
          @endif
        </select>
        <div style="font-size: 12px; color: #64748b; margin-top: 4px;">
          Only users who have opened and logged into the mobile app appear here.
        </div>
      </div>

      <!-- Broadcast test info -->
      <div id="group-target-broadcast" style="display: none; background: #f1f5f9; padding: 10px 14px; border-radius: 6px; font-size: 13px; color: #334155; margin-bottom: 14px;">
        <i data-lucide="info" style="width: 14px; height: 14px; display: inline-block; vertical-align: middle;"></i>
        Will immediately dispatch test push alerts to the first 10 active devices in the database.
      </div>

      <div class="form-row">
        <div class="form-group" style="flex: 2;">
          <label class="form-label" style="font-weight: 600;">Test Title *</label>
          <input class="input" name="title" required maxlength="120" value="SportX Test Notification">
        </div>
        <div class="form-group" style="flex: 3;">
          <label class="form-label" style="font-weight: 600;">Test Body *</label>
          <input class="input" name="body" required maxlength="500" value="Hello! Firebase push notification setup is working smoothly 🚀">
        </div>
      </div>

      <div style="display: flex; gap: 12px; align-items: center; margin-top: 12px;">
        <button class="btn btn-primary" type="submit" style="background: #2563eb; border-color: #1d4ed8;">
          <i data-lucide="send" style="width: 14px; height: 14px;"></i> Send Test Push Notification
        </button>
        <span style="font-size: 12px; color: #64748b;">
          Direct synchronous test — sends immediately and reports Google FCM result.
        </span>
      </div>
    </form>
  </div>

  <div class="card">
    <div class="card-header">
      <span class="card-title"><i data-lucide="megaphone"></i>Broadcast</span>
      @if(!$fcmEnabled)
        <span class="header-badge warning" title="Set FCM_PROJECT_ID and FCM_CREDENTIALS_PATH to enable push">FCM off</span>
      @else
        <span class="badge active">FCM ready</span>
      @endif
    </div>
    <form method="POST" action="{{ route('admin.notifications.broadcast') }}" id="bcastForm">@csrf
      <div class="form-row">
        <div class="form-group" style="flex:2;"><label class="form-label">Title *</label><input class="input" id="bcast-title" name="title" required maxlength="120" placeholder="e.g. New tournament season open!"></div>
        <div class="form-group"><label class="form-label">Type</label><select class="select" id="bcast-type" name="type"><option value="info">Info</option><option value="success">Success</option><option value="warning">Warning</option></select></div>
      </div>
      <div class="form-group"><label class="form-label">Message *</label><textarea class="input" id="bcast-body" name="body" rows="3" required maxlength="500" placeholder="Write the broadcast message…"></textarea></div>

      <div class="form-group">
        <label class="form-label">Target roles <span style="color:#6b7280;font-weight:400;">— leave empty for all active users ({{ number_format($totalActive) }})</span></label>
        <div style="display:flex;flex-wrap:wrap;gap:8px;">
          @php $allRoles = ['athlete','coach','academy','organizer','sponsor','talent_scout','admin']; @endphp
          @foreach($allRoles as $r)
            <label style="display:flex;align-items:center;gap:6px;font-size:13px;background:#f9fafb;border:1px solid #e5e7eb;padding:6px 10px;border-radius:20px;cursor:pointer;">
              <input type="checkbox" name="roles[]" value="{{ $r }}" onchange="updateRecipientPreview()"> {{ ucfirst(str_replace('_',' ',$r)) }}
              <span style="color:#6b7280;">({{ $roleCounts[$r] ?? 0 }})</span>
            </label>
          @endforeach
        </div>
        <div id="recipientPreview" style="margin-top:8px;font-size:12px;color:#1677ff;"></div>
      </div>

      <div class="form-group">
        <label class="form-label">Delivery channels</label>
        <div style="display:flex;gap:12px;flex-wrap:wrap;">
          <label style="display:flex;align-items:center;gap:8px;font-size:13px;background:#fff;border:1px solid #e5e7eb;padding:8px 12px;border-radius:8px;cursor:pointer;">
            <input type="checkbox" name="channels[]" value="in_app" checked onchange="updateChannelHint()"> In-app (bell inbox)
          </label>
          <label style="display:flex;align-items:center;gap:8px;font-size:13px;background:#fff;border:1px solid #e5e7eb;padding:8px 12px;border-radius:8px;cursor:pointer;{{ !$fcmEnabled ? 'opacity:0.6;' : '' }}">
            <input type="checkbox" name="channels[]" value="push" {{ $fcmEnabled ? 'checked' : '' }} {{ !$fcmEnabled ? 'disabled' : '' }} onchange="updateChannelHint()"> Push (FCM) @if(!$fcmEnabled)<span style="color:#dc2626;">— not configured</span>@endif
          </label>
        </div>
        <div id="channelHint" style="margin-top:6px;font-size:12px;color:#6b7280;"></div>
      </div>

      <button class="btn btn-primary" type="submit"><i data-lucide="send" style="width:14px;height:14px;"></i> Send Broadcast</button>
    </form>
  </div>

  @foreach($templates as $t)
    <div class="card no-pad">
      <div class="template-header">
        <span class="template-type {{ $t['type'] }}">{{ $t['type'] }}</span>
        <span class="template-name">{{ $t['name'] }}</span>
      </div>
      <div class="template-body">
        <div class="template-preview">"{{ $t['body'] }}"</div>
        <div class="template-meta">
          <span><i data-lucide="send" style="width:14px;height:14px;"></i> Sent: {{ number_format($sent[$t['type']] ?? 0) }} times</span>
          <span><i data-lucide="bell" style="width:14px;height:14px;"></i> System template</span>
        </div>
        <div class="template-actions">
          <button type="button" class="action-btn edit" onclick="loadTemplate(this)" data-name="{{ $t['name'] }}" data-body="{{ $t['body'] }}" data-type="{{ $t['type'] === 'email' ? 'info' : ($t['type'] === 'sms' ? 'warning' : 'success') }}"><i data-lucide="pencil"></i> Use template</button>
        </div>
      </div>
    </div>
  @endforeach

@push('scripts')
<script>
  const roleCounts = @json($roleCounts);
  const totalActive = {{ $totalActive }};

  function updateRecipientPreview(){
    const checked = [...document.querySelectorAll('input[name="roles[]"]:checked')].map(el=>el.value);
    const el = document.getElementById('recipientPreview');
    if(checked.length===0){
      el.textContent = `→ Will send to all active users (${totalActive})`;
    } else {
      let sum = 0;
      checked.forEach(r => sum += (roleCounts[r] || 0));
      el.textContent = `→ Will send to ${sum} users: ${checked.join(', ')}`;
    }
  }
  function updateChannelHint(){
    const ch = [...document.querySelectorAll('input[name="channels[]"]:checked')].map(el=>el.value);
    const hint = document.getElementById('channelHint');
    if(ch.length===0) hint.textContent = 'Select at least one channel.';
    else if(ch.includes('in_app') && ch.includes('push')) hint.textContent = 'Recipients get both inbox notification and push alert.';
    else if(ch.includes('push')) hint.textContent = 'Push only — requires device tokens; recipients without tokens will miss it.';
    else hint.textContent = 'In-app only — appears in bell inbox on next app open.';
  }
  function loadTemplate(btn) {
    document.getElementById('bcast-title').value = btn.dataset.name;
    document.getElementById('bcast-body').value = btn.dataset.body;
    document.getElementById('bcast-type').value = btn.dataset.type;
    document.getElementById('bcast-title').scrollIntoView({ behavior: 'smooth', block: 'center' });
    document.getElementById('bcast-title').focus();
  }
  updateRecipientPreview();
  updateChannelHint();
  document.getElementById('bcastForm').addEventListener('submit', function(e){
    const ch = [...document.querySelectorAll('input[name="channels[]"]:checked')];
    if(ch.length===0){ e.preventDefault(); alert('Select at least one delivery channel (In-app or Push).'); }
  });

  function toggleTestTargetMode(mode) {
    const tokenGroup = document.getElementById('group-target-token');
    const userGroup = document.getElementById('group-target-user');
    const bcastGroup = document.getElementById('group-target-broadcast');
    const tokenInput = document.getElementById('test-device-token');
    const userSelect = document.getElementById('test-user-select');

    if (tokenGroup) tokenGroup.style.display = (mode === 'token') ? 'block' : 'none';
    if (userGroup) userGroup.style.display = (mode === 'user') ? 'block' : 'none';
    if (bcastGroup) bcastGroup.style.display = (mode === 'broadcast_test') ? 'block' : 'none';

    if (tokenInput) tokenInput.required = (mode === 'token');
    if (userSelect) userSelect.required = (mode === 'user');
  }
</script>
@endpush
@endsection
