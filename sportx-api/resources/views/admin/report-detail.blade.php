@extends('admin.layouts.app')
@section('title', 'Report #'.$report->id)
@section('header-actions')
  <a href="{{ route('admin.reports') }}" class="back-btn"><i data-lucide="arrow-left"></i> Back to Reports</a>
@endsection

@section('content')
  <div class="detail-card">
    <div class="detail-header">
      <div class="detail-id">Report #{{ $report->id }}</div>
      <span class="badge {{ $report->status === 'pending' ? 'pending' : 'active' }}">{{ ucfirst($report->status) }}</span>
    </div>

    <div class="detail-section">
      <h3>Report Details</h3>
      <div class="detail-row">
        <span class="label">Reason:</span>
        <span class="value">{{ ucfirst($report->reason ?: 'Not specified') }}</span>
      </div>
      <div class="detail-row">
        <span class="label">Comment:</span>
        <span class="value">{{ $report->comment ?: 'No comment provided' }}</span>
      </div>
      <div class="detail-row">
        <span class="label">Filed:</span>
        <span class="value">{{ $report->created_at?->diffForHumans() }}</span>
      </div>
      <div class="detail-row">
        <span class="label">Reporter:</span>
        <span class="value">User #{{ $report->reporter_user_id }}</span>
      </div>
    </div>

    <div class="detail-section">
      <h3>Reported Content</h3>
      <div class="detail-row">
        <span class="label">Type:</span>
        <span class="value">{{ class_basename($report->reportable_type ?? 'Unknown') }}</span>
      </div>
      <div class="detail-row">
        <span class="label">ID:</span>
        <span class="value">#{{ $report->reportable_id }}</span>
      </div>
    </div>

    @if($report->status === 'pending')
    <div class="detail-actions">
      <form method="POST" action="{{ route('admin.reports.action', $report->id) }}">
        @csrf
        <input type="hidden" name="action" value="resolve">
        <button class="btn-primary">Resolve Report</button>
      </form>
      <form method="POST" action="{{ route('admin.reports.action', $report->id) }}">
        @csrf
        <input type="hidden" name="action" value="escalate">
        <button class="btn-secondary">Escalate</button>
      </form>
    </div>
    @endif
  </div>
@endsection
