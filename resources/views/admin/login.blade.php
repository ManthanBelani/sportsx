@extends('admin.layouts.app')
@section('title', 'Admin Login · SportX India')
@section('content')
<div class="login-page">
  <div class="login-card">
    <div class="login-logo">SX</div>
    <div class="login-title">SportX Admin</div>
    <div class="login-subtitle">Sign in to the control panel</div>

    @if(session('error')) <div class="flash flash-error">{{ session('error') }}</div> @endif
    @if($errors->any()) <div class="flash flash-error">{{ implode(' ', $errors->all()) }}</div> @endif

    <form method="POST" action="{{ route('admin.login') }}">
      @csrf
      <div class="form-group">
        <label class="form-label">Email</label>
        <input class="input" type="email" name="email" value="{{ old('email') }}" placeholder="admin@sportx.in" required autofocus>
      </div>
      <div class="form-group">
        <label class="form-label">Password</label>
        <input class="input" type="password" name="password" placeholder="••••••••" required>
      </div>
      <div class="form-group" style="display:flex;align-items:center;gap:8px;">
        <input type="checkbox" name="remember" id="remember">
        <label for="remember" style="font-size:13px;color:#6B7280;">Remember me</label>
      </div>
      <button type="submit" class="btn btn-primary btn-block">Sign in</button>
    </form>
  </div>
</div>
@endsection
