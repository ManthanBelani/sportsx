@extends('admin.layouts.main')

@section('title', 'Sport Categories')

@push('topbar-actions')
<button class="btn btn-primary"><i data-lucide="plus" style="width:16px;height:16px;"></i> Add Category</button>
@endpush

@section('content')
<style>
  .card { background: #fff; border-radius: 12px; border: 1px solid #e5e7eb; overflow: hidden; margin-bottom: 20px; }
  .card-header { padding: 16px 20px; border-bottom: 1px solid #e5e7eb; display: flex; align-items: center; justify-content: space-between; }
  .card-title { font-size: 15px; font-weight: 600; }
  .table { width: 100%; border-collapse: collapse; }
  .table th { text-align: left; padding: 12px 20px; font-size: 12px; font-weight: 600; color: #6b7280; background: #f9fafb; border-bottom: 1px solid #e5e7eb; }
  .table td { padding: 14px 20px; font-size: 14px; border-bottom: 1px solid #f0f0f0; vertical-align: middle; }
  .table tr:hover { background: #f9fafb; }
  .cat-cell { display: flex; align-items: center; gap: 12px; }
  .cat-icon { width: 36px; height: 36px; background: #f0f7ff; border-radius: 8px; display: flex; align-items: center; justify-content: center; }
  .cat-name { font-weight: 500; }
  .cat-subcount { font-size: 12px; color: #6b7280; }
  .action-btns { display: flex; gap: 8px; }
  .action-btn { padding: 6px 12px; border-radius: 6px; font-size: 12px; font-weight: 500; border: none; cursor: pointer; }
  .action-btn.edit { background: #f0f7ff; color: #1677ff; }
  .action-btn.delete { background: #fee2e2; color: #dc2626; }
  .badge { font-size: 11px; padding: 4px 8px; border-radius: 4px; font-weight: 500; }
  .badge.active { background: #dcfce7; color: #16a34a; }
  .badge.inactive { background: #fee2e2; color: #dc2626; }
</style>

<div class="card">
  <div class="card-header">
    <span class="card-title" id="categories-count">All Sports (0)</span>
  </div>
  <table class="table">
    <thead>
      <tr>
        <th>Sport</th>
        <th>Sub-categories</th>
        <th>Listings</th>
        <th>Status</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody id="categories-list">
      <tr><td colspan="5" style="text-align:center;padding:40px;color:#6b7280;">Loading categories...</td></tr>
    </tbody>
  </table>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', () => {
    if (!requireAuth()) return;
    renderCategories();
});

function renderCategories() {
    const list = document.getElementById('categories-list');
    
    // MVP mock data
    const categories = [
        { id: 1, name: 'Football', sub: '4 sub-categories', subsList: 'U-8, U-12, U-16, Senior', listings: '1,247', status: 'active', color: '1677ff' },
        { id: 2, name: 'Cricket', sub: '6 sub-categories', subsList: 'Batting, Bowling, Fielding, U-14, U-19, Senior', listings: '2,341', status: 'active', color: '16a34a' },
        { id: 3, name: 'Badminton', sub: '3 sub-categories', subsList: 'Singles, Doubles, Mixed', listings: '892', status: 'active', color: 'd97706' },
        { id: 4, name: 'Chess', sub: '2 sub-categories', subsList: 'Classical, Rapid', listings: '456', status: 'inactive', color: '9333ea' },
    ];

    document.getElementById('categories-count').textContent = `All Sports (${categories.length})`;

    list.innerHTML = categories.map(c => `
        <tr>
          <td>
            <div class="cat-cell">
              <div class="cat-icon"><i data-lucide="circle" style="width:18px;height:18px;color:#${c.color};"></i></div>
              <div>
                <div class="cat-name">${c.name}</div>
                <div class="cat-subcount">${c.sub}</div>
              </div>
            </div>
          </td>
          <td>${c.subsList}</td>
          <td>${c.listings}</td>
          <td><span class="badge ${c.status}">${c.status.charAt(0).toUpperCase() + c.status.slice(1)}</span></td>
          <td>
            <div class="action-btns">
              <button class="action-btn edit" onclick="alert('Edit ${c.id}')"><i data-lucide="pencil" style="width:12px;height:12px;"></i> Edit</button>
              <button class="action-btn delete" onclick="alert('Delete ${c.id}')"><i data-lucide="trash-2" style="width:12px;height:12px;"></i></button>
            </div>
          </td>
        </tr>
    `).join('');
    
    lucide.createIcons();
}
</script>
@endpush
