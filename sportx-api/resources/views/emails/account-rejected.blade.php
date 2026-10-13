@extends('emails.layout', ['accent' => '#dc2626', 'accentDark' => '#991b1b'])

@section('subject', 'Update on your SportX registration')

@section('content')
    <h2 style="margin:0 0 16px;font-size:20px;font-weight:600;color:#111111;">
        {{ $suspended ? 'Your account has been suspended' : 'Registration update' }}
    </h2>
    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">Hi {{ $name }},</p>

    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">
        @if ($suspended)
            Your SportX {{ $role }} account is currently suspended, so your profile is no longer visible to other members.
        @else
            We were unable to approve your SportX {{ $role }} registration at this time.
        @endif
    </p>

    @if ($reason)
        <div style="margin:0 0 24px;padding:16px;background-color:#fef2f2;border-radius:8px;border-left:4px solid #dc2626;">
            <p style="margin:0 0 4px;font-size:13px;font-weight:600;color:#991b1b;">Reason given</p>
            <p style="margin:0;font-size:13px;line-height:1.6;color:#991b1b;">{{ $reason }}</p>
        </div>
    @endif

    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">If you think this is a mistake, reply to our team and we'll take another look — most rejections are missing documents that are quick to fix.</p>

    <p style="margin:0;text-align:center;">
        <a href="{{ $supportUrl }}" style="display:inline-block;padding:14px 32px;background-color:#dc2626;color:#ffffff;font-size:14px;font-weight:600;text-decoration:none;border-radius:8px;">Contact support</a>
    </p>
@endsection