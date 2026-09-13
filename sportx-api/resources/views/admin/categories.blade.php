@extends('admin.layouts.app')
@section('title', 'Sport Categories')
@section('header-actions')
  <span class="header-badge">{{ $sports->count() }} Sports</span>
@endsection

@section('content')
  <div class="grid-2">
    <div class="card no-pad">
      <div class="card-header"><span class="card-title">Sports ({{ $sports->count() }})</span></div>
      <form id="addSport" class="search-bar" method="POST" action="{{ route('admin.categories.store', 'sports') }}">@csrf
        <input class="input" name="name" placeholder="Sport name" required style="flex:1;">
        <input class="input" name="sort_order" type="number" placeholder="order" style="max-width:80px;">
        <button class="btn btn-primary"><i data-lucide="plus" style="width:14px;height:14px;"></i> Add</button>
      </form>
      <div class="table-scroll">
      <table class="table">
        <thead><tr><th>Sport</th><th>Order</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody>
          @forelse($sports as $s)
            <tr>
              <td>
                <div class="cat-cell">
                  <div class="cat-icon"><i data-lucide="circle" style="width:14px;height:14px;color:#1677ff;"></i></div>
                  <div><div class="cat-name">{{ $s->name }}</div></div>
                </div>
              </td>
              <td>{{ $s->sort_order ?? '—' }}</td>
              <td><span class="badge {{ $s->is_active ? 'active' : 'inactive' }}">{{ $s->is_active ? 'Active' : 'Inactive' }}</span></td>
              <td>
                <div class="action-btns">
                  <form method="POST" action="{{ route('admin.categories.toggle', ['sports', $s->id]) }}">@csrf<button class="action-btn {{ $s->is_active ? 'warn' : 'approve' }}" title="{{ $s->is_active ? 'Deactivate' : 'Activate' }}"><i data-lucide="{{ $s->is_active ? 'pause' : 'play' }}" style="width:12px;height:12px;"></i></button></form>
                  <form method="POST" action="{{ route('admin.categories.destroy', ['sports', $s->id]) }}" onsubmit="return confirm('Delete {{ $s->name }}?')">@csrf @method('DELETE')<button class="action-btn delete"><i data-lucide="trash-2" style="width:12px;height:12px;"></i></button></form>
                </div>
              </td>
            </tr>
          @empty <tr><td colspan="4" class="empty">No sports.</td></tr> @endforelse
        </tbody>
      </table>
      </div>
    </div>

    <div>
      <div class="card no-pad" style="margin-bottom:20px;">
        <div class="card-header"><span class="card-title">Cities ({{ $cities->count() }})</span></div>
        <form class="search-bar" method="POST" action="{{ route('admin.categories.store', 'cities') }}">@csrf
          <input class="input" name="name" placeholder="City" required>
          <input class="input" name="state" placeholder="State">
          <button class="btn btn-primary"><i data-lucide="plus" style="width:12px;height:12px;"></i> Add</button>
        </form>
        <div class="table-scroll">
        <table class="table"><thead><tr><th>City</th><th>State</th><th>Status</th><th></th></tr></thead><tbody>
          @forelse($cities as $c)
            <tr><td><div class="cat-name">{{ $c->name }}</div></td><td>{{ $c->state ?: '—' }}</td>
              <td><span class="badge {{ $c->is_active ? 'active' : 'inactive' }}">{{ $c->is_active ? 'Active' : 'Inactive' }}</span></td>
              <td>
                <div class="action-btns">
                  <form method="POST" action="{{ route('admin.categories.toggle', ['cities', $c->id]) }}">@csrf<button class="action-btn view"><i data-lucide="power" style="width:12px;height:12px;"></i></button></form>
                  <form method="POST" action="{{ route('admin.categories.destroy', ['cities', $c->id]) }}" onsubmit="return confirm('Delete city?')">@csrf @method('DELETE')<button class="action-btn delete"><i data-lucide="trash-2" style="width:12px;height:12px;"></i></button></form>
                </div>
              </td>
            </tr>
          @empty <tr><td colspan="4" class="empty">No cities.</td></tr> @endforelse
        </tbody></table>
        </div>
      </div>

      <div class="card no-pad">
        <div class="card-header"><span class="card-title">Age Groups ({{ $ageGroups->count() }})</span></div>
        <form class="search-bar" method="POST" action="{{ route('admin.categories.store', 'age-groups') }}">@csrf
          <input class="input" name="name" placeholder="e.g. U-16" required>
          <input class="input" name="min_age" type="number" placeholder="min" style="max-width:70px;">
          <input class="input" name="max_age" type="number" placeholder="max" style="max-width:70px;">
          <button class="btn btn-primary"><i data-lucide="plus" style="width:12px;height:12px;"></i> Add</button>
        </form>
        <div class="table-scroll">
        <table class="table"><thead><tr><th>Name</th><th>Range</th><th>Status</th><th></th></tr></thead><tbody>
          @forelse($ageGroups as $a)
            <tr><td><div class="cat-name">{{ $a->name }}</div></td><td>{{ $a->min_age !== null ? $a->min_age : '?' }}–{{ $a->max_age !== null ? $a->max_age : '?' }}</td>
              <td><span class="badge {{ $a->is_active ? 'active' : 'inactive' }}">{{ $a->is_active ? 'Active' : 'Inactive' }}</span></td>
              <td>
                <div class="action-btns">
                  <form method="POST" action="{{ route('admin.categories.toggle', ['age-groups', $a->id]) }}">@csrf<button class="action-btn view"><i data-lucide="power" style="width:12px;height:12px;"></i></button></form>
                  <form method="POST" action="{{ route('admin.categories.destroy', ['age-groups', $a->id]) }}" onsubmit="return confirm('Delete?')">@csrf @method('DELETE')<button class="action-btn delete"><i data-lucide="trash-2" style="width:12px;height:12px;"></i></button></form>
                </div>
              </td>
            </tr>
          @empty <tr><td colspan="4" class="empty">No age groups.</td></tr> @endforelse
        </tbody></table>
        </div>
      </div>
    </div>
  </div>
@endsection
