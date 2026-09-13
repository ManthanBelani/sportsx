@extends('admin.layouts.app')
@section('title', ucfirst(str_replace('-',' ',$type)))
@section('header-actions')
  <a href="{{ route('admin.content.create', $type) }}" class="btn btn-primary"><i data-lucide="plus" style="width:16px;height:16px;"></i> New {{ ucfirst(str_replace('-',' ',$type)) }}</a>
@endsection

@section('content')
<a href="{{ route('admin.content') }}" class="btn btn-ghost" style="margin-bottom:16px; border:1px solid #e5e7eb;">← All content</a>

<div class="card no-pad">
  <div class="card-header"><span class="card-title">{{ ucfirst(str_replace('-',' ',$type)) }}</span><span class="header-badge">{{ $items->total() }} total</span></div>
  <div class="table-scroll">
  <table class="table">
    <thead><tr><th>ID</th><th>Name / Title</th><th>Status</th><th>Created</th><th>Actions</th></tr></thead>
    <tbody>
      @forelse($items as $item)
        @php
          $title = $item->name ?? $item->full_name ?? $item->title ?? $item->organization_name ?? ('#'.$item->id);
          $currentStatus = $item->{$statusCol} ?? '—';
        @endphp
        <tr>
          <td>#{{ $item->id }}</td>
          <td><div class="cat-name">{{ $title }}</div></td>
          <td><span class="badge {{ $currentStatus === 'published' ? 'active' : 'inactive' }}">{{ ucfirst($currentStatus) }}</span></td>
          <td>{{ $item->created_at?->format('d M Y') }}</td>
          <td>
            <div class="action-btns">
              <a href="{{ route('admin.content.edit', [$type, $item->id]) }}" class="action-btn edit"><i data-lucide="pencil" style="width:12px;height:12px;"></i> Edit</a>
              <form method="POST" action="{{ route('admin.content.publish', [$type, $item->id]) }}">@csrf
                <input type="hidden" name="publish" value="{{ $currentStatus === 'published' ? '0' : '1' }}">
                <button class="action-btn {{ $currentStatus === 'published' ? 'warn' : 'approve' }}">{{ $currentStatus === 'published' ? 'Unpublish' : 'Publish' }}</button>
              </form>
              <form method="POST" action="{{ route('admin.content.destroy', [$type, $item->id]) }}" onsubmit="return confirm('Delete this item?')">@csrf @method('DELETE')
                <button class="action-btn delete"><i data-lucide="trash-2" style="width:12px;height:12px;"></i></button>
              </form>
            </div>
          </td>
        </tr>
      @empty
        <tr><td colspan="5" class="empty">No items yet.</td></tr>
      @endforelse
    </tbody>
  </table>
  </div>
</div>
@if($items->hasPages())<div class="pager">{{ $items->links() }}</div>@endif
@endsection
