@extends('admin.layouts.app')
@section('title', 'Sport Categories')
@section('header-actions')
  <a href="#addSport" class="btn btn-primary"><i data-lucide="plus" style="width:16px;height:16px;"></i> Add Category</a>
@endsection

@section('content')
  <div class="grid-2">
    <div class="card no-pad">
      <div class="card-header"><span class="card-title">Sports ({{ $sports->count() }})</span></div>
      <form id="addSport" class="search-bar" method="POST" action="{{ route('admin.categories.store', 'sports') }}">@csrf
        <input class="input" name="name" placeholder="Sport name" required>
        <input class="input" name="sort_order" type="number" placeholder="order" style="max-width:90px;">
        <button class="btn btn-primary">Add</button>
      </form>
      <table class="table">
        <thead><tr><th>Sport</th><th>Order</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody>
          @forelse($sports as $s)
            <tr>
              <td>
                <form method="POST" action="{{ route('admin.categories.update', ['sports', $s->id]) }}" style="display:flex;gap:6px;align-items:center;">@csrf @method('PUT')
                  <div class="cat-cell">
                    <div class="cat-icon"><i data-lucide="circle" style="width:18px;height:18px;color:#1677ff;"></i></div>
                    <input class="input" name="name" value="{{ $s->name }}" style="padding:6px 10px;">
                    <input class="input" name="sort_order" type="number" value="{{ $s->sort_order }}" style="width:70px;padding:6px 10px;">
                  </div>
              </td>
              <td><span class="badge {{ $s->is_active ? 'active' : 'inactive' }}">{{ $s->is_active ? 'Active' : 'Inactive' }}</span></td>
              <td><div class="action-btns">
                <button class="action-btn edit" type="submit"><i data-lucide="save" style="width:12px;height:12px;"></i></button>
                </form>
                <form method="POST" action="{{ route('admin.categories.toggle', ['sports', $s->id]) }}">@csrf<button class="action-btn view"><i data-lucide="power" style="width:12px;height:12px;"></i></button></form>
                <form method="POST" action="{{ route('admin.categories.destroy', ['sports', $s->id]) }}">@csrf @method('DELETE')<button class="action-btn delete"><i data-lucide="trash-2" style="width:12px;height:12px;"></i></button></form>
              </div></td>
            </tr>
          @empty <tr><td colspan="4" class="empty">No sports.</td></tr> @endforelse
        </tbody>
      </table>
    </div>

    <div>
      <div class="card no-pad" style="margin-bottom:20px;">
        <div class="card-header"><span class="card-title">Cities ({{ $cities->count() }})</span></div>
        <form class="search-bar" method="POST" action="{{ route('admin.categories.store', 'cities') }}">@csrf
          <input class="input" name="name" placeholder="City" required>
          <input class="input" name="state" placeholder="State">
          <button class="btn btn-primary">Add</button>
        </form>
        <table class="table"><thead><tr><th>City</th><th>State</th><th></th></tr></thead><tbody>
          @forelse($cities as $c)
            <tr><td><div class="cat-name">{{ $c->name }}</div></td><td>{{ $c->state ?: '—' }}</td>
              <td><form method="POST" action="{{ route('admin.categories.destroy', ['cities', $c->id]) }}">@csrf @method('DELETE')<button class="action-btn delete"><i data-lucide="trash-2" style="width:12px;height:12px;"></i></button></form></td></tr>
          @empty <tr><td colspan="3" class="empty">No cities.</td></tr> @endforelse
        </tbody></table>
      </div>

      <div class="card no-pad">
        <div class="card-header"><span class="card-title">Age Groups ({{ $ageGroups->count() }})</span></div>
        <form class="search-bar" method="POST" action="{{ route('admin.categories.store', 'age-groups') }}">@csrf
          <input class="input" name="name" placeholder="e.g. U-16" required>
          <input class="input" name="min_age" type="number" placeholder="min" style="max-width:80px;">
          <input class="input" name="max_age" type="number" placeholder="max" style="max-width:80px;">
          <button class="btn btn-primary">Add</button>
        </form>
        <table class="table"><thead><tr><th>Name</th><th>Range</th><th></th></tr></thead><tbody>
          @forelse($ageGroups as $a)
            <tr><td><div class="cat-name">{{ $a->name }}</div></td><td>{{ $a->min_age ?: '?' }}–{{ $a->max_age ?: '?' }}</td>
              <td><form method="POST" action="{{ route('admin.categories.destroy', ['age-groups', $a->id]) }}">@csrf @method('DELETE')<button class="action-btn delete"><i data-lucide="trash-2" style="width:12px;height:12px;"></i></button></form></td></tr>
          @empty <tr><td colspan="3" class="empty">No age groups.</td></tr> @endforelse
        </tbody></table>
      </div>
    </div>
  </div>
@endsection
