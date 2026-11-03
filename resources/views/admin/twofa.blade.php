@extends('admin.layouts.app')
@section('title', 'Two-Factor Verification · SportX India')
@section('content')
<div class="login-page">
  <div class="login-card">
    <div class="login-logo">🔐</div>
    <div class="login-title">Two-Factor Authentication</div>
    <div class="login-subtitle">Enter the 6-digit code from your authenticator app.</div>

    @if(session('error')) <div class="flash flash-error">{{ session('error') }}</div> @endif
    @if($errors->any()) <div class="flash flash-error">{{ implode(' ', $errors->all()) }}</div> @endif

    @if(!empty($setup_url))
      <div class="flash" style="background:#eff6ff;border:1px solid #bfdbfe;color:#1e40af;text-align:left;">
        <strong>First-time setup:</strong> add SportX to your authenticator app (Google Authenticator, Authy, 1Password…).<br>
        Scan this link with your app, or enter the secret manually:<br>
        <code style="word-break:break-all;display:block;margin-top:6px;font-size:12px;">{{ $setup_url }}</code>
        <code style="word-break:break-all;display:block;margin-top:6px;font-size:14px;font-weight:700;">{{ $secret }}</code>
      </div>
    @endif

    <form method="POST" action="{{ route('admin.2fa') }}">
      @csrf
      <div class="form-group">
        <input class="input otp-input" type="text" name="code" maxlength="6" pattern="\d{6}" inputmode="numeric" placeholder="000000" required autofocus>
      </div>
      <button type="submit" class="btn btn-primary btn-block">Verify & Continue</button>
    </form>
    <form method="POST" action="{{ route('admin.logout') }}" style="margin-top:14px;text-align:center;">
      @csrf
      <button type="submit" class="btn btn-ghost btn-sm">Cancel & sign out</button>
    </form>
  </div>
</div>
@endsection
