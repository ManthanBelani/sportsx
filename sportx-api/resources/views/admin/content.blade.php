@extends('admin.layouts.app')
@section('title', 'Content Management')
@section('header-actions')
  <span class="header-badge">7 Directories</span>
@endsection

@section('content')
<p style="margin-bottom:20px; font-size:13px; color:#6b7280;">Browse, publish/unpublish, or remove listings across every directory. Click a card to manage its items.</p>

<style>
.content-grid { display:grid; grid-template-columns: repeat(3, 1fr); gap:18px; }
.content-card {
  background:#fff; border:1px solid #e5e7eb; border-radius:16px;
  text-decoration:none; color:inherit; display:flex; flex-direction:column;
  overflow:hidden; transition: all .2s ease;
}
.content-card:hover { transform: translateY(-3px); box-shadow: 0 12px 28px rgba(0,0,0,.08); border-color:#d1d5db; }
.content-card-top { padding:20px 20px 16px; display:flex; align-items:flex-start; justify-content:space-between; gap:12px; }
.content-icon {
  width:48px; height:48px; border-radius:12px; display:flex; align-items:center; justify-content:center; flex-shrink:0;
}
.content-icon.academies { background: linear-gradient(135deg,#dcfce7,#bbf7d0); color:#15803d; }
.content-icon.coaches { background: linear-gradient(135deg,#dbeafe,#bfdbfe); color:#1d4ed8; }
.content-icon.trials { background: linear-gradient(135deg,#fef3c7,#fde68a); color:#b45309; }
.content-icon.tournaments { background: linear-gradient(135deg,#fce7f3,#fbcfe8); color:#be185d; }
.content-icon.scholarships { background: linear-gradient(135deg,#e0e7ff,#c7d2fe); color:#4338ca; }
.content-icon.sponsorships { background: linear-gradient(135deg,#f3e8ff,#e9d5ff); color:#7e22ce; }
.content-icon.sports-venues { background: linear-gradient(135deg,#ffedd5,#fed7aa); color:#c2410c; }
.content-card-title { font-size:15px; font-weight:700; color:#111827; line-height:1.2; }
.content-card-desc { font-size:12px; color:#6b7280; margin-top:4px; line-height:1.4; }
.content-card-arrow { width:28px; height:28px; border-radius:8px; background:#f9fafb; border:1px solid #e5e7eb; display:flex; align-items:center; justify-content:center; color:#9ca3af; flex-shrink:0; transition: all .15s; }
.content-card:hover .content-card-arrow { background:#111827; color:#fff; border-color:#111827; }
.content-card-stats { display:flex; gap:0; background:#f9fafb; border-top:1px solid #f0f0f0; }
.content-stat { flex:1; text-align:center; padding:12px 8px; position:relative; }
.content-stat + .content-stat { border-left:1px solid #f0f0f0; }
.content-stat b { display:block; font-size:18px; font-weight:700; color:#111827; line-height:1; }
.content-stat span { font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.5px; color:#6b7280; margin-top:4px; display:block; }
.content-stat.live b { color:#16a34a; }
.content-stat.draft b { color:#d97706; }
.content-stat-footer { padding:10px 20px; background:#fff; border-top:1px solid #f0f0f0; display:flex; align-items:center; justify-content:space-between; font-size:12px; font-weight:600; color:#1677ff; }
.content-stat-footer i { transition: transform .15s; }
.content-card:hover .content-stat-footer i { transform: translateX(3px); }
@media(max-width:1024px){ .content-grid{ grid-template-columns: repeat(2,1fr);} }
@media(max-width:560px){ .content-grid{ grid-template-columns:1fr;} }
</style>

<div class="content-grid">
  @php
    $labels = ['academies'=>'Academies','coaches'=>'Coaches','trials'=>'Trials','tournaments'=>'Tournaments','scholarships'=>'Scholarships','sponsorships'=>'Sponsorships','sports-venues'=>'Sports Venues'];
    $descs = ['academies'=>'Training centers & academies','coaches'=>'Verified coach profiles','trials'=>'Selection trials & tryouts','tournaments'=>'Competitions & leagues','scholarships'=>'Aid & scholarship offers','sponsorships'=>'Sponsor opportunities','sports-venues'=>'Grounds & venues'];
    $icons = ['academies'=>'building-2','coaches'=>'users','trials'=>'target','tournaments'=>'trophy','scholarships'=>'graduation-cap','sponsorships'=>'handshake','sports-venues'=>'map-pin'];
  @endphp
  @foreach($counts as $type => $c)
  <a href="{{ route('admin.content.list', $type) }}" class="content-card">
    <div class="content-card-top">
      <div style="display:flex; gap:14px; align-items:flex-start;">
        <div class="content-icon {{ $type }}"><i data-lucide="{{ $icons[$type] ?? 'file-text' }}" style="width:22px;height:22px;"></i></div>
        <div>
          <div class="content-card-title">{{ $labels[$type] ?? ucfirst(str_replace('-',' ',$type)) }}</div>
          <div class="content-card-desc">{{ $descs[$type] ?? '' }}</div>
        </div>
      </div>
      <div class="content-card-arrow"><i data-lucide="chevron-right" style="width:14px;height:14px;"></i></div>
    </div>
    <div class="content-card-stats">
      <div class="content-stat"><b>{{ number_format($c['total']) }}</b><span>Total</span></div>
      <div class="content-stat live"><b>{{ number_format($c['published']) }}</b><span>Live</span></div>
      <div class="content-stat draft"><b>{{ number_format($c['draft']) }}</b><span>Draft</span></div>
    </div>
    <div class="content-stat-footer">
      <span>Manage {{ $labels[$type] ?? $type }}</span><i data-lucide="arrow-right" style="width:14px;height:14px;"></i>
    </div>
  </a>
  @endforeach
</div>
@endsection
