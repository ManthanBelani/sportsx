@extends('admin.layouts.app')
@section('title', 'Content')

@section('content')
<p class="muted" style="margin-bottom:16px;">Browse, publish/unpublish, or remove listings across every directory.</p>

<div class="content-grid">
  @php
    $labels = ['academies'=>'Academies','coaches'=>'Coaches','trials'=>'Trials','tournaments'=>'Tournaments','scholarships'=>'Scholarships','sponsorships'=>'Sponsorships','sports-venues'=>'Sports Venues'];
  @endphp
  @foreach($counts as $type => $c)
  <a href="{{ route('admin.content.list', $type) }}" class="content-card">
    <div class="content-card-title">{{ $labels[$type] ?? ucfirst(str_replace('-',' ',$type)) }}</div>
    <div class="content-card-stats">
      <div><b>{{ $c['total'] }}</b>Total</div>
      <div><b style="color:#16a34a;">{{ $c['published'] }}</b>Live</div>
      <div><b style="color:#d97706;">{{ $c['draft'] }}</b>Draft</div>
    </div>
  </a>
  @endforeach
</div>
@endsection
