@extends('admin.layouts.app')
@section('title', ucfirst(str_replace('-',' ',$type)))
@section('header-actions')
  <a href="{{ route('admin.content.create', $type) }}" class="btn btn-primary"><i data-lucide="plus" style="width:16px;height:16px;"></i> New {{ ucfirst(str_replace('-',' ',$type)) }}</a>
@endsection

@section('content')
<a href="{{ route('admin.content') }}" class="btn btn-ghost btn-sm" style="margin-bottom:16px;">← All content</a>

<div class="table-wrap">
  <table class="data">
    <thead>
      <tr><th>ID</th><th>Name / Title</th><th>Status</th><th>Created</th><th>Actions</th></tr>
    </thead>
    <tbody>
      @forelse($items as $item)
        @php
          $title = $item->name ?? $item->full_name ?? $item->title ?? $item->organization_name ?? ('#'.$item->id);
          $currentStatus = $item->{$statusCol} ?? '—';
        @endphp
        <tr>
          <td>{{ $item->id }}</td>
          <td>{{ $title }}</td>
          <td><span class="badge badge-{{ $currentStatus === 'published' ? 'success' : 'gray' }}">{{ $currentStatus }}</span></td>
          <td class="muted">{{ $item->created_at?->format('d M Y') }}</td>
          <td>
            <div class="row-actions">
              <a href="{{ route('admin.content.edit', [$type, $item->id]) }}" class="btn btn-ghost btn-sm"><i data-lucide="pencil" style="width:14px;height:14px;"></i> Edit</a>
              <form method="POST" action="{{ route('admin.content.publish', [$type, $item->id]) }}">@csrf
                <input type="hidden" name="publish" value="{{ $currentStatus === 'published' ? '0' : '1' }}">
                <button class="btn btn-{{ $currentStatus === 'published' ? 'ghost' : 'success' }} btn-sm">{{ $currentStatus === 'published' ? 'Unpublish' : 'Publish' }}</button>
              </form>
              <form method="POST" action="{{ route('admin.content.destroy', [$type, $item->id]) }}" onsubmit="return confirm('Delete this item?')">@csrf @method('DELETE')
                <button class="btn btn-danger btn-sm">Delete</button>
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

@if($items->hasPages())
<div class="pager">{{ $items->links() }}</div>
@endif
@endsection
