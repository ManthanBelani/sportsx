@extends('admin.layouts.app')
@section('title', 'Sponsor Verification')
@section('header-actions')
  <span class="header-badge" style="background:#d97706;color:#fff;">{{ number_format($pendingCount) }} Pending</span>
@endsection

@section('content')
  <div class="grid-2">
    @forelse($sponsorships as $s)
      @php
        $profile = $s->sponsor;
        $user = $profile?->user;
        $brandName = $profile?->brand_name ?? $s->organization_name ?? $user?->name ?? 'Unknown Sponsor';
        $loc = $user?->email ? $user->email : ($s->contact_email ?? '—');
      @endphp
      <div class="card no-pad">
        <div class="sponsor-header">
          <div class="sponsor-logo"><i data-lucide="briefcase" style="width:28px;height:28px;color:{{ $s->status === 'published' ? '#4338ca' : '#1677ff' }};"></i></div>
          <div class="sponsor-info">
            <div class="sponsor-name">{{ $s->title ?? $brandName }}</div>
            <div class="sponsor-type">{{ $brandName }} • {{ $loc }}</div>
          </div>
          <span class="sponsor-tier {{ $s->status === 'published' ? 'platinum' : 'gold' }}">{{ $s->status === 'published' ? 'Verified' : ucfirst($s->status) }}</span>
        </div>
        <div class="docs-section">
          <div class="docs-title">Details</div>
          <div class="doc-row"><div class="doc-icon"><i data-lucide="indian-rupee" style="width:16px;height:16px;color:#6b7280;"></i></div><span class="doc-name">Sponsorship amount</span><span class="doc-status {{ $s->amount ? 'verified' : 'pending' }}">{{ $s->amount ? '₹'.$s->amount : 'Not set' }}</span></div>
          <div class="doc-row"><div class="doc-icon"><i data-lucide="file-text" style="width:16px;height:16px;color:#6b7280;"></i></div><span class="doc-name">Documents required</span><span class="doc-status {{ $s->documents_required ? 'verified' : 'pending' }}">{{ $s->documents_required ? 'Provided' : 'None' }}</span></div>
        </div>
        <div class="sponsor-actions" style="padding:16px 20px;">
          <form method="POST" action="{{ route('admin.sponsors.action', $s->id) }}">@csrf<input type="hidden" name="action" value="approve"><button class="action-btn approve"><i data-lucide="check"></i> Approve</button></form>
          <form method="POST" action="{{ route('admin.sponsors.action', $s->id) }}">@csrf<input type="hidden" name="action" value="reject"><button class="action-btn reject"><i data-lucide="x"></i> Reject</button></form>
        </div>
      </div>
    @empty
      <div class="card empty">No sponsorships to verify.</div>
    @endforelse
  </div>
  @if($sponsorships->hasPages())<div class="pager">{{ $sponsorships->links() }}</div>@endif
@endsection
