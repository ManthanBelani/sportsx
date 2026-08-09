<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="csrf-token" content="{{ csrf_token() }}">
  <title>@yield('title', 'Admin Dashboard | SportX India')</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <script src="https://unpkg.com/lucide@latest/dist/umd/lucide.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Inter', system-ui, -apple-system, sans-serif;
      background: #f7f8fa;
      color: #111111;
      min-height: 100vh;
      display: flex;
    }
    .sidebar {
      width: 260px;
      background: #111111;
      min-height: 100vh;
      position: fixed;
      left: 0;
      top: 0;
      display: flex;
      flex-direction: column;
      z-index: 100;
    }
    .sidebar-brand {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 20px 24px;
      border-bottom: 1px solid #333;
    }
    .sidebar-brand-icon {
      width: 40px;
      height: 40px;
      background: linear-gradient(135deg, #1677ff, #0d47a1);
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .sidebar-brand-text {
      font-size: 18px;
      font-weight: 700;
      color: #fff;
    }
    .sidebar-nav { flex: 1; padding: 16px 0; overflow-y: auto; }
    .sidebar-nav-section { padding: 0 12px; margin-bottom: 8px; }
    .sidebar-nav-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: #6b7280; padding: 8px 12px; }
    .sidebar-nav-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 10px 16px;
      color: #9ca3af;
      text-decoration: none;
      font-size: 14px;
      font-weight: 500;
      border-radius: 8px;
      margin: 2px 0;
      transition: all 0.15s;
    }
    .sidebar-nav-item:hover { background: #1a1a1a; color: #fff; }
    .sidebar-nav-item.active { background: #1677ff; color: #fff; }
    .sidebar-nav-item svg { width: 18px; height: 18px; }
    .sidebar-footer { padding: 16px 24px; border-top: 1px solid #333; }
    .sidebar-user { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
    .sidebar-user-avatar { width: 36px; height: 36px; background: #333; border-radius: 8px; display: flex; align-items: center; justify-content: center; }
    .sidebar-user-info { flex: 1; }
    .sidebar-user-name { font-size: 13px; font-weight: 600; color: #fff; }
    .sidebar-user-role { font-size: 11px; color: #6b7280; }
    .logout-btn { background: none; border: none; color: #ef4444; cursor: pointer; display: flex; align-items: center; }
    
    .main { margin-left: 260px; flex: 1; min-height: 100vh; display: flex; flex-direction: column; width: calc(100% - 260px); }
    .main-header {
      background: #fff;
      padding: 16px 32px;
      border-bottom: 1px solid #e5e7eb;
      display: flex;
      align-items: center;
      justify-content: space-between;
      position: sticky;
      top: 0;
      z-index: 50;
    }
    .main-header-left { display: flex; align-items: center; gap: 16px; }
    .main-header h1 { font-size: 20px; font-weight: 600; }
    .header-badge { background: #1677ff; color: #fff; font-size: 12px; padding: 4px 12px; border-radius: 20px; font-weight: 500; }
    .main-content { padding: 24px 32px; flex: 1; overflow-x: hidden; }
    
    /* Common UI Components */
    .stat-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 24px; }
    .stat-card { background: #fff; border-radius: 12px; padding: 20px; border: 1px solid #e5e7eb; }
    .stat-icon { width: 44px; height: 44px; border-radius: 10px; display: flex; align-items: center; justify-content: center; margin-bottom: 12px; }
    .stat-icon.blue { background: #dbeafe; }
    .stat-icon.green { background: #dcfce7; }
    .stat-icon.orange { background: #fef3c7; }
    .stat-icon.red { background: #fee2e2; }
    .stat-label { font-size: 13px; color: #6b7280; margin-bottom: 4px; font-weight: 500; }
    .stat-value { font-size: 28px; font-weight: 700; color: #111; }
    .stat-change { font-size: 12px; color: #6b7280; margin-top: 4px; }
    .stat-change.up { color: #16a34a; }
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
    .card { background: #fff; border-radius: 12px; padding: 20px; border: 1px solid #e5e7eb; margin-bottom: 24px; }
    .card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; padding-bottom: 12px; border-bottom: 1px solid #f0f0f0; }
    .card-title { font-size: 15px; font-weight: 600; display: flex; align-items: center; gap: 8px; }
    .card-title svg { width: 18px; height: 18px; color: #6b7280; }
    .see-all { font-size: 13px; color: #1677ff; font-weight: 500; text-decoration: none; }
    
    /* Tables */
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 12px 16px; text-align: left; border-bottom: 1px solid #f0f0f0; }
    th { font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; background: #f9fafb; }
    td { font-size: 14px; }
    
    /* Utility */
    .btn { display: inline-flex; align-items: center; gap: 8px; padding: 8px 16px; border-radius: 8px; font-size: 13px; font-weight: 500; border: none; cursor: pointer; text-decoration: none; }
    .btn-primary { background: #1677ff; color: #fff; }
    .btn-outline { background: #fff; border: 1px solid #e5e7eb; color: #111; }
    .btn-danger { background: #fee2e2; color: #dc2626; }
    
    @stack('styles')
  </style>
</head>
<body>
  <aside class="sidebar">
    <div class="sidebar-brand">
      <div class="sidebar-brand-icon"><i data-lucide="shield" style="width:22px;height:22px;color:#fff;"></i></div>
      <span class="sidebar-brand-text">SportX</span>
    </div>
    <nav class="sidebar-nav">
      <div class="sidebar-nav-section">
        <div class="sidebar-nav-label">Main</div>
        <a href="{{ route('admin.dashboard') }}" class="sidebar-nav-item @if(request()->routeIs('admin.dashboard')) active @endif"><i data-lucide="layout-dashboard"></i>Dashboard</a>
        <a href="{{ route('admin.users') }}" class="sidebar-nav-item @if(request()->routeIs('admin.users')) active @endif"><i data-lucide="users"></i>Users</a>
        <a href="{{ route('admin.moderation') }}" class="sidebar-nav-item @if(request()->routeIs('admin.moderation')) active @endif"><i data-lucide="clipboard-list"></i>Moderation</a>
        <a href="{{ route('admin.reports') }}" class="sidebar-nav-item @if(request()->routeIs('admin.reports')) active @endif"><i data-lucide="alert-octagon"></i>Reports</a>
        <a href="{{ route('admin.approvals') }}" class="sidebar-nav-item @if(request()->routeIs('admin.approvals')) active @endif"><i data-lucide="check-circle"></i>Approvals</a>
        <a href="{{ route('admin.opportunities') }}" class="sidebar-nav-item @if(request()->routeIs('admin.opportunities')) active @endif"><i data-lucide="briefcase"></i>Opportunities</a>
      </div>
      <div class="sidebar-nav-section">
        <div class="sidebar-nav-label">Management</div>
        <a href="#" class="sidebar-nav-item"><i data-lucide="badge-check"></i>Sponsors</a>
        <a href="#" class="sidebar-nav-item"><i data-lucide="flag"></i>Content Flags</a>
      </div>
      <div class="sidebar-nav-section">
        <div class="sidebar-nav-label">System</div>
        <a href="#" class="sidebar-nav-item"><i data-lucide="bar-chart-2"></i>Analytics</a>
        <a href="{{ route('admin.notifications.compose') }}" class="sidebar-nav-item @if(request()->routeIs('admin.notifications.compose')) active @endif"><i data-lucide="bell"></i>Notifications</a>
        <a href="#" class="sidebar-nav-item"><i data-lucide="tag"></i>Categories</a>
        <a href="#" class="sidebar-nav-item"><i data-lucide="settings"></i>Settings</a>
      </div>
    </nav>
    <div class="sidebar-footer">
      <div class="sidebar-user">
        <div class="sidebar-user-avatar"><i data-lucide="user" style="width:18px;height:18px;color:#9ca3af;"></i></div>
        <div class="sidebar-user-info">
          <div class="sidebar-user-name">Admin User</div>
          <div class="sidebar-user-role">Super Admin</div>
        </div>
        <button onclick="logout()" class="logout-btn" title="Logout"><i data-lucide="log-out" style="width:18px;height:18px;"></i></button>
      </div>
    </div>
  </aside>

  <main class="main">
    <header class="main-header">
      <div class="main-header-left">
        <h1>@yield('title', 'Dashboard')</h1>
      </div>
      @stack('topbar-actions')
    </header>

    <div class="main-content">
      @yield('content')
    </div>
  </main>
  
  <script>
    lucide.createIcons();
    
    // Auth helpers for API interactions in blade
    function getAuthToken() {
        return localStorage.getItem('token');
    }
    
    function requireAuth() {
        const token = getAuthToken();
        if (!token) {
            window.location.href = '/admin/login';
            return false;
        }
        return true;
    }
    
    function logout() {
        localStorage.removeItem('token');
        window.location.href = '/admin/login';
    }
    
    async function api(method, url, data = null) {
        const token = getAuthToken();
        const headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        };
        if (token) headers['Authorization'] = `Bearer ${token}`;
        
        const options = { method, headers };
        if (data) options.body = JSON.stringify(data);
        
        try {
            const res = await fetch(`/api/admin${url}`, options);
            if (res.status === 401) {
                logout();
                return { ok: false, error: 'Unauthorized' };
            }
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                return { ok: false, error: err.message || 'Error' };
            }
            const json = await res.json().catch(() => ({}));
            return { ok: true, data: json };
        } catch (e) {
            return { ok: false, error: e.message };
        }
    }
  </script>
  @stack('scripts')
</body>
</html>
