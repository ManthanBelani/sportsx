@extends('admin.layouts.app')
@section('title', 'User · ' . $u->name)
@section('header-actions')
  <a href="{{ route('admin.users') }}" class="btn btn-ghost">← Back</a>
@endsection

@section('content')
  <div class="card">
    <div class="listing-header" style="border:none;padding:0 0 16px;border-bottom:1px solid #f0f0f0;">
      <div class="listing-img" style="background:#1677ff;color:#fff;font-weight:700;">{{ strtoupper(substr($u->name,0,1)) }}</div>
      <div class="listing-info">
        <div class="listing-name">{{ $u->name }}</div>
        <div class="listing-meta">{{ ucfirst($u->role) }} • {{ $u->email }}</div>
        <div style="margin-top:6px;"><span class="badge {{ $u->status }}">{{ ucfirst($u->status) }}</span></div>
      </div>
    </div>
    <div class="grid-2" style="margin-top:16px;">
      <div><div class="stat-label">Phone</div><div>{{ $u->phone ?: '—' }}</div></div>
      <div><div class="stat-label">Email verified</div><div>{{ $u->email_verified_at?->format('M d, Y H:i') ?: 'No' }}</div></div>
      <div><div class="stat-label">Joined</div><div>{{ $u->created_at?->format('M d, Y H:i') }}</div></div>
      <div><div class="stat-label">User ID</div><div>#{{ $u->id }}</div></div>
    </div>
  </div>

  @if($u->role !== 'admin')
  <div class="card">
    <div class="card-header"><span class="card-title">Account Actions</span></div>
    <div class="action-btns">
      <form method="POST" action="{{ route('admin.users.status', $u->id) }}">@csrf<input type="hidden" name="action" value="activate"><button class="action-btn approve"><i data-lucide="check"></i> Activate</button></form>
      <form method="POST" action="{{ route('admin.users.status', $u->id) }}">@csrf<input type="hidden" name="action" value="suspend"><button class="action-btn warn"><i data-lucide="alert-triangle"></i> Suspend</button></form>
      <form method="POST" action="{{ route('admin.users.status', $u->id) }}">@csrf<input type="hidden" name="action" value="reject"><button class="action-btn reject"><i data-lucide="x"></i> Reject</button></form>
      <form method="POST" action="{{ route('admin.users.destroy', $u->id) }}" onsubmit="return confirm('Delete this user permanently?')">@csrf @method('DELETE')<button class="action-btn delete"><i data-lucide="trash-2"></i> Delete</button></form>
    </div>
  </div>
  @endif
@endsection
