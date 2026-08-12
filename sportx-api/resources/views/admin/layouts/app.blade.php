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
    html, body { min-height: 100%; }
    body { font-family: 'Inter', system-ui, -apple-system, sans-serif; background: #f7f8fa; color: #111111; min-height: 100vh; overflow-x: hidden; }
    a { text-decoration: none; color: inherit; }

    /* ── Sidebar (fixed rail on desktop, off-canvas drawer on mobile) ── */
    .sidebar { width: 260px; max-width: 86vw; background: #111111; position: fixed; left: 0; top: 0; bottom: 0; display: flex; flex-direction: column; z-index: 100; }
    .sidebar-brand { display: flex; align-items: center; gap: 12px; padding: 20px 24px; border-bottom: 1px solid #333; }
    .sidebar-brand-icon { width: 40px; height: 40px; background: linear-gradient(135deg, #1677ff, #0d47a1); border-radius: 10px; display: flex; align-items: center; justify-content: center; }
    .sidebar-brand-text { font-size: 18px; font-weight: 700; color: #fff; }
    .sidebar-nav { flex: 1; padding: 16px 0; overflow-y: auto; }
    .sidebar-nav-section { padding: 0 12px; margin-bottom: 8px; }
    .sidebar-nav-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: #6b7280; padding: 8px 12px; }
    .sidebar-nav-item { display: flex; align-items: center; gap: 12px; padding: 10px 16px; color: #9ca3af; text-decoration: none; font-size: 14px; font-weight: 500; border-radius: 8px; margin: 2px 0; transition: all 0.15s; }
    .sidebar-nav-item:hover { background: #1a1a1a; color: #fff; }
    .sidebar-nav-item.active { background: #1677ff; color: #fff; }
    .sidebar-nav-item svg { width: 18px; height: 18px; }
    .sidebar-footer { padding: 16px 24px; border-top: 1px solid #333; }
    .sidebar-user { display: flex; align-items: center; gap: 12px; }
    .sidebar-user-avatar { width: 36px; height: 36px; background: #333; border-radius: 8px; display: flex; align-items: center; justify-content: center; }
    .sidebar-user-info { flex: 1; }
    .sidebar-user-name { font-size: 13px; font-weight: 600; color: #fff; }
    .sidebar-user-role { font-size: 11px; color: #6b7280; }
    .logout-btn { background: none; border: none; color: #ef4444; cursor: pointer; }

    /* ── Main ── */
    .main { margin-left: 260px; min-height: 100vh; display: flex; flex-direction: column; width: auto; }
    .main-header { background: #fff; padding: 16px 32px; border-bottom: 1px solid #e5e7eb; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 50; }
    .main-header h1 { font-size: 20px; font-weight: 600; }
    .header-badge { background: #1677ff; color: #fff; font-size: 12px; padding: 4px 12px; border-radius: 20px; font-weight: 500; }
    .header-badge.warning { background: #fef3c7; color: #d97706; }
    .header-right { display: flex; align-items: center; gap: 12px; }
    .admin-chip { display: flex; align-items: center; gap: 10px; padding: 4px 6px 4px 4px; border-radius: 30px; background: #fff; border: 1px solid #e5e7eb; }
    .admin-avatar { width: 34px; height: 34px; border-radius: 50%; background: linear-gradient(135deg, #1677ff, #0d47a1); color: #fff; font-weight: 700; font-size: 14px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
    .admin-meta { line-height: 1.2; }
    .admin-name { font-size: 13px; font-weight: 600; color: #111; }
    .admin-role { font-size: 11px; color: #6b7280; }
    .main-content { padding: 24px 32px; flex: 1; min-width: 0; }

    /* ── Stats ── */
    .stat-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 24px; }
    .stat-card { background: #fff; border-radius: 12px; padding: 20px; border: 1px solid #e5e7eb; }
    .stat-icon { width: 44px; height: 44px; border-radius: 10px; display: flex; align-items: center; justify-content: center; margin-bottom: 12px; }
    .stat-icon.blue { background: #dbeafe; } .stat-icon.green { background: #dcfce7; } .stat-icon.orange { background: #fef3c7; } .stat-icon.red { background: #fee2e2; }
    .stat-label { font-size: 13px; color: #6b7280; margin-bottom: 4px; font-weight: 500; }
    .stat-value { font-size: 28px; font-weight: 700; color: #111; }
    .stat-change { font-size: 12px; color: #6b7280; margin-top: 4px; }
    .stat-change.up { color: #16a34a; }

    /* ── Cards & layout ── */
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
    .card { background: #fff; border-radius: 12px; padding: 20px; border: 1px solid #e5e7eb; margin-bottom: 24px; }
    .card.no-pad { padding: 0; overflow: hidden; }
    .card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; padding-bottom: 12px; border-bottom: 1px solid #f0f0f0; }
    .card.no-pad .card-header { margin: 0; padding: 16px 20px; border-bottom: 1px solid #e5e7eb; }
    .card-title { font-size: 15px; font-weight: 600; display: flex; align-items: center; gap: 8px; }
    .card-title svg { width: 18px; height: 18px; color: #6b7280; }
    .card-subtitle { font-size: 12px; color: #6b7280; font-weight: 400; }
    .card-desc { font-size: 12px; color: #6b7280; font-weight: 400; }
    .see-all { font-size: 13px; color: #1677ff; font-weight: 500; text-decoration: none; }

    /* ── Alerts ── */
    .alert-card { display: flex; align-items: center; gap: 14px; padding: 14px 0; border-bottom: 1px solid #f0f0f0; }
    .alert-card:last-child { border-bottom: none; }
    .alert-icon { width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
    .alert-icon.danger { background: #fee2e2; } .alert-icon.warning { background: #fef3c7; } .alert-icon.info { background: #dbeafe; }
    .alert-content { flex: 1; min-width: 0; }
    .alert-title { font-size: 13px; font-weight: 500; }
    .alert-meta { font-size: 11px; color: #6b7280; margin-top: 2px; }
    .alert-badge { font-size: 10px; padding: 4px 10px; border-radius: 6px; font-weight: 500; flex-shrink: 0; }
    .alert-badge.critical { background: #fee2e2; color: #dc2626; } .alert-badge.pending { background: #fef3c7; color: #d97706; } .alert-badge.new { background: #dbeafe; color: #1677ff; } .alert-badge.resolved { background: #dcfce7; color: #16a34a; }

    /* ── Quick actions ── */
    .quick-action-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
    .quick-action { background: #f9fafb; border-radius: 10px; padding: 16px; text-align: center; text-decoration: none; color: #111; transition: all 0.15s; border: 1px solid #e5e7eb; }
    .quick-action:hover { background: #f0f7ff; border-color: #1677ff; }
    .quick-action-icon { width: 44px; height: 44px; background: #fff; border-radius: 10px; display: flex; align-items: center; justify-content: center; margin: 0 auto 10px; border: 1px solid #e5e7eb; }
    .quick-action-label { font-size: 13px; font-weight: 500; }

    /* ── Charts ── */
    .bar-chart { display: flex; align-items: flex-end; gap: 12px; height: 120px; padding-top: 20px; }
    .bar-group { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 6px; height: 100%; justify-content: flex-end; }
    .bar { width: 100%; background: #dbeafe; border-radius: 6px 6px 0 0; min-height: 20px; }
    .bar.highlight { background: #1677ff; }
    .bar-label { font-size: 11px; color: #6b7280; margin-top: 8px; }
    .chart-area { display: flex; align-items: flex-end; gap: 10px; height: 180px; padding-top: 20px; }
    .chart-bar { flex: 1; background: linear-gradient(180deg, #1677ff, #60a5fa); border-radius: 8px 8px 0 0; min-height: 12px; }
    .chart-labels { display: flex; gap: 10px; margin-top: 8px; }
    .chart-label { flex: 1; text-align: center; font-size: 11px; color: #6b7280; }
    .chart-stats { display: flex; justify-content: space-around; margin-top: 16px; padding-top: 16px; border-top: 1px solid #f0f0f0; }
    .chart-stat { text-align: center; } .chart-stat-value { font-size: 15px; font-weight: 600; } .chart-stat-label { font-size: 11px; color: #6b7280; }

    /* ── Tables ── */
    .table { width: 100%; border-collapse: collapse; }
    .table th { text-align: left; padding: 12px 20px; font-size: 12px; font-weight: 600; color: #6b7280; background: #f9fafb; border-bottom: 1px solid #e5e7eb; }
    .table td { padding: 14px 20px; font-size: 14px; border-bottom: 1px solid #f0f0f0; }
    .table tr:hover { background: #f9fafb; }
    .user-cell, .cat-cell, .sport-cell { display: flex; align-items: center; gap: 12px; }
    .user-avatar, .cat-icon, .sport-icon { width: 36px; height: 36px; background: #f0f7ff; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: #1677ff; }
    .user-name, .cat-name { font-weight: 500; } .user-email, .cat-subcount { font-size: 12px; color: #6b7280; }

    /* ── Badges ── */
    .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 500; }
    .badge.athlete { background: #fef3c7; color: #d97706; } .badge.coach { background: #dbeafe; color: #1677ff; } .badge.academy { background: #dcfce7; color: #16a34a; } .badge.organizer { background: #e0e7ff; color: #4338ca; } .badge.sponsor { background: #f3e8ff; color: #9333ea; } .badge.admin { background: #f3e8ff; color: #9333ea; }
    .badge.active { background: #dcfce7; color: #16a34a; } .badge.inactive, .badge.rejected { background: #fee2e2; color: #dc2626; } .badge.pending { background: #fef3c7; color: #d97706; }
    .status-dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; margin-right: 6px; }
    .status-dot.active { background: #16a34a; } .status-dot.suspended { background: #dc2626; } .status-dot.inactive { background: #6b7280; }
    .rank-badge { display: inline-flex; align-items: center; justify-content: center; width: 26px; height: 26px; border-radius: 8px; background: #f0f7ff; color: #1677ff; font-weight: 600; font-size: 13px; }

    /* ── Buttons / actions ── */
    .btn { padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 500; border: none; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; text-decoration: none; font-family: inherit; }
    .btn-primary { background: #1677ff; color: #fff; }
    .btn-danger { background: #dc2626; color: #fff; }
    .btn-ghost { background: #fff; border: 1px solid #e5e7eb; color: #111; }
    .action-btns { display: flex; gap: 8px; flex-wrap: wrap; }
    .action-btn { padding: 6px 12px; border-radius: 6px; font-size: 13px; font-weight: 500; border: none; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; font-family: inherit; }
    .action-btn.view { background: #f0f7ff; color: #1677ff; } .action-btn.edit { background: #f0f7ff; color: #1677ff; }
    .action-btn.approve, .action-btn.resolve, .action-btn.dismiss { background: #dcfce7; color: #16a34a; }
    .action-btn.reject, .action-btn.remove, .action-btn.delete { background: #fee2e2; color: #dc2626; }
    .action-btn.warn, .action-btn.escalate { background: #fef3c7; color: #d97706; }
    .action-btn.duplicate { background: #f3e8ff; color: #9333ea; }
    .action-btn.disable { background: #fee2e2; color: #dc2626; }

    /* ── Search / filters ── */
    .search-bar { display: flex; gap: 12px; padding: 16px 20px; background: #f9fafb; border-bottom: 1px solid #e5e7eb; flex-wrap: wrap; }
    .search-input { flex: 1; display: flex; align-items: center; gap: 10px; background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 10px 14px; }
    .search-input input, .search-input select { border: none; background: none; outline: none; font-size: 14px; flex: 1; font-family: inherit; }
    .filter-btn { display: inline-flex; align-items: center; gap: 6px; padding: 10px 14px; background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; font-size: 14px; font-weight: 500; cursor: pointer; }

    /* ── Tabs ── */
    .tabs { display: flex; gap: 4px; margin-bottom: 24px; background: #fff; padding: 4px; border-radius: 10px; border: 1px solid #e5e7eb; width: fit-content; }
    .tab { padding: 8px 16px; border-radius: 8px; font-size: 14px; font-weight: 500; cursor: pointer; color: #6b7280; border: none; background: none; font-family: inherit; text-decoration: none; }
    .tab.active { background: #111; color: #fff; }

    /* ── Listing / report / flag / sponsor / template cards ── */
    .listing-header, .report-row-head { display: flex; align-items: center; gap: 16px; padding: 16px 20px; border-bottom: 1px solid #f0f0f0; }
    .listing-img, .card-header-icon, .report-type, .sponsor-logo { width: 60px; height: 60px; background: #f0f7ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
    .report-type { width: 40px; height: 40px; border-radius: 10px; }
    .listing-info, .report-info, .sponsor-info, .card-header-info { flex: 1; min-width: 0; }
    .listing-name, .report-title, .sponsor-name, .card-header-title { font-size: 15px; font-weight: 600; margin-bottom: 2px; }
    .listing-meta, .report-meta, .sponsor-type, .card-header-meta { font-size: 12px; color: #6b7280; display: flex; align-items: center; gap: 6px; }
    .listing-flagged { background: #fee2e2; color: #dc2626; font-size: 11px; padding: 4px 8px; border-radius: 6px; font-weight: 500; }
    .listing-body, .card-body { padding: 16px 20px; }
    .listing-desc, .report-detail, .flag-desc { font-size: 13px; color: #6b7280; margin-bottom: 12px; line-height: 1.5; }
    .listing-actions, .action-bar, .sponsor-actions { display: flex; gap: 10px; flex-wrap: wrap; }
    .report-target { font-size: 12px; color: #6b7280; margin-bottom: 12px; display: flex; align-items: center; gap: 6px; }
    .report-badge { font-size: 11px; padding: 4px 10px; border-radius: 6px; font-weight: 500; flex-shrink: 0; }
    .report-badge.critical { background: #fee2e2; color: #dc2626; } .report-badge.pending { background: #fef3c7; color: #d97706; } .report-badge.resolved { background: #dcfce7; color: #16a34a; }
    .flag-tags { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 12px; }
    .flag-tag { background: #fee2e2; color: #dc2626; font-size: 11px; padding: 4px 10px; border-radius: 6px; font-weight: 500; }

    /* Sponsor docs */
    .sponsor-header { display: flex; align-items: center; gap: 16px; padding: 16px 20px; border-bottom: 1px solid #f0f0f0; }
    .sponsor-tier { font-size: 11px; padding: 4px 10px; border-radius: 6px; font-weight: 600; }
    .sponsor-tier.platinum { background: #e5e7eb; color: #444; } .sponsor-tier.gold { background: #fef3c7; color: #d97706; }
    .docs-section { padding: 16px 20px; border-top: 1px solid #f0f0f0; }
    .docs-title { font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; margin-bottom: 12px; }
    .doc-row { display: flex; align-items: center; gap: 10px; padding: 8px 0; font-size: 13px; }
    .doc-name { flex: 1; } .doc-icon { display: flex; }
    .doc-status.verified { color: #16a34a; font-size: 12px; } .doc-status.pending { color: #d97706; font-size: 12px; }

    /* Templates */
    .template-header { display: flex; align-items: center; gap: 10px; padding: 14px 20px; border-bottom: 1px solid #f0f0f0; }
    .template-type { font-size: 11px; padding: 4px 10px; border-radius: 6px; font-weight: 600; text-transform: uppercase; }
    .template-type.email { background: #dbeafe; color: #1677ff; } .template-type.push { background: #dcfce7; color: #16a34a; } .template-type.sms { background: #fef3c7; color: #d97706; }
    .template-name { font-weight: 600; font-size: 14px; }
    .template-body { padding: 14px 20px; }
    .template-preview { font-size: 13px; color: #6b7280; line-height: 1.5; margin-bottom: 10px; }
    .template-meta { display: flex; gap: 16px; font-size: 12px; color: #6b7280; margin-bottom: 12px; }
    .template-meta span { display: inline-flex; align-items: center; gap: 4px; }

    /* Settings */
    .settings-list { }
    .settings-item { display: flex; align-items: center; gap: 14px; padding: 16px 20px; border-bottom: 1px solid #f0f0f0; }
    .settings-item:last-child { border-bottom: none; }
    .settings-icon { display: flex; } .settings-info { flex: 1; }
    .settings-label { font-size: 14px; font-weight: 500; } .settings-desc { font-size: 12px; color: #6b7280; margin-top: 2px; }
    .settings-value { font-size: 14px; font-weight: 500; color: #6b7280; }
    .toggle { width: 42px; height: 24px; border-radius: 12px; border: none; cursor: pointer; background: #e5e7eb; position: relative; transition: background .15s; }
    .toggle.on { background: #16a34a; }
    .toggle::after { content: ''; position: absolute; top: 3px; left: 3px; width: 18px; height: 18px; border-radius: 50%; background: #fff; transition: transform .15s; }
    .toggle.on::after { transform: translateX(18px); }
    .danger-zone { border-color: #fecaca; }

    /* Forms */
    .form-group { margin-bottom: 14px; } .form-label { display: block; font-size: 13px; font-weight: 500; margin-bottom: 6px; }
    .input, .select, textarea.input { width: 100%; padding: 10px 14px; border: 1px solid #e5e7eb; border-radius: 8px; font-size: 14px; font-family: inherit; outline: none; background: #fff; }
    .input:focus { border-color: #1677ff; }
    .form-row { display: flex; gap: 10px; }

    /* Flash / pager / empty */
    .flash { padding: 12px 16px; border-radius: 10px; margin-bottom: 16px; font-size: 13px; font-weight: 500; }
    .flash-success { background: #dcfce7; color: #166534; border: 1px solid #86efac; }
    .flash-error { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
    .pager { margin-top: 16px; display: flex; justify-content: center; gap: 6px; flex-wrap: wrap; }
    .pager a, .pager span { padding: 6px 12px; border: 1px solid #e5e7eb; border-radius: 8px; font-size: 13px; }
    .empty { text-align: center; padding: 48px 16px; color: #9ca3af; }
    .login-page { display: flex; align-items: center; justify-content: center; min-height: 100vh; background: linear-gradient(135deg,#0d47a1,#1677ff); }
    .login-card { background: #fff; border-radius: 16px; padding: 36px; width: 100%; max-width: 400px; box-shadow: 0 24px 60px rgba(0,0,0,.25); }
    .login-logo { width: 52px; height: 52px; border-radius: 14px; background: linear-gradient(135deg,#1677ff,#0d47a1); display: flex; align-items: center; justify-content: center; color: #fff; font-weight: 700; font-size: 22px; margin: 0 auto 16px; }
    .login-title { text-align: center; font-size: 22px; font-weight: 700; } .login-subtitle { text-align: center; color: #6b7280; font-size: 13px; margin: 4px 0 24px; }
    .otp-input { letter-spacing: 8px; font-size: 22px; text-align: center; }

    @stack('styles')

    /* ── Responsive ── */
    .menu-btn { display: none; width: 38px; height: 38px; border: 1px solid #e5e7eb; background: #fff; border-radius: 8px; cursor: pointer; align-items: center; justify-content: center; }
    .nav-backdrop { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.45); z-index: 90; }
    .table-scroll { width: 100%; overflow-x: auto; }

    @media (max-width: 1024px) {
      .sidebar { transform: translateX(-100%); transition: transform .25s ease; box-shadow: 0 0 40px rgba(0,0,0,.3); }
      body.nav-open .sidebar { transform: translateX(0); }
      body.nav-open .nav-backdrop { display: block; }
      .main { margin-left: 0; }
      .menu-btn { display: inline-flex; }
      .main-header-left { gap: 10px; }
    }
    @media (max-width: 860px) {
      .stat-grid { grid-template-columns: repeat(2, 1fr); }
      .grid-2 { grid-template-columns: 1fr; }
      .quick-action-grid { grid-template-columns: repeat(2, 1fr); }
      .main-content { padding: 16px; }
      .main-header { padding: 12px 16px; }
    }
    @media (max-width: 560px) {
      .stat-grid { grid-template-columns: 1fr; }
      .search-bar { flex-direction: column; align-items: stretch; }
      .search-bar .filter-btn, .search-bar .btn { width: 100%; justify-content: center; }
      .listing-actions, .action-bar, .sponsor-actions, .action-btns { flex-direction: column; }
      .listing-actions .action-btn, .action-bar .action-btn, .action-btns .action-btn { width: 100%; justify-content: center; }
      .template-meta { flex-wrap: wrap; gap: 8px; }
      .main-header h1 { font-size: 17px; }
      .admin-meta { display: none; }
    }
  </style>
</head>
<body>
@yield('body-open')

@if(!request()->routeIs('admin.login') && !request()->routeIs('admin.2fa'))
<div>
  <div class="nav-backdrop" onclick="document.body.classList.remove('nav-open')"></div>
  <aside class="sidebar">
    <div class="sidebar-brand">
      <div class="sidebar-brand-icon"><i data-lucide="shield" style="width:22px;height:22px;color:#fff;"></i></div>
      <span class="sidebar-brand-text">SportX</span>
    </div>
    <nav class="sidebar-nav">
      <div class="sidebar-nav-section">
        <div class="sidebar-nav-label">Main</div>
        <a href="{{ route('admin.dashboard') }}" class="sidebar-nav-item @if(request()->routeIs('admin.dashboard')) active @endif"><i data-lucide="layout-dashboard"></i>Dashboard</a>
        <a href="{{ route('admin.users') }}" class="sidebar-nav-item @if(request()->routeIs('admin.users','admin.users.detail')) active @endif"><i data-lucide="users"></i>Users</a>
        <a href="{{ route('admin.moderation') }}" class="sidebar-nav-item @if(request()->routeIs('admin.moderation')) active @endif"><i data-lucide="clipboard-list"></i>Moderation</a>
        <a href="{{ route('admin.reports') }}" class="sidebar-nav-item @if(request()->routeIs('admin.reports')) active @endif"><i data-lucide="alert-octagon"></i>Reports</a>
      </div>
      <div class="sidebar-nav-section">
        <div class="sidebar-nav-label">Management</div>
        <a href="{{ route('admin.sponsors') }}" class="sidebar-nav-item @if(request()->routeIs('admin.sponsors')) active @endif"><i data-lucide="badge-check"></i>Sponsors</a>
        <a href="{{ route('admin.flags') }}" class="sidebar-nav-item @if(request()->routeIs('admin.flags')) active @endif"><i data-lucide="flag"></i>Content Flags</a>
      </div>
      <div class="sidebar-nav-section">
        <div class="sidebar-nav-label">System</div>
        <a href="{{ route('admin.analytics') }}" class="sidebar-nav-item @if(request()->routeIs('admin.analytics')) active @endif"><i data-lucide="bar-chart-2"></i>Analytics</a>
        <a href="{{ route('admin.expiry') }}" class="sidebar-nav-item @if(request()->routeIs('admin.expiry')) active @endif"><i data-lucide="clock"></i>Expiry</a>
        <a href="{{ route('admin.notifications') }}" class="sidebar-nav-item @if(request()->routeIs('admin.notifications')) active @endif"><i data-lucide="bell"></i>Notifications</a>
        <a href="{{ route('admin.categories') }}" class="sidebar-nav-item @if(request()->routeIs('admin.categories')) active @endif"><i data-lucide="tag"></i>Categories</a>
        <a href="{{ route('admin.settings') }}" class="sidebar-nav-item @if(request()->routeIs('admin.settings')) active @endif"><i data-lucide="settings"></i>Settings</a>
      </div>
    </nav>
    <div class="sidebar-footer">
      <div class="sidebar-user">
        <div class="sidebar-user-avatar"><i data-lucide="user" style="width:18px;height:18px;color:#9ca3af;"></i></div>
        <div class="sidebar-user-info">
          <div class="sidebar-user-name">{{ Auth::user()?->name ?? 'Admin User' }}</div>
          <div class="sidebar-user-role">Super Admin</div>
        </div>
        <form method="POST" action="{{ route('admin.logout') }}">@csrf
          <button class="logout-btn" title="Logout"><i data-lucide="log-out" style="width:18px;height:18px;"></i></button>
        </form>
      </div>
    </div>
  </aside>

  <main class="main">
    <header class="main-header">
      <div class="main-header-left">
        <button class="menu-btn" onclick="document.body.classList.toggle('nav-open')" aria-label="Menu"><i data-lucide="menu" style="width:20px;height:20px;"></i></button>
        <h1>@yield('title', 'Dashboard')</h1>
      </div>
      <div class="header-right">
        @yield('header-actions')
        <div class="admin-chip">
          <div class="admin-avatar">{{ strtoupper(substr(Auth::user()?->name ?? 'A', 0, 1)) }}</div>
          <div class="admin-meta">
            <div class="admin-name">{{ Auth::user()?->name ?? 'Admin' }}</div>
            <div class="admin-role">Super Admin</div>
          </div>
        </div>
      </div>
    </header>
    <div class="main-content">
      @if(session('success'))<div class="flash flash-success">{{ session('success') }}</div>@endif
      @if(session('error'))<div class="flash flash-error">{{ session('error') }}</div>@endif
      @yield('content')
    </div>
  </main>
</div>
@else
  @yield('content')
@endif

<script>
  lucide.createIcons();
  // Close the mobile drawer after navigating.
  document.querySelectorAll('.sidebar-nav-item').forEach(function (el) {
    el.addEventListener('click', function () { document.body.classList.remove('nav-open'); });
  });
  // Auto-wrap data tables in a horizontal-scroll container for small screens.
  document.querySelectorAll('table.table, table.data').forEach(function (t) {
    if (t.parentElement.classList.contains('table-scroll')) return;
    var w = document.createElement('div'); w.className = 'table-scroll';
    t.parentNode.insertBefore(w, t); w.appendChild(t);
  });
</script>
@stack('scripts')
</body>
</html>
