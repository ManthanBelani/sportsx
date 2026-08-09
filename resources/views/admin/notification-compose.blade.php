@extends('admin.layouts.main')

@section('title', 'Notification Templates')

@push('topbar-actions')
<button class="btn btn-primary" onclick="alert('Compose new notification')">Compose New</button>
@endpush

@section('content')
<style>
  .card { background: #fff; border-radius: 12px; border: 1px solid #e5e7eb; margin-bottom: 16px; overflow: hidden; }
  .template-header { display: flex; align-items: center; gap: 12px; padding: 14px 20px; border-bottom: 1px solid #f0f0f0; background: #f9fafb; }
  .template-type { font-size: 11px; padding: 4px 10px; border-radius: 6px; font-weight: 500; }
  .template-type.email { background: #dbeafe; color: #1677ff; }
  .template-type.push { background: #fef3c7; color: #d97706; }
  .template-type.sms { background: #dcfce7; color: #16a34a; }
  .template-name { font-size: 14px; font-weight: 600; }
  .template-body { padding: 16px 20px; }
  .template-preview { font-size: 13px; color: #6b7280; line-height: 1.5; background: #f9fafb; padding: 12px; border-radius: 8px; margin-bottom: 12px; }
  .template-meta { display: flex; gap: 20px; font-size: 12px; color: #6b7280; margin-bottom: 12px; }
  .template-meta span { display: flex; align-items: center; gap: 6px; }
  .template-actions { display: flex; gap: 8px; }
  .action-btn { padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 500; border: none; cursor: pointer; display: flex; align-items: center; gap: 6px; }
  .action-btn.edit { background: #f0f7ff; color: #1677ff; }
  .action-btn.duplicate { background: #f9fafb; color: #6b7280; border: 1px solid #e5e7eb; }
  .action-btn.delete { background: #fee2e2; color: #dc2626; }
</style>

<div id="templates-list">
  <div style="text-align:center;padding:40px;color:#6b7280;">Loading templates...</div>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', () => {
    if (!requireAuth()) return;
    renderTemplates();
});

function renderTemplates() {
    const list = document.getElementById('templates-list');
    
    // MVP mock data based on design
    const templates = [
        { id: 1, type: 'email', name: 'Welcome to SportX', preview: '"Welcome to SportX India! We\'re excited to have you join our community of athletes, coaches, and sports enthusiasts. Start exploring trials, tournaments, and scholarships near you..."', sent: '12,847', metricIcon: 'trending-up', metricVal: '68% open rate' },
        { id: 2, type: 'push', name: 'Trial Reminder', preview: '"Reminder: Your football trial at Sunrise Academy is tomorrow at 7:00 AM. Don\'t forget to bring your gear! Location: Kanteerava Stadium, Bangalore."', sent: '4,231', metricIcon: 'trending-up', metricVal: '89% open rate' },
        { id: 3, type: 'sms', name: 'Scholarship Deadline', preview: '"SportX: Last day to apply for the AIFF Scholarship! 25 athletes will be selected for INR 50,000/year. Apply now: sportx.in/apply"', sent: '8,912', metricIcon: 'trending-up', metricVal: '45% click rate' },
    ];

    list.innerHTML = templates.map(t => `
        <div class="card">
          <div class="template-header">
            <span class="template-type ${t.type}">${t.type.toUpperCase()}</span>
            <span class="template-name">${t.name}</span>
          </div>
          <div class="template-body">
            <div class="template-preview">${t.preview}</div>
            <div class="template-meta">
              <span><i data-lucide="send" style="width:14px;height:14px;"></i> Sent: ${t.sent} times</span>
              <span><i data-lucide="${t.metricIcon}" style="width:14px;height:14px;"></i> ${t.metricVal}</span>
            </div>
            <div class="template-actions">
              <button class="action-btn edit" onclick="alert('Edit')"><i data-lucide="pencil" style="width:14px;height:14px;"></i> Edit</button>
              <button class="action-btn duplicate" onclick="alert('Duplicate')"><i data-lucide="copy" style="width:14px;height:14px;"></i> Duplicate</button>
              <button class="action-btn delete" onclick="alert('Delete')"><i data-lucide="trash-2" style="width:14px;height:14px;"></i> Delete</button>
            </div>
          </div>
        </div>
    `).join('');
    
    lucide.createIcons();
}
</script>
@endpush
