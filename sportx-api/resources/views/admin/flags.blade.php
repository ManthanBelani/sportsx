@extends('admin.layouts.app')
@section('title', 'Content Flags')
@section('header-actions')
  <span class="header-badge warning">{{ $flags->total() }} Flagged</span>
@endsection

@section('content')
  @forelse($flags as $f)
    @php $morphName = class_basename($f->reportable_type ?? 'Listing'); @endphp
    <div class="card no-pad">
      <div class="listing-header">
        <div class="card-header-icon"><i data-lucide="flag" style="width:22px;height:22px;color:#dc2626;"></i></div>
        <div class="listing-info">
          <div class="listing-name">{{ $morphName }} #{{ $f->reportable_id }}</div>
          <div class="listing-meta">Reported by User #{{ $f->reporter_user_id ?? 'Anon' }} • {{ $f->created_at?->diffForHumans() }}</div>
        </div>
        <span class="flag-tag">{{ $f->reason ?: 'Flagged' }}</span>
      </div>
      <div class="card-body">
        <div class="flag-tags"><span class="flag-tag">{{ $f->reason ?: 'Inappropriate' }}</span></div>
        <div class="flag-desc">"{{ $f->comment ?: 'No description provided by reporter.' }}"</div>
        <div class="action-bar">
          <form method="POST" action="{{ route('admin.flags.action', $f->id) }}">@csrf<input type="hidden" name="action" value="remove"><button class="action-btn remove" onclick="return confirm('Remove this content?')"><i data-lucide="trash-2"></i> Remove</button></form>
          <form method="POST" action="{{ route('admin.flags.action', $f->id) }}">@csrf<input type="hidden" name="action" value="warn"><button class="action-btn warn"><i data-lucide="alert-triangle"></i> Warn User</button></form>
          <form method="POST" action="{{ route('admin.flags.action', $f->id) }}">@csrf<input type="hidden" name="action" value="dismiss"><button class="action-btn dismiss"><i data-lucide="check"></i> Dismiss</button></form>
        </div>
      </div>
    </div>
  @empty
    <div class="card empty">No flagged content 🎉</div>
  @endforelse
  @if($flags->hasPages())<div class="pager">{{ $flags->links() }}</div>@endif
@endsection
