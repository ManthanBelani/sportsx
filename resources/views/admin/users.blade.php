@extends('admin.layouts.main')

@section('title', 'User Management')

@push('topbar-actions')
<span class="header-badge" id="total-users-badge">Loading...</span>
@endpush

@section('content')
<style>
  .card { background: #fff; border-radius: 12px; border: 1px solid #e5e7eb; margin-bottom: 24px; overflow: hidden; }
  .card-header { padding: 16px 20px; border-bottom: 1px solid #e5e7eb; display: flex; justify-content: space-between; align-items: center; }
  .card-title { font-size: 15px; font-weight: 600; }
  .search-bar { display: flex; gap: 12px; padding: 16px 20px; background: #f9fafb; border-bottom: 1px solid #e5e7eb; }
  .search-input { flex: 1; display: flex; align-items: center; gap: 10px; background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 10px 14px; }
  .search-input input { border: none; background: none; outline: none; font-size: 14px; flex: 1; }
  .filter-btn { display: flex; align-items: center; gap: 6px; padding: 10px 14px; background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; font-size: 14px; font-weight: 500; cursor: pointer; }
  
  /* Rich Grid Cards styles */
  .users-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; padding: 20px; }
  .user-card { background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 20px; display: flex; flex-direction: column; gap: 16px; box-shadow: 0 1px 2px rgba(0,0,0,0.05); transition: transform 0.2s, box-shadow 0.2s; }
  .user-card:hover { transform: translateY(-2px); box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
  .user-card-header { display: flex; justify-content: space-between; align-items: flex-start; }
  .user-profile { display: flex; gap: 12px; align-items: center; }
  .user-avatar { width: 42px; height: 42px; background: #f0f7ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: #1677ff; }
  .user-name { font-weight: 600; font-size: 15px; color: #111; }
  .user-email { font-size: 13px; color: #6b7280; }
  
  .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 500; }
  .badge.athlete { background: #fef3c7; color: #d97706; }
  .badge.coach { background: #dbeafe; color: #1677ff; }
  .badge.academy { background: #dcfce7; color: #16a34a; }
  .badge.sponsor { background: #f3e8ff; color: #9333ea; }
  
  .user-card-meta { display: flex; justify-content: space-between; align-items: center; font-size: 13px; color: #6b7280; }
  .status-indicator { display: flex; align-items: center; gap: 6px; }
  .status-dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; }
  .status-dot.active { background: #16a34a; }
  .status-dot.inactive { background: #6b7280; }
  
  .user-card-footer { border-top: 1px solid #f0f0f0; padding-top: 16px; display: flex; gap: 8px; }
  .action-btn { flex: 1; padding: 8px 12px; border-radius: 8px; font-size: 13px; font-weight: 500; border: none; cursor: pointer; text-decoration: none; display: flex; align-items: center; justify-content: center; gap: 6px; }
  .action-btn.view { background: #f0f7ff; color: #1677ff; }
  .action-btn.warn { background: #fef3c7; color: #d97706; }
</style>

<div class="card">
  <div class="card-header">
    <span class="card-title">All Users</span>
  </div>
  <div class="search-bar">
    <div class="search-input">
      <i data-lucide="search" style="width:18px;height:18px;color:#6b7280;"></i>
      <input type="text" id="search-input" placeholder="Search users by name, email or ID..." oninput="renderUsers()">
    </div>
    <select id="role-filter" class="filter-btn" onchange="renderUsers()" style="border: 1px solid #e5e7eb; border-radius: 8px; background: #fff; padding: 10px 14px; outline: none; cursor: pointer;">
      <option value="all">All Roles</option>
      <option value="athlete">Athlete</option>
      <option value="coach">Coach</option>
      <option value="sponsor">Sponsor</option>
      <option value="academy">Academy</option>
    </select>
  </div>
  
  <div class="users-grid" id="users-grid-container">
    <div style="grid-column: 1 / -1; text-align: center; padding: 40px; color: #6b7280;">Loading users...</div>
  </div>
</div>
@endsection

@push('scripts')
<script>
let allUsers = [];

document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;
    await loadUsers();
});

async function loadUsers() {
    // For MVP we mock the unified list
    allUsers = [
        { id: 1, name: 'Priya Sharma', email: 'priya.sharma@email.com', role: 'Athlete', joined: 'Jan 15, 2024', active: true },
        { id: 2, name: 'Arjun Kumar', email: 'arjun.k@email.com', role: 'Coach', joined: 'Jan 16, 2024', active: false },
        { id: 3, name: 'Tata Sports', email: 'contact@tatasports.in', role: 'Sponsor', joined: 'Jan 20, 2024', active: true },
        { id: 4, name: 'Delhi Cricket Academy', email: 'info@dca.in', role: 'Academy', joined: 'Jan 22, 2024', active: true },
        { id: 5, name: 'Rohan Verma', email: 'rohan.v@email.com', role: 'Athlete', joined: 'Feb 01, 2024', active: true },
        { id: 6, name: 'Vikram Singh', email: 'vikram.s@email.com', role: 'Coach', joined: 'Feb 10, 2024', active: true },
    ];
    document.getElementById('total-users-badge').textContent = allUsers.length + ' Users';
    renderUsers();
}

function renderUsers() {
    const search = document.getElementById('search-input').value.toLowerCase();
    const roleFilter = document.getElementById('role-filter').value;
    const container = document.getElementById('users-grid-container');
    
    let filtered = allUsers.filter(u => {
        if (roleFilter !== 'all' && u.role.toLowerCase() !== roleFilter) return false;
        if (search && !u.name.toLowerCase().includes(search) && !u.email.toLowerCase().includes(search)) return false;
        return true;
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div style="grid-column: 1 / -1; text-align: center; padding: 40px; color: #6b7280;">No users found matching your search.</div>';
        return;
    }

    container.innerHTML = filtered.map(u => {
        const badgeClass = u.role.toLowerCase();
        return `
            <div class="user-card">
              <div class="user-card-header">
                <div class="user-profile">
                  <div class="user-avatar"><i data-lucide="user" style="width:20px;height:20px;"></i></div>
                  <div>
                    <div class="user-name">${u.name}</div>
                    <div class="user-email">${u.email}</div>
                  </div>
                </div>
              </div>
              
              <div class="user-card-meta">
                <span class="badge ${badgeClass}">${u.role}</span>
                <div class="status-indicator">
                  <span class="status-dot ${u.active ? 'active' : 'inactive'}"></span>
                  ${u.active ? 'Active' : 'Inactive'}
                </div>
              </div>
              
              <div style="font-size: 13px; color: #6b7280; display: flex; align-items: center; gap: 6px;">
                <i data-lucide="calendar" style="width:14px;height:14px;"></i> Joined ${u.joined}
              </div>
              
              <div class="user-card-footer">
                <a href="{{ route('admin.users') }}/${u.id}" class="action-btn view">
                  <i data-lucide="eye" style="width:16px;height:16px;"></i> View Profile
                </a>
                <button class="action-btn warn">
                  <i data-lucide="alert-triangle" style="width:16px;height:16px;"></i> Warn
                </button>
              </div>
            </div>
        `;
    }).join('');
    
    lucide.createIcons();
}
</script>
@endpush
