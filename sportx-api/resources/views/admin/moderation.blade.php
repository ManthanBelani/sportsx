@extends('admin.layouts.app')
@section('title', 'Listing Moderation')
@section('header-actions')
  <span class="header-badge warning">{{ $counts['pending'] }} Pending</span>
@endsection

@section('content')
  <div class="tabs">
    @foreach(['pending'=>'Pending','resolved'=>'Resolved','removed'=>'Removed/Warned','all'=>'All'] as $key => $label)
      <a class="tab {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.moderation', ['status' => $key]) }}">{{ $label }} ({{ number_format($counts[$key]) }})</a>
    @endforeach
  </div>

  @forelse($reports as $r)
    @php $reportable = $r->reportable; @endphp
    <div class="card no-pad">
      <div class="listing-header">
        <div class="listing-img"><i data-lucide="file-text" style="width:28px;height:28px;color:#1677ff;"></i></div>
        <div class="listing-info">
          <div class="listing-name">{{ $reportable?->name ?? $reportable?->full_name ?? class_basename($r->reportable_type ?? 'Listing').' #'.$r->reportable_id }}</div>
          <div class="listing-meta"><i data-lucide="flag" style="width:12px;height:12px;"></i> {{ $r->reason ?: 'Reported' }} • {{ $r->created_at?->diffForHumans() }}</div>
        </div>
        @if($r->status === 'pending')<span class="listing-flagged"><i data-lucide="alert-triangle" style="width:12px;height:12px;"></i> Flagged</span>@else <span class="badge active">{{ $r->status }}</span>@endif
      </div>
      <div class="listing-body">
        <div class="listing-desc">{{ $r->comment ?: 'No additional detail provided by the reporter.' }}</div>
        @if($r->status === 'pending')
        <div class="listing-actions">
          <a href="{{ route('admin.content') }}" class="action-btn view"><i data-lucide="eye"></i> View</a>
          <form method="POST" action="{{ route('admin.moderation.action', $r->id) }}">@csrf<input type="hidden" name="action" value="approve"><button class="action-btn approve"><i data-lucide="check"></i> Approve</button></form>
          <form method="POST" action="{{ route('admin.moderation.action', $r->id) }}">@csrf<input type="hidden" name="action" value="remove"><button class="action-btn reject" onclick="return confirm('Remove this listing?')"><i data-lucide="x"></i> Reject & Remove</button></form>
        </div>
        @endif
      </div>
    </div>
  @empty
    <div class="card empty"><div>No listings awaiting moderation 🎉</div></div>
  @endforelse
  @if($reports->hasPages())<div class="pager">{{ $reports->links() }}</div>@endif
@endsection
