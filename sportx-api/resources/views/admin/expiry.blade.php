@extends('admin.layouts.app')
@section('title', 'Expiry Monitor')
@section('header-actions', '<span class="header-badge warning">'.$counts['pending'].' Pending</span>')

@section('content')
  <div class="tabs">
    @foreach(['pending'=>'Pending','expired'=>'Expired','overridden'=>'Overridden'] as $key => $label)
      <a class="tab {{ $tab === $key ? 'active' : '' }}" href="{{ route('admin.expiry', ['tab' => $key]) }}">{{ $label }} ({{ number_format($counts[$key]) }})</a>
    @endforeach
  </div>

  <div class="card no-pad">
    <div class="card-header"><span class="card-title">Expiry Events ({{ ucfirst($tab) }})</span></div>
    <div class="table-scroll">
    <table class="table">
      <thead><tr><th>ID</th><th>Content</th><th>Type</th><th>Scheduled</th><th>Status</th><th>Actions</th></tr></thead>
      <tbody>
        @forelse($events as $e)
          <tr>
            <td>{{ $e->id }}</td>
            <td>#{{ $e->content_id }}</td>
            <td><span class="badge badge-gray">{{ $e->content_type }}</span></td>
            <td class="muted">{{ $e->scheduled_at?->format('d M Y H:i') }}</td>
            <td><span class="badge {{ $e->status==='expired'?'inactive':($e->status==='overridden'?'pending':'active') }}">{{ $e->status }}</span></td>
            <td>
              @if($e->status !== 'overridden')
                <div class="action-btns">
                  <form method="POST" action="{{ route('admin.expiry.override', $e->id) }}">@csrf<button class="action-btn warn"><i data-lucide="pause"></i> Override</button></form>
                  <form method="POST" action="{{ route('admin.expiry.restore', $e->id) }}">@csrf<button class="action-btn approve"><i data-lucide="rotate-ccw"></i> Restore</button></form>
                </div>
              @else
                <span class="muted">overridden</span>
              @endif
            </td>
          </tr>
        @empty
          <tr><td colspan="6" class="empty">No {{ $tab }} expiry events.</td></tr>
        @endforelse
      </tbody>
    </table>
    </div>
  </div>
  @if($events->hasPages())<div class="pager">{{ $events->links() }}</div>@endif

  <div class="card">
    <div class="card-header"><span class="card-title">Expiry Rules</span></div>
    <form method="POST" action="{{ route('admin.expiry.rules') }}">@csrf
      <div class="table-scroll">
      <table class="table">
        <thead><tr><th>Content Type</th><th>Days After</th><th>Trigger Field</th><th>Active</th></tr></thead>
        <tbody>
          @foreach($rules as $i => $r)
            <tr>
              <td>{{ ucfirst(str_replace('_',' ',$r->content_type)) }}<input type="hidden" name="rules[{{ $i }}][id]" value="{{ $r->id }}"></td>
              <td><input class="input" type="number" min="1" name="rules[{{ $i }}][days_after]" value="{{ old("rules.$i.days_after", $r->days_after) }}" style="width:100px;"></td>
              <td><input class="input" type="text" name="rules[{{ $i }}][trigger_field]" value="{{ old("rules.$i.trigger_field", $r->trigger_field) }}" style="width:180px;"></td>
              <td><input type="checkbox" name="rules[{{ $i }}][is_active]" value="1" {{ $r->is_active ? 'checked' : '' }}></td>
            </tr>
          @endforeach
        </tbody>
      </table>
      </div>
      @if($rules->isNotEmpty())<button class="btn btn-primary" style="margin-top:14px;"><i data-lucide="save" style="width:14px;height:14px;"></i> Save Rules</button>@endif
    </form>
  </div>
@endsection
