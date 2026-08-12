@extends('admin.layouts.app')
@section('title', 'User Management')
@section('header-actions')
  <span class="header-badge">{{ number_format($users->total()) }} Users</span>
@endsection

@section('content')
  <div class="card no-pad">
    <div class="card-header"><span class="card-title">All Users</span></div>
    <form class="search-bar" method="GET" action="{{ route('admin.users') }}">
      <div class="search-input">
        <i data-lucide="search" style="width:18px;height:18px;color:#6b7280;"></i>
        <input type="text" name="q" value="{{ request('q') }}" placeholder="Search users by name or email…">
      </div>
      <select class="filter-btn" name="role">
        <option value="">All roles</option>
        @foreach(['athlete','coach','academy','organizer','sponsor','admin'] as $r)
          <option value="{{ $r }}" @if(request('role')===$r) selected @endif>{{ ucfirst($r) }}</option>
        @endforeach
      </select>
      <select class="filter-btn" name="status">
        <option value="">All status</option>
        @foreach(['active','suspended','rejected'] as $s)
          <option value="{{ $s }}" @if(request('status')===$s) selected @endif>{{ ucfirst($s) }}</option>
        @endforeach
      </select>
      <button class="btn btn-primary"><i data-lucide="filter" style="width:14px;height:14px;"></i>Filter</button>
    </form>

    <div class="table-scroll">
    <table class="table">
      <thead><tr><th>User</th><th>Role</th><th>Status</th><th>Joined</th><th>Actions</th></tr></thead>
      <tbody>
        @forelse($users as $u)
          <tr>
            <td>
              <div class="user-cell">
                <div class="user-avatar"><i data-lucide="user" style="width:18px;height:18px;"></i></div>
                <div><div class="user-name">{{ $u->name }}</div><div class="user-email">{{ $u->email }}</div></div>
              </div>
            </td>
            <td><span class="badge {{ $u->role }}">{{ ucfirst($u->role) }}</span></td>
            <td><span class="status-dot {{ $u->status === 'active' ? 'active' : ($u->status === 'suspended' ? 'suspended' : 'inactive') }}"></span>{{ ucfirst($u->status) }}</td>
            <td>{{ $u->created_at?->format('M d, Y') }}</td>
            <td>
              @if($u->role !== 'admin')
                <div class="action-btns">
                  <a href="{{ route('admin.users.detail', $u->id) }}" class="action-btn view"><i data-lucide="eye" style="width:14px;height:14px;"></i> View</a>
                  <form method="POST" action="{{ route('admin.users.status', $u->id) }}">@csrf
                    <input type="hidden" name="action" value="{{ $u->status === 'active' ? 'suspend' : 'activate' }}">
                    <button class="action-btn {{ $u->status === 'active' ? 'warn' : 'approve' }}">{{ $u->status === 'active' ? 'Suspend' : 'Activate' }}</button>
                  </form>
                </div>
              @else
                <a href="{{ route('admin.users.detail', $u->id) }}" class="action-btn view">View</a>
              @endif
            </td>
          </tr>
        @empty
          <tr><td colspan="5" class="empty">No users found.</td></tr>
        @endforelse
      </tbody>
    </table>
    </div>
  </div>
  @if($users->hasPages())<div class="pager">{{ $users->links() }}</div>@endif
@endsection
