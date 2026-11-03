@extends('admin.layouts.app')
@section('title', 'Verification Badges')
@section('header-actions')
  <span class="header-badge warning">{{ $counts['pending'] }} Pending</span>
@endsection

@section('content')
@push('styles')
<style>
  .approval-tabs{display:flex;gap:4px;margin-bottom:12px;background:#fff;padding:4px;border-radius:10px;border:1px solid #e5e7eb;width:fit-content;max-width:100%;overflow-x:auto;-webkit-overflow-scrolling:touch;}
  .approval-tabs::-webkit-scrollbar{display:none;}
  .approval-tab{padding:7px 12px;border-radius:8px;font-size:12px;font-weight:600;border:none;background:none;cursor:pointer;color:#6b7280;display:flex;gap:6px;align-items:center;white-space:nowrap;}
  .approval-tab.active{background:#111;color:#fff;}
  .approval-tab .cnt{background:#e5e7eb;padding:2px 6px;border-radius:20px;font-size:11px;}
  .approval-tab.active .cnt{background:rgba(255,255,255,0.2);}
  .proof-grid{display:flex;gap:8px;flex-wrap:wrap;margin-top:10px;}
  .proof-thumb{width:88px;height:88px;border-radius:8px;border:1px solid #e5e7eb;background:#f9fafb;overflow:hidden;display:flex;align-items:center;justify-content:center;}
  .proof-thumb img{width:100%;height:100%;object-fit:cover;display:block;}
  .proof-file{flex-direction:column;gap:4px;padding:8px;text-decoration:none;color:#374151;font-size:10px;text-align:center;word-break:break-all;line-height:1.2;}
  .notes-box{background:#f9fafb;border:1px solid #e5e7eb;border-radius:8px;padding:8px 10px;font-size:12px;color:#4b5563;margin-top:10px;}
  .reviewed-line{font-size:12px;color:#6b7280;margin-top:8px;}
  .reviewed-line b{color:#374151;font-weight:600;}
  @media(max-width:560px){
    .approval-tabs{width:100%;}
    .card-header{flex-wrap:wrap;gap:6px;}
    .listing-body .listing-actions{flex-direction:column;}
    .proof-thumb{width:72px;height:72px;}
  }
</style>
@endpush

<div class="card no-pad">
  <div class="card-header">
    <span class="card-title"><i data-lucide="badge-check" style="width:16px;height:16px;color:#1677ff;"></i> Verification Badge Requests</span>
    <span style="font-size:11px;color:#6b7280;">Blue-check requests submitted from the app (More &rarr; Verification badge)</span>
  </div>

  <div style="padding:12px 16px;">
    <div class="approval-tabs">
      @foreach(['pending'=>'Pending','approved'=>'Approved','rejected'=>'Rejected','all'=>'All'] as $key => $label)
        <button class="approval-tab {{ $status === $key ? 'active' : '' }}" onclick="location.href='{{ route('admin.verification', ['status' => $key]) }}'">{{ $label }} <span class="cnt">{{ number_format($counts[$key]) }}</span></button>
      @endforeach
    </div>
  </div>

  <div style="padding:0 16px 16px;">
    @forelse($requests as $v)
      @php
        $entity = $v->verifiable;
        $entityLabel = ucwords(str_replace('_', ' ', class_basename($v->verifiable_type)));
        $entityName = $entity?->name ?? $entity?->full_name ?? $entity?->title ?? '';
      @endphp
      <div class="card no-pad" style="margin-bottom:10px;">
        <div class="listing-header">
          <div class="user-avatar" style="width:40px;height:40px;"><i data-lucide="badge-check" style="width:18px;height:18px;color:#1677ff;"></i></div>
          <div class="listing-info">
            <div class="listing-name">{{ $v->requester?->name ?? 'Unknown user' }} <span class="badge {{ $v->requester?->role ?? 'athlete' }}" style="margin-left:6px;">{{ ucfirst(str_replace('_', ' ', $v->requester?->role ?? 'user')) }}</span></div>
            <div class="listing-meta">{{ $entityLabel }}{{ $entityName ? ' • '.$entityName : ' #'.$v->verifiable_id }} • Requested {{ $v->created_at?->diffForHumans() }}</div>
          </div>
          @if($v->status === 'pending')<span class="badge pending">Pending</span>
          @elseif($v->status === 'approved')<span class="badge active">Approved</span>
          @else<span class="badge rejected">Rejected</span>@endif
        </div>
        <div class="listing-body">
          @if($v->notes)
            <div class="notes-box">&ldquo;{{ $v->notes }}&rdquo;</div>
          @endif

          @php $ids = $v->proof_media_ids ?? []; @endphp
          @if(count($ids))
            <div class="proof-grid">
              @foreach($ids as $mid)
                @php $doc = $proofDocs->get($mid); @endphp
                @if($doc)
                  @php $url = \Illuminate\Support\Facades\URL::temporarySignedRoute('media.download', now()->addMinutes(60), ['id' => $doc->id]); @endphp
                  @if(str_starts_with($doc->mime_type ?? '', 'image/'))
                    <a href="{{ $url }}" target="_blank" rel="noopener" class="proof-thumb" title="Open {{ $doc->original_name ?: 'document' }}"><img src="{{ $url }}" alt="{{ $doc->original_name ?: 'Proof document' }}"></a>
                  @else
                    <a href="{{ $url }}" target="_blank" rel="noopener" class="proof-thumb proof-file"><i data-lucide="file-text" style="width:16px;height:16px;"></i>{{ \Illuminate\Support\Str::limit($doc->original_name ?: 'Document', 14) }}</a>
                  @endif
                @endif
              @endforeach
            </div>
          @else
            <div class="listing-desc" style="color:#9ca3af;">No proof documents submitted.</div>
          @endif

          @if($v->status === 'pending')
            <div class="listing-actions">
              <form method="POST" action="{{ route('admin.verification.approve', $v->id) }}" onsubmit="return confirm('Approve this request and grant the blue-check badge?')">@csrf<button class="action-btn approve"><i data-lucide="check" style="width:14px;height:14px;"></i> Approve &amp; Grant Badge</button></form>
              <button type="button" class="action-btn reject" data-url="{{ route('admin.verification.reject', $v->id) }}" data-name="{{ $v->requester?->name ?? 'the user' }}" onclick="openRejectModal(this)"><i data-lucide="x" style="width:14px;height:14px;"></i> Reject</button>
            </div>
          @else
            <div class="reviewed-line">
              Reviewed by <b>{{ $v->reviewer?->name ?? 'an admin' }}</b> {{ $v->reviewed_at?->diffForHumans() }}
              @if($v->decision_reason) &mdash; &ldquo;{{ $v->decision_reason }}&rdquo; @endif
            </div>
          @endif
        </div>
      </div>
    @empty
      <div class="empty">No {{ $status === 'all' ? '' : $status }} verification requests 🎉</div>
    @endforelse
    @if($requests->hasPages())<div class="pager">{{ $requests->links() }}</div>@endif
  </div>
</div>

{{-- Reject modal — a reason is mandatory and is sent to the user --}}
<div id="rejectModal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:1000;align-items:center;justify-content:center;padding:16px;">
  <div style="background:#fff;border-radius:12px;max-width:440px;width:100%;padding:20px;">
    <h3 style="font-size:15px;font-weight:700;margin-bottom:4px;">Reject verification request</h3>
    <p style="font-size:12px;color:#6b7280;margin-bottom:12px;">A reason is required &mdash; it is delivered to <span id="rejectUserName">the user</span> as a notification.</p>
    <form method="POST" id="rejectForm" action="">
      @csrf
      <textarea name="reason" required maxlength="1000" rows="3" placeholder="e.g. Document photo is blurry or the name does not match the profile" style="width:100%;border:1px solid #e5e7eb;border-radius:8px;padding:10px;font-size:13px;font-family:inherit;margin-bottom:12px;box-sizing:border-box;"></textarea>
      <div style="display:flex;gap:8px;justify-content:flex-end;flex-wrap:wrap;">
        <button type="button" class="action-btn view" onclick="closeRejectModal()">Cancel</button>
        <button type="submit" class="action-btn reject">Confirm rejection</button>
      </div>
    </form>
  </div>
</div>

@push('scripts')
<script>
function openRejectModal(btn){
  document.getElementById('rejectForm').action = btn.dataset.url;
  document.getElementById('rejectUserName').textContent = btn.dataset.name || 'the user';
  var m = document.getElementById('rejectModal');
  m.style.display = 'flex';
  var ta = m.querySelector('textarea'); if (ta) ta.focus();
}
function closeRejectModal(){
  document.getElementById('rejectModal').style.display = 'none';
}
</script>
@endpush
@endsection
