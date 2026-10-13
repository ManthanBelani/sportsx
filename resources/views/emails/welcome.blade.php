@extends('emails.layout', ['accent' => '#16a34a', 'accentDark' => '#15803d'])

@section('subject', 'Welcome to SportX India')

@section('content')
    <h2 style="margin:0 0 16px;font-size:20px;font-weight:600;color:#111111;">You're in, {{ $name }}!</h2>
    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">Your SportX {{ $role }} account is ready. Complete your profile to start getting discovered.</p>

    @if ($pendingApproval)
        <div style="margin:0 0 24px;padding:16px;background-color:#eff6ff;border-radius:8px;border-left:4px solid #1677ff;">
            <p style="margin:0 0 8px;font-size:14px;font-weight:600;color:#1e3a8a;">Approval in progress</p>
            <p style="margin:0;font-size:13px;line-height:1.6;color:#1e40af;">{{ $role }} accounts are reviewed by our team to keep SportX trustworthy. You can explore the app in the meantime — full access unlocks as soon as you're approved.</p>
        </div>
    @endif

    <p style="margin:0 0 32px;text-align:center;">
        <a href="{{ $appUrl }}" style="display:inline-block;padding:14px 32px;background-color:#16a34a;color:#ffffff;font-size:14px;font-weight:600;text-decoration:none;border-radius:8px;">Open SportX</a>
    </p>

    <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">Discover trials, tournaments, scholarships and academies near you — all in one place.</p>
@endsection