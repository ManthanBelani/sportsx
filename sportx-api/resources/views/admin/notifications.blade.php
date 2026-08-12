@extends('admin.layouts.app')
@section('title', 'Notification Templates')
@section('header-actions')
  <span class="header-badge">Total sent: {{ number_format($sent->sum()) }}</span>
@endsection

@section('content')
  <div class="card">
    <div class="card-header"><span class="card-title"><i data-lucide="megaphone"></i>Broadcast to All Users</span></div>
    <form method="POST" action="{{ route('admin.notifications.broadcast') }}">@csrf
      <div class="form-row">
        <div class="form-group" style="flex:2;"><label class="form-label">Title</label><input class="input" id="bcast-title" name="title" required placeholder="e.g. New tournament season open!"></div>
        <div class="form-group"><label class="form-label">Type</label><select class="select" id="bcast-type" name="type"><option value="info">Info</option><option value="success">Success</option><option value="warning">Warning</option></select></div>
      </div>
      <div class="form-group"><label class="form-label">Message</label><textarea class="input" id="bcast-body" name="body" rows="3" required placeholder="Write the broadcast message…"></textarea></div>
      <button class="btn btn-primary"><i data-lucide="send" style="width:14px;height:14px;"></i> Send Broadcast</button>
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
          <span><i data-lucide="send" style="width:14px;height:14px;"></i> Sent: {{ number_format($sent[$t['name']] ?? 0) }} times</span>
          <span><i data-lucide="bell" style="width:14px;height:14px;"></i> System template</span>
        </div>
        <div class="template-actions">
          <button type="button" class="action-btn edit" onclick="loadTemplate(this)" data-name="{{ $t['name'] }}" data-body="{{ $t['body'] }}" data-type="{{ $t['type'] === 'email' ? 'info' : ($t['type'] === 'sms' ? 'warning' : 'success') }}"><i data-lucide="pencil"></i> Edit</button>
          <button type="button" class="action-btn duplicate" onclick="loadTemplate(this)" data-name="{{ $t['name'] }} (copy)" data-body="{{ $t['body'] }}" data-type="{{ $t['type'] === 'email' ? 'info' : ($t['type'] === 'sms' ? 'warning' : 'success') }}"><i data-lucide="copy"></i> Duplicate</button>
        </div>
      </div>
    </div>
  @endforeach
@push('scripts')
<script>
  function loadTemplate(btn) {
    document.getElementById('bcast-title').value = btn.dataset.name;
    document.getElementById('bcast-body').value = btn.dataset.body;
    document.getElementById('bcast-type').value = btn.dataset.type;
    document.getElementById('bcast-title').scrollIntoView({ behavior: 'smooth', block: 'center' });
    document.getElementById('bcast-title').focus();
  }
</script>
@endpush
@endsection
