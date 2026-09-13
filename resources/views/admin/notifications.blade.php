@extends('admin.layouts.app')
@section('title', 'Notification Templates')
@section('header-actions')
  <span class="header-badge">Total sent: {{ number_format($sent['_total'] ?? $sent->sum()) }}</span>
@endsection

@section('content')
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
</script>
@endpush
@endsection
